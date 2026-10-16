import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'lan_crypto.dart';

/// PC-hosted pairing + file server. The phone scans a QR containing
/// `novapair://<ip>:<port>/<token>` — the token is required on every API
/// call, so random LAN clients can't browse files.
///
/// Endpoints (all need ?token=):
///   GET  /api/info                      → {name, version}
///   GET  /api/list?dir=abs-or-empty     → entries of a shared folder
///   GET  /api/dl?path=abs               → file bytes (must be inside a share)
///   POST /api/upload?dir=abs            → multipart upload into shared dir
///   POST /api/pair {phoneUrl}           → phone registers its share server
///   GET  /api/phone                     → {url} of registered phone server
///   POST /api/unpair                    → clear registration + rotate token
class PairServer {
  PairServer({required this.onPhoneChanged, String? token})
    : _token = (token != null && token.isNotEmpty) ? token : _newToken();

  /// Called when the registered phone URL changes (pair/unpair).
  final void Function(String? phoneUrl) onPhoneChanged;

  /// Fixed port keeps the pairing link stable across restarts; if the
  /// port is busy (another copy running), falls back to a random one.
  static const preferredPort = 48320;

  HttpServer? _server;
  String? _ip;
  final String _token;
  String? _phoneUrl;

  /// Absolute paths of folders shared with the phone.
  List<String> sharedRoots = [];

  /// APK file currently shared via the "APK with QR" dialog — served at
  /// GET /apk?token=... so a phone camera scan downloads it.
  String? sharedApk;

  String get token => _token;

  static String _newToken() => List.generate(
    16,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  String get pairUrl => 'novapair://$_ip:${_server?.port}/$_token';
  int get port => _server?.port ?? 0;
  String? get phoneUrl => _phoneUrl;
  String? get ip => _ip;

  static Future<String?> localIp() async {
    final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final iface in ifaces) {
      for (final a in iface.addresses) {
        if (!a.isLoopback) return a.address;
      }
    }
    return null;
  }

  Future<void> start() async {
    try {
      _ip = await localIp();
      if (_server == null) {
        try {
          _server = await HttpServer.bind(
            InternetAddress.anyIPv4,
            preferredPort,
          );
        } catch (_) {
          _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        }
      }
      _server!.listen(_handle);
      _log('listening: $pairUrl');
    } catch (e) {
      _log('start failed: $e');
      rethrow;
    }
  }

  static void _log(String msg) {
    try {
      File(
        '${File(Platform.resolvedExecutable).parent.path}'
        '\\data\\nova_server.log',
      ).writeAsStringSync('${DateTime.now()} $msg\n', mode: FileMode.append);
    } catch (_) {}
    // ignore: avoid_print
    print('[PairServer] $msg');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _phoneUrl = null;
  }

  /// API auth: HMAC signature (ts+sig) — the token itself never travels
  /// the wire. Only /apk accepts the raw token (camera → browser flow).
  bool _auth(HttpRequest req) {
    final q = req.uri.queryParameters;
    final ts = int.tryParse(q['ts'] ?? '') ?? 0;
    final sig = q['sig'] ?? '';
    return LanCrypto.verify(_token, req.method, req.uri.path, ts, sig);
  }

  /// Reads + decrypts a sealed request body (phone always sends sealed).
  Future<Uint8List> _body(HttpRequest req) async {
    final raw = await req.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
    final plain = await LanCrypto.open(_token, raw);
    if (plain == null) throw 'bad-body';
    return plain;
  }

  /// Seals and writes a response (all /api responses are encrypted).
  Future<void> _sealed(HttpRequest req, List<int> bytes) async {
    final packed = await LanCrypto.seal(_token, bytes);
    req.response.headers
      ..contentType = ContentType.binary
      ..contentLength = packed.length;
    req.response.add(packed);
    await req.response.close();
  }

  bool _insideShare(String path) {
    final abs = File(path).absolute.path.replaceAll('/', '\\');
    for (final root in sharedRoots) {
      final r = File(root).absolute.path.replaceAll('/', '\\');
      if (abs == r || abs.startsWith('$r\\')) return true;
    }
    return false;
  }

  /// /apk is the only route where the raw token is accepted — the phone
  /// camera opens it in a browser that cannot sign or decrypt.
  bool _authApk(HttpRequest req) => req.uri.queryParameters['token'] == _token;

  Future<void> _handle(HttpRequest req) async {
    try {
      final p = req.uri.path;
      if (req.method == 'GET' && p == '/apk' && _authApk(req)) {
        await _serveApk(req);
        return;
      }
      if (!_auth(req)) {
        req.response
          ..statusCode = 403
          ..write('Forbidden');
        await req.response.close();
        return;
      }
      if (req.method == 'GET' && p == '/api/info') {
        _json(req, {'name': 'Nova Desktop', 'version': 2});
      } else if (req.method == 'GET' && p == '/api/list') {
        await _list(req);
      } else if (req.method == 'GET' && p == '/api/dl') {
        await _download(req);
      } else if (req.method == 'POST' && p == '/api/upload') {
        await _upload(req);
      } else if (req.method == 'POST' && p == '/api/pair') {
        final body = await _body(req);
        final data = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
        _phoneUrl = data['phoneUrl'] as String?;
        onPhoneChanged(_phoneUrl);
        _json(req, {'ok': true});
      } else if (req.method == 'POST' && p == '/api/unpair') {
        // Pairing stays valid — the phone can reconnect anytime until it
        // unpairs from its side too. Only the registered share URL clears.
        _phoneUrl = null;
        onPhoneChanged(null);
        _json(req, {'ok': true});
      } else if (req.method == 'GET' && p == '/api/phone') {
        _json(req, {'url': _phoneUrl});
      } else if (req.method == 'GET' && p == '/api/thumb') {
        await _serveThumb(req);
      } else if (req.method == 'POST' && p == '/api/rename') {
        await _rename(req);
      } else {
        req.response
          ..statusCode = 404
          ..write('Not found');
        await req.response.close();
      }
    } catch (e) {
      try {
        req.response
          ..statusCode = 500
          ..write('$e');
        await req.response.close();
      } catch (_) {}
    }
  }

  /// Encrypted JSON response — the client opens it with the shared token.
  void _json(HttpRequest req, Object data) {
    _sealed(req, utf8.encode(jsonEncode(data)));
  }

  /// [dir] empty → list shared roots; else list that dir (must be in share).
  Future<void> _list(HttpRequest req) async {
    final dir = req.uri.queryParameters['dir'] ?? '';
    final List<Map<String, Object?>> entries = [];
    if (dir.isEmpty) {
      for (final r in sharedRoots) {
        final d = Directory(r);
        if (d.existsSync()) {
          entries.add({
            'name': r.split(Platform.pathSeparator).last,
            'path': r,
            'isDir': true,
          });
        }
      }
    } else {
      if (!_insideShare(dir)) {
        req.response
          ..statusCode = 403
          ..write('Outside shared roots');
        req.response.close();
        return;
      }
      for (final e in Directory(dir).listSync()) {
        final name = e.path.split(Platform.pathSeparator).last;
        if (name.startsWith('.')) continue;
        entries.add({
          'name': name,
          'path': e.path,
          'isDir': e is Directory,
          'size': e is File ? e.lengthSync() : 0,
        });
      }
    }
    entries.sort((a, b) {
      final d = (b['isDir'] == true ? 1 : 0) - (a['isDir'] == true ? 1 : 0);
      return d != 0 ? d : ('${a['name']}').compareTo('${b['name']}');
    });
    _json(req, entries);
  }

  Future<void> _download(HttpRequest req) async {
    final path = req.uri.queryParameters['path'] ?? '';
    if (path.isEmpty || !_insideShare(path)) {
      req.response.statusCode = 403;
      await req.response.close();
      return;
    }
    final f = File(path);
    if (!f.existsSync()) {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    // File contents are AES-256-GCM sealed for the paired phone only.
    await _sealed(req, await f.readAsBytes());
  }

  /// Serves the currently shared APK as a forced download — used by the
  /// "APK with QR" flow where the phone's camera opens this URL.
  Future<void> _serveApk(HttpRequest req) async {
    final path = sharedApk;
    if (path == null || !File(path).existsSync()) {
      req.response
        ..statusCode = 404
        ..write('No APK shared');
      await req.response.close();
      return;
    }
    final f = File(path);
    final name = path.split(Platform.pathSeparator).last;
    req.response.headers
      ..contentType = ContentType('application', 'vnd.android.package-archive')
      ..contentLength = await f.length()
      ..set(
        'Content-Disposition',
        'attachment; filename="${Uri.encodeComponent(name)}"',
      );
    _log('apk download: $name (${await f.length()} bytes)');
    await f.openRead().pipe(req.response);
  }

  /// GET /api/thumb?path=… → scaled JPEG thumbnail for images.
  /// 204 when the file has no thumbnail (apk/video/others fall back to
  /// type icons on the phone side).
  Future<void> _serveThumb(HttpRequest req) async {
    final path = req.uri.queryParameters['path'] ?? '';
    final ext = path.toLowerCase().split('.').last;
    const imgExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
    if (!imgExts.contains(ext) || !_insideShare(path)) {
      req.response.statusCode = 204;
      await req.response.close();
      return;
    }
    try {
      final decoded = img.decodeImage(await File(path).readAsBytes());
      if (decoded == null) throw 'decode';
      final thumb = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? 160 : null,
        height: decoded.height > decoded.width ? 160 : null,
      );
      await _sealed(req, img.encodeJpg(thumb, quality: 80));
    } catch (_) {
      req.response.statusCode = 204;
      await req.response.close();
    }
  }

  /// POST /api/rename {path, name} — renames a file inside a shared
  /// folder (phone can rename PC files while browsing).
  Future<void> _rename(HttpRequest req) async {
    try {
      final body = await _body(req);
      final data = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
      final path = data['path'] as String? ?? '';
      final name = (data['name'] as String? ?? '')
          .split(Platform.pathSeparator)
          .last;
      if (path.isEmpty || name.isEmpty || !_insideShare(path)) {
        req.response.statusCode = 403;
        await req.response.close();
        return;
      }
      final f = File(path);
      if (!f.existsSync()) {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      await f.rename('${f.parent.path}${Platform.pathSeparator}$name');
      _json(req, {'ok': true});
    } catch (e) {
      req.response
        ..statusCode = 500
        ..write('$e');
      await req.response.close();
    }
  }

  Future<void> _upload(HttpRequest req) async {
    final dir = req.uri.queryParameters['dir'] ?? '';
    if (dir.isEmpty || !_insideShare(dir)) {
      req.response.statusCode = 403;
      await req.response.close();
      return;
    }
    // The body arrives sealed — decrypt first, then parse multipart.
    final body = await _body(req);
    final boundary = req.uri.queryParameters['boundary'];
    if (boundary == null || boundary.isEmpty) {
      req.response.statusCode = 400;
      await req.response.close();
      return;
    }
    final delim = utf8.encode('--$boundary');
    final headerEnd = utf8.encode('\r\n\r\n');
    var pos = _indexOf(body, delim, 0);
    var saved = 0;
    while (pos >= 0) {
      final partStart = pos + delim.length;
      if (partStart + 2 <= body.length &&
          body[partStart] == 45 &&
          body[partStart + 1] == 45) {
        break;
      }
      final hEnd = _indexOf(body, headerEnd, partStart);
      if (hEnd < 0) break;
      final headers = latin1.decode(body.sublist(partStart, hEnd));
      final next = _indexOf(body, delim, hEnd);
      if (next < 0) break;
      final content = body.sublist(hEnd + 4, next - 2);
      final name = _fileName(headers);
      if (name != null && name.isNotEmpty) {
        final safe = name.split('/').last.split('\\').last;
        var out = '$dir${Platform.pathSeparator}$safe';
        var n = 1;
        while (File(out).existsSync()) {
          final dot = safe.lastIndexOf('.');
          out = dot > 0
              ? '$dir${Platform.pathSeparator}${safe.substring(0, dot)} ($n)${safe.substring(dot)}'
              : '$dir${Platform.pathSeparator}$safe ($n)';
          n++;
        }
        await File(out).writeAsBytes(content);
        saved++;
      }
      pos = next;
    }
    _json(req, {'saved': saved});
  }

  static String? _fileName(String headers) {
    final m = RegExp(r'filename="([^"]*)"').firstMatch(headers);
    return m?.group(1);
  }

  static int _indexOf(List<int> haystack, List<int> needle, int from) {
    outer:
    for (var i = from; i + needle.length <= haystack.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }
}

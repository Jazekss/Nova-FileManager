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
/// Endpoints (all need a valid ts+nonce+sig signature):
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
  RawDatagramSocket? _udp;
  final String _token;
  String? _phoneUrl;

  /// LAN IPv4 addresses, best first (real Wi-Fi/Ethernet before virtual
  /// adapters such as Hyper-V/WSL/VirtualBox/VPN). The QR carries the
  /// first one as host and the rest as `?alt=` fallbacks — picking a
  /// virtual adapter's IP was why some laptops never paired.
  List<String> ips = [];

  /// Last time a correctly signed request arrived from the phone — the
  /// UI treats the phone as online while this is recent.
  DateTime? lastSeen;

  /// Address the phone's last signed request came from.
  String? lastPhoneIp;

  /// Set by "Disconnect" on the PC: a phone heartbeat within the next
  /// minute is answered with `unpair: true` (reaches phones that share
  /// nothing, too). Expires so a later fresh QR pairing isn't kicked.
  DateTime? _kickAt;

  void kickPhone() {
    _kickAt = DateTime.now();
    lastSeen = null;
  }

  /// Absolute paths of folders shared with the phone.
  List<String> sharedRoots = [];

  /// APK file currently shared via the "APK with QR" dialog — served at
  /// GET /apk?k=... so a phone camera scan downloads it.
  String? sharedApk;

  /// One-off token for the /apk browser download — deliberately NOT the
  /// pairing token, so the master secret never travels the wire even in
  /// this unsigned flow.
  String apkToken = _newToken();

  /// Restores a persisted phone share URL on app start — the phone's
  /// server may still be running, so the panel can reconnect without a
  /// fresh /api/pair registration.
  void restorePhoneUrl(String? url) => _phoneUrl = url;

  String get token => _token;

  static String _newToken() => List.generate(
    16,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  /// Rotates the /apk download token — call whenever a new APK is
  /// picked so old QR links stop working.
  void rotateApkToken() => apkToken = _newToken();

  String? get ip => ips.isEmpty ? null : ips.first;

  String get pairUrl {
    final alt = ips.skip(1).take(3).join(',');
    return 'novapair://$ip:${_server?.port}/$_token'
        '${alt.isEmpty ? '' : '?alt=$alt'}';
  }

  int get port => _server?.port ?? 0;
  String? get phoneUrl => _phoneUrl;

  /// True while the phone has talked to us recently (heartbeat ~8 s).
  bool get phoneOnline =>
      lastSeen != null &&
      DateTime.now().difference(lastSeen!) < const Duration(seconds: 25);

  /// Re-reads the adapter list — call periodically so a DHCP change or
  /// a switch between Wi-Fi/cable shows the right QR. Returns true when
  /// the list changed.
  Future<bool> refreshIps() async {
    final fresh = await localIps();
    final changed = fresh.join(',') != ips.join(',');
    ips = fresh;
    return changed;
  }

  /// All usable IPv4 addresses ranked by how likely the phone can reach
  /// them.
  static Future<List<String>> localIps() async {
    final List<(int, String)> scored = [];
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in ifaces) {
        final name = iface.name.toLowerCase();
        for (final a in iface.addresses) {
          if (a.isLoopback || a.isLinkLocal) continue;
          scored.add((_score(name, a.address), a.address));
        }
      }
    } catch (_) {}
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return scored.map((e) => e.$2).toSet().toList();
  }

  static const _virtualHints = [
    'vethernet',
    'virtualbox',
    'vbox',
    'vmware',
    'hyper-v',
    'wsl',
    'docker',
    'vpn',
    'tap',
    'tun',
    'tailscale',
    'zerotier',
    'hamachi',
    'radmin',
    'wireguard',
    'nordlynx',
    'bluetooth',
    'npcap',
    'loopback',
    'pseudo',
  ];

  static int _score(String name, String ip) {
    var s = 0;
    if (_virtualHints.any(name.contains)) s -= 100;
    if (name.contains('wi-fi') ||
        name.contains('wifi') ||
        name.contains('wlan') ||
        name.contains('wireless') ||
        name.contains('bezvadu')) {
      s += 20;
    }
    if (name.startsWith('ethernet') || name.contains('local area')) s += 15;
    if (ip.startsWith('192.168.56.')) s -= 50; // VirtualBox host-only
    if (ip.startsWith('192.168.')) {
      s += 10;
    } else if (ip.startsWith('10.')) {
      s += 6;
    } else if (RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip)) {
      s += 2; // also Hyper-V/WSL ranges — lowest of the private ones
    }
    return s;
  }

  Future<void> start() async {
    try {
      await refreshIps();
      if (_server == null) {
        try {
          _server = await HttpServer.bind(
            InternetAddress.anyIPv4,
            preferredPort,
          );
        } catch (_) {
          _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        }
        _server!.listen(_handle);
      }
      await _startDiscovery();
      _log('listening: $pairUrl  (ips: ${ips.join(', ')})');
    } catch (e) {
      _log('start failed: $e');
      rethrow;
    }
  }

  /// Answers UDP "NOVA_DISCOVER" probes with `NOVA_HERE|pairId|port|name`
  /// — a paired phone whose stored address went stale (new DHCP lease,
  /// other network) finds this PC again without a new QR scan. Only the
  /// HMAC-derived pair id is revealed, never the token.
  Future<void> _startDiscovery() async {
    if (_udp != null) return;
    try {
      final udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        LanCrypto.discoveryPort,
        reuseAddress: true,
      );
      _udp = udp;
      final id = LanCrypto.pairId(_token);
      final host = Platform.localHostname.replaceAll('|', ' ');
      udp.listen((ev) {
        if (ev != RawSocketEvent.read) return;
        final dg = udp.receive();
        if (dg == null) return;
        final msg = utf8.decode(dg.data, allowMalformed: true).trim();
        if (msg != LanCrypto.discoverProbe) return;
        try {
          udp.send(
            utf8.encode('NOVA_HERE|$id|$port|$host'),
            dg.address,
            dg.port,
          );
        } catch (_) {}
      });
    } catch (e) {
      _log('discovery bind failed: $e');
    }
  }

  static void _log(String msg) {
    try {
      final base =
          Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
      final dir = Directory('$base\\NovaTransfer')..createSync(recursive: true);
      File('${dir.path}\\nova_server.log')
          .writeAsStringSync('${DateTime.now()} $msg\n', mode: FileMode.append);
    } catch (_) {}
    // ignore: avoid_print
    print('[PairServer] $msg');
  }

  Future<void> stop() async {
    _udp?.close();
    _udp = null;
    await _server?.close(force: true);
    _server = null;
    _phoneUrl = null;
  }

  /// API auth: HMAC signature over method+path+query+ts — the token
  /// itself never travels the wire. Replayed signatures are refused;
  /// only /apk uses its own one-off token (camera → browser flow).
  bool _auth(HttpRequest req) {
    final q = req.uri.queryParameters;
    final ts = int.tryParse(q['ts'] ?? '') ?? 0;
    final sig = q['sig'] ?? '';
    if (!LanCrypto.verify(_token, req.method, req.uri.path, ts, sig, q)) {
      return false;
    }
    return _seen(sig);
  }

  /// Signatures accepted inside their validity window — an identical
  /// replayed packet is refused (requests carry a unique nonce).
  final Map<String, int> _seenSigs = {};

  bool _seen(String sig) {
    final now = LanCrypto.now();
    _seenSigs.removeWhere((_, t) => (now - t).abs() > LanCrypto.windowSec + 60);
    if (_seenSigs.containsKey(sig)) return false;
    _seenSigs[sig] = now;
    return true;
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

  /// /apk is the only unsigned route — the phone camera opens it in a
  /// browser that cannot sign or decrypt. It uses a dedicated one-off
  /// token so the pairing secret never appears in a request.
  bool _authApk(HttpRequest req) =>
      sharedApk != null && req.uri.queryParameters['k'] == apkToken;

  Future<void> _handle(HttpRequest req) async {
    try {
      final p = req.uri.path;
      if (req.method == 'GET' && p == '/apk' && _authApk(req)) {
        await _serveApk(req);
        return;
      }
      if (!_auth(req)) {
        // Server clock lets the phone fix a skewed clock and retry
        // instead of believing it was unpaired.
        req.response
          ..statusCode = 403
          ..headers.set(LanCrypto.timeHeader, '${LanCrypto.now()}')
          ..write('Forbidden');
        await req.response.close();
        return;
      }
      lastSeen = DateTime.now();
      lastPhoneIp = req.connectionInfo?.remoteAddress.address;
      if (req.method == 'GET' && p == '/api/info') {
        // A (re)pairing phone probes /api/info first — a stale
        // "disconnect" must not kick the fresh pairing.
        _kickAt = null;
        _json(req, {'name': 'Nova Desktop', 'version': 3});
      } else if (req.method == 'GET' && p == '/api/list') {
        await _list(req);
      } else if (req.method == 'GET' && p == '/api/dl') {
        await _download(req);
      } else if (req.method == 'POST' && p == '/api/upload') {
        await _upload(req);
      } else if (req.method == 'POST' && p == '/api/pair') {
        final body = await _body(req);
        final data = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
        final kick = _kickAt;
        if (kick != null &&
            DateTime.now().difference(kick) < const Duration(minutes: 1)) {
          // "Disconnect" on the PC — the phone drops its pairing when it
          // reads this on its next heartbeat.
          _kickAt = null;
          lastSeen = null;
          _json(req, {'ok': true, 'unpair': true});
          return;
        }
        // Heartbeat-safe: the phone re-posts every few seconds, the UI
        // only hears about real changes.
        final url = _reachableUrl(data['phoneUrl'] as String?, req);
        if (url != _phoneUrl) {
          _phoneUrl = url;
          onPhoneChanged(_phoneUrl);
        }
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

  /// The phone may report an address we can't route to (mobile-data
  /// interface, stale DHCP lease) — the address its request actually
  /// came from is the one that works, so swap the host for that.
  static String? _reachableUrl(String? url, HttpRequest req) {
    if (url == null || url.isEmpty) return null;
    final remote = req.connectionInfo?.remoteAddress.address;
    final u = Uri.tryParse(url);
    if (u == null || remote == null) return url;
    return u.replace(host: remote).toString();
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

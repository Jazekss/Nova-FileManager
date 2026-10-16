import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../../core/crypto/lan_crypto.dart';

/// A file (or zipped folder) offered for download over the HTTP share page.
class SharedFile {
  const SharedFile({
    required this.path,
    required this.downloadName,
    required this.size,
  });

  final String path;
  final String downloadName;
  final int size;
}

/// Tiny embedded HTTP server used for LAN file transfer:
/// - GET /        → upload form + download links for shared files
/// - GET /f/{i}   → downloads shared file i
/// - GET /api/list → JSON share list (for companion clients)
/// - POST /upload → multipart upload, saved into [uploadDir]
///
/// No encryption — meant for trusted home/office Wi-Fi only.
class WifiShareServer {
  WifiShareServer({required this.uploadDir, this.onReceived, this.onUnpair});

  /// Can be switched while the server is running — later uploads land in
  /// the new folder.
  Directory uploadDir;
  final void Function(String fileName)? onReceived;

  /// Called when the paired PC asks to disconnect (POST /api/unpair).
  final void Function()? onUnpair;

  HttpServer? _server;
  List<SharedFile> _shares = const [];
  String _shareToken = '';

  int get port => _server?.port ?? 0;
  List<SharedFile> get shares => _shares;
  String? _ip;

  /// URL registered with the paired PC — carries `?k=<token>`; every
  /// endpoint requires a signed request and answers with sealed bytes.
  String get url => _ip == null ? '' : 'http://$_ip:$port?k=$_shareToken';

  /// First non-loopback IPv4 address (wlan0 on Android).
  static Future<String?> localIp() async {
    final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final iface in ifaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return null;
  }

  Future<void> start(List<SharedFile> shares) async {
    _shares = shares;
    _shareToken = List.generate(
      16,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    _ip = await localIp();
    if (_ip == null) {
      throw const SocketException('No Wi-Fi network found');
    }
    await uploadDir.create(recursive: true);
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handle);
  }

  Future<void> stop() async => _server?.close(force: true);

  /// Signed-request auth against this share session's token.
  bool _auth(HttpRequest req) {
    final q = req.uri.queryParameters;
    final ts = int.tryParse(q['ts'] ?? '') ?? 0;
    final sig = q['sig'] ?? '';
    return LanCrypto.verify(_shareToken, req.method, req.uri.path, ts, sig);
  }

  Future<Uint8List> _sealedBody(HttpRequest req) async {
    final raw = await req.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
    final plain = await LanCrypto.open(_shareToken, raw);
    if (plain == null) throw 'bad-body';
    return plain;
  }

  Future<void> _seal(HttpRequest req, List<int> bytes) async {
    final packed = await LanCrypto.seal(_shareToken, bytes);
    req.response.headers
      ..contentType = ContentType.binary
      ..contentLength = packed.length;
    req.response.add(packed);
    await req.response.close();
  }

  Future<void> _handle(HttpRequest req) async {
    try {
      if (req.method == 'GET' && (req.uri.path == '/' || req.uri.path == '')) {
        _serveIndex(req);
        return;
      }
      if (!_auth(req)) {
        req.response
          ..statusCode = 403
          ..write('Forbidden');
        await req.response.close();
        return;
      }
      if (req.method == 'GET' && req.uri.path == '/api/list') {
        await _serveApiList(req);
      } else if (req.method == 'GET' && req.uri.path.startsWith('/f/')) {
        await _serveFile(req);
      } else if (req.method == 'GET' && req.uri.path.startsWith('/api/thumb')) {
        await _serveThumb(req);
      } else if (req.method == 'POST' && req.uri.path == '/api/rename') {
        await _rename(req);
      } else if (req.method == 'POST' && req.uri.path == '/api/unpair') {
        req.response
          ..statusCode = 200
          ..write('{"ok":true}');
        await req.response.close();
        onUnpair?.call();
      } else if (req.method == 'POST' && req.uri.path == '/upload') {
        await _handleUpload(req);
      } else {
        req.response
          ..statusCode = 404
          ..write('Not found');
        await req.response.close();
      }
    } catch (_) {
      try {
        req.response.statusCode = 500;
        await req.response.close();
      } catch (_) {}
    }
  }

  /// No data is exposed without a signed request — the index page only
  /// confirms the share server is alive.
  void _serveIndex(HttpRequest req) {
    req.response
      ..headers.contentType = ContentType.html
      ..write(
        '<!doctype html><meta charset="utf-8"><title>Nova share</title>'
        '<p style="font-family:system-ui">Nova phone share is active.</p>',
      );
    req.response.close();
  }

  /// Sealed JSON: [{"i":0,"name":"a.txt","size":123}].
  Future<void> _serveApiList(HttpRequest req) {
    final json = jsonEncode([
      for (var i = 0; i < _shares.length; i++)
        {'i': i, 'name': _shares[i].downloadName, 'size': _shares[i].size},
    ]);
    return _seal(req, utf8.encode(json));
  }

  Future<void> _serveFile(HttpRequest req) async {
    final i = int.tryParse(req.uri.path.substring(3)) ?? -1;
    if (i < 0 || i >= _shares.length) {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    final s = _shares[i];
    await _seal(req, await File(s.path).readAsBytes());
  }

  static const _channel = MethodChannel('dev.nova.nova_file_manager/storage');
  static const _imgExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
  static const _videoExts = {'mp4', 'mkv', 'avi', 'mov', 'webm', '3gp'};
  static const _apkExts = {'apk', 'aab'};

  /// GET /api/thumb?i=N → JPEG/PNG thumbnail for a shared file:
  /// images are resized locally, video frames and APK icons come from
  /// the native channel. 204 when no thumbnail exists.
  Future<void> _serveThumb(HttpRequest req) async {
    final i =
        int.tryParse(req.uri.queryParameters['i'] ?? '') ??
        int.tryParse(req.uri.queryParameters['idx'] ?? '') ??
        -1;
    if (i < 0 || i >= _shares.length) {
      req.response.statusCode = 204;
      await req.response.close();
      return;
    }
    final f = File(_shares[i].path);
    final name = f.path.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : '';
    List<int>? bytes;
    try {
      if (_imgExts.contains(ext)) {
        final decoded = img.decodeImage(await f.readAsBytes());
        if (decoded != null) {
          final thumb = img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 160 : null,
            height: decoded.height > decoded.width ? 160 : null,
          );
          bytes = img.encodeJpg(thumb, quality: 80);
        }
      } else if (_apkExts.contains(ext)) {
        bytes = await _channel.invokeMethod<List<int>>('apkIcon', {
          'path': f.path,
        });
      } else if (_videoExts.contains(ext)) {
        bytes = await _channel.invokeMethod<List<int>>('videoThumb', {
          'path': f.path,
        });
      }
    } catch (_) {}
    if (bytes == null) {
      req.response.statusCode = 204;
      await req.response.close();
      return;
    }
    await _seal(req, bytes);
  }

  /// POST /api/rename {i, name} — renames a shared file on disk.
  /// The PC's right panel calls this when the user renames a phone file.
  Future<void> _rename(HttpRequest req) async {
    final body = await _sealedBody(req);
    final data = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
    final i = (data['i'] as num?)?.toInt() ?? -1;
    final name = (data['name'] as String? ?? '').split('/').last;
    if (i < 0 || i >= _shares.length || name.isEmpty) {
      req.response.statusCode = 400;
      await req.response.close();
      return;
    }
    try {
      final old = _shares[i];
      final newPath = '${File(old.path).parent.path}/$name';
      await File(old.path).rename(newPath);
      _shares = [
        for (var j = 0; j < _shares.length; j++)
          j == i
              ? SharedFile(path: newPath, downloadName: name, size: old.size)
              : _shares[j],
      ];
      await _seal(req, utf8.encode('{"ok":true}'));
    } catch (e) {
      req.response
        ..statusCode = 500
        ..write('$e');
      await req.response.close();
    }
  }

  /// Minimal multipart/form-data parser: splits the body on the boundary,
  /// reads the filename from Content-Disposition and writes part bytes.
  Future<void> _handleUpload(HttpRequest req) async {
    final boundary = req.uri.queryParameters['boundary'];
    if (boundary == null || boundary.isEmpty) {
      req.response.statusCode = 400;
      await req.response.close();
      return;
    }
    final body = await _sealedBody(req);
    final delim = utf8.encode('--$boundary');
    final headerEnd = utf8.encode('\r\n\r\n');

    var pos = _indexOf(body, delim, 0);
    while (pos >= 0) {
      final partStart = pos + delim.length;
      // '--' after the delimiter marks the final boundary.
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
      // Trim the trailing CRLF that precedes the next boundary.
      final content = body.sublist(hEnd + 4, next - 2);
      final name = _fileName(headers);
      if (name != null && name.isNotEmpty) {
        final safe = name.split('/').last.split('\\').last;
        await File('${uploadDir.path}/$safe').writeAsBytes(content);
        onReceived?.call(safe);
      }
      pos = next;
    }
    await _seal(req, utf8.encode('{"ok":true}'));
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

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:nova_link/nova_link.dart' show SafePath, LanStream;

import '../../../core/crypto/lan_crypto.dart';
import '../../pc_share/data/lan_discovery.dart';

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

/// Tiny embedded HTTP server used for LAN file transfer.
///
/// Shares an arbitrary list of root paths (files and/or folders) with a
/// paired PC. Folder contents are browsable — every path request is
/// restricted to the shared roots. All endpoints except `/` require a
/// signed request and answer with AES-GCM sealed bytes.
///
/// Endpoints:
/// - GET  /api/list?dir=        → entries (empty dir = shared roots)
/// - GET  /api/dl?path=         → sealed file bytes
/// - GET  /api/thumb?path=      → sealed JPEG thumbnail (204 if none)
/// - POST /api/rename {path,name}
/// - POST /api/delete {path}
/// - POST /api/unpair           → drop the pairing
/// - POST /upload               → sealed multipart into [uploadDir]
class WifiShareServer {
  WifiShareServer({required this.uploadDir, this.onReceived, this.onUnpair});

  /// Can be switched while the server is running — later uploads land in
  /// the new folder.
  Directory uploadDir;
  final void Function(String fileName)? onReceived;

  /// Called when the paired PC asks to disconnect (POST /api/unpair).
  final void Function()? onUnpair;

  HttpServer? _server;
  List<String> _roots = const [];
  String _shareToken = '';

  int get port => _server?.port ?? 0;
  List<String> get roots => _roots;
  String? _ip;

  /// URL registered with the paired PC — carries `?k=<token>`; every
  /// endpoint requires a signed request and answers with sealed bytes.
  String get url => _ip == null ? '' : 'http://$_ip:$port?k=$_shareToken';

  /// Best LAN IPv4 (Wi-Fi before mobile data). The PC also swaps in the
  /// address our requests really come from, so this is only a hint.
  static Future<String?> localIp() async {
    final ips = await LanDiscovery.localIps();
    return ips.isEmpty ? null : ips.first;
  }

  /// [roots] may be file and/or directory paths — directories become
  /// browsable roots on the paired PC.
  Future<void> start(List<String> roots) async {
    _roots = roots;
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

  /// Absolute [path] must be a shared root or live under one — '/'-style
  /// separators throughout since Android paths always use them.
  /// '..' segments and symlinks can't escape the shared roots.
  bool _insideRoots(String path) => SafePath.inside(path, _roots);

  /// Signed-request auth against this share session's token. The query
  /// string is part of the signature, and every (unique, nonce-carrying)
  /// signature is accepted once — replayed packets are rejected.
  bool _auth(HttpRequest req) {
    final q = req.uri.queryParameters;
    final ts = int.tryParse(q['ts'] ?? '') ?? 0;
    final sig = q['sig'] ?? '';
    if (!LanCrypto.verify(_shareToken, req.method, req.uri.path, ts, sig, q)) {
      return false;
    }
    return _seen(sig);
  }

  /// Signatures seen inside the validity window — a replayed request
  /// carries the identical sig and is refused.
  final Map<String, int> _seenSigs = {};

  bool _seen(String sig) {
    final now = LanCrypto.now();
    _seenSigs.removeWhere((_, t) => (now - t).abs() > LanCrypto.windowSec + 60);
    if (_seenSigs.containsKey(sig)) return false;
    _seenSigs[sig] = now;
    return true;
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
          ..headers.set(LanCrypto.timeHeader, '${LanCrypto.now()}')
          ..write('Forbidden');
        await req.response.close();
        return;
      }
      if (req.method == 'GET' && req.uri.path == '/api/list') {
        await _serveApiList(req);
      } else if (req.method == 'GET' && req.uri.path == '/api/dl') {
        await _serveFile(req);
      } else if (req.method == 'GET' && req.uri.path == '/api/view') {
        final path = req.uri.queryParameters['path'] ?? '';
        final b = _insideRoots(path) && File(path).existsSync()
            ? await viewJpeg(path)
            : null;
        if (b == null) {
          req.response.statusCode = 204;
          await req.response.close();
        } else {
          await _seal(req, b);
        }
      } else if (req.method == 'GET' && req.uri.path.startsWith('/api/thumb')) {
        await _serveThumb(req);
      } else if (req.method == 'POST' && req.uri.path == '/api/rename') {
        await _rename(req);
      } else if (req.method == 'POST' && req.uri.path == '/api/delete') {
        await _delete(req);
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

  Map<String, Object?> _entry(FileSystemEntity e) {
    final isDir = e is Directory;
    var size = 0;
    var mtime = 0;
    try {
      final s = e.statSync();
      size = e is File ? s.size : 0;
      mtime = s.modified.millisecondsSinceEpoch;
    } catch (_) {}
    return {
      'name': e.path.split('/').last,
      'path': e.path,
      'isDir': isDir,
      'size': size,
      'mtime': mtime,
    };
  }

  /// Sealed JSON list. Empty `dir` → shared roots; otherwise the dir's
  /// contents (must be inside a shared root).
  Future<void> _serveApiList(HttpRequest req) {
    final dir = req.uri.queryParameters['dir'] ?? '';
    final List<Map<String, Object?>> entries = [];
    if (dir.isEmpty) {
      for (final r in _roots) {
        try {
          final type = FileSystemEntity.typeSync(r);
          if (type == FileSystemEntityType.notFound) continue;
          entries.add(
            _entry(
              type == FileSystemEntityType.directory ? Directory(r) : File(r),
            ),
          );
        } catch (_) {}
      }
    } else {
      if (!_insideRoots(dir) || !Directory(dir).existsSync()) {
        req.response
          ..statusCode = 403
          ..write('Outside shared roots');
        req.response.close();
        return Future.value();
      }
      for (final e in Directory(dir).listSync()) {
        if (e.path.split('/').last.startsWith('.')) continue;
        try {
          entries.add(_entry(e));
        } catch (_) {}
      }
    }
    entries.sort((a, b) {
      final d = (b['isDir'] == true ? 1 : 0) - (a['isDir'] == true ? 1 : 0);
      return d != 0 ? d : ('${a['name']}').compareTo('${b['name']}');
    });
    return _seal(req, utf8.encode(jsonEncode(entries)));
  }

  Future<void> _serveFile(HttpRequest req) async {
    final path = req.uri.queryParameters['path'] ?? '';
    if (path.isEmpty || !_insideRoots(path) || !File(path).existsSync()) {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    await LanStream.serveFile(req, _shareToken, File(path));
  }

  static const _channel = MethodChannel('dev.nova.nova_file_manager/storage');
  static const _imgExts = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
    'avif',
  };
  static const _videoExts = {
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    '3gp',
    'm4v',
    'wmv',
    'flv',
    'ts',
    'mpg',
    'mpeg',
  };
  static const _audioExts = {
    'mp3',
    'wav',
    'ogg',
    'oga',
    'opus',
    'm4a',
    'aac',
    'flac',
    'wma',
    'amr',
  };
  static const _apkExts = {'apk', 'aab'};

  /// Thumbnail cache — "path:mtime" → bytes (null = no thumbnail).
  /// Capped so a long session can't grow unbounded.
  final Map<String, List<int>?> _thumbCache = {};
  static const _thumbCacheMax = 400;

  /// GET /api/thumb?path=… → JPEG/PNG thumbnail for a shared file:
  /// images are resized in an isolate (decoding multi-MP photos on the
  /// UI isolate stalls the whole app), video frames and APK icons come
  /// from the native channel. 204 when no thumbnail exists.
  Future<void> _serveThumb(HttpRequest req) async {
    final path = req.uri.queryParameters['path'] ?? '';
    List<int>? bytes;
    var found = false;
    if (_insideRoots(path) && File(path).existsSync()) {
      var key = path;
      try {
        key =
            '$path:${FileStat.statSync(path).modified.millisecondsSinceEpoch}';
      } catch (_) {}
      if (_thumbCache.containsKey(key)) {
        bytes = _thumbCache[key];
        found = true;
      } else {
        bytes = await thumbnailFor(path);
        if (_thumbCache.length >= _thumbCacheMax) _thumbCache.clear();
        _thumbCache[key] = bytes;
        found = true;
      }
    }
    if (!found || bytes == null) {
      req.response.statusCode = 204;
      await req.response.close();
      return;
    }
    await _seal(req, bytes);
  }

  /// Full-size JPEG of a photo (max 2560 px) — lets a PC that can't
  /// decode HEIC/HEIF still preview Samsung photos.
  static Future<List<int>?> viewJpeg(String path) async {
    try {
      return await _channel.invokeMethod<List<int>>('imageJpeg', {
        'path': path,
        'max': 2560,
      });
    } catch (_) {
      return null;
    }
  }

  /// Thumbnail bytes for [path] (image, APK icon or video frame) or
  /// null — shared with the multi-device mesh server.
  static Future<List<int>?> thumbnailFor(String path) async {
    final ext = path.toLowerCase().split('.').last;
    try {
      if (_imgExts.contains(ext)) {
        // Native decoder: fast, EXIF-rotated, and handles HEIC/HEIF.
        return await _channel.invokeMethod<List<int>>('imageJpeg', {
              'path': path,
              'max': 320,
            }) ??
            await Isolate.run(() => _makeImageThumb(path));
      } else if (_audioExts.contains(ext)) {
        return await _channel.invokeMethod<List<int>>('audioArt', {
          'path': path,
        });
      } else if (_apkExts.contains(ext)) {
        return await _channel.invokeMethod<List<int>>('apkIcon', {
          'path': path,
        });
      } else if (_videoExts.contains(ext)) {
        return await _channel.invokeMethod<List<int>>('videoThumb', {
          'path': path,
        });
      }
    } catch (_) {}
    return null;
  }

  /// Decode + resize inside a worker isolate.
  static List<int>? _makeImageThumb(String path) {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) return null;
    final thumb = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? 160 : null,
      height: decoded.height > decoded.width ? 160 : null,
    );
    return img.encodeJpg(thumb, quality: 80);
  }

  /// POST /api/rename {path, name} — renames a file inside a shared root.
  Future<void> _rename(HttpRequest req) async {
    final body = await _sealedBody(req);
    final data = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
    final path = data['path'] as String? ?? '';
    final name = (data['name'] as String? ?? '').split('/').last;
    if (path.isEmpty || name.isEmpty || !_insideRoots(path)) {
      req.response.statusCode = 400;
      await req.response.close();
      return;
    }
    try {
      final f = File(path);
      if (!f.existsSync()) throw 'not-found';
      await f.rename('${f.parent.path}/$name');
      await _seal(req, utf8.encode('{"ok":true}'));
    } catch (e) {
      req.response
        ..statusCode = 500
        ..write('$e');
      await req.response.close();
    }
  }

  /// POST /api/delete {path} — deletes a shared file or folder
  /// (folders recursively) — restricted to the shared roots.
  Future<void> _delete(HttpRequest req) async {
    final body = await _sealedBody(req);
    final data = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
    final path = data['path'] as String? ?? '';
    if (path.isEmpty || !_insideRoots(path)) {
      req.response.statusCode = 400;
      await req.response.close();
      return;
    }
    try {
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.directory) {
        await Directory(path).delete(recursive: true);
      } else if (type == FileSystemEntityType.file) {
        await File(path).delete();
      } else {
        throw 'not-found';
      }
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
        final safe = SafePath.safeFileName(name);
        if (safe == null) {
          pos = next;
          continue;
        }
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

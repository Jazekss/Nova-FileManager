import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/crypto/lan_crypto.dart';

/// Client for the desktop pairing server (Nova Transfer).
/// Pairing link format: novapair://host:port/token
///
/// The token never goes on the wire — every request is signed
/// (HMAC-SHA256 + timestamp) and every body/response is AES-256-GCM
/// sealed. A LAN sniffer sees only ciphertext.
class PcClient {
  static const _keyPair = 'pc_share_pair_v1';
  static const _timeout = Duration(seconds: 8);

  String? baseUrl;
  String? token;

  bool get isPaired => baseUrl != null && token != null;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_keyPair);
    if (raw != null) _apply(raw);
  }

  /// Parses `novapair://host:port/token` (or http:// same shape).
  /// Returns false when the link is malformed.
  bool _apply(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.host.isEmpty || uri.port == 0) return false;
    final tok = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    if (tok.isEmpty) return false;
    baseUrl = 'http://${uri.host}:${uri.port}';
    token = tok;
    return true;
  }

  /// Applies a scanned/typed pairing link and verifies the token via
  /// /api/info. Returns null on success, error text on failure.
  Future<String?> pair(String link, {String? phoneUrl}) async {
    if (!_apply(link)) return 'invalid_link';
    try {
      final res = await _get('/api/info');
      if (res == null) return 'decrypt_failed';
      final p = await SharedPreferences.getInstance();
      await p.setString(_keyPair, link.trim());
      await registerPhoneUrl(phoneUrl);
      return null;
    } catch (e) {
      baseUrl = null;
      token = null;
      return '$e';
    }
  }

  /// Re-registers the phone's share URL (after the share set changes).
  /// [phoneUrl] may carry `?k=<shareToken>` for the phone's own server.
  Future<void> registerPhoneUrl(String? phoneUrl) async {
    try {
      await _post('/api/pair', {'phoneUrl': phoneUrl});
    } catch (_) {}
  }

  Future<void> unpair() async {
    try {
      await _post('/api/unpair', {});
    } catch (_) {}
    baseUrl = null;
    token = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyPair);
  }

  /// Signed GET → decrypted body bytes (null on bad signature/decrypt).
  Future<Uint8List?> _get(String path, [Map<String, String>? q]) async {
    final ts = LanCrypto.now();
    final sig = LanCrypto.sign(token!, 'GET', path, ts);
    final res = await http
        .get(
          Uri.parse('$baseUrl$path')
              .replace(queryParameters: {'ts': '$ts', 'sig': sig, ...?q}),
        )
        .timeout(_timeout);
    if (res.statusCode == 403) throw StateError('unpaired');
    if (res.statusCode == 204) return null; // no thumbnail
    if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
    return LanCrypto.open(token!, res.bodyBytes);
  }

  /// Signed POST with a sealed JSON body.
  Future<void> _post(String path, Object body) async {
    final ts = LanCrypto.now();
    final sig = LanCrypto.sign(token!, 'POST', path, ts);
    final packed = await LanCrypto.seal(token!, utf8.encode(jsonEncode(body)));
    final res = await http
        .post(
          Uri.parse('$baseUrl$path')
              .replace(queryParameters: {'ts': '$ts', 'sig': sig}),
          body: packed,
        )
        .timeout(_timeout);
    if (res.statusCode == 403) throw StateError('unpaired');
    if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
  }

  /// [dir] empty → shared roots; else entries inside that dir.
  /// Throws StateError('unpaired') when the signature was rejected.
  Future<List<PcEntry>> list([String dir = '']) async {
    final bytes = await _get('/api/list', {'dir': dir});
    if (bytes == null) throw 'decrypt_failed';
    return (jsonDecode(utf8.decode(bytes)) as List)
        .map(
          (e) => PcEntry(
            name: e['name'] as String,
            path: e['path'] as String,
            isDir: e['isDir'] as bool,
            size: (e['size'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  /// Fetches a sealed thumbnail for [e]; null when none exists.
  Future<Uint8List?> thumb(PcEntry e) {
    if (!isPaired || e.isDir) return Future.value();
    return _get('/api/thumb', {'path': e.path});
  }

  /// Downloads [entry] into [destDir]; returns the written path.
  Future<String> download(PcEntry entry, String destDir) async {
    final bytes = await _get('/api/dl', {'path': entry.path});
    if (bytes == null) throw 'decrypt_failed';
    var out = '$destDir/${entry.name}';
    var n = 1;
    while (File(out).existsSync()) {
      final dot = entry.name.lastIndexOf('.');
      out = dot > 0
          ? '$destDir/${entry.name.substring(0, dot)} ($n)${entry.name.substring(dot)}'
          : '$destDir/${entry.name} ($n)';
      n++;
    }
    await File(out).writeAsBytes(bytes);
    return out;
  }

  /// Uploads a local file into PC folder [destDir] (sealed multipart).
  Future<void> upload(String localPath, String destDir) async {
    final file = File(localPath);
    final name = localPath.substring(localPath.lastIndexOf('/') + 1);
    final bytes = await file.readAsBytes();
    final boundary =
        'nova-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    final part = BytesBuilder()
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(
        utf8.encode(
          'Content-Disposition: form-data; name="files"; filename="$name"\r\n',
        ),
      )
      ..add(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));

    final ts = LanCrypto.now();
    final sig = LanCrypto.sign(token!, 'POST', '/api/upload', ts);
    final uri = Uri.parse('$baseUrl/api/upload').replace(
      queryParameters: {
        'ts': '$ts',
        'sig': sig,
        'dir': destDir,
        'boundary': boundary,
      },
    );
    final req = await HttpClient().postUrl(uri);
    req.add(await LanCrypto.seal(token!, part.toBytes()));
    final res = await req.close();
    await res.drain<void>();
    if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
  }
}

class PcEntry {
  const PcEntry({
    required this.name,
    required this.path,
    required this.isDir,
    this.size = 0,
  });
  final String name;
  final String path;
  final bool isDir;
  final int size;
}

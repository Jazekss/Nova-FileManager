import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nova_link/nova_link.dart'
    show PairingHost, PairError, LanStream;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/crypto/lan_crypto.dart';
import 'lan_discovery.dart';

/// Outcome of trying to (re)reach the paired desktop.
enum PcReach { ok, unreachable, rejected }

/// Client for the desktop pairing server (Nova Transfer).
/// Pairing link format: novapair://host:port/token[?alt=ip2,ip3]
///
/// The token never goes on the wire — every request is signed
/// (HMAC-SHA256 + timestamp) and every body/response is AES-256-GCM
/// sealed. A LAN sniffer sees only ciphertext.
class PcClient {
  static const _keyPair = 'pc_share_pair_v1';

  /// Short calls (list/info/posts). Transfers get their own generous
  /// budgets — an 8s cap used to kill big downloads mid-flight.
  static const _timeout = Duration(seconds: 15);
  static const _probeTimeout = Duration(seconds: 3);

  String? host;
  int port = 0;
  String? token;

  /// Other PC addresses from the QR (other adapters) — tried when the
  /// main one doesn't answer.
  List<String> alt = [];

  /// PC clock minus phone clock (seconds), learnt from a 403 reply —
  /// a wrong clock on either side no longer looks like "unpaired".
  int _skew = 0;

  String? get baseUrl => host == null ? null : 'http://$host:$port';
  bool get isPaired => host != null && token != null;

  /// Public pairing id (matches discovery replies from this PC).
  String? get pairId => token == null ? null : LanCrypto.pairId(token!);

  String get _link =>
      'novapair://$host:$port/$token'
      '${alt.isEmpty ? '' : '?alt=${alt.join(',')}'}';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_keyPair);
    if (raw != null) _apply(raw);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyPair, _link);
  }

  /// Parses `novapair://host:port/token?alt=…` (or http:// same shape).
  /// Returns false when the link is malformed.
  bool _apply(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.host.isEmpty || uri.port == 0) return false;
    final tok = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    if (tok.isEmpty) return false;
    host = uri.host;
    port = uri.port;
    token = tok;
    alt = (uri.queryParameters['alt'] ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != uri.host)
        .toList();
    return true;
  }

  /// Applies a scanned/typed pairing link and finds a working address
  /// (main host, QR fallbacks, then LAN discovery). Returns null on
  /// success, an error code ('invalid_link' / 'unreachable' /
  /// 'rejected') otherwise.
  Future<String?> pair(String link, {String? phoneUrl}) async {
    if (!_apply(link)) return 'invalid_link';
    _skew = 0;
    final r = await reconnect();
    if (r != PcReach.ok) {
      host = null;
      token = null;
      return r == PcReach.rejected ? 'rejected' : 'unreachable';
    }
    await _save();
    await registerPhoneUrl(phoneUrl);
    return null;
  }

  /// Pairs by typed address (`192.168.1.5` or `192.168.1.5:48320`) and
  /// the one-time code shown on the PC. Also accepts a full
  /// `novapair://` link pasted into the address field.
  Future<String?> pairWithCode(String address, String code) async {
    final a = address.trim();
    if (a.startsWith('novapair://') || a.startsWith('http')) return pair(a);
    final m = RegExp(r'^([0-9]{1,3}(?:\.[0-9]{1,3}){3})(?::([0-9]{1,5}))?$')
        .firstMatch(a);
    if (m == null) return 'invalid_link';
    final h = m.group(1)!;
    final pt = int.tryParse(m.group(2) ?? '') ?? 48320;
    try {
      final r = await PairingHost.join(
        host: h,
        port: pt,
        code: code,
        myId: 'nova-phone-primary',
        myName: 'Nova',
        kind: 'phone',
      );
      final tok = '${r.extra['token'] ?? ''}';
      if (tok.isEmpty) return 'rejected';
      return await pair('novapair://$h:$pt/$tok');
    } on PairError catch (e) {
      return switch (e.code) {
        'bad_code' || 'expired' || 'closed' || 'too_many' => 'bad_code',
        _ => 'unreachable',
      };
    }
  }

  /// Finds the PC again: current host → QR fallback hosts (in parallel)
  /// → UDP broadcast discovery. A new working address is persisted so
  /// the next launch starts from it.
  Future<PcReach> reconnect() async {
    if (token == null || host == null) return PcReach.unreachable;
    final first = await _probe(host!, port);
    if (first != PcReach.unreachable) return first;

    final others = alt.where((h) => h != host).toList();
    if (others.isNotEmpty) {
      final hit = await _firstOk(others.map((h) => _probeHost(h, port)));
      if (hit != null) {
        await _switchTo(hit, port);
        return PcReach.ok;
      }
    }

    final found = await LanDiscovery.find(pairId!);
    if (found != null) {
      final (h, p) = found;
      final r = await _probe(h, p);
      if (r == PcReach.ok) await _switchTo(h, p);
      return r;
    }
    return PcReach.unreachable;
  }

  Future<void> _switchTo(String newHost, int newPort) async {
    if (newHost == host && newPort == port) return;
    if (host != null && !alt.contains(host)) alt = [host!, ...alt];
    alt.remove(newHost);
    host = newHost;
    port = newPort;
    await _save();
  }

  Future<String?> _probeHost(String h, int p) async =>
      await _probe(h, p) == PcReach.ok ? h : null;

  /// Signed /api/info against one address with a short timeout.
  Future<PcReach> _probe(String h, int p) async {
    try {
      final bytes = await _get(
        '/api/info',
        timeout: _probeTimeout,
        base: 'http://$h:$p',
      );
      return bytes == null ? PcReach.rejected : PcReach.ok;
    } on StateError {
      return PcReach.rejected;
    } catch (_) {
      return PcReach.unreachable;
    }
  }

  static Future<T?> _firstOk<T>(Iterable<Future<T?>> futures) {
    final list = futures.toList();
    final c = Completer<T?>();
    var left = list.length;
    for (final f in list) {
      f.then((v) {
        left--;
        if (v != null && !c.isCompleted) c.complete(v);
        if (left == 0 && !c.isCompleted) c.complete(null);
      });
    }
    return c.future;
  }

  /// Re-registers the phone's share URL (after the share set changes).
  /// [phoneUrl] may carry `?k=<shareToken>` for the phone's own server.
  Future<void> registerPhoneUrl(String? phoneUrl) async {
    try {
      await heartbeat(phoneUrl);
    } catch (_) {}
  }

  /// Registers [phoneUrl] (or null when nothing is shared) — doubles as
  /// the keep-alive. Throws when the PC can't be reached. Returns false
  /// when the PC asked this phone to unpair.
  Future<bool> heartbeat(String? phoneUrl) async {
    final res = await _post('/api/pair', {'phoneUrl': phoneUrl});
    if (res == null) return true;
    try {
      final data = jsonDecode(utf8.decode(res));
      if (data is Map && data['unpair'] == true) return false;
    } catch (_) {}
    return true;
  }

  Future<void> unpair() async {
    try {
      await _post('/api/unpair', {}).timeout(const Duration(seconds: 3));
    } catch (_) {}
    await forget();
  }

  /// Drops the pairing locally (and from storage) without telling the PC.
  Future<void> forget() async {
    host = null;
    token = null;
    alt = [];
    _skew = 0;
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyPair);
  }

  Map<String, String> _signed(
    String method,
    String path,
    Map<String, String> params,
  ) {
    final ts = LanCrypto.now() + _skew;
    final sig = LanCrypto.sign(token!, method, path, ts, params);
    return {...params, 'ts': '$ts', 'sig': sig};
  }

  /// A 403 carrying the PC clock with a big difference means our clock
  /// is off — adopt the skew and let the caller retry once.
  bool _learnSkew(http.BaseResponse res) {
    final pcTs = int.tryParse(res.headers[LanCrypto.timeHeader] ?? '');
    if (pcTs == null) return false;
    final diff = pcTs - LanCrypto.now();
    if ((diff - _skew).abs() < 30) return false;
    _skew = diff;
    return true;
  }

  /// Signed GET → decrypted body bytes (null on 204 / bad decrypt).
  /// Throws StateError('rejected') when the PC refuses the signature.
  Future<Uint8List?> _get(
    String path, {
    Map<String, String>? q,
    Duration timeout = _timeout,
    String? base,
    bool retried = false,
  }) async {
    final params = {'nonce': LanCrypto.nonce(), ...?q};
    final res = await http
        .get(
          Uri.parse('${base ?? baseUrl}$path')
              .replace(queryParameters: _signed('GET', path, params)),
        )
        .timeout(timeout);
    if (res.statusCode == 403) {
      if (!retried && _learnSkew(res)) {
        return _get(path, q: q, timeout: timeout, base: base, retried: true);
      }
      throw StateError('rejected');
    }
    if (res.statusCode == 204) return null; // no thumbnail
    if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
    return LanCrypto.open(token!, res.bodyBytes);
  }

  /// Signed POST with a sealed JSON body → decrypted response bytes.
  Future<Uint8List?> _post(
    String path,
    Object body, {
    bool retried = false,
  }) async {
    final params = {'nonce': LanCrypto.nonce()};
    final packed = await LanCrypto.seal(token!, utf8.encode(jsonEncode(body)));
    final res = await http
        .post(
          Uri.parse('$baseUrl$path')
              .replace(queryParameters: _signed('POST', path, params)),
          body: packed,
        )
        .timeout(_timeout);
    if (res.statusCode == 403) {
      if (!retried && _learnSkew(res)) {
        return _post(path, body, retried: true);
      }
      throw StateError('rejected');
    }
    if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
    return LanCrypto.open(token!, res.bodyBytes);
  }

  /// [dir] empty → shared roots; else entries inside that dir.
  /// Throws StateError('rejected') when the signature was rejected.
  Future<List<PcEntry>> list([String dir = '']) async {
    final bytes = await _get('/api/list', q: dir.isEmpty ? null : {'dir': dir});
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
    return _get(
      '/api/thumb',
      q: {'path': e.path},
      timeout: const Duration(seconds: 30),
    );
  }

  /// Fetches the whole file into memory for preview without saving —
  /// used by the in-app image lightbox / video / audio preview.
  Future<Uint8List?> fetch(PcEntry e) async =>
      LanStream.readAll(token!, await _dl(e.path));

  /// Streams a PC file straight into [out] (video/audio previews).
  Future<void> fetchTo(PcEntry e, File out) async =>
      LanStream.toFile(token!, await _dl(e.path), out);

  /// Signed GET /api/dl → framed (256 KB sealed chunks) response.
  Future<http.StreamedResponse> _dl(String path) async {
    final params = {'nonce': LanCrypto.nonce(), 'path': path};
    final uri = Uri.parse('$baseUrl/api/dl')
        .replace(queryParameters: _signed('GET', '/api/dl', params));
    final res = await LanStream.get(uri, timeout: _timeout);
    if (res.statusCode == 403) {
      await res.stream.drain<void>();
      throw StateError('rejected');
    }
    if (res.statusCode != 200) {
      await res.stream.drain<void>();
      throw 'HTTP ${res.statusCode}';
    }
    return res;
  }

  /// Renames a file inside the PC's shared folder.
  Future<void> rename(PcEntry e, String newName) =>
      _post('/api/rename', {'path': e.path, 'name': newName});

  /// Downloads [entry] into [destDir]; returns the written path.
  Future<String> download(PcEntry entry, String destDir) async {
    var out = '$destDir/${entry.name}';
    var n = 1;
    while (File(out).existsSync()) {
      final dot = entry.name.lastIndexOf('.');
      out = dot > 0
          ? '$destDir/${entry.name.substring(0, dot)} ($n)${entry.name.substring(dot)}'
          : '$destDir/${entry.name} ($n)';
      n++;
    }
    await LanStream.toFile(token!, await _dl(entry.path), File(out));
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

    final params = {
      'nonce': LanCrypto.nonce(),
      'dir': destDir,
      'boundary': boundary,
    };
    final uri = Uri.parse('$baseUrl/api/upload')
        .replace(queryParameters: _signed('POST', '/api/upload', params));
    final req = await HttpClient().postUrl(uri);
    req.add(await LanCrypto.seal(token!, part.toBytes()));
    final res = await req.close().timeout(
      const Duration(minutes: 10),
      onTimeout: () => throw 'upload_timeout',
    );
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

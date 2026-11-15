import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart' as cg;
import 'package:http/http.dart' as http;

import 'lan_crypto.dart';

/// One-time pairing code: 12 characters from an alphabet without
/// look-alikes (no 0/O, 1/I/L), shown as `ABCD-EFGH-JKMN` (60 bits).
class PairCode {
  PairCode._();

  static const _abc = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static final _rng = Random.secure();

  static String generate() =>
      List.generate(12, (_) => _abc[_rng.nextInt(_abc.length)]).join();

  static String normalize(String s) =>
      s.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  static String format(String c) {
    final n = normalize(c);
    final parts = <String>[];
    for (var i = 0; i < n.length; i += 4) {
      parts.add(n.substring(i, min(i + 4, n.length)));
    }
    return parts.join('-');
  }

  static bool looksValid(String s) => normalize(s).length == 12;
}

/// Who is on the other end of a pairing.
class PairPeerInfo {
  PairPeerInfo({
    required this.id,
    required this.name,
    required this.kind,
    this.host,
    this.port = 0,
  });

  final String id;
  final String name;

  /// 'pc' or 'phone'.
  final String kind;
  final String? host;
  final int port;
}

/// Result of a successful pairing on the joining side.
class PairResult {
  PairResult({required this.peer, required this.key, required this.extra});
  final PairPeerInfo peer;

  /// 256-bit per-pair secret (hex) — signs and seals all later traffic.
  final String key;
  final Map<String, dynamic> extra;
}

class _Pending {
  _Pending(this.macKey, this.joiner, this.created);
  final List<int> macKey;
  final PairPeerInfo joiner;
  final DateTime created;
}

/// Pairing protocol (both directions use the same code):
///
///  1. joiner → POST /pair/1 {pub, id, name, kind, port, nonce}
///     host   ← {sid, pub, id, name, kind, nonce, mac=HMAC(K,"host")}
///  2. joiner checks the host's mac, then
///     joiner → POST /pair/2 {sid, mac=HMAC(K,"joiner")}
///     host   ← sealed(key, {ok, extra})
///
/// with K = HMAC(code, X25519(dh) || sha256(transcript)) and the pair key
/// = HMAC(K, "key"). A passive sniffer never learns dh, so it can't test
/// codes; an active attacker gets one guess per attempt (codes are 60
/// bits, attempts are capped, pending handshakes expire in 20 s) and the
/// code is single-use.
class PairingHost {
  PairingHost({
    required this.myId,
    required this.myName,
    required this.kind,
    required this.onPaired,
    this.onCodeChanged,
  });

  String myId;
  String myName;
  final String kind;

  /// Called after a successful handshake; the returned map is sent to
  /// the joiner (sealed) — e.g. the primary-pairing token.
  final FutureOr<Map<String, dynamic>> Function(PairPeerInfo peer, String key)
  onPaired;
  final void Function()? onCodeChanged;

  String? _code;
  DateTime? _expires;
  int _attempts = 0;
  final Map<String, _Pending> _pending = {};

  static const _maxAttempts = 10;
  static const _pendingTtl = Duration(seconds: 20);

  /// Current code, or null while pairing is closed.
  String? get code {
    if (_code != null && DateTime.now().isAfter(_expires!)) close();
    return _code;
  }

  /// Opens (or refreshes) pairing for [ttl] with a fresh code.
  String open({Duration ttl = const Duration(minutes: 10)}) {
    _code = PairCode.generate();
    _expires = DateTime.now().add(ttl);
    _attempts = 0;
    _pending.clear();
    onCodeChanged?.call();
    return _code!;
  }

  void close() {
    final had = _code != null;
    _code = null;
    _expires = null;
    _pending.clear();
    if (had) onCodeChanged?.call();
  }

  /// Rotates the code after use / too many tries (keeps pairing open).
  void _rotate() {
    if (_code == null) return;
    final left = _expires!.difference(DateTime.now());
    open(ttl: left.isNegative ? Duration.zero : left);
  }

  bool handles(HttpRequest req) =>
      req.method == 'POST' &&
      (req.uri.path == '/pair/1' || req.uri.path == '/pair/2');

  Future<void> handle(HttpRequest req) async {
    try {
      final raw = await _readLimited(req, 8192);
      final body = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
      if (req.uri.path == '/pair/1') {
        await _step1(req, body);
      } else {
        await _step2(req, body);
      }
    } catch (_) {
      await _fail(req, 400, 'bad_request');
    }
  }

  Future<void> _step1(HttpRequest req, Map<String, dynamic> b) async {
    final code = this.code;
    if (code == null) return _fail(req, 410, 'closed');
    if (++_attempts > _maxAttempts) {
      _rotate();
      return _fail(req, 429, 'too_many');
    }
    final now = DateTime.now();
    _pending.removeWhere((_, p) => now.difference(p.created) > _pendingTtl);
    if (_pending.length > 8) return _fail(req, 429, 'busy');

    final jPub = base64.decode(b['pub'] as String);
    final jNonce = b['nonce'] as String;
    final joiner = PairPeerInfo(
      id: _clean(b['id'], 40),
      name: _clean(b['name'], 60),
      kind: b['kind'] == 'pc' ? 'pc' : 'phone',
      host: req.connectionInfo?.remoteAddress.address,
      port: (b['port'] as num?)?.toInt() ?? 0,
    );
    if (joiner.id.isEmpty || jPub.length != 32) {
      return _fail(req, 400, 'bad_request');
    }

    final algo = cg.X25519();
    final kp = await algo.newKeyPair();
    final hPub = (await kp.extractPublicKey()).bytes;
    final hNonce = LanCrypto.nonce();
    final macKey = await _macKey(
      code,
      kp,
      jPub,
      _transcript(jPub, hPub, joiner.id, myId, jNonce, hNonce),
    );
    final sid = LanCrypto.nonce() + LanCrypto.nonce();
    _pending[sid] = _Pending(macKey, joiner, now);
    await _json(req, {
      'sid': sid,
      'pub': base64.encode(hPub),
      'id': myId,
      'name': myName,
      'kind': kind,
      'nonce': hNonce,
      'mac': _mac(macKey, 'host'),
    });
  }

  Future<void> _step2(HttpRequest req, Map<String, dynamic> b) async {
    final p = _pending.remove(b['sid']);
    if (p == null || code == null) return _fail(req, 410, 'expired');
    if (DateTime.now().difference(p.created) > _pendingTtl) {
      return _fail(req, 410, 'expired');
    }
    if (!LanCrypto.constTimeEq(_mac(p.macKey, 'joiner'), '${b['mac']}')) {
      return _fail(req, 403, 'bad_code');
    }
    final key = _mac(p.macKey, 'key');
    final extra = await onPaired(p.joiner, key);
    _rotate(); // single use
    final sealed = await LanCrypto.seal(
      key,
      utf8.encode(jsonEncode({'ok': true, 'extra': extra})),
    );
    req.response.headers.contentType = ContentType.binary;
    req.response.add(sealed);
    await req.response.close();
  }

  // ---------------- joiner side ----------------

  /// Runs the handshake against `host:port` with [code]. Throws a
  /// [PairError] with a short code on failure.
  static Future<PairResult> join({
    required String host,
    required int port,
    required String code,
    required String myId,
    required String myName,
    required String kind,
    int myPort = 0,
  }) async {
    final c = PairCode.normalize(code);
    final base = 'http://${_hostPart(host)}:$port';
    final algo = cg.X25519();
    final kp = await algo.newKeyPair();
    final jPub = (await kp.extractPublicKey()).bytes;
    final jNonce = LanCrypto.nonce();

    final http.Response r1;
    try {
      r1 = await http
          .post(
            Uri.parse('$base/pair/1'),
            body: jsonEncode({
              'pub': base64.encode(jPub),
              'id': myId,
              'name': myName,
              'kind': kind,
              'port': myPort,
              'nonce': jNonce,
            }),
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      throw const PairError('unreachable');
    }
    if (r1.statusCode == 410) throw const PairError('closed');
    if (r1.statusCode == 429) throw const PairError('too_many');
    if (r1.statusCode != 200) throw const PairError('unreachable');
    final b = jsonDecode(r1.body) as Map<String, dynamic>;
    final hPub = base64.decode(b['pub'] as String);
    final hostInfo = PairPeerInfo(
      id: _clean(b['id'], 40),
      name: _clean(b['name'], 60),
      kind: b['kind'] == 'pc' ? 'pc' : 'phone',
      host: host,
      port: port,
    );
    final macKey = await _macKey(
      c,
      kp,
      hPub,
      _transcript(jPub, hPub, myId, hostInfo.id, jNonce, '${b['nonce']}'),
    );
    if (!LanCrypto.constTimeEq(_mac(macKey, 'host'), '${b['mac']}')) {
      // Wrong code — or someone in the middle. Either way: stop here.
      throw const PairError('bad_code');
    }
    final r2 = await http
        .post(
          Uri.parse('$base/pair/2'),
          body: jsonEncode({'sid': b['sid'], 'mac': _mac(macKey, 'joiner')}),
        )
        .timeout(const Duration(seconds: 15));
    if (r2.statusCode == 403) throw const PairError('bad_code');
    if (r2.statusCode != 200) throw const PairError('expired');
    final key = _mac(macKey, 'key');
    final plain = await LanCrypto.open(key, r2.bodyBytes);
    if (plain == null) throw const PairError('bad_code');
    final res = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    return PairResult(
      peer: hostInfo,
      key: key,
      extra: (res['extra'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  // ---------------- helpers ----------------

  static String _hostPart(String h) => h.contains(':') ? '[$h]' : h;

  static String _clean(Object? v, int max) {
    final s = '${v ?? ''}'.replaceAll(RegExp(r'[\x00-\x1f|]'), '').trim();
    return s.length > max ? s.substring(0, max) : s;
  }

  static List<int> _transcript(
    List<int> jPub,
    List<int> hPub,
    String jId,
    String hId,
    String jNonce,
    String hNonce,
  ) => hash.sha256
      .convert(
        utf8.encode(
          'nova-pair-v1|${base64.encode(jPub)}|${base64.encode(hPub)}'
          '|$jId|$hId|$jNonce|$hNonce',
        ),
      )
      .bytes;

  static Future<List<int>> _macKey(
    String code,
    cg.SimpleKeyPair kp,
    List<int> remotePub,
    List<int> transcript,
  ) async {
    final shared = await cg.X25519().sharedSecretKey(
      keyPair: kp,
      remotePublicKey: cg.SimplePublicKey(
        remotePub,
        type: cg.KeyPairType.x25519,
      ),
    );
    final dh = await shared.extractBytes();
    return hash.Hmac(
      hash.sha256,
      utf8.encode(PairCode.normalize(code)),
    ).convert([...dh, ...transcript]).bytes;
  }

  static String _mac(List<int> key, String label) =>
      hash.Hmac(hash.sha256, key).convert(utf8.encode(label)).toString();

  static Future<Uint8List> _readLimited(HttpRequest req, int max) async {
    final b = BytesBuilder();
    await for (final chunk in req) {
      b.add(chunk);
      if (b.length > max) throw 'too_big';
    }
    return b.toBytes();
  }

  static Future<void> _json(HttpRequest req, Object data) async {
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(data));
    await req.response.close();
  }

  static Future<void> _fail(HttpRequest req, int status, String msg) async {
    try {
      req.response
        ..statusCode = status
        ..write(msg);
      await req.response.close();
    } catch (_) {}
  }
}

class PairError implements Exception {
  const PairError(this.code);

  /// unreachable | closed | bad_code | too_many | expired
  final String code;
  @override
  String toString() => code;
}

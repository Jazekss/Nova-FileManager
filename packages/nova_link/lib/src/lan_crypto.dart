import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cg;

/// Shared-secret request signing + AES-256-GCM body sealing for the
/// Nova LAN link. The pairing token is shared out-of-band (QR) and never
/// travels the wire — requests carry ts+nonce+sig instead:
///
///   sig = hex(HMAC-SHA256(token, "METHOD|path|query|ts"))
///
/// `query` is the sorted, percent-encoded parameter list (excluding
/// ts/sig themselves), so a proxy can't swap arguments without breaking
/// the signature. Bodies are sealed as nonce(12) || ciphertext || tag(16).
class LanCrypto {
  LanCrypto._();

  /// Max clock skew between devices.
  static const windowSec = 600;

  static final _aes = cg.AesGcm.with256bits();
  static final _rng = Random.secure();

  static cg.SecretKey _key(String token) =>
      cg.SecretKey(sha256.convert(utf8.encode(token)).bytes);

  /// Random per-request nonce — makes every signature unique even for
  /// repeated identical requests inside the same second.
  static String nonce() => List.generate(
    8,
    (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  /// Sorted, percent-encoded "k=v&k=v" — ts/sig are excluded since they
  /// are added after signing.
  static String canonicalQuery(Map<String, String> query) {
    final q = {...query}
      ..remove('ts')
      ..remove('sig');
    final keys = q.keys.toList()..sort();
    return keys
        .map(
          (k) =>
              '${Uri.encodeQueryComponent(k)}='
              '${Uri.encodeQueryComponent(q[k]!)}',
        )
        .join('&');
  }

  static String _payload(
    String method,
    String path,
    int ts,
    Map<String, String> query,
  ) => '${method.toUpperCase()}|$path|${canonicalQuery(query)}|$ts';

  static String sign(
    String token,
    String method,
    String path,
    int ts, [
    Map<String, String> query = const {},
  ]) => Hmac(
    sha256,
    utf8.encode(token),
  ).convert(utf8.encode(_payload(method, path, ts, query))).toString();

  /// Checks signature + timestamp window. [path] is the request path only
  /// and [query] the request parameters (ts/sig may be included — they
  /// are stripped before comparison).
  static bool verify(
    String token,
    String method,
    String path,
    int ts,
    String sig, [
    Map<String, String> query = const {},
  ]) {
    if (sig.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if ((now - ts).abs() > windowSec) return false;
    return constTimeEq(sign(token, method, path, ts, query), sig);
  }

  static int now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// UDP port the desktop answers LAN discovery probes on.
  static const discoveryPort = 48321;
  static const discoverProbe = 'NOVA_DISCOVER';

  /// Public id of a pairing — lets the phone recognise ITS desktop in
  /// discovery replies without the token ever leaving either device.
  static String pairId(String token) => Hmac(
    sha256,
    utf8.encode(token),
  ).convert(utf8.encode('nova-pair-id')).toString().substring(0, 16);

  /// Response header carrying the server clock on 403 — the client uses
  /// it to correct clock skew instead of treating the PC as unpaired.
  static const timeHeader = 'x-nova-time';

  /// UDP port of the multi-device mesh discovery (all Nova devices).
  static const meshDiscoveryPort = 48322;

  /// Short tag proving knowledge of a pair [key] for discovery [nonce]
  /// without revealing the key or any device id on the network.
  static String tag(String key, String nonce) => Hmac(
    sha256,
    utf8.encode(key),
  ).convert(utf8.encode('nova-tag|$nonce')).toString().substring(0, 16);

  /// Constant-time-ish hex comparison — avoids leaking the signature
  /// prefix through early-exit timing.
  static bool constTimeEq(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Encrypts bytes → nonce||ct||tag.
  static Future<Uint8List> seal(String token, List<int> plain) async {
    final box = await _aes.encrypt(plain, secretKey: _key(token));
    return Uint8List.fromList([
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  /// Decrypts nonce||ct||tag, null on bad key/tampered data.
  static Future<Uint8List?> open(String token, List<int> packed) async {
    if (packed.length < 12 + 16) return null;
    final box = cg.SecretBox(
      Uint8List.fromList(packed.sublist(12, packed.length - 16)),
      nonce: packed.sublist(0, 12),
      mac: cg.Mac(packed.sublist(packed.length - 16)),
    );
    try {
      final d = await _aes.decrypt(box, secretKey: _key(token));
      return Uint8List.fromList(d);
    } catch (_) {
      return null;
    }
  }
}

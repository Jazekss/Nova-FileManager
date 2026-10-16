import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cg;

/// Shared-secret request signing + AES-256-GCM body sealing for the
/// Nova LAN link. The pairing token is shared out-of-band (QR) and never
/// travels the wire — requests carry ts+sig instead:
///
///   sig = hex(HMAC-SHA256(token, "METHOD|path|ts"))
///
/// Bodies are sealed as nonce(12) || ciphertext || tag(16).
class LanCrypto {
  LanCrypto._();

  /// Max clock skew between devices.
  static const windowSec = 600;

  static final _aes = cg.AesGcm.with256bits();

  static cg.SecretKey _key(String token) =>
      cg.SecretKey(sha256.convert(utf8.encode(token)).bytes);

  static String sign(String token, String method, String path, int ts) => Hmac(
    sha256,
    utf8.encode(token),
  ).convert(utf8.encode('${method.toUpperCase()}|$path|$ts')).toString();

  /// Checks signature + timestamp window. [path] is the request path only
  /// (no query string).
  static bool verify(
    String token,
    String method,
    String path,
    int ts,
    String sig,
  ) {
    if (sig.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if ((now - ts).abs() > windowSec) return false;
    return sign(token, method, path, ts) == sig;
  }

  static int now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

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

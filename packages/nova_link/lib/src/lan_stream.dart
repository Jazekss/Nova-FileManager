import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart' as cg;
import 'package:http/http.dart' as http;

/// Streamed file transfer: the file is sealed in 256 KB AES-256-GCM
/// frames instead of one huge blob. The sender never holds the whole
/// file, the event loop stays free between frames (heartbeats keep
/// working during a video download) and the receiver can write to disk
/// as data arrives.
///
/// Frame: `len(4, BE) | flag(1) | nonce(12) | ciphertext | tag(16)`
/// with AAD = `nova-chunk|<index>|<flag>`; flag 1 marks the last frame.
/// Reordering, dropping, truncating or appending frames breaks the tag
/// or the end check.
class LanStream {
  LanStream._();

  /// Response header announcing a framed body.
  static const header = 'x-nova-stream';
  static const _chunk = 256 * 1024;

  static final _aes = cg.AesGcm.with256bits();
  static final _rng = Random.secure();

  /// Optional platform AES-GCM (Android's hardware-backed provider).
  /// Seal returns ciphertext||tag; open takes ciphertext||tag and throws
  /// on a bad tag. The pure-Dart fallback is ~10× slower on phones.
  static Future<Uint8List> Function(
    Uint8List key,
    Uint8List nonce,
    Uint8List data,
    Uint8List aad,
  )?
  nativeSeal;
  static Future<Uint8List> Function(
    Uint8List key,
    Uint8List nonce,
    Uint8List data,
    Uint8List aad,
  )?
  nativeOpen;

  static Uint8List _rawKey(String token) =>
      Uint8List.fromList(hash.sha256.convert(utf8.encode(token)).bytes);
  static final _client = http.Client();

  static cg.SecretKey _key(String token) =>
      cg.SecretKey(hash.sha256.convert(utf8.encode(token)).bytes);

  static List<int> _aad(int idx, int flag) =>
      utf8.encode('nova-chunk|$idx|$flag');

  /// Sealed frames of [file].
  static Stream<List<int>> sealFile(String token, File file) async* {
    final key = _key(token);
    final rawKey = _rawKey(token);
    final raf = await file.open();
    try {
      final len = await raf.length();
      var pos = 0;
      var idx = 0;
      do {
        final n = min(_chunk, len - pos);
        final data = n == 0 ? Uint8List(0) : await raf.read(n);
        pos += data.length;
        final flag = pos >= len ? 1 : 0;
        final List<int> nonce;
        final List<int> sealed;
        final ns = nativeSeal;
        if (ns != null) {
          final n = Uint8List.fromList(
            List.generate(12, (_) => _rng.nextInt(256)),
          );
          nonce = n;
          sealed = await ns(
            rawKey,
            nonce as Uint8List,
            data,
            Uint8List.fromList(_aad(idx, flag)),
          );
        } else {
          final box = await _aes.encrypt(
            data,
            secretKey: key,
            aad: _aad(idx, flag),
          );
          nonce = box.nonce;
          sealed = [...box.cipherText, ...box.mac.bytes];
        }
        final body = nonce.length + sealed.length;
        final out = BytesBuilder(copy: false)
          ..add([
            (body >> 24) & 255,
            (body >> 16) & 255,
            (body >> 8) & 255,
            body & 255,
            flag,
          ])
          ..add(nonce)
          ..add(sealed);
        yield out.takeBytes();
        idx++;
        if (data.isEmpty) break;
      } while (pos < len);
    } finally {
      await raf.close();
    }
  }

  /// Writes a framed body to [req]'s response.
  static Future<void> serveFile(HttpRequest req, String token, File f) async {
    req.response.headers
      ..contentType = ContentType.binary
      ..set(header, '1');
    await req.response.addStream(sealFile(token, f));
    await req.response.close();
  }

  /// Decrypted plaintext chunks of a framed stream. Throws on tampering
  /// or truncation.
  static Stream<Uint8List> open(String token, Stream<List<int>> input) async* {
    final key = _key(token);
    final rawKey = _rawKey(token);
    final no = nativeOpen;
    var buf = Uint8List(0);
    var idx = 0;
    var done = false;
    await for (final part in input) {
      if (done) throw const FormatException('data after last frame');
      final merged = Uint8List(buf.length + part.length)
        ..setAll(0, buf)
        ..setAll(buf.length, part);
      var off = 0;
      while (merged.length - off >= 5) {
        final len =
            (merged[off] << 24) |
            (merged[off + 1] << 16) |
            (merged[off + 2] << 8) |
            merged[off + 3];
        if (len < 28 || len > _chunk + 64) {
          throw const FormatException('bad frame');
        }
        if (merged.length - off - 5 < len) break;
        final flag = merged[off + 4];
        final f = Uint8List.sublistView(merged, off + 5, off + 5 + len);
        final List<int> plain;
        if (no != null) {
          plain = await no(
            rawKey,
            Uint8List.fromList(Uint8List.sublistView(f, 0, 12)),
            Uint8List.fromList(Uint8List.sublistView(f, 12)),
            Uint8List.fromList(_aad(idx, flag)),
          );
        } else {
          final box = cg.SecretBox(
            Uint8List.sublistView(f, 12, len - 16),
            nonce: Uint8List.sublistView(f, 0, 12),
            mac: cg.Mac(Uint8List.sublistView(f, len - 16)),
          );
          plain = await _aes.decrypt(box, secretKey: key, aad: _aad(idx, flag));
        }
        yield plain is Uint8List ? plain : Uint8List.fromList(plain);
        idx++;
        off += 5 + len;
        if (flag == 1) {
          done = true;
          break;
        }
      }
      buf = Uint8List.sublistView(merged, off);
      if (done && buf.isNotEmpty) throw const FormatException('trailing data');
    }
    if (!done) throw const FormatException('truncated');
  }

  /// Signed-GET helper: sends [uri] and returns the streamed response.
  static Future<http.StreamedResponse> get(Uri uri, {Duration? timeout}) {
    final f = _client.send(http.Request('GET', uri));
    return timeout == null ? f : f.timeout(timeout);
  }

  /// Whole decrypted body (images, previews).
  static Future<Uint8List> readAll(
    String token,
    http.StreamedResponse res,
  ) async {
    final b = BytesBuilder(copy: false);
    await for (final c in open(token, res.stream)) {
      b.add(c);
    }
    return b.takeBytes();
  }

  /// Decrypts straight into [out] (downloads, video temp files).
  static Future<void> toFile(
    String token,
    http.StreamedResponse res,
    File out,
  ) async {
    final sink = out.openWrite();
    try {
      await for (final c in open(token, res.stream)) {
        sink.add(c);
      }
      await sink.close();
    } catch (_) {
      await sink.close();
      try {
        await out.delete();
      } catch (_) {}
      rethrow;
    }
  }
}

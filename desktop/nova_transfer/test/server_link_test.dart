import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nova_transfer/lan_crypto.dart';
import 'package:nova_transfer/server.dart';

/// End-to-end checks of the link features the phone relies on:
/// UDP discovery, clock-skew hint on 403, heartbeat-safe /api/pair with
/// host rewrite, and the PC-side "disconnect" kick.
void main() {
  late PairServer server;
  final changes = <String?>[];
  const token = '00112233445566778899aabbccddeeff';

  setUpAll(() async {
    server = PairServer(token: token, onPhoneChanged: changes.add);
    await server.start();
  });
  tearDownAll(() => server.stop());

  Uri signed(String method, String path, {int skew = 0}) {
    final params = {'nonce': LanCrypto.nonce()};
    final ts = LanCrypto.now() + skew;
    final sig = LanCrypto.sign(token, method, path, ts, params);
    return Uri.parse('http://127.0.0.1:${server.port}$path').replace(
      queryParameters: {...params, 'ts': '$ts', 'sig': sig},
    );
  }

  Future<Map<String, dynamic>> pair(String? url) async {
    final body = await LanCrypto.seal(
      token,
      utf8.encode(jsonEncode({'phoneUrl': url})),
    );
    final res = await http.post(signed('POST', '/api/pair'), body: body);
    expect(res.statusCode, 200);
    final plain = await LanCrypto.open(token, res.bodyBytes);
    return jsonDecode(utf8.decode(plain!)) as Map<String, dynamic>;
  }

  test('pair link carries a usable host', () {
    expect(server.pairUrl, startsWith('novapair://'));
    expect(server.ip, isNotNull);
  });

  test('UDP discovery answers with pair id and port', () async {
    final sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final reply = Completer<String>();
    sock.listen((e) {
      final dg = sock.receive();
      if (dg != null && !reply.isCompleted) reply.complete(utf8.decode(dg.data));
    });
    sock.send(
      utf8.encode(LanCrypto.discoverProbe),
      InternetAddress.loopbackIPv4,
      LanCrypto.discoveryPort,
    );
    final msg = await reply.future.timeout(const Duration(seconds: 3));
    sock.close();
    expect(msg.split('|'), [
      'NOVA_HERE',
      LanCrypto.pairId(token),
      '${server.port}',
      isNotEmpty,
    ]);
  });

  test('skewed clock gets 403 with server time header', () async {
    final res = await http.get(signed('GET', '/api/info', skew: -3600));
    expect(res.statusCode, 403);
    final t = int.parse(res.headers[LanCrypto.timeHeader]!);
    expect((t - LanCrypto.now()).abs(), lessThan(5));
    final ok = await http.get(signed('GET', '/api/info'));
    expect(ok.statusCode, 200);
    expect(server.phoneOnline, isTrue);
  });

  test('heartbeat /api/pair rewrites host and only fires on change', () async {
    changes.clear();
    await pair('http://10.99.99.99:5555?k=abc');
    await pair('http://10.99.99.99:5555?k=abc');
    await pair('http://192.168.1.50:5555?k=abc'); // same after rewrite
    expect(changes, ['http://127.0.0.1:5555?k=abc']);
    expect(server.phoneUrl, 'http://127.0.0.1:5555?k=abc');
  });

  test('disconnect kicks the next heartbeat, fresh pairing clears it', () async {
    server.kickPhone();
    expect((await pair(null))['unpair'], isTrue);
    expect((await pair(null))['unpair'], isNull);

    server.kickPhone();
    await http.get(signed('GET', '/api/info')); // re-pair probe
    expect((await pair(null))['unpair'], isNull);
  });
}

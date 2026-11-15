import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nova_link/nova_link.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late Directory shareA, secret;
  late MeshNode a, b;
  final store = <String, String>{};

  MeshNode node(String n, int port, List<String> Function(MeshPeer) roots) =>
      MeshNode(
        kind: n == 'A' ? 'pc' : 'phone',
        load: () async => store[n],
        save: (j) async => store[n] = j,
        rootsFor: roots,
        preferredPort: port,
      );

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('nova_mesh');
    shareA = Directory('${tmp.path}${Platform.pathSeparator}share')
      ..createSync();
    secret = Directory('${tmp.path}${Platform.pathSeparator}secret')
      ..createSync();
    File(
      '${shareA.path}${Platform.pathSeparator}hello.txt',
    ).writeAsStringSync('hi');
    File(
      '${secret.path}${Platform.pathSeparator}pw.txt',
    ).writeAsStringSync('nope');
    a = node('A', 48390, (_) => [shareA.path]);
    b = node('B', 48391, (_) => []);
    await a.init(defaultName: 'PC');
    await b.init(defaultName: 'Phone');
    await a.start();
    await b.start();
  });

  tearDownAll(() async {
    await a.dispose();
    await b.dispose();
    await tmp.delete(recursive: true);
  });

  test('safe path blocks traversal', () {
    final sep = Platform.pathSeparator;
    expect(
      SafePath.inside('${shareA.path}${sep}hello.txt', [shareA.path]),
      isTrue,
    );
    expect(
      SafePath.inside('${shareA.path}$sep..${sep}secret${sep}pw.txt', [
        shareA.path,
      ]),
      isFalse,
    );
    expect(SafePath.inside('${shareA.path}x', [shareA.path]), isFalse);
    expect(SafePath.safeFileName('..'), isNull);
    expect(SafePath.safeFileName(r'..\..\evil.exe'), 'evil.exe');
  });

  test('closed pairing and wrong code are refused', () async {
    await expectLater(
      b.pairWith('127.0.0.1', a.port, 'ABCDEFGHJKMN'),
      throwsA(isA<PairError>().having((e) => e.code, 'code', 'closed')),
    );
    a.pairing.open();
    await expectLater(
      b.pairWith('127.0.0.1', a.port, 'ABCDEFGHJKMN'),
      throwsA(isA<PairError>().having((e) => e.code, 'code', 'bad_code')),
    );
    expect(a.peers, isEmpty);
  });

  test('pair, list, download, upload, block outside paths', () async {
    final code = a.pairing.open();
    final peerA = await b.pairWith('127.0.0.1', a.port, PairCode.format(code));
    expect(peerA.name, 'PC');
    expect(a.peers.single.name, 'Phone');
    expect(a.pairing.code, isNot(code)); // single use

    final roots = await b.list(peerA);
    expect(roots.single.isDir, isTrue);
    final files = await b.list(peerA, roots.single.path);
    expect(files.single.name, 'hello.txt');
    expect(utf8.decode(await b.download(peerA, files.single.path)), 'hi');

    final sep = Platform.pathSeparator;
    await expectLater(
      b.download(peerA, '${shareA.path}$sep..${sep}secret${sep}pw.txt'),
      throwsA(isA<MeshError>()),
    );
    await expectLater(b.list(peerA, secret.path), throwsA(isA<MeshError>()));

    await b.upload(peerA, roots.single.path, r'..\x.txt', utf8.encode('up'));
    expect(File('${shareA.path}${sep}x.txt').readAsStringSync(), 'up');
    expect(File('${tmp.path}${sep}x.txt').existsSync(), isFalse);
  });

  test('unsigned and unknown-sender requests are refused', () async {
    final r = await http.get(
      Uri.parse('http://127.0.0.1:${a.port}/api/list?from=nobody'),
    );
    expect(r.statusCode, 403);
    expect(r.headers['x-nova-unknown'], '1');
    final r2 = await http.get(
      Uri.parse('http://127.0.0.1:${a.port}/api/list?from=${b.id}&ts=1&sig=x'),
    );
    expect(r2.statusCode, 403);
  });

  test('heartbeat marks online; removal reaches the other side', () async {
    await b.tick();
    final peerA = b.peers.single;
    expect(peerA.online, isTrue);
    await b.remove(peerA);
    expect(b.peers, isEmpty);
    expect(a.peers, isEmpty);
  });
}

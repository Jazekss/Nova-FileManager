import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_file_manager/features/recycle_bin/data/recycle_bin_service.dart';

void main() {
  late Directory tmp;
  late Directory binDir;
  late RecycleBinService service;

  String norm(String p) => p.replaceAll('\\', '/');

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('nova_bin_test');
    binDir = Directory('${tmp.path}/bin');
    service = RecycleBinService(binDir: norm(binDir.path));
    await service.init();
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  test('moveToBin stores file and metadata', () async {
    final f = await File('${tmp.path}/doomed.txt').writeAsString('bye');
    final items = await service.moveToBin([norm(f.path)]);

    expect(items.length, 1);
    expect(items.first.name, 'doomed.txt');
    expect(File(items.first.binPath).existsSync(), isTrue);
    expect(f.existsSync(), isFalse);
    expect((await service.loadItems()).length, 1);
    expect(await service.totalSize(), greaterThan(0));
  });

  test('restore puts the file back at original path', () async {
    final f = await File('${tmp.path}/back.txt').writeAsString('hi');
    final original = norm(f.path);
    final items = await service.moveToBin([original]);

    await service.restore(items.first);

    expect(File(original).existsSync(), isTrue);
    expect(await service.loadItems(), isEmpty);
  });

  test('restore with occupied target uses (restored) suffix', () async {
    final f = await File('${tmp.path}/conflict.txt').writeAsString('old');
    final items = await service.moveToBin([norm(f.path)]);
    await File('${tmp.path}/conflict.txt').writeAsString('new');

    await service.restore(items.first);

    expect(File('${tmp.path}/conflict.txt').readAsStringSync(), 'new');
    expect(
      File('${tmp.path}/conflict.txt (restored)').readAsStringSync(),
      'old',
    );
  });

  test('deleteForever removes file and metadata', () async {
    final f = await File('${tmp.path}/gone.txt').create();
    final items = await service.moveToBin([norm(f.path)]);

    await service.deleteForever(items.first);

    expect(File(items.first.binPath).existsSync(), isFalse);
    expect(await service.loadItems(), isEmpty);
  });

  test('moveOut moves bin item to chosen folder', () async {
    final f = await File('${tmp.path}/out.txt').writeAsString('x');
    await Directory('${tmp.path}/target').create();
    final items = await service.moveToBin([norm(f.path)]);

    await service.moveOut(items.first, norm('${tmp.path}/target'));

    expect(File('${tmp.path}/target/out.txt').existsSync(), isTrue);
    expect(await service.loadItems(), isEmpty);
  });

  test('empty clears the whole bin', () async {
    await File('${tmp.path}/a.txt').create();
    await File('${tmp.path}/b.txt').create();
    await service.moveToBin([
      norm('${tmp.path}/a.txt'),
      norm('${tmp.path}/b.txt'),
    ]);

    await service.empty();

    expect(await service.loadItems(), isEmpty);
    expect(await service.totalSize(), 0);
  });
}

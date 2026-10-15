import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_file_manager/features/file_manager/data/file_operations.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('nova_test');
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  String p(String name) => '${tmp.path}/$name';

  test('createFolder creates a directory', () async {
    final path = await FileOperations.createFolder(tmp.path, 'docs');
    expect(Directory(path).existsSync(), isTrue);
  });

  test('rename renames a file', () async {
    await File(p('a.txt')).create();
    await FileOperations.rename(p('a.txt'), 'b.txt');
    expect(File(p('b.txt')).existsSync(), isTrue);
    expect(File(p('a.txt')).existsSync(), isFalse);
  });

  test('copy copies file tree to destination', () async {
    await Directory(p('src')).create();
    await File(p('src/f1.txt')).writeAsString('hello');
    await Directory(p('src/nested')).create();
    await File(p('src/nested/f2.txt')).writeAsString('world');
    await Directory(p('dest')).create();

    await FileOperations.copy([p('src')], p('dest'));

    expect(File(p('dest/src/f1.txt')).readAsStringSync(), 'hello');
    expect(File(p('dest/src/nested/f2.txt')).readAsStringSync(), 'world');
    // Original still exists
    expect(File(p('src/f1.txt')).existsSync(), isTrue);
  });

  test('move relocates a file', () async {
    await File(p('m.txt')).writeAsString('x');
    await Directory(p('dest')).create();

    await FileOperations.move([p('m.txt')], p('dest'));

    expect(File(p('dest/m.txt')).existsSync(), isTrue);
    expect(File(p('m.txt')).existsSync(), isFalse);
  });

  test('delete removes trees recursively', () async {
    await Directory(p('d')).create();
    await File(p('d/inner.txt')).create();

    await FileOperations.delete([p('d')]);

    expect(Directory(p('d')).existsSync(), isFalse);
  });
}

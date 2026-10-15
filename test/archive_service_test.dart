import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_file_manager/core/platform/storage_platform.dart';
import 'package:nova_file_manager/features/archive/data/archive_service.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('nova_zip_test');
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  String norm(String p) => p.replaceAll('\\', '/');

  test('isArchive detects supported extensions', () {
    expect(ArchiveService.isArchive('/x/a.zip'), isTrue);
    expect(ArchiveService.isArchive('/x/a.7z'), isTrue);
    expect(ArchiveService.isArchive('/x/a.rar'), isTrue);
    expect(ArchiveService.isArchive('/x/a.txt'), isFalse);
    expect(ArchiveService.isArchive('/x/dir'), isFalse);
  });

  test('createZip, list and extract round-trip', () async {
    await Directory('${tmp.path}/src').create();
    await File('${tmp.path}/src/one.txt').writeAsString('one');
    await Directory('${tmp.path}/src/sub').create();
    await File('${tmp.path}/src/sub/two.txt').writeAsString('two');
    final zipPath = norm('${tmp.path}/out.zip');

    final err = await ArchiveService.createZip([
      norm('${tmp.path}/src'),
    ], zipPath);
    expect(err, isNull);
    expect(File(zipPath).existsSync(), isTrue);

    // list() needs a StoragePlatform for non-zip types; zip path is pure Dart
    // so a null platform never gets used.
    final entries = await ArchiveService(_NoPlatform()).list(zipPath);
    final names = entries.map((e) => e.name).toList();
    expect(names.any((n) => n.contains('one.txt')), isTrue);
    expect(names.any((n) => n.contains('two.txt')), isTrue);

    await Directory('${tmp.path}/extracted').create();
    await ArchiveService(_NoPlatform())
        .extractAll(zipPath, norm('${tmp.path}/extracted'));
    expect(
      File('${tmp.path}/extracted/src/one.txt').existsSync() ||
          File('${tmp.path}/extracted/one.txt').existsSync(),
      isTrue,
    );
  });
}

/// ZIP paths never touch the platform channel.
class _NoPlatform implements StoragePlatform {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used for zip');
}

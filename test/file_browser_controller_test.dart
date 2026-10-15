import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_file_manager/core/models/file_entry.dart';
import 'package:nova_file_manager/core/models/storage_volume.dart';
import 'package:nova_file_manager/core/platform/storage_platform.dart';
import 'package:nova_file_manager/core/settings/settings_controller.dart';
import 'package:nova_file_manager/features/file_manager/application/file_browser_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeStoragePlatform implements StoragePlatform {
  FakeStoragePlatform(this.rootPath);

  final String rootPath;

  @override
  Future<int> getSdkInt() async => 35;

  @override
  Future<List<StorageVolume>> getVolumes() async => [
    StorageVolume(
      label: 'Internal storage',
      path: rootPath,
      isPrimary: true,
      isRemovable: false,
    ),
  ];

  @override
  Future<StorageStats> getStats(String path) async =>
      const StorageStats(totalBytes: 1000, freeBytes: 400, availableBytes: 400);

  @override
  Future<int> getInstalledAppCount() async => 42;

  @override
  Future<bool> openFile(String path) async => false;

  @override
  Future<List<Map>> archiveList(String path) async => [];

  @override
  Future<void> archiveExtract(String path, String destDir) async {}
}

void main() {
  late Directory tmp;
  late String root;
  late SettingsController settings;
  late FileBrowserController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('nova_browser_test');
    root = tmp.path.replaceAll('\\', '/');
    settings = SettingsController();
    await settings.load();
    controller = FileBrowserController(FakeStoragePlatform(root), settings);
    await controller.init();
  });

  tearDown(() async {
    controller.dispose();
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  Future<FileEntry> entryByName(String name) async =>
      controller.entries.firstWhere((e) => e.name == name);

  test('init loads volumes and lists root', () async {
    await File('$root/hello.txt').create();
    await controller.refresh();
    expect(controller.volumes.length, 1);
    expect(controller.entries.any((e) => e.name == 'hello.txt'), isTrue);
  });

  test('hidden files filtered unless showHidden', () async {
    await File('$root/.secret').create();
    await controller.refresh();
    expect(controller.entries.any((e) => e.name == '.secret'), isFalse);
    await settings.setShowHidden(true);
    await controller.refresh();
    expect(controller.entries.any((e) => e.name == '.secret'), isTrue);
  });

  test('directories sort before files', () async {
    await File('$root/zfile.txt').create();
    await Directory('$root/adir').create();
    await controller.refresh();
    expect(controller.entries.first.name, 'adir');
  });

  test('navigateTo changes directory and back', () async {
    await Directory('$root/sub').create();
    await controller.navigateTo('$root/sub');
    expect(controller.currentPath.endsWith('/sub'), isTrue);
    expect(controller.canGoUp, isTrue);
    await controller.goUp();
    expect(controller.currentPath, root);
    expect(controller.canGoUp, isFalse);
  });

  test('selection toggles and clears', () async {
    await File('$root/a.txt').create();
    await controller.refresh();
    final e = await entryByName('a.txt');
    controller
      ..enterSelection()
      ..toggleSelect(e);
    expect(controller.selectionMode, isTrue);
    expect(controller.selectedPaths, contains(e.path));
    controller.clearSelection();
    expect(controller.selectionMode, isFalse);
    expect(controller.selectedPaths, isEmpty);
  });

  test('createFolder adds entry to listing', () async {
    final err = await controller.createFolder('newfolder');
    expect(err, isNull);
    expect(controller.entries.any((e) => e.name == 'newfolder'), isTrue);
  });
}

import 'dart:convert';
import 'dart:io';

import '../../file_manager/data/file_operations.dart';

/// One item stored in the recycle bin.
class BinItem {
  const BinItem({
    required this.id,
    required this.name,
    required this.binPath,
    required this.originalPath,
    required this.isDirectory,
    required this.size,
    required this.deletedAt,
  });

  final String id;
  final String name;

  /// Location inside the bin folder.
  final String binPath;

  /// Where the file lived before deletion.
  final String originalPath;
  final bool isDirectory;
  final int size;
  final DateTime deletedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'binPath': binPath,
    'originalPath': originalPath,
    'isDirectory': isDirectory,
    'size': size,
    'deletedAt': deletedAt.toIso8601String(),
  };

  factory BinItem.fromJson(Map<String, dynamic> json) => BinItem(
    id: json['id'] as String,
    name: json['name'] as String,
    binPath: json['binPath'] as String,
    originalPath: json['originalPath'] as String,
    isDirectory: json['isDirectory'] as bool? ?? false,
    size: (json['size'] as num?)?.toInt() ?? 0,
    deletedAt:
        DateTime.tryParse(json['deletedAt'] as String? ?? '') ?? DateTime(1970),
  );
}

/// Own recycle bin: deleted files are moved into an app-private folder and
/// recorded in meta.json so they can be restored to their original location.
class RecycleBinService {
  RecycleBinService({required this.binDir});

  final String binDir;

  File get _metaFile => File('$binDir/meta.json');

  Future<void> init() async {
    await Directory(binDir).create(recursive: true);
  }

  Future<List<BinItem>> loadItems() async {
    try {
      if (!await _metaFile.exists()) return [];
      final decoded = jsonDecode(await _metaFile.readAsString());
      final items = (decoded['items'] as List)
          .map((e) => BinItem.fromJson(e as Map<String, dynamic>))
          .toList();
      // Drop items whose backing file vanished.
      items.retainWhere(
        (i) =>
            FileSystemEntity.typeSync(i.binPath) !=
            FileSystemEntityType.notFound,
      );
      items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveItems(List<BinItem> items) async {
    await init();
    await _metaFile.writeAsString(
      jsonEncode({'items': items.map((i) => i.toJson()).toList()}),
    );
  }

  /// Moves [paths] into the bin. Returns the items that were binned.
  static int _idCounter = 0;

  Future<List<BinItem>> moveToBin(List<String> paths) async {
    await init();
    final items = await loadItems();
    final added = <BinItem>[];
    for (final path in paths) {
      final normalized = path.replaceAll('\\', '/');
      final name = normalized.substring(normalized.lastIndexOf('/') + 1);
      final type = FileSystemEntity.typeSync(normalized);
      if (type == FileSystemEntityType.notFound) continue;

      final id = '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
      await FileOperations.move([normalized], binDir);
      final moved = '$binDir/$name';
      final binPath = '$binDir/$id';
      if (type == FileSystemEntityType.directory) {
        await Directory(moved).rename(binPath);
      } else {
        await File(moved).rename(binPath);
      }

      int size = 0;
      try {
        if (type == FileSystemEntityType.directory) {
          size = await _dirSize(Directory(binPath));
        } else {
          size = await File(binPath).length();
        }
      } catch (_) {}

      added.add(
        BinItem(
          id: id,
          name: name,
          binPath: binPath,
          originalPath: normalized,
          isDirectory: type == FileSystemEntityType.directory,
          size: size,
          deletedAt: DateTime.now(),
        ),
      );
    }
    items.addAll(added);
    await _saveItems(items);
    return added;
  }

  /// Restores an item to its original location. If the original path is
  /// taken, the restored name gets a "(restored)" suffix.
  Future<void> restore(BinItem item) async {
    final parent = item.originalPath.substring(
      0,
      item.originalPath.lastIndexOf('/'),
    );
    await Directory(parent).create(recursive: true);
    var target = item.originalPath;
    if (FileSystemEntity.typeSync(target) != FileSystemEntityType.notFound) {
      target = '$target (restored)';
    }
    await FileOperations.move([item.binPath], parent);
    final movedPath = '$parent/${item.id}';
    if (movedPath != target) {
      if (item.isDirectory) {
        await Directory(movedPath).rename(target);
      } else {
        await File(movedPath).rename(target);
      }
    }
    final items = await loadItems();
    items.removeWhere((i) => i.id == item.id);
    await _saveItems(items);
  }

  /// Moves a bin item to an arbitrary folder ("move out of the bin").
  Future<void> moveOut(BinItem item, String destDir) async {
    var target = '$destDir/${item.name}';
    if (FileSystemEntity.typeSync(target) != FileSystemEntityType.notFound) {
      target = '$destDir/${item.name} (restored)';
    }
    await FileOperations.move([item.binPath], destDir);
    final movedPath = '$destDir/${item.id}';
    if (item.isDirectory) {
      await Directory(movedPath).rename(target);
    } else {
      await File(movedPath).rename(target);
    }
    final items = await loadItems();
    items.removeWhere((i) => i.id == item.id);
    await _saveItems(items);
  }

  /// Permanently deletes a bin item.
  Future<void> deleteForever(BinItem item) async {
    await FileOperations.delete([item.binPath]);
    final items = await loadItems();
    items.removeWhere((i) => i.id == item.id);
    await _saveItems(items);
  }

  /// Deletes everything in the bin.
  Future<void> empty() async {
    for (final item in await loadItems()) {
      await FileOperations.delete([item.binPath]);
    }
    await _saveItems([]);
  }

  /// Total size of all binned files in bytes.
  Future<int> totalSize() async {
    int sum = 0;
    for (final item in await loadItems()) {
      sum += item.size;
    }
    return sum;
  }

  static Future<int> _dirSize(Directory dir) async {
    int sum = 0;
    try {
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File) {
          try {
            sum += await e.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return sum;
  }
}

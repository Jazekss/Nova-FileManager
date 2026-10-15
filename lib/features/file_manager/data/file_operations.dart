import 'dart:io';
import 'dart:isolate';

/// File-system operations. Heavy work (copy/delete of trees) runs in an
/// isolate so the UI thread stays responsive.
class FileOperations {
  /// Creates a folder. Returns the created directory path.
  static Future<String> createFolder(String parentPath, String name) async {
    final dir = Directory('$parentPath/$name');
    await dir.create();
    return dir.path;
  }

  /// Renames a file or folder within the same parent.
  static Future<void> rename(String path, String newName) async {
    final parent = path.substring(0, path.lastIndexOf('/'));
    final target = '$parent/$newName';
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).rename(target);
    } else {
      await File(path).rename(target);
    }
  }

  /// Copies entries into [destDir]. Runs in a background isolate.
  static Future<void> copy(List<String> paths, String destDir) =>
      Isolate.run(() => _copyAll(paths, destDir));

  /// Moves entries into [destDir]. Tries a cheap rename first, falls back to
  /// copy + delete for cross-volume moves. Runs in a background isolate.
  static Future<void> move(List<String> paths, String destDir) =>
      Isolate.run(() => _moveAll(paths, destDir));

  /// Deletes entries recursively. Runs in a background isolate.
  static Future<void> delete(List<String> paths) =>
      Isolate.run(() => _deleteAll(paths));

  static void _copyAll(List<String> paths, String destDir) {
    for (final path in paths) {
      _copyInto(path, '$destDir/${_nameOf(path)}');
    }
  }

  static void _copyInto(String src, String dest) {
    if (FileSystemEntity.typeSync(src) == FileSystemEntityType.directory) {
      Directory(dest).createSync(recursive: true);
      for (final child in Directory(src).listSync()) {
        _copyInto(child.path, '$dest/${_nameOf(child.path)}');
      }
    } else {
      File(src).copySync(dest);
    }
  }

  static void _moveAll(List<String> paths, String destDir) {
    for (final path in paths) {
      final dest = '$destDir/${_nameOf(path)}';
      try {
        if (FileSystemEntity.typeSync(path) == FileSystemEntityType.directory) {
          Directory(path).renameSync(dest);
        } else {
          File(path).renameSync(dest);
        }
      } on FileSystemException {
        // Cross-volume move: rename is not allowed, copy then delete.
        _copyInto(path, dest);
        _deletePath(path);
      }
    }
  }

  static void _deleteAll(List<String> paths) {
    for (final path in paths) {
      _deletePath(path);
    }
  }

  static void _deletePath(String path) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.directory) {
      Directory(path).deleteSync(recursive: true);
    } else if (type != FileSystemEntityType.notFound) {
      File(path).deleteSync();
    }
  }

  /// Last path segment; normalizes Windows separators so tests and
  /// cross-platform paths behave the same as on Android.
  static String _nameOf(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.substring(normalized.lastIndexOf('/') + 1);
  }
}

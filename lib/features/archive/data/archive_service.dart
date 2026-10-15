import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';

import '../../../core/platform/storage_platform.dart';

/// One entry inside an archive.
class ArchiveEntryInfo {
  const ArchiveEntryInfo({
    required this.name,
    required this.size,
    required this.isDirectory,
  });

  final String name;
  final int size;
  final bool isDirectory;
}

/// Archive support: ZIP is handled in pure Dart (isolate-safe), while 7z and
/// RAR are delegated to the Android side (commons-compress / junrar).
/// RAR is read-only — creation is not offered anywhere.
class ArchiveService {
  ArchiveService(this._platform);

  final StoragePlatform _platform;

  static const _zipExt = 'zip';
  static const _nativeExts = {'7z', 'rar'};

  static bool isArchive(String path) {
    final ext = _ext(path);
    return ext == _zipExt || _nativeExts.contains(ext);
  }

  static String _ext(String path) {
    final name = path.substring(path.lastIndexOf('/') + 1);
    final idx = name.lastIndexOf('.');
    return idx <= 0 ? '' : name.substring(idx + 1).toLowerCase();
  }

  /// Lists top-level + nested entries of the archive.
  Future<List<ArchiveEntryInfo>> list(String path) async {
    if (_ext(path) == _zipExt) return Isolate.run(() => _listZip(path));
    final raw = await _platform.archiveList(path);
    return raw
        .map(
          (e) => ArchiveEntryInfo(
            name: e['name'] as String? ?? '',
            size: (e['size'] as num?)?.toInt() ?? 0,
            isDirectory: e['isDir'] as bool? ?? false,
          ),
        )
        .toList();
  }

  /// Extracts the whole archive into [destDir].
  Future<void> extractAll(String path, String destDir) {
    if (_ext(path) == _zipExt) {
      return Isolate.run(() => _extractZip(path, destDir));
    }
    return _platform.archiveExtract(path, destDir);
  }

  /// Creates a ZIP at [destPath] containing [sources] (files/dirs).
  /// Returns an error string or null. Runs off the UI thread.
  static Future<String?> createZip(List<String> sources, String destPath) {
    return Isolate.run(() async {
      try {
        await _createZipSync(sources, destPath);
        return null;
      } catch (e) {
        return e.toString();
      }
    });
  }

  // --- ZIP implementation (pure Dart) ---

  static List<ArchiveEntryInfo> _listZip(String path) {
    final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    return archive.files
        .map(
          (f) => ArchiveEntryInfo(
            name: f.name,
            size: f.size,
            isDirectory: !f.isFile,
          ),
        )
        .toList();
  }

  static void _extractZip(String path, String destDir) {
    final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    extractArchiveToDisk(archive, destDir);
  }

  static Future<void> _createZipSync(
    List<String> sources,
    String destPath,
  ) async {
    final encoder = ZipFileEncoder();
    encoder.create(destPath);
    try {
      for (final src in sources) {
        if (FileSystemEntity.typeSync(src) == FileSystemEntityType.directory) {
          await encoder.addDirectory(Directory(src));
        } else {
          await encoder.addFile(File(src));
        }
      }
    } finally {
      await encoder.close();
    }
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/models/file_entry.dart';
import '../../../core/models/storage_volume.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/utils/wildcard.dart';

class SearchController extends ChangeNotifier {
  SearchController(this._settings);

  final SettingsController _settings;

  List<FileEntry> results = [];
  bool scanning = false;
  int scannedCount = 0;
  bool _cancelled = false;

  static const maxResults = 500;

  /// Directories skipped while scanning — huge, permission-blocked or
  /// system-managed trees that inflate scan time without useful hits.
  static const _skipDirs = {
    'Android/data',
    'Android/obb',
    'lost+found',
    'LOST.DIR',
    '.thumbnails',
    '.Trash-\$recycle',
    '.\$Recycle.Bin\$',
  };

  static bool _skipDir(String path) {
    final norm = path.replaceAll('\\', '/');
    for (final s in _skipDirs) {
      if (norm.endsWith('/$s') || norm.endsWith(s)) return true;
    }
    return false;
  }

  /// Scans [rootPath] for entries whose name matches [pattern]
  /// (Windows-style wildcards) and whose modified date is inside
  /// [from]-[to] (inclusive, optional).
  Future<void> run({
    required StorageVolume volume,
    required String rootPath,
    required String pattern,
    DateTime? from,
    DateTime? to,
  }) async {
    if (pattern.trim().isEmpty) return;
    results = [];
    scannedCount = 0;
    scanning = true;
    _cancelled = false;
    notifyListeners();

    final matcher = wildcardToRegExp(pattern.trim());
    final toEnd = to == null
        ? null
        : DateTime(to.year, to.month, to.day, 23, 59, 59);

    try {
      await _scan(Directory(rootPath), matcher, from, toEnd);
    } finally {
      scanning = false;
      notifyListeners();
    }
  }

  void cancel() {
    _cancelled = true;
  }

  Future<void> _scan(
    Directory dir,
    RegExp matcher,
    DateTime? from,
    DateTime? to,
  ) async {
    if (_cancelled || results.length >= maxResults) return;
    late final List<FileSystemEntity> children;
    try {
      children = await dir.list(followLinks: false).toList();
    } catch (_) {
      return; // folder not accessible — skip silently
    }
    for (final entity in children) {
      if (_cancelled || results.length >= maxResults) return;
      scannedCount++;
      if (scannedCount % 200 == 0) notifyListeners();

      final path = entity.path.replaceAll('\\', '/');
      final name = path.substring(path.lastIndexOf('/') + 1);
      final isDir = entity is Directory;
      if (!_settings.showHidden && name.startsWith('.')) {
        continue;
      }

      if (matcher.hasMatch(name)) {
        FileStat stat;
        try {
          stat = await entity.stat();
        } catch (_) {
          continue;
        }
        final modified = stat.modified;
        final inRange =
            (from == null || !modified.isBefore(from)) &&
            (to == null || !modified.isAfter(to));
        if (inRange) results.add(_toEntry(entity, name, stat, path));
      }
      if (isDir && !_skipDir(path)) {
        await _scan(entity, matcher, from, to);
      }
    }
  }

  FileEntry _toEntry(
    FileSystemEntity entity,
    String name,
    FileStat stat,
    String path,
  ) => FileEntry(
    name: name,
    path: path,
    isDirectory: entity is Directory,
    size: stat.size,
    modified: stat.modified,
    changed: stat.changed,
  );
}

import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';

/// One user-installed app.
class AppInfo {
  AppInfo({
    required this.pkg,
    required this.name,
    required this.version,
    required this.apkBytes,
    this.appBytes,
    this.dataBytes,
    this.cacheBytes,
    this.lastUsed,
    this.updated,
  });

  final String pkg;
  final String name;
  final String version;
  final int apkBytes;
  final int? appBytes;
  final int? dataBytes;
  final int? cacheBytes;
  final DateTime? lastUsed;
  final DateTime? updated;

  /// Full footprint when Usage access is granted, else the APK size.
  int get totalBytes => appBytes == null
      ? apkBytes
      : appBytes! + (dataBytes ?? 0) + (cacheBytes ?? 0);

  static AppInfo fromMap(Map<dynamic, dynamic> m) {
    DateTime? ts(Object? v) =>
        v is int && v > 0 ? DateTime.fromMillisecondsSinceEpoch(v) : null;
    int? n(Object? v) => v is int ? v : null;
    return AppInfo(
      pkg: m['pkg'] as String,
      name: m['name'] as String,
      version: (m['version'] as String?) ?? '',
      apkBytes: n(m['apkBytes']) ?? 0,
      appBytes: n(m['appBytes']),
      dataBytes: n(m['dataBytes']),
      cacheBytes: n(m['cacheBytes']),
      lastUsed: ts(m['lastUsed']),
      updated: ts(m['updated']),
    );
  }
}

/// A file or folder the cleaner may delete.
class JunkItem {
  JunkItem({
    required this.path,
    required this.kind,
    required this.bytes,
    required this.isDir,
  });

  final String path;

  /// thumbs | cache | temp | tempdir | log | empty | leftover | nova
  final String kind;
  final int bytes;
  final bool isDir;
}

class AppsService {
  AppsService._();

  static const _ch = MethodChannel('dev.nova.nova_file_manager/storage');

  static Future<bool> hasUsageAccess() async =>
      await _ch.invokeMethod<bool>('appsUsageAccess') ?? false;

  static Future<void> openUsageAccess() =>
      _ch.invokeMethod<bool>('appsOpenUsageAccess');

  static Future<List<AppInfo>> list() async {
    final r = await _ch.invokeMethod<List<dynamic>>('appsList') ?? [];
    return r.map((e) => AppInfo.fromMap(e as Map)).toList();
  }

  static final Map<String, Future<Uint8List?>> _icons = {};
  static Future<Uint8List?> icon(String pkg) => _icons.putIfAbsent(
    pkg,
    () => _ch
        .invokeMethod<Uint8List>('appsIcon', {'pkg': pkg})
        .catchError((_) => null),
  );

  static Future<bool> isInstalled(String pkg) async =>
      await _ch.invokeMethod<bool>('appsIsInstalled', {'pkg': pkg}) ?? false;

  static Future<void> uninstall(String pkg) =>
      _ch.invokeMethod<bool>('appsUninstall', {'pkg': pkg});

  static Future<void> openInfo(String pkg) =>
      _ch.invokeMethod<bool>('appsOpenInfo', {'pkg': pkg});

  /// Android 11+ system dialog clearing every app's cache.
  static Future<bool> clearAllCaches() async =>
      await _ch.invokeMethod<bool>('appsClearAllCaches') ?? false;

  static Future<List<String>> allPackages() async =>
      (await _ch.invokeMethod<List<dynamic>>('appsAllPackages') ?? [])
          .cast<String>();

  /// Shared-storage junk under [root]: thumbnail caches, temp and log
  /// files, cache folders, empty folders and folders left behind by
  /// uninstalled apps (`Android/media/<pkg>`, `/<pkg>`). Runs in an
  /// isolate. Android/data and Android/obb are never touched.
  static Future<List<JunkItem>> scanJunk(
    String root, {
    String? novaTemp,
  }) async {
    final pkgs = (await allPackages()).toSet();
    return Isolate.run(() => _scanJunk(root, pkgs, novaTemp));
  }

  /// Folders an uninstalled [pkg] / [appName] left in shared storage.
  static Future<List<JunkItem>> leftoversOf(
    String root,
    String pkg,
    String appName,
  ) => Isolate.run(() {
    final out = <JunkItem>[];
    void add(String p) {
      final d = Directory(p);
      if (d.existsSync()) {
        out.add(
          JunkItem(path: p, kind: 'leftover', bytes: _size(d), isDir: true),
        );
      }
    }

    add('$root/Android/media/$pkg');
    add('$root/$pkg');
    final clean = appName.trim();
    if (clean.length >= 3 && !_protected.contains(clean.toLowerCase())) {
      add('$root/$clean');
    }
    return out;
  });
}

/// Top-level folders that belong to the user, never treated as leftovers.
const _protected = {
  'android',
  'dcim',
  'download',
  'downloads',
  'documents',
  'pictures',
  'music',
  'movies',
  'podcasts',
  'ringtones',
  'alarms',
  'notifications',
  'audiobooks',
  'recordings',
  'screenshots',
  'nova',
};

int _size(FileSystemEntity e) {
  try {
    if (e is File) return e.lengthSync();
    var t = 0;
    for (final f in Directory(
      e.path,
    ).listSync(recursive: true, followLinks: false)) {
      if (f is File) {
        try {
          t += f.lengthSync();
        } catch (_) {}
      }
    }
    return t;
  } catch (_) {
    return 0;
  }
}

List<JunkItem> _scanJunk(String root, Set<String> pkgs, String? novaTemp) {
  final out = <JunkItem>[];
  final pkgRe = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+){1,}$');
  const tempExt = {'tmp', 'temp', 'part', 'crdownload'};
  const logExt = {'log'};
  const cacheNames = {
    '.thumbnails',
    'cache',
    '.cache',
    'temp',
    '.temp',
    'tmp',
    '.tmp',
  };

  // Leftovers in Android/media (readable with "All files access").
  final media = Directory('$root/Android/media');
  if (media.existsSync()) {
    for (final d in media.listSync(followLinks: false)) {
      final name = d.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (d is Directory && pkgRe.hasMatch(name) && !pkgs.contains(name)) {
        out.add(
          JunkItem(
            path: d.path,
            kind: 'leftover',
            bytes: _size(d),
            isDir: true,
          ),
        );
      }
    }
  }

  void walk(Directory dir, int depth) {
    List<FileSystemEntity> list;
    try {
      list = dir.listSync(followLinks: false);
    } catch (_) {
      return;
    }
    for (final e in list) {
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final lower = name.toLowerCase();
      if (e is Directory) {
        if (depth == 0 && lower == 'android') continue;
        if (depth == 0 && pkgRe.hasMatch(name) && !pkgs.contains(name)) {
          out.add(
            JunkItem(
              path: e.path,
              kind: 'leftover',
              bytes: _size(e),
              isDir: true,
            ),
          );
          continue;
        }
        if (cacheNames.contains(lower)) {
          final b = _size(e);
          if (b > 0) {
            out.add(
              JunkItem(
                path: e.path,
                // Cache folders are safe to drop; a folder merely called
                // "temp"/"tmp" may hold the user's own files → own group.
                kind: lower.contains('thumb')
                    ? 'thumbs'
                    : lower.contains('cache')
                    ? 'cache'
                    : 'tempdir',
                bytes: b,
                isDir: true,
              ),
            );
          }
          continue;
        }
        bool empty;
        try {
          empty = e.listSync().isEmpty;
        } catch (_) {
          empty = false;
        }
        if (empty && depth > 0) {
          out.add(JunkItem(path: e.path, kind: 'empty', bytes: 0, isDir: true));
          continue;
        }
        if (depth < 8) walk(e, depth + 1);
      } else if (e is File) {
        final dot = lower.lastIndexOf('.');
        final ext = dot < 0 ? '' : lower.substring(dot + 1);
        if (tempExt.contains(ext)) {
          out.add(
            JunkItem(path: e.path, kind: 'temp', bytes: _size(e), isDir: false),
          );
        } else if (logExt.contains(ext)) {
          out.add(
            JunkItem(path: e.path, kind: 'log', bytes: _size(e), isDir: false),
          );
        }
      }
    }
  }

  walk(Directory(root), 0);

  if (novaTemp != null) {
    final t = Directory(novaTemp);
    if (t.existsSync()) {
      for (final d in t.listSync(followLinks: false)) {
        final name = d.uri.pathSegments.where((s) => s.isNotEmpty).last;
        if (name.startsWith('nova_')) {
          out.add(
            JunkItem(
              path: d.path,
              kind: 'nova',
              bytes: _size(d),
              isDir: d is Directory,
            ),
          );
        }
      }
    }
  }
  out.sort((a, b) => b.bytes.compareTo(a.bytes));
  return out;
}

/// Deletes [items] (files or folders). Returns how many were removed.
Future<int> deleteJunk(List<JunkItem> items) => Isolate.run(() {
  var n = 0;
  for (final i in items) {
    try {
      if (i.isDir) {
        Directory(i.path).deleteSync(recursive: true);
      } else {
        File(i.path).deleteSync();
      }
      n++;
    } catch (_) {}
  }
  return n;
});

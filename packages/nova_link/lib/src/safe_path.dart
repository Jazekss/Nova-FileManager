import 'dart:io';

/// Path confinement for everything a remote device asks for.
///
/// A plain `startsWith(root)` check lets `C:\Share\..\Windows` or a
/// symlink/junction inside a shared folder escape it. Here the path is
/// normalised lexically ('.'/'..' resolved, separators unified, case
/// folded on Windows) and, when it exists, its real target is checked
/// against the real roots too.
class SafePath {
  SafePath._();

  static String norm(String p) {
    final win = Platform.isWindows;
    var s = p.replaceAll('\\', '/');
    var prefix = '';
    final drive = RegExp(r'^[A-Za-z]:').firstMatch(s);
    if (drive != null) {
      prefix = drive.group(0)!.toUpperCase();
      s = s.substring(2);
    }
    final out = <String>[];
    for (final seg in s.split('/')) {
      if (seg.isEmpty || seg == '.') continue;
      if (seg == '..') {
        if (out.isNotEmpty) out.removeLast();
        continue;
      }
      out.add(seg);
    }
    final r = '$prefix/${out.join('/')}';
    return win ? r.toLowerCase() : r;
  }

  static bool _under(String p, String root) =>
      p == root || p.startsWith(root.endsWith('/') ? root : '$root/');

  static String _real(String p) {
    try {
      final t = FileSystemEntity.typeSync(p);
      if (t == FileSystemEntityType.directory) {
        return norm(Directory(p).resolveSymbolicLinksSync());
      }
      if (t == FileSystemEntityType.file) {
        return norm(File(p).resolveSymbolicLinksSync());
      }
    } catch (_) {}
    return norm(p);
  }

  /// True when [path] is one of [roots] or lies inside one of them.
  static bool inside(String path, Iterable<String> roots) {
    if (path.isEmpty || path.contains('\u0000')) return false;
    final rootList = roots.where((r) => r.isNotEmpty).toList();
    if (rootList.isEmpty) return false;
    final n = norm(path);
    if (!rootList.map(norm).any((r) => _under(n, r))) return false;
    try {
      if (FileSystemEntity.typeSync(path, followLinks: false) ==
          FileSystemEntityType.notFound) {
        return true; // e.g. a new upload target — lexical check suffices
      }
      final real = _real(path);
      return rootList.map(_real).any((r) => _under(real, r));
    } catch (_) {
      return false;
    }
  }

  /// Last path segment, whichever separator the remote side used.
  static String baseName(String p) {
    final parts = p.split(RegExp(r'[\\/]')).where((e) => e.isNotEmpty);
    return parts.isEmpty ? p : parts.last;
  }

  /// A file name safe to create inside a folder (no separators, no
  /// reserved characters, not '.'/'..').
  static String? safeFileName(String name) {
    final b = baseName(name).replaceAll(RegExp(r'[<>:"|?*\x00-\x1f]'), '_');
    final t = b.trim();
    if (t.isEmpty || t == '.' || t == '..') return null;
    return t.length > 200 ? t.substring(t.length - 200) : t;
  }
}

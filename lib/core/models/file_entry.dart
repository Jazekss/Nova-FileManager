class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    this.modified,
    this.changed,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? modified;
  final DateTime? changed;

  String get parentPath {
    final idx = path.lastIndexOf('/');
    return idx <= 0 ? '/' : path.substring(0, idx);
  }

  String get extension {
    final idx = name.lastIndexOf('.');
    return idx <= 0 ? '' : name.substring(idx + 1).toLowerCase();
  }

  bool get isHidden => name.startsWith('.');
}

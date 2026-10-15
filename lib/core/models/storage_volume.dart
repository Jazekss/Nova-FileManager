class StorageVolume {
  const StorageVolume({
    required this.label,
    required this.path,
    required this.isPrimary,
    required this.isRemovable,
  });

  final String label;
  final String path;
  final bool isPrimary;
  final bool isRemovable;
}

class StorageStats {
  const StorageStats({
    required this.totalBytes,
    required this.freeBytes,
    required this.availableBytes,
  });

  final int totalBytes;
  final int freeBytes;
  final int availableBytes;

  int get usedBytes => totalBytes - freeBytes;
  double get usedFraction => totalBytes == 0 ? 0 : usedBytes / totalBytes;
}

import 'package:flutter/services.dart';

import '../models/storage_volume.dart';

/// Abstraction over Android platform APIs (storage volumes, statfs, packages).
abstract class StoragePlatform {
  Future<int> getSdkInt();
  Future<List<StorageVolume>> getVolumes();
  Future<StorageStats> getStats(String path);
  Future<int> getInstalledAppCount();

  /// Opens a file with a system app. Returns false if nothing can handle it.
  Future<bool> openFile(String path);

  /// Lists entries of a 7z/RAR archive (native implementation).
  Future<List<Map>> archiveList(String path);

  /// Extracts a 7z/RAR archive into [destDir].
  Future<void> archiveExtract(String path, String destDir);
}

class MethodChannelStoragePlatform implements StoragePlatform {
  static const _channel = MethodChannel('dev.nova.nova_file_manager/storage');

  @override
  Future<int> getSdkInt() async =>
      (await _channel.invokeMethod<int>('getSdkInt')) ?? 0;

  @override
  Future<List<StorageVolume>> getVolumes() async {
    final raw = await _channel.invokeListMethod<Map>('getStorageVolumes');
    return (raw ?? [])
        .map(
          (m) => StorageVolume(
            label: m['label'] as String? ?? 'Storage',
            path: m['path'] as String? ?? '',
            isPrimary: m['isPrimary'] as bool? ?? false,
            isRemovable: m['isRemovable'] as bool? ?? false,
          ),
        )
        .where((v) => v.path.isNotEmpty)
        .toList();
  }

  @override
  Future<StorageStats> getStats(String path) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>(
      'getStorageStats',
      {'path': path},
    );
    return StorageStats(
      totalBytes: (raw?['totalBytes'] as num?)?.toInt() ?? 0,
      freeBytes: (raw?['freeBytes'] as num?)?.toInt() ?? 0,
      availableBytes: (raw?['availableBytes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<int> getInstalledAppCount() async =>
      (await _channel.invokeMethod<int>('getInstalledAppCount')) ?? 0;

  @override
  Future<bool> openFile(String path) async =>
      (await _channel.invokeMethod<bool>('openFile', {'path': path})) ?? false;

  @override
  Future<List<Map>> archiveList(String path) async =>
      (await _channel.invokeListMethod<Map>('archiveList', {'path': path})) ??
      [];

  @override
  Future<void> archiveExtract(String path, String destDir) => _channel
      .invokeMethod<void>('archiveExtract', {'path': path, 'destDir': destDir});
}

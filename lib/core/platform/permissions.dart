import 'package:permission_handler/permission_handler.dart';

import 'storage_platform.dart';

/// Storage access helpers. Android 11+ (API 30) needs MANAGE_EXTERNAL_STORAGE
/// ("All files access"); older versions use the classic storage permission.
class StoragePermissions {
  StoragePermissions(this._platform);

  final StoragePlatform _platform;

  Future<bool> isGranted() async {
    final sdk = await _sdkInt();
    if (sdk >= 30) {
      return Permission.manageExternalStorage.isGranted;
    }
    return Permission.storage.isGranted;
  }

  /// Opens the system settings page for All files access on API 30+, or
  /// requests the runtime storage permission on older versions.
  Future<bool> request() async {
    final sdk = await _sdkInt();
    if (sdk >= 30) {
      return (await Permission.manageExternalStorage.request()).isGranted;
    }
    return (await Permission.storage.request()).isGranted;
  }

  Future<int> _sdkInt() async {
    try {
      return await _platform.getSdkInt();
    } catch (_) {
      return 30; // assume modern Android if channel fails
    }
  }
}

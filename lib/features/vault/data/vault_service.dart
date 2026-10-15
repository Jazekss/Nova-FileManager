import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Private encrypted storage ("Vault"). Files are AES-256-GCM encrypted by an
/// Android Keystore key (native channel) and stored as `<name>.nvx` in an
/// app-private directory that is invisible to other apps and file managers.
class VaultService {
  VaultService({required this.vaultDir, this.cacheDir});

  static const _channel = MethodChannel('dev.nova.nova_file_manager/storage');
  static const _keyPin = 'vault_pin_v1';
  static const _ext = '.nvx';

  /// App-private directory holding .nvx files.
  final String vaultDir;

  /// Temp dir for decrypted previews; cleaned on lock.
  final String? cacheDir;

  // --- PIN ---

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPin) != null;
  }

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    await prefs.setString(_keyPin, '$salt\$${_hash(pin, salt)}');
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyPin);
    if (stored == null) return false;
    final sep = stored.indexOf('\$');
    return _hash(pin, stored.substring(0, sep)) == stored.substring(sep + 1);
  }

  // --- Crypto (Android Keystore via platform channel) ---

  Future<void> ensureKey() => _channel.invokeMethod('vaultEnsureKey');

  Future<void> _encrypt(String src, String dest) =>
      _channel.invokeMethod('vaultEncrypt', {'src': src, 'dest': dest});

  Future<void> _decrypt(String src, String dest) =>
      _channel.invokeMethod('vaultDecrypt', {'src': src, 'dest': dest});

  // --- Items ---

  List<FileSystemEntity> list() {
    final dir = Directory(vaultDir);
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(_ext))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  static String displayName(File f) => f.path.substring(
    f.path.lastIndexOf('/') + 1,
    f.path.length - _ext.length,
  );

  /// Encrypts [srcPath] into the vault and deletes the original.
  /// Folders are zipped first, so the vault item is `<name>.zip.nvx` —
  /// exporting restores a zip that the user can extract.
  Future<void> moveToVault(String srcPath) async {
    await ensureKey();
    final name = srcPath.substring(srcPath.lastIndexOf('/') + 1);
    if (FileSystemEntity.typeSync(srcPath) == FileSystemEntityType.directory) {
      final tmp = await Directory.systemTemp.createTemp('nova_vault');
      final zipPath = '${tmp.path}/$name.zip';
      final err = await _zipTo(srcPath, zipPath);
      if (err != null) throw err;
      var dest = '$vaultDir/$name.zip$_ext';
      var n = 1;
      while (File(dest).existsSync()) {
        dest = '$vaultDir/$name.$n.zip$_ext';
        n++;
      }
      await Directory(vaultDir).create(recursive: true);
      await _encrypt(zipPath, dest);
      await tmp.delete(recursive: true);
      await Directory(srcPath).delete(recursive: true);
      return;
    }
    var dest = '$vaultDir/$name$_ext';
    var n = 1;
    while (File(dest).existsSync()) {
      dest = '$vaultDir/$name.$n$_ext';
      n++;
    }
    await Directory(vaultDir).create(recursive: true);
    await _encrypt(srcPath, dest);
    await File(srcPath).delete();
  }

  static Future<String?> _zipTo(String srcDir, String zipPath) async {
    try {
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addDirectory(Directory(srcDir));
      await encoder.close();
      return null;
    } catch (e) {
      return '$e';
    }
  }

  /// Decrypts an item into [destDir] under its original name and removes it
  /// from the vault.
  Future<String> export(File item, String destDir) async {
    await ensureKey();
    final name = displayName(item);
    var out = '$destDir/$name';
    var n = 1;
    while (File(out).existsSync()) {
      final dot = name.lastIndexOf('.');
      out = dot > 0
          ? '$destDir/${name.substring(0, dot)} ($n)${name.substring(dot)}'
          : '$destDir/$name ($n)';
      n++;
    }
    await _decrypt(item.path, out);
    await item.delete();
    return out;
  }

  /// Decrypts to the temp view dir for viewing. Caller deletes afterwards.
  Future<String> decryptToTemp(File item) async {
    await ensureKey();
    final dir = '${cacheDir ?? vaultDir}/vault_view';
    await Directory(dir).create(recursive: true);
    final out = '$dir/${displayName(item)}';
    await _decrypt(item.path, out);
    return out;
  }

  Future<void> deleteItem(File item) => item.delete();

  /// Removes all decrypted temp previews.
  void clearTemp() {
    if (cacheDir == null) return;
    final dir = Directory('$cacheDir/vault_view');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desktop app settings: theme, language, shared folder list.
class DesktopSettings extends ChangeNotifier {
  static const _keyTheme = 'theme';
  static const _keyLang = 'language';
  static const _keyShares = 'sharedFolders';
  static const _keyPairToken = 'pairToken';
  static const _keyThumbs = 'shareThumbs';

  ThemeMode themeMode = ThemeMode.system;
  String? languageCode;
  List<String> sharedFolders = [];

  /// Fetch thumbnails for phone-shared files — off by default since it
  /// makes list loading slower.
  bool showThumbs = false;

  /// Persistent pairing token — keeps the QR/pairing link stable across
  /// restarts so a paired phone reconnects without rescanning.
  String? pairToken;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeMode = switch (p.getString(_keyTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    languageCode = p.getString(_keyLang);
    sharedFolders = p.getStringList(_keyShares) ?? [];
    pairToken = p.getString(_keyPairToken);
    showThumbs = p.getBool(_keyThumbs) ?? false;
    notifyListeners();
  }

  Future<void> setShowThumbs(bool v) async {
    showThumbs = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyThumbs, v);
  }

  Future<void> savePairToken(String token) async {
    pairToken = token;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyPairToken, token);
  }

  Future<void> setTheme(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyTheme, m.name);
  }

  Future<void> setLanguage(String? code) async {
    languageCode = code;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    if (code == null) {
      await p.remove(_keyLang);
    } else {
      await p.setString(_keyLang, code);
    }
  }

  Future<void> setSharedFolders(List<String> dirs) async {
    sharedFolders = dirs;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_keyShares, dirs);
  }
}

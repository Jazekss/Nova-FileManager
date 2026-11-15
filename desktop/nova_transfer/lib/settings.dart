import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desktop app settings: theme, language, shared folder list.
class DesktopSettings extends ChangeNotifier {
  static const _keyTheme = 'theme';
  static const _keyLang = 'language';
  static const _keyShares = 'sharedFolders';
  static const _keyPairToken = 'pairToken';
  static const _keyThumbs = 'shareThumbs';
  static const _keyPaneWidth = 'paneWidth';
  static const _keyViewMode = 'viewMode';
  static const _keyPhoneUrl = 'phoneUrl';
  static const _keyManagePhone = 'managePhone';
  static const _keyPhoneSort = 'phoneSort';
  static const _keyScopes = 'folderScopes';

  ThemeMode themeMode = ThemeMode.system;

  /// Who sees each shared folder besides "my phone" (which sees all):
  /// 'phone' (only my phone), 'all' (every paired device) or
  /// `ids:<id>,<id>` (picked devices). Missing = 'phone'.
  Map<String, String> folderScopes = {};

  String scopeOf(String path) => folderScopes[path] ?? 'phone';

  /// True when mesh device [peerId] may see [path].
  bool sharedWith(String path, String peerId) {
    final s = scopeOf(path);
    if (s == 'all') return true;
    if (!s.startsWith('ids:')) return false;
    return s.substring(4).split(',').contains(peerId);
  }

  Future<void> setScope(String path, String? scope) async {
    if (scope == null || scope == 'phone') {
      folderScopes.remove(path);
    } else {
      folderScopes[path] = scope;
    }
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyScopes, jsonEncode(folderScopes));
  }

  String? languageCode;
  List<String> sharedFolders = [];

  /// Fetch thumbnails for phone-shared files — off by default since it
  /// makes list loading slower.
  bool showThumbs = false;

  /// Width of the left "PC folders" pane — persisted between launches.
  double paneWidth = 300;

  /// Phone-pane view mode: list / small / large.
  String viewMode = 'small';

  /// Persistent pairing token — keeps the QR/pairing link stable across
  /// restarts so a paired phone reconnects without rescanning.
  String? pairToken;

  /// Last registered phone share URL — restored on launch so the right
  /// panel reconnects without the phone re-registering.
  String? phoneUrl;

  /// Allow file management (select/delete) on phone-shared files.
  bool managePhone = true;

  /// Phone-pane sort: `field_dir` — field: name|size|date,
  /// dir: asc|desc. Default newest first.
  String phoneSort = 'date_desc';

  String get phoneSortField => phoneSort.split('_').first;
  bool get phoneSortAsc => phoneSort.endsWith('_asc');

  Future<void> setPhoneSort(String field, bool asc) async {
    phoneSort = '${field}_${asc ? 'asc' : 'desc'}';
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyPhoneSort, phoneSort);
  }

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
    paneWidth = p.getDouble(_keyPaneWidth) ?? 300;
    viewMode = p.getString(_keyViewMode) ?? 'small';
    phoneUrl = p.getString(_keyPhoneUrl);
    managePhone = p.getBool(_keyManagePhone) ?? true;
    try {
      folderScopes = (jsonDecode(p.getString(_keyScopes) ?? '{}') as Map)
          .cast<String, String>();
    } catch (_) {}
    final sort = p.getString(_keyPhoneSort) ?? 'date_desc';
    phoneSort = switch (sort) {
      'name_asc' ||
      'name_desc' ||
      'size_asc' ||
      'size_desc' ||
      'date_asc' ||
      'date_desc' => sort,
      _ => 'date_desc',
    };
    notifyListeners();
  }

  Future<void> setPhoneUrl(String? url) async {
    phoneUrl = url;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    if (url == null) {
      await p.remove(_keyPhoneUrl);
    } else {
      await p.setString(_keyPhoneUrl, url);
    }
  }

  Future<void> setManagePhone(bool v) async {
    managePhone = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyManagePhone, v);
  }

  Future<void> setPaneWidth(double w) async {
    paneWidth = w;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_keyPaneWidth, w);
  }

  Future<void> setViewMode(String m) async {
    viewMode = m;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyViewMode, m);
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

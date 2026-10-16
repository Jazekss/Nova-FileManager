import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/format.dart';

/// Languages the app ships translations for. `null` = follow the system.
const supportedLanguageCodes = [
  'en',
  'lv',
  'lt',
  'et',
  'nb',
  'sv',
  'pl',
  'de',
  'ru',
];

class SettingsController extends ChangeNotifier {
  static const _keyTheme = 'themeMode';
  static const _keyUnit = 'sizeUnit';
  static const _keyHidden = 'showHidden';
  static const _keyLang = 'languageCode';
  static const _keyThumbs = 'shareThumbs';
  static const _keyPcView = 'pcShareView';

  ThemeMode _themeMode = ThemeMode.system;
  SizeUnit _sizeUnit = SizeUnit.auto;
  bool _showHidden = false;
  bool _shareThumbs = false;
  String? _languageCode;

  ThemeMode get themeMode => _themeMode;
  SizeUnit get sizeUnit => _sizeUnit;
  bool get showHidden => _showHidden;

  /// Fetch image/video/APK thumbnails while browsing a paired PC —
  /// slower list loading, so it's off by default.
  bool get shareThumbs => _shareThumbs;

  /// PC-share view mode: list / medium / large.
  String get pcShareView => _pcShareView;
  String _pcShareView = 'list';
  String? get languageCode => _languageCode;

  /// Null locale = follow the system language.
  Locale? get locale => _languageCode == null ? null : Locale(_languageCode!);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt(_keyTheme) ?? 0];
    _sizeUnit = SizeUnit.values[prefs.getInt(_keyUnit) ?? 0];
    _showHidden = prefs.getBool(_keyHidden) ?? false;
    _shareThumbs = prefs.getBool(_keyThumbs) ?? false;
    _pcShareView = prefs.getString(_keyPcView) ?? 'list';
    _languageCode = prefs.getString(_keyLang);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    (await SharedPreferences.getInstance()).setInt(_keyTheme, mode.index);
  }

  Future<void> setSizeUnit(SizeUnit unit) async {
    _sizeUnit = unit;
    notifyListeners();
    (await SharedPreferences.getInstance()).setInt(_keyUnit, unit.index);
  }

  Future<void> setShowHidden(bool value) async {
    _showHidden = value;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_keyHidden, value);
  }

  Future<void> setShareThumbs(bool value) async {
    _shareThumbs = value;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_keyThumbs, value);
  }

  Future<void> setPcShareView(String mode) async {
    _pcShareView = mode;
    notifyListeners();
    (await SharedPreferences.getInstance()).setString(_keyPcView, mode);
  }

  Future<void> setLanguage(String? code) async {
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_keyLang);
    } else {
      await prefs.setString(_keyLang, code);
    }
  }
}

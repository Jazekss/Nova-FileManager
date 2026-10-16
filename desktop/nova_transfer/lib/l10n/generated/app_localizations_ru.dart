// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get pcFolders => 'Общие папки ПК';

  @override
  String get phoneFiles => 'Общее с телефона';

  @override
  String get addFolder => 'Добавить папку';

  @override
  String get remove => 'Удалить';

  @override
  String get refresh => 'Обновить';

  @override
  String get options => 'Настройки';

  @override
  String get connection => 'Соединение';

  @override
  String get showQr => 'Показать QR для сопряжения';

  @override
  String get qrHint => 'Сканируйте приложением Nova на телефоне';

  @override
  String get phoneConnected => 'Телефон подключён';

  @override
  String get noPhone => 'Телефон не подключён';

  @override
  String get disconnect => 'Отключить';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get themeAuto => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get about => 'О программе';

  @override
  String get version => 'Версия';

  @override
  String get developer => 'Разработчик';

  @override
  String get buyCoffee => 'Buy me a coffee';

  @override
  String get download => 'Скачать';

  @override
  String get uploadHere => 'Загрузить в эту папку';

  @override
  String get emptyList => 'Пока ничего не расшарено';

  @override
  String get folderEmpty => 'Папка пуста';

  @override
  String get up => 'Вверх';

  @override
  String get settings => 'Настройки';

  @override
  String get manualCode => 'Или введите вручную на телефоне:';

  @override
  String get pairUrl => 'Ссылка сопряжения';

  @override
  String get phoneUnreachable =>
      'Не удаётся связаться с телефоном — проверьте общий доступ и Wi-Fi.';

  @override
  String get shareApk => 'APK через QR';

  @override
  String get chooseApk => 'Выберите файл .apk';

  @override
  String get apkQrHint =>
      'Сначала выберите APK, затем отсканируйте QR камерой телефона — скачается в Download/.';

  @override
  String get apkScanNow =>
      'Отсканируйте камерой телефона, чтобы скачать этот APK.';

  @override
  String get shareThumbs => 'Показывать миниатюры';

  @override
  String get shareThumbsNote =>
      'Превью фото/видео/APK — список грузится медленнее.';

  @override
  String get view => 'Просмотр';

  @override
  String get rename => 'Переименовать';

  @override
  String get cancel => 'Отмена';

  @override
  String get back => 'Назад';

  @override
  String get close => 'Закрыть';
}

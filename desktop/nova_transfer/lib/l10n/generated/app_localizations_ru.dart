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

  @override
  String get delete => 'Удалить';

  @override
  String get managePhone => 'Управление файлами телефона';

  @override
  String get managePhoneNote =>
      'Отметить и удалить файлы в общих папках телефона';

  @override
  String get sort => 'Сортировка';

  @override
  String get sortName => 'Имя';

  @override
  String get sortSize => 'Размер';

  @override
  String get sortDate => 'Дата';

  @override
  String get sortAsc => 'По возрастанию';

  @override
  String get sortDesc => 'По убыванию';

  @override
  String get statusReconnecting => 'Переподключение…';

  @override
  String get statusWaiting => 'Ожидание телефона';

  @override
  String get connectTitle => 'Подключите телефон';

  @override
  String get connectStep1 => 'На телефоне откройте Nova → Обмен с ПК';

  @override
  String get connectStep2 =>
      'Нажмите «Сканировать QR» и наведите камеру на этот код';

  @override
  String get connectAuto =>
      'Уже сопряжено? Просто откройте Nova на телефоне — подключение восстановится само.';

  @override
  String get noNetwork => 'На этом компьютере не найдено сетевое подключение.';

  @override
  String get firewallOk => 'Брандмауэр Windows разрешает Nova Transfer';

  @override
  String get firewallBlocked =>
      'Брандмауэр Windows блокирует подключение телефона.';

  @override
  String get firewallUnknown =>
      'Если телефон не подключается, разрешите Nova Transfer в брандмауэре Windows.';

  @override
  String get firewallFix => 'Разрешить';

  @override
  String get sameWifiHint =>
      'Телефон и компьютер должны быть в одной сети. Гостевой Wi-Fi часто не даёт устройствам видеть друг друга.';

  @override
  String get phoneShareHint =>
      'Пока ничего не открыто. На телефоне: Обмен с ПК → ⋮ → Поделиться папкой телефона.';

  @override
  String get phoneReconnecting => 'Телефон не отвечает — переподключение…';

  @override
  String get phoneReconnectHint =>
      'Откройте Nova на телефоне в той же сети Wi-Fi — подключение восстановится через несколько секунд.';

  @override
  String get disconnectNote =>
      'Телефон забудет этот компьютер, и QR-код придётся сканировать снова.';
}

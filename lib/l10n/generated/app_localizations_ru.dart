// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Nova File Manager';

  @override
  String get navHome => 'Главная';

  @override
  String get navFiles => 'Файлы';

  @override
  String get navSearch => 'Поиск';

  @override
  String get permTitle => 'Требуется доступ к хранилищу';

  @override
  String get permBody =>
      'Nova нужен доступ «Ко всем файлам», чтобы просматривать, копировать и перемещать файлы во внутренней памяти и на SD-карте.\n\nДаже с ним Android блокирует доступ к папкам Android/data других приложений, а настоящие системные файлы требуют root.';

  @override
  String get permGrant => 'Предоставить доступ';

  @override
  String get permContinueLimited => 'Продолжить с ограниченным доступом';

  @override
  String get settings => 'Настройки';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get sizeUnits => 'Единицы размера';

  @override
  String get unitAuto => 'Авто';

  @override
  String get showHidden => 'Показывать скрытые файлы';

  @override
  String get showHiddenSubtitle => 'Файлы и папки, начинающиеся с точки';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный язык';

  @override
  String get about => 'О приложении';

  @override
  String versionLabel(Object version) {
    return 'Версия $version';
  }

  @override
  String get developerLine => 'Разработчик: JKdizains — jkdizains.lv';

  @override
  String get developerThanks =>
      'Разработано одним человеком. Спасибо за поддержку!';

  @override
  String get coffeeButton => 'Угости меня кофе';

  @override
  String get storage => 'Хранилище';

  @override
  String get internalStorage => 'Внутренняя память';

  @override
  String get sdCard => 'SD-карта';

  @override
  String get save => 'Сохранить';

  @override
  String get saved => 'Сохранено';

  @override
  String get fileTooLarge => 'Файл слишком большой для редактирования';

  @override
  String get change => 'Изменить';

  @override
  String get renameExtWarnTitle => 'Изменить расширение?';

  @override
  String renameExtWarnBody(String oldExt, String newExt) {
    return 'Изменение $oldExt на $newExt может сделать файл нечитаемым для других приложений.';
  }

  @override
  String get shareWifi => 'Поделиться по Wi-Fi';

  @override
  String get wifiTransfer => 'Передача по Wi-Fi';

  @override
  String get wifiCardSubtitle => 'Отправка и приём файлов с компьютера';

  @override
  String get wifiOpenHint =>
      'Откройте этот адрес на компьютере (та же сеть Wi-Fi)';

  @override
  String get wifiSharedFiles => 'Общие файлы';

  @override
  String wifiUploadNote(String path) {
    return 'Загрузки сохраняются в $path';
  }

  @override
  String wifiReceived(String name) {
    return 'Получено: $name';
  }

  @override
  String get wifiStop => 'Остановить';

  @override
  String get vault => 'Хранилище';

  @override
  String get vaultCardSubtitle => 'Зашифрованные личные файлы';

  @override
  String get vaultUnlockReason => 'Разблокировать хранилище';

  @override
  String get vaultSetPin => 'Задайте PIN (4–8 цифр)';

  @override
  String get vaultEnterPin => 'Введите PIN хранилища';

  @override
  String get vaultUnlock => 'Разблокировать';

  @override
  String get vaultUseBiometric => 'Использовать биометрию';

  @override
  String get vaultPinTooShort => 'PIN должен содержать минимум 4 цифры';

  @override
  String get vaultWrongPin => 'Неверный PIN';

  @override
  String get vaultEmpty => 'Хранилище пусто';

  @override
  String get vaultEmptyHint =>
      'Перемещайте файлы сюда: контекстное меню файла → В хранилище';

  @override
  String get vaultExport => 'Экспортировать из хранилища';

  @override
  String get movedToVault => 'Перемещено в хранилище';

  @override
  String get exported => 'Экспортировано';

  @override
  String get moveToVault => 'В хранилище';

  @override
  String get convertTo => 'Конвертировать в';

  @override
  String get converted => 'Конвертировано';

  @override
  String get convertFailed => 'Не удалось конвертировать файл';

  @override
  String get download => 'Скачать';

  @override
  String get downloaded => 'Скачано';

  @override
  String get upload => 'Загрузить';

  @override
  String get uploaded => 'Загружено';

  @override
  String get signOut => 'Выйти';

  @override
  String get driveIntro =>
      'Войдите, чтобы просматривать и управлять файлами Google Drive.';

  @override
  String get driveScopeNote =>
      'Nova использует минимальное разрешение Drive: видны только файлы, созданные приложением или открытые через него.';

  @override
  String get driveSignIn => 'Войти через Google';

  @override
  String get driveSignInFailed => 'Вход отменён или не удался';

  @override
  String get driveTrashQ => 'Переместить в корзину Drive?';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get sharedToPc => 'Открыт доступ к ПК';

  @override
  String get sharedFromPc => 'Общие с ПК';

  @override
  String get pairWithPc => 'Связать с компьютером';

  @override
  String get pcPairHint =>
      'Откройте Nova File Manager Desktop на ПК и покажите QR сопряжения в меню подключения.';

  @override
  String get invalidPairLink => 'Неверная ссылка сопряжения';

  @override
  String get uploadHere => 'Загрузить сюда';

  @override
  String get sharePhoneFolder => 'Поделиться папкой телефона';

  @override
  String get pairFailed => 'Сопряжение не удалось';

  @override
  String get pair => 'Связать';

  @override
  String get disconnect => 'Отключить';

  @override
  String get scanQr => 'Сканировать QR';

  @override
  String get pcShare => 'Обмен с ПК';

  @override
  String get enterManually => 'Ввести вручную';

  @override
  String get enterPairLink => 'Введите ссылку сопряжения';

  @override
  String get refresh => 'Обновить';

  @override
  String get pressAgainToExit => 'Нажмите «назад» ещё раз, чтобы выйти';

  @override
  String get shareThumbs => 'Миниатюры в обмене с ПК';

  @override
  String get shareThumbsNote =>
      'Показывает превью фото/видео/APK — список загружается медленнее.';

  @override
  String get noStorage => 'Хранилища не найдены';

  @override
  String get notAvailable => 'Недоступно';

  @override
  String get noData => 'Нет данных';

  @override
  String freeOf(Object free, Object total) {
    return '$free свободно из $total';
  }

  @override
  String get installedApps => 'Установленные приложения';

  @override
  String get recycleBin => 'Корзина';

  @override
  String binItems(Object count, Object size) {
    return '$count элементов · $size';
  }

  @override
  String get quickAccess => 'Быстрый доступ';

  @override
  String get androidLimits => 'Ограничения Android';

  @override
  String get limitData =>
      'Папки Android/data и Android/obb других приложений заблокированы в Android 11+, даже с доступом ко всем файлам.';

  @override
  String get limitSystem =>
      'Настоящие системные файлы (/system, /data) требуют root — это приложение root не использует.';

  @override
  String get limitSd =>
      'На некоторых устройствах запись на SD-карту может требовать доступа через системный диалог.';

  @override
  String get fileManager => 'Файловый менеджер';

  @override
  String get newFolder => 'Новая папка';

  @override
  String get folderName => 'Имя папки';

  @override
  String get select => 'Выбрать';

  @override
  String get selectAll => 'Выбрать всё';

  @override
  String get openWith => 'Открыть с помощью';

  @override
  String get rename => 'Переименовать';

  @override
  String get copyTo => 'Копировать в...';

  @override
  String get moveTo => 'Переместить в...';

  @override
  String get createZip => 'Создать ZIP';

  @override
  String get properties => 'Свойства';

  @override
  String get delete => 'Удалить';

  @override
  String get view => 'Вид';

  @override
  String get viewDetailed => 'Подробный список';

  @override
  String get viewSmall => 'Мелкие значки';

  @override
  String get viewLarge => 'Крупные значки';

  @override
  String get sort => 'Сортировка';

  @override
  String get sortName => 'Имя';

  @override
  String get sortSize => 'Размер';

  @override
  String get sortDate => 'Дата';

  @override
  String selectedCount(Object count) {
    return 'Выбрано: $count';
  }

  @override
  String deleteTitle(Object count) {
    return 'Удалить $count элемент(ов)?';
  }

  @override
  String get deleteBody =>
      'Переместите в корзину, чтобы позже можно было восстановить, или удалите навсегда.';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Закрыть';

  @override
  String get deletePermanently => 'Удалить навсегда';

  @override
  String get toRecycleBin => 'В корзину';

  @override
  String get movedToBin => 'Перемещено в корзину';

  @override
  String get deleted => 'Удалено';

  @override
  String get moved => 'Перемещено';

  @override
  String get copied => 'Скопировано';

  @override
  String get renamed => 'Переименовано';

  @override
  String get folderCreated => 'Папка создана';

  @override
  String get zipCreated => 'ZIP создан';

  @override
  String get noAppToOpen => 'Не найдено приложение для открытия файла';

  @override
  String get retry => 'Повторить';

  @override
  String get emptyFolder => 'Эта папка пуста';

  @override
  String get sameFolderError => 'Назначение — текущая папка';

  @override
  String get permissionDeniedError =>
      'Доступ запрещён. Некоторые места (напр., Android/data или системные папки) ограничены Android и требуют особого доступа.';

  @override
  String get typeFolder => 'Папка';

  @override
  String typeFile(Object ext) {
    return 'Файл (.$ext)';
  }

  @override
  String get propType => 'Тип';

  @override
  String get propPath => 'Путь';

  @override
  String get propSize => 'Размер';

  @override
  String get propModified => 'Изменён';

  @override
  String get propCreated => 'Создан';

  @override
  String get chooseDestination => 'Выберите назначение';

  @override
  String get up => 'Вверх';

  @override
  String get noSubfolders => 'Нет подпапок';

  @override
  String get selectHere => 'Выбрать здесь';

  @override
  String get cannotOpenFolder => 'Не удаётся открыть папку';

  @override
  String get fileNamePattern => 'Имя файла или шаблон';

  @override
  String get searchHint => 'напр., *.pdf или отчёт';

  @override
  String get wholeStorage => 'Всё хранилище';

  @override
  String get searchWholeStorage => 'Искать по всему хранилищу';

  @override
  String get fromDate => 'С даты';

  @override
  String get toDate => 'По дату';

  @override
  String get clearDates => 'Сбросить даты';

  @override
  String get search => 'Искать';

  @override
  String scannedCount(Object count) {
    return 'Просканировано $count элементов…';
  }

  @override
  String get noResults => 'Пока нет результатов';

  @override
  String get emptyBinQ => 'Очистить корзину?';

  @override
  String get emptyBinBody =>
      'Все элементы будут удалены навсегда. Это нельзя отменить.';

  @override
  String get emptyBin => 'Очистить';

  @override
  String get binEmptied => 'Корзина очищена';

  @override
  String get binEmpty => 'Корзина пуста';

  @override
  String get restore => 'Восстановить';

  @override
  String get restored => 'Восстановлено';

  @override
  String get deleteForeverQ => 'Удалить навсегда?';

  @override
  String get extractAll => 'Распаковать всё';

  @override
  String get archiveEmpty => 'Архив пуст';

  @override
  String archiveReadError(Object error) {
    return 'Не удалось прочитать архив: $error';
  }

  @override
  String extractedTo(Object path) {
    return 'Распаковано в $path';
  }

  @override
  String extractFailed(Object error) {
    return 'Ошибка распаковки: $error';
  }

  @override
  String cannotPlay(Object error) {
    return 'Не удаётся воспроизвести: $error';
  }

  @override
  String get pcReconnecting => 'Компьютер недоступен — переподключение…';

  @override
  String get pcRejected =>
      'Компьютер больше не узнаёт этот телефон. Отсканируйте QR-код снова.';

  @override
  String get pcUnreachableHint =>
      'Не удаётся связаться с компьютером. Убедитесь, что Nova Transfer открыт, оба устройства в одной сети Wi-Fi, а брандмауэр Windows разрешает Nova Transfer.';

  @override
  String get otherDevices => 'Другие устройства';

  @override
  String get otherDevicesHint =>
      'Свяжите свои другие компьютеры и телефоны для быстрой передачи файлов. Nova должна быть открыта на обоих устройствах; сопряжённые устройства переподключаются сами.';

  @override
  String get thisDevice => 'Это устройство';

  @override
  String get deviceName => 'Имя устройства';

  @override
  String get devices => 'Устройства';

  @override
  String get addDevice => 'Добавить устройство';

  @override
  String get pairCode => 'Код';

  @override
  String get deviceAddress => 'Адрес';

  @override
  String get pairCodeWrong =>
      'Неверный или устаревший код — проверьте и повторите.';

  @override
  String get deviceUnreachable =>
      'Устройство недоступно. Открыта ли там Nova и в той же ли сети Wi-Fi?';

  @override
  String get noDevices => 'Устройств пока нет';

  @override
  String get online => 'В сети';

  @override
  String get offline => 'Не в сети — откройте на нём Nova';

  @override
  String get deviceRejected => 'Это устройство удалило сопряжение';

  @override
  String get removeDevice => 'Удалить устройство';

  @override
  String get removeDeviceNote =>
      'Оба устройства забудут друг друга. Для повторного сопряжения нужен новый код.';

  @override
  String get shareWith => 'Открыть для';

  @override
  String get shareAll => 'Все сопряжённые устройства';

  @override
  String get deviceOffline =>
      'Устройство не отвечает — откройте на нём Nova в той же сети Wi-Fi.';

  @override
  String pairedWith(String name) {
    return 'Связано с $name';
  }

  @override
  String receivedFrom(String name, String file) {
    return 'Получено от $name: $file';
  }

  @override
  String get otherDevicesCard => 'Другие компьютеры и телефоны';

  @override
  String get scanOtherQr => 'Сканировать QR другого устройства';

  @override
  String get showMyQr => 'Показать QR этого телефона';

  @override
  String get enterAddressCode => 'Ввести адрес и код';

  @override
  String get pcAddress => 'Адрес компьютера';

  @override
  String get myQrHint =>
      'На другом устройстве откройте Nova → Другие устройства → Добавить устройство, затем отсканируйте этот QR или введите адрес и код. Код одноразовый.';

  @override
  String get sharedWithDevices => 'Открыто с этого телефона';

  @override
  String get shareScopeAll => 'Все устройства';

  @override
  String get addShare => 'Открыть папку или файл';

  @override
  String get appsCardSubtitle => 'Размер, последнее использование, удаление';

  @override
  String get files => 'Файлы';

  @override
  String get filesCardSubtitle => 'Фото, видео, документы и др. по категориям';

  @override
  String get uninstall => 'Удалить';

  @override
  String uninstallQ(int count) {
    return 'Удалить приложения: $count?';
  }

  @override
  String get uninstallNote =>
      'Android попросит подтвердить каждое приложение. При удалении стираются и кэш, и личные данные; оставшиеся папки затем предложим удалить.';

  @override
  String uninstalledCount(int count) {
    return 'Удалено приложений: $count';
  }

  @override
  String get total => 'Всего';

  @override
  String get appInfo => 'О приложении';

  @override
  String get appInfoNote => 'Очистить кэш или данные в настройках Android';

  @override
  String get cleaner => 'Очистка';

  @override
  String get sortBySize => 'Размер';

  @override
  String get sortByLastUsed => 'Последнее использование (давние сначала)';

  @override
  String get sortByName => 'Имя';

  @override
  String get sortByDate => 'Дата';

  @override
  String appsSummary(int count, String size) {
    return 'Приложений: $count · $size';
  }

  @override
  String get cacheTotal => 'Кэш';

  @override
  String get usageAccessTitle => 'Разрешите «Доступ к истории использования»';

  @override
  String get usageAccessNote =>
      'Нужно, чтобы показать полный размер, кэш и время последнего использования.';

  @override
  String get allow => 'Разрешить';

  @override
  String get neverUsed => 'Давно не использовалось';

  @override
  String get lastUsedUnknown => 'Посл. использование: дайте доступ';

  @override
  String get lastUsed => 'Посл. запуск';

  @override
  String get leftoversTitle => 'Оставшиеся папки';

  @override
  String get leftoversNote =>
      'Эти папки принадлежали удалённым приложениям. Снимите отметку с того, что хотите оставить.';

  @override
  String get keep => 'Оставить';

  @override
  String deletedCount(int count) {
    return 'Удалено: $count';
  }

  @override
  String get rescan => 'Сканировать снова';

  @override
  String get clearAllCaches => 'Очистить кэш всех приложений';

  @override
  String get clearAllCachesQ => 'Очистить кэш всех приложений?';

  @override
  String get clearAllCachesNote =>
      'Android попросит подтвердить. Данные и входы сохранятся — удаляются только временные файлы.';

  @override
  String get clearAllCachesUnavailable =>
      'Нужен Android 11+ и доступ ко всем файлам. На старых версиях откройте сведения о приложении.';

  @override
  String get clear => 'Очистить';

  @override
  String deleteJunkQ(int count) {
    return 'Удалить элементы: $count?';
  }

  @override
  String get deleteJunkNote =>
      'Это необратимо — элементы не попадут в корзину.';

  @override
  String get junkThumbs => 'Кэш миниатюр';

  @override
  String get junkTemp => 'Временные файлы';

  @override
  String get junkCacheDirs => 'Папки кэша';

  @override
  String get junkTempDirs => 'Папки «Temp» (проверьте)';

  @override
  String get junkLogs => 'Файлы журналов';

  @override
  String get junkEmpty => 'Пустые папки';

  @override
  String get junkLeftovers => 'От удалённых приложений';

  @override
  String get junkNova => 'Временные файлы Nova';

  @override
  String get deleteSelected => 'Удалить выбранное';

  @override
  String get scanning => 'Сканирование…';

  @override
  String get appCaches => 'Кэш приложений';

  @override
  String get appCachesNote =>
      'Нажмите на приложение, чтобы очистить только его в настройках.';

  @override
  String get junkFiles => 'Ненужные файлы';

  @override
  String get selectNone => 'Снять выбор';

  @override
  String get noJunk => 'Нечего очищать — отлично!';

  @override
  String get catImages => 'Изображения';

  @override
  String get catVideos => 'Видео';

  @override
  String get catAudio => 'Аудио';

  @override
  String get catDocuments => 'Документы';

  @override
  String get catArchives => 'Архивы';

  @override
  String get catApks => 'Установщики (APK)';

  @override
  String get catLarge => 'Большие файлы (100 МБ+)';

  @override
  String get catOther => 'Другие файлы';

  @override
  String moveToBinQ(int count) {
    return 'Переместить файлы в корзину: $count?';
  }

  @override
  String get moveToBinNote => 'Их можно восстановить из корзины.';

  @override
  String movedToBinN(int count) {
    return 'В корзину: $count';
  }

  @override
  String moveFilesQ(int count) {
    return 'Переместить файлы сюда: $count?';
  }

  @override
  String get move => 'Переместить';

  @override
  String movedCount(int count) {
    return 'Перемещено файлов: $count';
  }

  @override
  String get pcAddressHelp =>
      'Используйте адрес и код из Nova Transfer → Подключение (не «Другие устройства»).';

  @override
  String get pcAddressBad =>
      'Введите адрес, напр. 192.168.1.10 или 192.168.1.10:48320';

  @override
  String get pcOtherDevicesCode =>
      'Этот адрес/код из «Другие устройства». Для своего ПК: Nova Transfer → Подключение.';
}

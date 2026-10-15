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
}

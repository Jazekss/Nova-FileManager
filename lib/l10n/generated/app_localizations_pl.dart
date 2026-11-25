// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Nova File Manager';

  @override
  String get navHome => 'Start';

  @override
  String get navFiles => 'Pliki';

  @override
  String get navSearch => 'Szukaj';

  @override
  String get permTitle => 'Wymagany dostęp do pamięci';

  @override
  String get permBody =>
      'Nova potrzebuje „Dostępu do wszystkich plików”, aby przeglądać, kopiować i przenosić pliki w pamięci wewnętrznej i na karcie SD.\n\nNawet z nim Android blokuje dostęp do folderów Android/data innych aplikacji, a prawdziwe pliki systemowe wymagają roota.';

  @override
  String get permGrant => 'Przyznaj dostęp';

  @override
  String get permContinueLimited => 'Kontynuuj z ograniczonym dostępem';

  @override
  String get settings => 'Ustawienia';

  @override
  String get appearance => 'Wygląd';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get sizeUnits => 'Jednostki rozmiaru';

  @override
  String get unitAuto => 'Auto';

  @override
  String get showHidden => 'Pokaż ukryte pliki';

  @override
  String get showHiddenSubtitle => 'Pliki i foldery zaczynające się od kropki';

  @override
  String get language => 'Język';

  @override
  String get languageSystem => 'Język systemowy';

  @override
  String get about => 'Informacje';

  @override
  String versionLabel(Object version) {
    return 'Wersja $version';
  }

  @override
  String get developerLine => 'Autor: JKdizains — jkdizains.lv';

  @override
  String get developerThanks =>
      'Stworzone przez jedną osobę. Dziękuję za wsparcie!';

  @override
  String get coffeeButton => 'Postaw mi kawę';

  @override
  String get storage => 'Pamięć';

  @override
  String get internalStorage => 'Pamięć wewnętrzna';

  @override
  String get sdCard => 'Karta SD';

  @override
  String get save => 'Zapisz';

  @override
  String get saved => 'Zapisano';

  @override
  String get fileTooLarge => 'Plik jest zbyt duży do edycji';

  @override
  String get change => 'Zmień';

  @override
  String get renameExtWarnTitle => 'Zmienić rozszerzenie?';

  @override
  String renameExtWarnBody(String oldExt, String newExt) {
    return 'Zmiana $oldExt na $newExt może sprawić, że inne aplikacje nie otworzą pliku.';
  }

  @override
  String get shareWifi => 'Udostępnij przez Wi-Fi';

  @override
  String get wifiTransfer => 'Transfer Wi-Fi';

  @override
  String get wifiCardSubtitle => 'Wysyłaj i odbieraj pliki z komputera';

  @override
  String get wifiOpenHint =>
      'Otwórz ten adres na komputerze (ta sama sieć Wi-Fi)';

  @override
  String get wifiSharedFiles => 'Udostępnione pliki';

  @override
  String wifiUploadNote(String path) {
    return 'Przesłane pliki zapisywane w $path';
  }

  @override
  String wifiReceived(String name) {
    return 'Odebrano: $name';
  }

  @override
  String get wifiStop => 'Zatrzymaj udostępnianie';

  @override
  String get vault => 'Sejf';

  @override
  String get vaultCardSubtitle => 'Zaszyfrowane prywatne pliki';

  @override
  String get vaultUnlockReason => 'Odblokuj sejf';

  @override
  String get vaultSetPin => 'Ustaw PIN (4–8 cyfr)';

  @override
  String get vaultEnterPin => 'Wpisz PIN sejfu';

  @override
  String get vaultUnlock => 'Odblokuj';

  @override
  String get vaultUseBiometric => 'Użyj biometrii';

  @override
  String get vaultPinTooShort => 'PIN musi mieć co najmniej 4 cyfry';

  @override
  String get vaultWrongPin => 'Nieprawidłowy PIN';

  @override
  String get vaultEmpty => 'Sejf jest pusty';

  @override
  String get vaultEmptyHint =>
      'Przenieś pliki tutaj: menu kontekstowe pliku → Przenieś do sejfu';

  @override
  String get vaultExport => 'Eksportuj z sejfu';

  @override
  String get movedToVault => 'Przeniesiono do sejfu';

  @override
  String get exported => 'Wyeksportowano';

  @override
  String get moveToVault => 'Przenieś do sejfu';

  @override
  String get convertTo => 'Konwertuj na';

  @override
  String get converted => 'Skonwertowano';

  @override
  String get convertFailed => 'Nie można skonwertować pliku';

  @override
  String get download => 'Pobierz';

  @override
  String get downloaded => 'Pobrano';

  @override
  String get upload => 'Prześlij';

  @override
  String get uploaded => 'Przesłano';

  @override
  String get signOut => 'Wyloguj';

  @override
  String get driveIntro =>
      'Zaloguj się, aby przeglądać i zarządzać plikami Google Drive.';

  @override
  String get driveScopeNote =>
      'Nova używa najmniejszego uprawnienia Drive: widzi tylko pliki utworzone przez aplikację lub otwarte przez nią.';

  @override
  String get driveSignIn => 'Zaloguj się przez Google';

  @override
  String get driveSignInFailed => 'Logowanie anulowane lub nieudane';

  @override
  String get driveTrashQ => 'Przenieść do kosza Drive?';

  @override
  String get comingSoon => 'Wkrótce';

  @override
  String get sharedToPc => 'Udostępniono do PC';

  @override
  String get sharedFromPc => 'Udostępnione z PC';

  @override
  String get pairWithPc => 'Sparuj z komputerem';

  @override
  String get pcPairHint =>
      'Otwórz Nova File Manager Desktop na PC i pokaż QR parowania w menu połączenia.';

  @override
  String get invalidPairLink => 'Nieprawidłowy link parowania';

  @override
  String get uploadHere => 'Prześlij tutaj';

  @override
  String get sharePhoneFolder => 'Udostępnij folder telefonu';

  @override
  String get pairFailed => 'Parowanie nieudane';

  @override
  String get pair => 'Sparuj';

  @override
  String get disconnect => 'Rozłącz';

  @override
  String get scanQr => 'Skanuj QR';

  @override
  String get pcShare => 'Udostępnianie PC';

  @override
  String get enterManually => 'Wpisz ręcznie';

  @override
  String get enterPairLink => 'Wpisz link parowania';

  @override
  String get refresh => 'Odśwież';

  @override
  String get pressAgainToExit => 'Naciśnij wstecz ponownie, aby wyjść';

  @override
  String get shareThumbs => 'Miniatury w udostępnianiu PC';

  @override
  String get shareThumbsNote =>
      'Pokazuje podglądy zdjęć/wideo/APK — lista ładuje się wolniej.';

  @override
  String get noStorage => 'Nie znaleziono pamięci';

  @override
  String get notAvailable => 'Niedostępne';

  @override
  String get noData => 'Brak danych';

  @override
  String freeOf(Object free, Object total) {
    return '$free wolne z $total';
  }

  @override
  String get installedApps => 'Zainstalowane aplikacje';

  @override
  String get recycleBin => 'Kosz';

  @override
  String binItems(Object count, Object size) {
    return '$count elementów · $size';
  }

  @override
  String get quickAccess => 'Szybki dostęp';

  @override
  String get androidLimits => 'Ograniczenia Androida';

  @override
  String get limitData =>
      'Foldery Android/data i Android/obb innych aplikacji są blokowane przez Android 11+, nawet przy dostępie do wszystkich plików.';

  @override
  String get limitSystem =>
      'Prawdziwe pliki systemowe (/system, /data) wymagają roota — ta aplikacja nie używa roota.';

  @override
  String get limitSd =>
      'Na niektórych urządzeniach zapis na kartę SD może wymagać przyznania dostępu przez selektor systemowy.';

  @override
  String get fileManager => 'Menedżer plików';

  @override
  String get newFolder => 'Nowy folder';

  @override
  String get folderName => 'Nazwa folderu';

  @override
  String get select => 'Zaznacz';

  @override
  String get selectAll => 'Zaznacz wszystko';

  @override
  String get openWith => 'Otwórz za pomocą';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get copyTo => 'Kopiuj do...';

  @override
  String get moveTo => 'Przenieś do...';

  @override
  String get createZip => 'Utwórz ZIP';

  @override
  String get properties => 'Właściwości';

  @override
  String get delete => 'Usuń';

  @override
  String get view => 'Widok';

  @override
  String get viewDetailed => 'Lista szczegółowa';

  @override
  String get viewSmall => 'Małe ikony';

  @override
  String get viewLarge => 'Duże ikony';

  @override
  String get sort => 'Sortuj';

  @override
  String get sortName => 'Nazwa';

  @override
  String get sortSize => 'Rozmiar';

  @override
  String get sortDate => 'Data';

  @override
  String selectedCount(Object count) {
    return 'Zaznaczono: $count';
  }

  @override
  String deleteTitle(Object count) {
    return 'Usunąć $count element(ów)?';
  }

  @override
  String get deleteBody =>
      'Przenieś do kosza, aby móc je później przywrócić, albo usuń trwale.';

  @override
  String get cancel => 'Anuluj';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Zamknij';

  @override
  String get deletePermanently => 'Usuń trwale';

  @override
  String get toRecycleBin => 'Do kosza';

  @override
  String get movedToBin => 'Przeniesiono do kosza';

  @override
  String get deleted => 'Usunięto';

  @override
  String get moved => 'Przeniesiono';

  @override
  String get copied => 'Skopiowano';

  @override
  String get renamed => 'Zmieniono nazwę';

  @override
  String get folderCreated => 'Utworzono folder';

  @override
  String get zipCreated => 'Utworzono ZIP';

  @override
  String get noAppToOpen => 'Nie znaleziono aplikacji do otwarcia tego pliku';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get emptyFolder => 'Ten folder jest pusty';

  @override
  String get sameFolderError => 'Miejsce docelowe to bieżący folder';

  @override
  String get permissionDeniedError =>
      'Odmowa dostępu. Niektóre lokalizacje (np. Android/data lub foldery systemowe) są ograniczone przez Androida i wymagają specjalnego dostępu.';

  @override
  String get typeFolder => 'Folder';

  @override
  String typeFile(Object ext) {
    return 'Plik (.$ext)';
  }

  @override
  String get propType => 'Typ';

  @override
  String get propPath => 'Ścieżka';

  @override
  String get propSize => 'Rozmiar';

  @override
  String get propModified => 'Zmodyfikowany';

  @override
  String get propCreated => 'Utworzony';

  @override
  String get chooseDestination => 'Wybierz miejsce docelowe';

  @override
  String get up => 'W górę';

  @override
  String get noSubfolders => 'Brak podfolderów';

  @override
  String get selectHere => 'Wybierz tutaj';

  @override
  String get cannotOpenFolder => 'Nie można otworzyć folderu';

  @override
  String get fileNamePattern => 'Nazwa pliku lub wzorzec';

  @override
  String get searchHint => 'np. *.pdf lub raport';

  @override
  String get wholeStorage => 'Cała pamięć';

  @override
  String get searchWholeStorage => 'Szukaj w całej pamięci';

  @override
  String get fromDate => 'Od daty';

  @override
  String get toDate => 'Do daty';

  @override
  String get clearDates => 'Wyczyść daty';

  @override
  String get search => 'Szukaj';

  @override
  String scannedCount(Object count) {
    return 'Przeskanowano $count elementów…';
  }

  @override
  String get noResults => 'Brak wyników';

  @override
  String get emptyBinQ => 'Opróżnić kosz?';

  @override
  String get emptyBinBody =>
      'Wszystkie elementy zostaną trwale usunięte. Nie można tego cofnąć.';

  @override
  String get emptyBin => 'Opróżnij';

  @override
  String get binEmptied => 'Kosz opróżniony';

  @override
  String get binEmpty => 'Kosz jest pusty';

  @override
  String get restore => 'Przywróć';

  @override
  String get restored => 'Przywrócono';

  @override
  String get deleteForeverQ => 'Usunąć trwale?';

  @override
  String get extractAll => 'Wypakuj wszystko';

  @override
  String get archiveEmpty => 'Archiwum jest puste';

  @override
  String archiveReadError(Object error) {
    return 'Nie można odczytać archiwum: $error';
  }

  @override
  String extractedTo(Object path) {
    return 'Wypakowano do $path';
  }

  @override
  String extractFailed(Object error) {
    return 'Wypakowywanie nie powiodło się: $error';
  }

  @override
  String cannotPlay(Object error) {
    return 'Nie można odtworzyć: $error';
  }

  @override
  String get pcReconnecting =>
      'Komputer niedostępny — trwa automatyczne ponowne łączenie…';

  @override
  String get pcRejected =>
      'Komputer nie rozpoznaje już tego telefonu. Zeskanuj kod QR ponownie.';

  @override
  String get pcUnreachableHint =>
      'Nie można połączyć się z komputerem. Upewnij się, że Nova Transfer jest otwarty, oba urządzenia są w tej samej sieci Wi-Fi, a Zapora Windows zezwala na Nova Transfer.';

  @override
  String get otherDevices => 'Inne urządzenia';

  @override
  String get otherDevicesHint =>
      'Połącz inne komputery i telefony, aby szybko przenosić pliki. Nova musi być otwarta na obu urządzeniach; sparowane urządzenia łączą się ponownie same.';

  @override
  String get thisDevice => 'To urządzenie';

  @override
  String get deviceName => 'Nazwa urządzenia';

  @override
  String get devices => 'Urządzenia';

  @override
  String get addDevice => 'Dodaj urządzenie';

  @override
  String get pairCode => 'Kod';

  @override
  String get deviceAddress => 'Adres';

  @override
  String get pairCodeWrong =>
      'Błędny lub wygasły kod — sprawdź i spróbuj ponownie.';

  @override
  String get deviceUnreachable =>
      'Nie można połączyć się z urządzeniem. Czy Nova jest tam otwarta i w tej samej sieci Wi-Fi?';

  @override
  String get noDevices => 'Brak urządzeń';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline — otwórz na nim Nova';

  @override
  String get deviceRejected => 'To urządzenie usunęło parowanie';

  @override
  String get removeDevice => 'Usuń urządzenie';

  @override
  String get removeDeviceNote =>
      'Oba urządzenia zapomną o sobie. Aby je ponownie połączyć, potrzebny będzie nowy kod.';

  @override
  String get shareWith => 'Udostępnij';

  @override
  String get shareAll => 'Wszystkie sparowane urządzenia';

  @override
  String get deviceOffline =>
      'Urządzenie nie odpowiada — otwórz na nim Nova w tej samej sieci Wi-Fi.';

  @override
  String pairedWith(String name) {
    return 'Połączono z $name';
  }

  @override
  String receivedFrom(String name, String file) {
    return 'Odebrano od $name: $file';
  }

  @override
  String get otherDevicesCard => 'Dodatkowe komputery i telefony';

  @override
  String get scanOtherQr => 'Zeskanuj QR drugiego urządzenia';

  @override
  String get showMyQr => 'Pokaż QR tego telefonu';

  @override
  String get enterAddressCode => 'Wpisz adres i kod';

  @override
  String get pcAddress => 'Adres komputera';

  @override
  String get myQrHint =>
      'Na drugim urządzeniu otwórz Nova → Inne urządzenia → Dodaj urządzenie, a następnie zeskanuj ten QR lub wpisz adres i kod. Kod działa raz.';

  @override
  String get sharedWithDevices => 'Udostępniane z tego telefonu';

  @override
  String get shareScopeAll => 'Wszystkie urządzenia';

  @override
  String get addShare => 'Udostępnij folder lub plik';

  @override
  String get appsCardSubtitle => 'Rozmiar, ostatnie użycie, odinstalowanie';

  @override
  String get files => 'Pliki';

  @override
  String get filesCardSubtitle =>
      'Zdjęcia, filmy, dokumenty i inne według kategorii';

  @override
  String get uninstall => 'Odinstaluj';

  @override
  String uninstallQ(int count) {
    return 'Odinstalować $count aplikacje?';
  }

  @override
  String get uninstallNote =>
      'Android poprosi o potwierdzenie każdej aplikacji. Odinstalowanie usuwa też pamięć podręczną i dane prywatne; pozostawione foldery zaproponujemy potem usunąć.';

  @override
  String uninstalledCount(int count) {
    return 'Odinstalowano aplikacje: $count';
  }

  @override
  String get total => 'Razem';

  @override
  String get appInfo => 'Informacje o aplikacji';

  @override
  String get appInfoNote =>
      'Wyczyść pamięć podręczną lub dane w ustawieniach Androida';

  @override
  String get cleaner => 'Czyszczenie';

  @override
  String get sortBySize => 'Rozmiar';

  @override
  String get sortByLastUsed => 'Ostatnie użycie (najstarsze najpierw)';

  @override
  String get sortByName => 'Nazwa';

  @override
  String get sortByDate => 'Data';

  @override
  String appsSummary(int count, String size) {
    return '$count aplikacji · $size';
  }

  @override
  String get cacheTotal => 'Pamięć podręczna';

  @override
  String get usageAccessTitle => 'Zezwól na „Dostęp do danych o użyciu”';

  @override
  String get usageAccessNote =>
      'Potrzebne do pokazania pełnego rozmiaru, pamięci podręcznej i ostatniego użycia.';

  @override
  String get allow => 'Zezwól';

  @override
  String get neverUsed => 'Nieużywana ostatnio';

  @override
  String get lastUsedUnknown => 'Ostatnie użycie: zezwól na dostęp do użycia';

  @override
  String get lastUsed => 'Ostatnio użyta';

  @override
  String get leftoversTitle => 'Pozostawione foldery';

  @override
  String get leftoversNote =>
      'Te foldery należały do usuniętych aplikacji. Odznacz to, co chcesz zachować.';

  @override
  String get keep => 'Zachowaj';

  @override
  String deletedCount(int count) {
    return 'Usunięto: $count';
  }

  @override
  String get rescan => 'Skanuj ponownie';

  @override
  String get clearAllCaches => 'Wyczyść pamięć podręczną wszystkich aplikacji';

  @override
  String get clearAllCachesQ =>
      'Wyczyścić pamięć podręczną wszystkich aplikacji?';

  @override
  String get clearAllCachesNote =>
      'Android poprosi o potwierdzenie. Aplikacje zachowają dane i logowania — usuwane są tylko pliki tymczasowe.';

  @override
  String get clearAllCachesUnavailable =>
      'Wymaga Androida 11+ i dostępu do wszystkich plików. Na starszym otwórz informacje o aplikacji.';

  @override
  String get clear => 'Wyczyść';

  @override
  String deleteJunkQ(int count) {
    return 'Usunąć $count elementy?';
  }

  @override
  String get deleteJunkNote => 'To jest trwałe — elementy nie trafią do kosza.';

  @override
  String get junkThumbs => 'Pamięć miniatur';

  @override
  String get junkTemp => 'Pliki tymczasowe';

  @override
  String get junkCacheDirs => 'Foldery pamięci podręcznej';

  @override
  String get junkTempDirs => 'Foldery „Temp” (sprawdź najpierw)';

  @override
  String get junkLogs => 'Pliki dziennika';

  @override
  String get junkEmpty => 'Puste foldery';

  @override
  String get junkLeftovers => 'Po odinstalowanych aplikacjach';

  @override
  String get junkNova => 'Pliki tymczasowe Nova';

  @override
  String get deleteSelected => 'Usuń zaznaczone';

  @override
  String get scanning => 'Skanowanie…';

  @override
  String get appCaches => 'Pamięć podręczna aplikacji';

  @override
  String get appCachesNote =>
      'Dotknij aplikacji, aby otworzyć jej ustawienia i wyczyścić tylko ją.';

  @override
  String get junkFiles => 'Niepotrzebne pliki';

  @override
  String get selectNone => 'Odznacz wszystko';

  @override
  String get noJunk => 'Nie ma czego czyścić — świetnie!';

  @override
  String get catImages => 'Obrazy';

  @override
  String get catVideos => 'Filmy';

  @override
  String get catAudio => 'Audio';

  @override
  String get catDocuments => 'Dokumenty';

  @override
  String get catArchives => 'Archiwa';

  @override
  String get catApks => 'Instalatory (APK)';

  @override
  String get catLarge => 'Duże pliki (100 MB+)';

  @override
  String get catOther => 'Inne pliki';

  @override
  String moveToBinQ(int count) {
    return 'Przenieść $count pliki do kosza?';
  }

  @override
  String get moveToBinNote => 'Można je przywrócić z kosza.';

  @override
  String movedToBinN(int count) {
    return '$count przeniesiono do kosza';
  }

  @override
  String moveFilesQ(int count) {
    return 'Przenieść $count pliki tutaj?';
  }

  @override
  String get move => 'Przenieś';

  @override
  String movedCount(int count) {
    return 'Przeniesiono pliki: $count';
  }

  @override
  String get pcAddressHelp =>
      'Użyj adresu i kodu z Nova Transfer → Połączenie (nie „Inne urządzenia”).';

  @override
  String get pcAddressBad =>
      'Wpisz adres, np. 192.168.1.10 lub 192.168.1.10:48320';

  @override
  String get pcOtherDevicesCode =>
      'Ten adres/kod należy do „Inne urządzenia”. Dla własnego PC użyj Nova Transfer → Połączenie.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get pcFolders => 'Udostępnione foldery PC';

  @override
  String get phoneFiles => 'Udostępnione z telefonu';

  @override
  String get addFolder => 'Dodaj folder';

  @override
  String get remove => 'Usuń';

  @override
  String get refresh => 'Odśwież';

  @override
  String get options => 'Opcje';

  @override
  String get connection => 'Połączenie';

  @override
  String get showQr => 'Pokaż QR parowania';

  @override
  String get qrHint => 'Zeskanuj aplikacją Nova w telefonie';

  @override
  String get phoneConnected => 'Telefon połączony';

  @override
  String get noPhone => 'Brak połączonego telefonu';

  @override
  String get disconnect => 'Rozłącz';

  @override
  String get language => 'Język';

  @override
  String get theme => 'Motyw';

  @override
  String get themeAuto => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get about => 'Informacje';

  @override
  String get version => 'Wersja';

  @override
  String get developer => 'Deweloper';

  @override
  String get buyCoffee => 'Buy me a coffee';

  @override
  String get download => 'Pobierz';

  @override
  String get uploadHere => 'Prześlij do tego folderu';

  @override
  String get emptyList => 'Nic nie udostępniono';

  @override
  String get folderEmpty => 'Folder jest pusty';

  @override
  String get up => 'W górę';

  @override
  String get settings => 'Ustawienia';

  @override
  String get manualCode => 'Lub wpisz ręcznie w telefonie:';

  @override
  String get pairUrl => 'Link parowania';

  @override
  String get phoneUnreachable =>
      'Nie można połączyć się z telefonem — sprawdź udostępnianie i Wi-Fi.';

  @override
  String get shareApk => 'Udostępnij APK przez QR';

  @override
  String get chooseApk => 'Wybierz plik .apk';

  @override
  String get apkQrHint =>
      'Najpierw wybierz APK, potem zeskanuj QR kamerą telefonu — pobierze się do Download/.';

  @override
  String get apkScanNow => 'Zeskanuj kamerą telefonu, aby pobrać to APK.';

  @override
  String get shareThumbs => 'Pokaż miniatury';

  @override
  String get shareThumbsNote =>
      'Podglądy zdjęć/wideo/APK — wolniejsze ładowanie listy.';

  @override
  String get view => 'Podgląd';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get cancel => 'Anuluj';

  @override
  String get back => 'Wstecz';

  @override
  String get close => 'Zamknij';

  @override
  String get delete => 'Usuń';

  @override
  String get managePhone => 'Zarządzaj plikami telefonu';

  @override
  String get managePhoneNote =>
      'Zaznacz i usuń pliki w udostępnionych folderach telefonu';

  @override
  String get sort => 'Sortuj';

  @override
  String get sortName => 'Nazwa';

  @override
  String get sortSize => 'Rozmiar';

  @override
  String get sortDate => 'Data';

  @override
  String get sortAsc => 'Rosnąco';

  @override
  String get sortDesc => 'Malejąco';

  @override
  String get statusReconnecting => 'Ponowne łączenie…';

  @override
  String get statusWaiting => 'Oczekiwanie na telefon';

  @override
  String get connectTitle => 'Połącz telefon';

  @override
  String get connectStep1 => 'Na telefonie otwórz Nova → Udostępnianie PC';

  @override
  String get connectStep2 => 'Stuknij „Skanuj QR” i skieruj aparat na ten kod';

  @override
  String get connectAuto =>
      'Już sparowano? Po prostu otwórz Nova na telefonie — połączy się sam.';

  @override
  String get noNetwork =>
      'Nie znaleziono połączenia sieciowego na tym komputerze.';

  @override
  String get firewallOk => 'Zapora Windows zezwala na Nova Transfer';

  @override
  String get firewallBlocked => 'Zapora Windows blokuje połączenie telefonu.';

  @override
  String get firewallUnknown =>
      'Jeśli telefon nie może się połączyć, zezwól na Nova Transfer w Zaporze Windows.';

  @override
  String get firewallFix => 'Zezwól';

  @override
  String get sameWifiHint =>
      'Telefon i komputer muszą być w tej samej sieci. Sieć Wi-Fi dla gości często blokuje widoczność urządzeń.';

  @override
  String get phoneShareHint =>
      'Nic jeszcze nie udostępniono. Na telefonie: Udostępnianie PC → ⋮ → Udostępnij folder telefonu.';

  @override
  String get phoneReconnecting =>
      'Telefon nie odpowiada — trwa automatyczne ponowne łączenie…';

  @override
  String get phoneReconnectHint =>
      'Otwórz Nova na telefonie w tej samej sieci Wi-Fi — połączy się w ciągu kilku sekund.';

  @override
  String get disconnectNote =>
      'Telefon zapomni ten komputer i trzeba będzie ponownie zeskanować kod QR.';
}

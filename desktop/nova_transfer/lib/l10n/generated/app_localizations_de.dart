// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get pcFolders => 'Freigegebene PC-Ordner';

  @override
  String get phoneFiles => 'Vom Telefon freigegeben';

  @override
  String get addFolder => 'Ordner hinzufügen';

  @override
  String get remove => 'Entfernen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get options => 'Optionen';

  @override
  String get connection => 'Verbindung';

  @override
  String get showQr => 'Kopplungs-QR zeigen';

  @override
  String get qrHint => 'Mit der Nova-App am Telefon scannen';

  @override
  String get phoneConnected => 'Telefon verbunden';

  @override
  String get noPhone => 'Kein Telefon verbunden';

  @override
  String get disconnect => 'Trennen';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Design';

  @override
  String get themeAuto => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get about => 'Über';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Entwickler';

  @override
  String get buyCoffee => 'Buy me a coffee';

  @override
  String get download => 'Herunterladen';

  @override
  String get uploadHere => 'In diesen Ordner hochladen';

  @override
  String get emptyList => 'Nichts freigegeben';

  @override
  String get folderEmpty => 'Ordner ist leer';

  @override
  String get up => 'Aufwärts';

  @override
  String get settings => 'Einstellungen';

  @override
  String get manualCode => 'Oder am Telefon manuell eingeben:';

  @override
  String get pairUrl => 'Kopplungslink';

  @override
  String get phoneUnreachable =>
      'Telefon nicht erreichbar — ist Freigabe aktiv und gleiches WLAN?';

  @override
  String get shareApk => 'APK per QR teilen';

  @override
  String get chooseApk => '.apk-Datei wählen';

  @override
  String get apkQrHint =>
      'Zuerst APK wählen, dann QR mit der Handykamera scannen — Download in Download/.';

  @override
  String get apkScanNow => 'Mit der Handykamera scannen, um das APK zu laden.';

  @override
  String get shareThumbs => 'Miniaturen anzeigen';

  @override
  String get shareThumbsNote =>
      'Bild-/Video-/APK-Vorschauen — langsamere Listenladung.';
}

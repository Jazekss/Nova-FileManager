// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get pcFolders => 'Delade PC-mappar';

  @override
  String get phoneFiles => 'Delat från telefon';

  @override
  String get addFolder => 'Lägg till mapp';

  @override
  String get remove => 'Ta bort';

  @override
  String get refresh => 'Uppdatera';

  @override
  String get options => 'Alternativ';

  @override
  String get connection => 'Anslutning';

  @override
  String get showQr => 'Visa parkopplings-QR';

  @override
  String get qrHint => 'Skanna med Nova-appen i telefonen';

  @override
  String get phoneConnected => 'Telefon ansluten';

  @override
  String get noPhone => 'Ingen telefon ansluten';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get language => 'Språk';

  @override
  String get theme => 'Tema';

  @override
  String get themeAuto => 'System';

  @override
  String get themeLight => 'Ljust';

  @override
  String get themeDark => 'Mörkt';

  @override
  String get about => 'Om';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Utvecklare';

  @override
  String get buyCoffee => 'Buy me a coffee';

  @override
  String get download => 'Ladda ner';

  @override
  String get uploadHere => 'Ladda upp till den här mappen';

  @override
  String get emptyList => 'Inget delat ännu';

  @override
  String get folderEmpty => 'Mappen är tom';

  @override
  String get up => 'Upp';

  @override
  String get settings => 'Inställningar';

  @override
  String get manualCode => 'Eller ange manuellt i telefonen:';

  @override
  String get pairUrl => 'Kopplingslänk';

  @override
  String get phoneUnreachable =>
      'Kan inte nå telefonen — kontrollera delning och Wi-Fi.';

  @override
  String get shareApk => 'Dela APK via QR';

  @override
  String get chooseApk => 'Välj .apk-fil';

  @override
  String get apkQrHint =>
      'Välj APK först, skanna sedan QR med telefonkameran — laddas ner till Download/.';

  @override
  String get apkScanNow =>
      'Skanna med telefonkameran för att ladda ner denna APK.';

  @override
  String get shareThumbs => 'Visa miniatyrer';

  @override
  String get shareThumbsNote =>
      'Bild-/video-/APK-förhandsvisningar — långsammare laddning.';

  @override
  String get view => 'Visa';

  @override
  String get rename => 'Byt namn';

  @override
  String get cancel => 'Avbryt';

  @override
  String get back => 'Tillbaka';

  @override
  String get close => 'Stäng';

  @override
  String get delete => 'Radera';

  @override
  String get managePhone => 'Hantera filer på telefonen';

  @override
  String get managePhoneNote =>
      'Markera och radera filer i telefonens delade mappar';

  @override
  String get sort => 'Sortera';

  @override
  String get sortName => 'Namn';

  @override
  String get sortSize => 'Storlek';

  @override
  String get sortDate => 'Datum';

  @override
  String get sortAsc => 'Stigande';

  @override
  String get sortDesc => 'Fallande';

  @override
  String get statusReconnecting => 'Återansluter…';

  @override
  String get statusWaiting => 'Väntar på telefon';

  @override
  String get connectTitle => 'Anslut telefonen';

  @override
  String get connectStep1 => 'Öppna Nova → PC-delning på telefonen';

  @override
  String get connectStep2 => 'Tryck på ”Skanna QR” och rikta kameran mot koden';

  @override
  String get connectAuto =>
      'Redan parkopplad? Öppna bara Nova på telefonen — den återansluter själv.';

  @override
  String get noNetwork => 'Ingen nätverksanslutning hittades på datorn.';

  @override
  String get firewallOk => 'Windows-brandväggen tillåter Nova Transfer';

  @override
  String get firewallBlocked =>
      'Windows-brandväggen hindrar telefonen från att ansluta.';

  @override
  String get firewallUnknown =>
      'Om telefonen inte kan ansluta, tillåt Nova Transfer i Windows-brandväggen.';

  @override
  String get firewallFix => 'Tillåt';

  @override
  String get sameWifiHint =>
      'Telefon och dator måste vara på samma nätverk. Gäst-Wi-Fi hindrar ofta enheter från att se varandra.';

  @override
  String get phoneShareHint =>
      'Inget delat än. På telefonen: PC-delning → ⋮ → Dela telefonmapp.';

  @override
  String get phoneReconnecting =>
      'Telefonen svarar inte — återansluter automatiskt…';

  @override
  String get phoneReconnectHint =>
      'Öppna Nova på telefonen på samma Wi-Fi — den återansluter inom några sekunder.';

  @override
  String get disconnectNote =>
      'Telefonen glömmer datorn och måste skanna QR-koden igen.';
}

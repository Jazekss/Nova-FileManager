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

  @override
  String get otherDevices => 'Andra enheter';

  @override
  String get otherDevicesHint =>
      'Koppla ihop dina andra datorer och telefoner för att flytta filer snabbt. Nova måste vara öppen på båda enheterna; parkopplade enheter återansluter själva.';

  @override
  String get thisDevice => 'Den här enheten';

  @override
  String get deviceName => 'Enhetsnamn';

  @override
  String get devices => 'Enheter';

  @override
  String get addDevice => 'Lägg till enhet';

  @override
  String get pairCode => 'Kod';

  @override
  String get deviceAddress => 'Adress';

  @override
  String get pairCodeWrong =>
      'Fel eller utgången kod — kontrollera och försök igen.';

  @override
  String get deviceUnreachable =>
      'Når inte enheten. Är Nova öppen där och på samma Wi-Fi?';

  @override
  String get noDevices => 'Inga enheter än';

  @override
  String get online => 'Ansluten';

  @override
  String get offline => 'Ej ansluten — öppna Nova på den';

  @override
  String get deviceRejected => 'Enheten har tagit bort parkopplingen';

  @override
  String get removeDevice => 'Ta bort enhet';

  @override
  String get removeDeviceNote =>
      'Båda enheterna glömmer varandra. För att koppla ihop dem igen behövs en ny kod.';

  @override
  String get shareWith => 'Dela med';

  @override
  String get shareAll => 'Alla parkopplade enheter';

  @override
  String get deviceOffline =>
      'Enheten svarar inte — öppna Nova på den på samma Wi-Fi.';

  @override
  String pairedWith(String name) {
    return 'Ihopkopplad med $name';
  }

  @override
  String receivedFrom(String name, String file) {
    return 'Mottaget från $name: $file';
  }

  @override
  String get myPhone => 'Min telefon';

  @override
  String get addByAddress => 'Lägg till via adress';

  @override
  String get pairOtherHint =>
      'Telefon: Nova → Andra enheter → Lägg till enhet → skanna QR-koden. Annan dator: Andra enheter → Lägg till via adress och ange adress och kod.';

  @override
  String get shareOnlyPhone => 'Bara min telefon';

  @override
  String get shareSelected => 'Bara enheterna som valts nedan';

  @override
  String get shareNote => 'Din telefon ser alltid alla delade mappar.';

  @override
  String get scopePhone => 'Telefon';

  @override
  String get scopeAll => 'Alla';

  @override
  String scopeSome(int count) {
    return '+$count enheter';
  }

  @override
  String get chooseFolder => 'Välj mapp';

  @override
  String get add => 'Lägg till';

  @override
  String get save => 'Spara';

  @override
  String get upload => 'Ladda upp';

  @override
  String get manualPair => 'Ingen kamera? Skriv på telefonen';

  @override
  String get copy => 'Kopiera';

  @override
  String get copied => 'Kopierat';

  @override
  String get codeOnce => 'Koden fungerar en gång och byts efter användning.';

  @override
  String get pickTab => 'Dubbelklicka på en flik för att byta namn';
}

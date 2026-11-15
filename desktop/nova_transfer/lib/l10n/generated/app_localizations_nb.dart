// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get pcFolders => 'Delte PC-mapper';

  @override
  String get phoneFiles => 'Delt fra telefon';

  @override
  String get addFolder => 'Legg til mappe';

  @override
  String get remove => 'Fjern';

  @override
  String get refresh => 'Oppdater';

  @override
  String get options => 'Alternativer';

  @override
  String get connection => 'Tilkobling';

  @override
  String get showQr => 'Vis sammenkoblings-QR';

  @override
  String get qrHint => 'Skann med Nova-appen på telefonen';

  @override
  String get phoneConnected => 'Telefon tilkoblet';

  @override
  String get noPhone => 'Ingen telefon tilkoblet';

  @override
  String get disconnect => 'Koble fra';

  @override
  String get language => 'Språk';

  @override
  String get theme => 'Tema';

  @override
  String get themeAuto => 'System';

  @override
  String get themeLight => 'Lys';

  @override
  String get themeDark => 'Mørk';

  @override
  String get about => 'Om';

  @override
  String get version => 'Versjon';

  @override
  String get developer => 'Utvikler';

  @override
  String get buyCoffee => 'Buy me a coffee';

  @override
  String get download => 'Last ned';

  @override
  String get uploadHere => 'Last opp til denne mappen';

  @override
  String get emptyList => 'Ingenting delt ennå';

  @override
  String get folderEmpty => 'Mappen er tom';

  @override
  String get up => 'Opp';

  @override
  String get settings => 'Innstillinger';

  @override
  String get manualCode => 'Eller skriv inn på telefonen:';

  @override
  String get pairUrl => 'Koblingslenke';

  @override
  String get phoneUnreachable =>
      'Får ikke kontakt med telefonen — sjekk deling og Wi-Fi.';

  @override
  String get shareApk => 'Del APK via QR';

  @override
  String get chooseApk => 'Velg .apk-fil';

  @override
  String get apkQrHint =>
      'Velg APK først, skann deretter QR med telefonkameraet — lastes ned til Download/.';

  @override
  String get apkScanNow =>
      'Skann med telefonkameraet for å laste ned denne APK-en.';

  @override
  String get shareThumbs => 'Vis miniatyrer';

  @override
  String get shareThumbsNote =>
      'Bilde-/video-/APK-forhåndsvisninger — tregere innlasting.';

  @override
  String get view => 'Vis';

  @override
  String get rename => 'Gi nytt navn';

  @override
  String get cancel => 'Avbryt';

  @override
  String get back => 'Tilbake';

  @override
  String get close => 'Lukk';

  @override
  String get delete => 'Slett';

  @override
  String get managePhone => 'Administrer filer på telefonen';

  @override
  String get managePhoneNote => 'Merk og slett filer i telefonens delte mapper';

  @override
  String get sort => 'Sorter';

  @override
  String get sortName => 'Navn';

  @override
  String get sortSize => 'Størrelse';

  @override
  String get sortDate => 'Dato';

  @override
  String get sortAsc => 'Stigende';

  @override
  String get sortDesc => 'Synkende';

  @override
  String get statusReconnecting => 'Kobler til på nytt…';

  @override
  String get statusWaiting => 'Venter på telefon';

  @override
  String get connectTitle => 'Koble til telefonen';

  @override
  String get connectStep1 => 'Åpne Nova → PC-deling på telefonen';

  @override
  String get connectStep2 => 'Trykk «Skann QR» og pek kameraet mot denne koden';

  @override
  String get connectAuto =>
      'Allerede paret? Bare åpne Nova på telefonen — den kobler til selv.';

  @override
  String get noNetwork => 'Fant ingen nettverkstilkobling på denne PC-en.';

  @override
  String get firewallOk => 'Windows-brannmuren tillater Nova Transfer';

  @override
  String get firewallBlocked =>
      'Windows-brannmuren hindrer telefonen i å koble til.';

  @override
  String get firewallUnknown =>
      'Hvis telefonen ikke kobler til, tillat Nova Transfer i Windows-brannmuren.';

  @override
  String get firewallFix => 'Tillat';

  @override
  String get sameWifiHint =>
      'Telefon og PC må være på samme nettverk. Gjeste-Wi-Fi hindrer ofte enheter i å se hverandre.';

  @override
  String get phoneShareHint =>
      'Ingenting delt ennå. På telefonen: PC-deling → ⋮ → Del telefonmappe.';

  @override
  String get phoneReconnecting =>
      'Telefonen svarer ikke — kobler til automatisk…';

  @override
  String get phoneReconnectHint =>
      'Åpne Nova på telefonen på samme Wi-Fi — den kobler til igjen i løpet av sekunder.';

  @override
  String get disconnectNote =>
      'Telefonen glemmer denne PC-en og må skanne QR-koden på nytt.';

  @override
  String get otherDevices => 'Andre enheter';

  @override
  String get otherDevicesHint =>
      'Koble sammen andre datamaskiner og telefoner for å flytte filer raskt. Nova må være åpen på begge enhetene; parede enheter kobler til igjen selv.';

  @override
  String get thisDevice => 'Denne enheten';

  @override
  String get deviceName => 'Enhetsnavn';

  @override
  String get devices => 'Enheter';

  @override
  String get addDevice => 'Legg til enhet';

  @override
  String get pairCode => 'Kode';

  @override
  String get deviceAddress => 'Adresse';

  @override
  String get pairCodeWrong => 'Feil eller utløpt kode — sjekk og prøv igjen.';

  @override
  String get deviceUnreachable =>
      'Får ikke kontakt med enheten. Er Nova åpen der og på samme Wi-Fi?';

  @override
  String get noDevices => 'Ingen enheter ennå';

  @override
  String get online => 'Tilkoblet';

  @override
  String get offline => 'Frakoblet — åpne Nova på den';

  @override
  String get deviceRejected => 'Denne enheten fjernet paringen';

  @override
  String get removeDevice => 'Fjern enhet';

  @override
  String get removeDeviceNote =>
      'Begge enhetene glemmer hverandre. For å koble dem igjen trengs en ny kode.';

  @override
  String get shareWith => 'Del med';

  @override
  String get shareAll => 'Alle parede enheter';

  @override
  String get deviceOffline =>
      'Enheten svarer ikke — åpne Nova på den på samme Wi-Fi.';

  @override
  String pairedWith(String name) {
    return 'Koblet til $name';
  }

  @override
  String receivedFrom(String name, String file) {
    return 'Mottatt fra $name: $file';
  }

  @override
  String get myPhone => 'Min telefon';

  @override
  String get addByAddress => 'Legg til med adresse';

  @override
  String get pairOtherHint =>
      'Telefon: Nova → Andre enheter → Legg til enhet → skann denne QR-koden. Annen PC: Andre enheter → Legg til med adresse, og skriv inn adresse og kode.';

  @override
  String get shareOnlyPhone => 'Bare min telefon';

  @override
  String get shareSelected => 'Bare enhetene valgt nedenfor';

  @override
  String get shareNote => 'Telefonen din ser alltid alle delte mapper.';

  @override
  String get scopePhone => 'Telefon';

  @override
  String get scopeAll => 'Alle';

  @override
  String scopeSome(int count) {
    return '+$count enheter';
  }

  @override
  String get chooseFolder => 'Velg mappe';

  @override
  String get add => 'Legg til';

  @override
  String get save => 'Lagre';

  @override
  String get upload => 'Last opp';

  @override
  String get manualPair => 'Ikke kamera? Skriv på telefonen';

  @override
  String get copy => 'Kopier';

  @override
  String get copied => 'Kopiert';

  @override
  String get codeOnce => 'Koden virker én gang og endres etter bruk.';

  @override
  String get pickTab => 'Dobbeltklikk en fane for å gi nytt navn';
}

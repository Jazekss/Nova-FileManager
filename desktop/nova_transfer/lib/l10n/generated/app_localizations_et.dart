// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get pcFolders => 'PC jagatud kaustad';

  @override
  String get phoneFiles => 'Jagatud telefonist';

  @override
  String get addFolder => 'Lisa kaust';

  @override
  String get remove => 'Eemalda';

  @override
  String get refresh => 'Värskenda';

  @override
  String get options => 'Suvandid';

  @override
  String get connection => 'Ühendus';

  @override
  String get showQr => 'Näita sidumise QR-i';

  @override
  String get qrHint => 'Skanni Nova rakendusega telefonis';

  @override
  String get phoneConnected => 'Telefon ühendatud';

  @override
  String get noPhone => 'Telefon pole ühendatud';

  @override
  String get disconnect => 'Katkesta';

  @override
  String get language => 'Keel';

  @override
  String get theme => 'Teema';

  @override
  String get themeAuto => 'Süsteem';

  @override
  String get themeLight => 'Hele';

  @override
  String get themeDark => 'Tume';

  @override
  String get about => 'Info';

  @override
  String get version => 'Versioon';

  @override
  String get developer => 'Arendaja';

  @override
  String get buyCoffee => 'Buy me a coffee';

  @override
  String get download => 'Laadi alla';

  @override
  String get uploadHere => 'Laadi sellesse kausta';

  @override
  String get emptyList => 'Pole midagi jagatud';

  @override
  String get folderEmpty => 'Kaust on tühi';

  @override
  String get up => 'Üles';

  @override
  String get settings => 'Seaded';

  @override
  String get manualCode => 'Või sisesta telefonis käsitsi:';

  @override
  String get pairUrl => 'Sidumislink';

  @override
  String get phoneUnreachable =>
      'Telefoni ei jõua — kontrolli jagamist ja Wi-Fi ühendust.';

  @override
  String get shareApk => 'APK QR kaudu';

  @override
  String get chooseApk => 'Vali .apk fail';

  @override
  String get apkQrHint =>
      'Vali esmalt APK, siis skanni QR telefoni kaameraga — laeb alla Download/.';

  @override
  String get apkScanNow =>
      'Skanni telefoni kaameraga, et see APK alla laadida.';

  @override
  String get shareThumbs => 'Näita pisipilte';

  @override
  String get shareThumbsNote =>
      'Pildi/video/APK eelvaated — aeglasem laadimine.';

  @override
  String get view => 'Vaata';

  @override
  String get rename => 'Nimeta ümber';

  @override
  String get cancel => 'Tühista';

  @override
  String get back => 'Tagasi';

  @override
  String get close => 'Sulge';

  @override
  String get delete => 'Kustuta';

  @override
  String get managePhone => 'Halda telefoni faile';

  @override
  String get managePhoneNote =>
      'Vali ja kustuta faile telefoni jagatud kaustades';

  @override
  String get sort => 'Sorteeri';

  @override
  String get sortName => 'Nimi';

  @override
  String get sortSize => 'Suurus';

  @override
  String get sortDate => 'Kuupäev';

  @override
  String get sortAsc => 'Kasvav';

  @override
  String get sortDesc => 'Kahanev';

  @override
  String get statusReconnecting => 'Ühendan uuesti…';

  @override
  String get statusWaiting => 'Ootan telefoni';

  @override
  String get connectTitle => 'Ühenda telefon';

  @override
  String get connectStep1 => 'Ava telefonis Nova → PC jagamine';

  @override
  String get connectStep2 =>
      'Vajuta „Skanni QR“ ja suuna kaamera sellele koodile';

  @override
  String get connectAuto =>
      'Juba seotud? Ava lihtsalt telefonis Nova — ühendus taastub ise.';

  @override
  String get noNetwork => 'Selles arvutis ei leitud võrguühendust.';

  @override
  String get firewallOk => 'Windowsi tulemüür lubab Nova Transferi';

  @override
  String get firewallBlocked => 'Windowsi tulemüür ei lase telefonil ühenduda.';

  @override
  String get firewallUnknown =>
      'Kui telefon ei saa ühendust, luba Nova Transfer Windowsi tulemüüris.';

  @override
  String get firewallFix => 'Luba';

  @override
  String get sameWifiHint =>
      'Telefon ja arvuti peavad olema samas võrgus. Külalis-Wi-Fi ei lase seadmetel sageli üksteist näha.';

  @override
  String get phoneShareHint =>
      'Midagi pole veel jagatud. Telefonis: PC jagamine → ⋮ → Jaga telefoni kausta.';

  @override
  String get phoneReconnecting =>
      'Telefon ei vasta — ühendan automaatselt uuesti…';

  @override
  String get phoneReconnectHint =>
      'Ava telefonis Nova samas Wi-Fi võrgus — ühendus taastub mõne sekundiga.';

  @override
  String get disconnectNote =>
      'Telefon unustab selle arvuti ja QR-kood tuleb uuesti skannida.';
}

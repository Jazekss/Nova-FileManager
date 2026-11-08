// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get pcFolders => 'Koplietotās PC mapes';

  @override
  String get phoneFiles => 'Koplietots no telefona';

  @override
  String get addFolder => 'Pievienot mapi';

  @override
  String get remove => 'Noņemt';

  @override
  String get refresh => 'Atsvaidzināt';

  @override
  String get options => 'Opcijas';

  @override
  String get connection => 'Savienojums';

  @override
  String get showQr => 'Rādīt pārošanas QR';

  @override
  String get qrHint => 'Skenē šo kodu ar Nova lietotni telefonā';

  @override
  String get phoneConnected => 'Telefons savienots';

  @override
  String get noPhone => 'Telefons nav savienots';

  @override
  String get disconnect => 'Atvienot';

  @override
  String get language => 'Valoda';

  @override
  String get theme => 'Tēma';

  @override
  String get themeAuto => 'Sistēmas';

  @override
  String get themeLight => 'Gaišā';

  @override
  String get themeDark => 'Tumšā';

  @override
  String get about => 'Par';

  @override
  String get version => 'Versija';

  @override
  String get developer => 'Izstrādātājs';

  @override
  String get buyCoffee => 'Buy me a coffee';

  @override
  String get download => 'Lejupielādēt';

  @override
  String get uploadHere => 'Augšupielādēt šajā mapē';

  @override
  String get emptyList => 'Vēl nekas nav koplietots';

  @override
  String get folderEmpty => 'Mape ir tukša';

  @override
  String get up => 'Augšup';

  @override
  String get settings => 'Iestatījumi';

  @override
  String get manualCode => 'Vai telefonā ievadi manuāli:';

  @override
  String get pairUrl => 'Pārošanas saite';

  @override
  String get phoneUnreachable =>
      'Nevar sasniegt telefonu — pārbaudi, vai tas koplieto un ir tajā pašā Wi-Fi.';

  @override
  String get shareApk => 'APK ar QR';

  @override
  String get chooseApk => 'Izvēlies .apk failu';

  @override
  String get apkQrHint =>
      'Vispirms izvēlies APK, tad skenē QR ar telefona kameru — fails ielādējas Download/.';

  @override
  String get apkScanNow =>
      'Skenē ar telefona kameru, lai lejupielādētu šo APK.';

  @override
  String get shareThumbs => 'Rādīt sīktēļus';

  @override
  String get shareThumbsNote =>
      'Attēlu/video/APK priekšskatījumi — lēnāka ielāde.';

  @override
  String get view => 'Skatīt';

  @override
  String get rename => 'Pārdēvēt';

  @override
  String get cancel => 'Atcelt';

  @override
  String get back => 'Atpakaļ';

  @override
  String get close => 'Aizvērt';

  @override
  String get delete => 'Dzēst';

  @override
  String get managePhone => 'Pārvaldīt failus telefonā';

  @override
  String get managePhoneNote =>
      'Atzīmēt un dzēst failus telefona koplietotajās mapēs';

  @override
  String get sort => 'Kārtot';

  @override
  String get sortName => 'Nosaukums';

  @override
  String get sortSize => 'Izmērs';

  @override
  String get sortDate => 'Datums';

  @override
  String get sortAsc => 'Augoši';

  @override
  String get sortDesc => 'Dilstoši';

  @override
  String get statusReconnecting => 'Atjauno savienojumu…';

  @override
  String get statusWaiting => 'Gaida telefonu';

  @override
  String get connectTitle => 'Savieno telefonu';

  @override
  String get connectStep1 => 'Telefonā atver Nova → PC koplietošana';

  @override
  String get connectStep2 => 'Spied “Skenēt QR” un notēmē kameru uz šo kodu';

  @override
  String get connectAuto =>
      'Jau savienots iepriekš? Vienkārši atver Nova telefonā — savienojums atjaunosies pats.';

  @override
  String get noNetwork => 'Šim datoram nav atrasts tīkla savienojums.';

  @override
  String get firewallOk => 'Windows ugunsmūris atļauj Nova Transfer';

  @override
  String get firewallBlocked =>
      'Windows ugunsmūris neļauj telefonam pieslēgties.';

  @override
  String get firewallUnknown =>
      'Ja telefons nevar pieslēgties, atļauj Nova Transfer Windows ugunsmūrī.';

  @override
  String get firewallFix => 'Atļaut';

  @override
  String get sameWifiHint =>
      'Telefonam un datoram jābūt vienā tīklā. Viesu Wi-Fi bieži neļauj ierīcēm vienai otru redzēt.';

  @override
  String get phoneShareHint =>
      'Vēl nekas nav koplietots. Telefonā: PC koplietošana → ⋮ → Koplietot telefona mapi.';

  @override
  String get phoneReconnecting =>
      'Telefons neatbild — savienojums tiek atjaunots automātiski…';

  @override
  String get phoneReconnectHint =>
      'Atver Nova telefonā un esi tajā pašā Wi-Fi — savienojums atjaunosies dažu sekunžu laikā.';

  @override
  String get disconnectNote =>
      'Telefons aizmirsīs šo datoru, un QR kods būs jāskenē vēlreiz.';
}

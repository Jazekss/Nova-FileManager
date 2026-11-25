// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get appTitle => 'Nova File Manager';

  @override
  String get navHome => 'Sākums';

  @override
  String get navFiles => 'Faili';

  @override
  String get navSearch => 'Meklēt';

  @override
  String get permTitle => 'Nepieciešama piekļuve krātuvei';

  @override
  String get permBody =>
      'Nova ir nepieciešama \"Visu failu piekļuve\", lai pārlūkotu, kopētu un pārvietotu failus iekšējā atmiņā un SD kartē.\n\nPat ar to Android bloķē piekļuvi citu lietotņu Android/data mapēm, un īstus sistēmas failus atver tikai root.';

  @override
  String get permGrant => 'Piešķirt piekļuvi';

  @override
  String get permContinueLimited => 'Turpināt ar ierobežotu piekļuvi';

  @override
  String get settings => 'Iestatījumi';

  @override
  String get appearance => 'Izskats';

  @override
  String get themeSystem => 'Sistēma';

  @override
  String get themeLight => 'Gaišs';

  @override
  String get themeDark => 'Tumšs';

  @override
  String get sizeUnits => 'Izmēru vienības';

  @override
  String get unitAuto => 'Auto';

  @override
  String get showHidden => 'Rādīt slēptos failus';

  @override
  String get showHiddenSubtitle => 'Faili un mapes, kas sākas ar punktu';

  @override
  String get language => 'Valoda';

  @override
  String get languageSystem => 'Sistēmas valoda';

  @override
  String get about => 'Par lietotni';

  @override
  String versionLabel(Object version) {
    return 'Versija $version';
  }

  @override
  String get developerLine => 'Izstrādāja JKdizains — jkdizains.lv';

  @override
  String get developerThanks =>
      'Izstrādāts vienpersoniski. Paldies par atbalstu!';

  @override
  String get coffeeButton => 'Uzsauc man kafiju';

  @override
  String get storage => 'Krātuve';

  @override
  String get internalStorage => 'Iekšējā atmiņa';

  @override
  String get sdCard => 'SD karte';

  @override
  String get save => 'Saglabāt';

  @override
  String get saved => 'Saglabāts';

  @override
  String get fileTooLarge => 'Fails ir pārāk liels rediģēšanai';

  @override
  String get change => 'Mainīt';

  @override
  String get renameExtWarnTitle => 'Mainīt paplašinājumu?';

  @override
  String renameExtWarnBody(String oldExt, String newExt) {
    return 'Mainot $oldExt uz $newExt, fails citās lietotnēs var vairs neatvērties.';
  }

  @override
  String get shareWifi => 'Koplietot caur Wi-Fi';

  @override
  String get wifiTransfer => 'Wi-Fi pārsūtīšana';

  @override
  String get wifiCardSubtitle => 'Sūtīt un saņemt failus no datora';

  @override
  String get wifiOpenHint => 'Atver šo adresi datorā (tajā pašā Wi-Fi tīklā)';

  @override
  String get wifiSharedFiles => 'Koplietotie faili';

  @override
  String wifiUploadNote(String path) {
    return 'Augšupielādes saglabājas mapē $path';
  }

  @override
  String wifiReceived(String name) {
    return 'Saņemts: $name';
  }

  @override
  String get wifiStop => 'Apturēt koplietošanu';

  @override
  String get vault => 'Seifs';

  @override
  String get vaultCardSubtitle => 'Šifrēti privāti faili';

  @override
  String get vaultUnlockReason => 'Atbloķē seifu';

  @override
  String get vaultSetPin => 'Iestati PIN (4–8 cipari)';

  @override
  String get vaultEnterPin => 'Ievadi seifa PIN';

  @override
  String get vaultUnlock => 'Atbloķēt';

  @override
  String get vaultUseBiometric => 'Izmantot biometriju';

  @override
  String get vaultPinTooShort => 'PIN jābūt vismaz 4 cipariem';

  @override
  String get vaultWrongPin => 'Nepareizs PIN';

  @override
  String get vaultEmpty => 'Seifs ir tukšs';

  @override
  String get vaultEmptyHint =>
      'Pārvieto failus šeit: faila konteksta izvēlne → Pārvietot uz seifu';

  @override
  String get vaultExport => 'Izvest no seifa';

  @override
  String get movedToVault => 'Pārvietots uz seifu';

  @override
  String get exported => 'Izvests';

  @override
  String get moveToVault => 'Pārvietot uz seifu';

  @override
  String get convertTo => 'Konvertēt uz';

  @override
  String get converted => 'Konvertēts';

  @override
  String get convertFailed => 'Failu neizdevās konvertēt';

  @override
  String get download => 'Lejupielādēt';

  @override
  String get downloaded => 'Lejupielādēts';

  @override
  String get upload => 'Augšupielādēt';

  @override
  String get uploaded => 'Augšupielādēts';

  @override
  String get signOut => 'Izrakstīties';

  @override
  String get driveIntro =>
      'Piesakies, lai pārlūkotu un pārvaldītu savus Google Drive failus.';

  @override
  String get driveScopeNote =>
      'Nova lieto mazāko Drive atļauju: tā redz tikai failus, ko izveidojusi pati lietotne vai atvērusi caur to.';

  @override
  String get driveSignIn => 'Pierakstīties ar Google';

  @override
  String get driveSignInFailed => 'Pierakstīšanās atcelta vai neizdevās';

  @override
  String get driveTrashQ => 'Pārvietot uz Drive miskasti?';

  @override
  String get comingSoon => 'Drīzumā';

  @override
  String get sharedToPc => 'Koplietots uz PC';

  @override
  String get sharedFromPc => 'Koplietots no datora';

  @override
  String get pairWithPc => 'Savieno ar datoru';

  @override
  String get pcPairHint =>
      'Atver Nova File Manager Desktop datorā un savienojuma izvēlnē parādi pārošanas QR.';

  @override
  String get invalidPairLink => 'Nederīga pārošanas saite';

  @override
  String get uploadHere => 'Augšupielādēt šeit';

  @override
  String get sharePhoneFolder => 'Koplietot telefona mapi';

  @override
  String get pairFailed => 'Savienošana neizdevās';

  @override
  String get pair => 'Savienot';

  @override
  String get disconnect => 'Atvienot';

  @override
  String get scanQr => 'Skenēt QR';

  @override
  String get pcShare => 'PC koplietošana';

  @override
  String get enterManually => 'Ievadīt manuāli';

  @override
  String get enterPairLink => 'Ievadi pārošanas saiti';

  @override
  String get refresh => 'Atsvaidzināt';

  @override
  String get pressAgainToExit => 'Nospied atpakaļ vēlreiz, lai izietu';

  @override
  String get shareThumbs => 'Sīktēļi PC koplietošanā';

  @override
  String get shareThumbsNote =>
      'Rāda attēlu/video/APK priekšskatījumus pārlūkojot PC mapes — ielāde kļūst lēnāka.';

  @override
  String get noStorage => 'Krātuves nav atrastas';

  @override
  String get notAvailable => 'Nav pieejama';

  @override
  String get noData => 'Nav datu';

  @override
  String freeOf(Object free, Object total) {
    return '$free brīvi no $total';
  }

  @override
  String get installedApps => 'Instalētās lietotnes';

  @override
  String get recycleBin => 'Miskaste';

  @override
  String binItems(Object count, Object size) {
    return '$count vienumi · $size';
  }

  @override
  String get quickAccess => 'Ātrā piekļuve';

  @override
  String get androidLimits => 'Android ierobežojumi';

  @override
  String get limitData =>
      'Citu lietotņu Android/data un Android/obb mapes Android 11+ ir bloķētas pat ar pilnu failu piekļuvi.';

  @override
  String get limitSystem =>
      'Īsti sistēmas faili (/system, /data) prasa root — šī lietotne root neizmanto.';

  @override
  String get limitSd =>
      'Dažās ierīcēs SD kartes rakstīšanai var būt nepieciešama piekļuve caur sistēmas izvēlni.';

  @override
  String get fileManager => 'Failu pārvaldnieks';

  @override
  String get newFolder => 'Jauna mape';

  @override
  String get folderName => 'Mapes nosaukums';

  @override
  String get select => 'Atlasīt';

  @override
  String get selectAll => 'Atlasīt visu';

  @override
  String get openWith => 'Atvērt ar';

  @override
  String get rename => 'Pārsaukt';

  @override
  String get copyTo => 'Kopēt uz...';

  @override
  String get moveTo => 'Pārvietot uz...';

  @override
  String get createZip => 'Izveidot ZIP';

  @override
  String get properties => 'Īpašības';

  @override
  String get delete => 'Dzēst';

  @override
  String get view => 'Skats';

  @override
  String get viewDetailed => 'Detalizēts saraksts';

  @override
  String get viewSmall => 'Mazas ikonas';

  @override
  String get viewLarge => 'Lielas ikonas';

  @override
  String get sort => 'Kārtot';

  @override
  String get sortName => 'Nosaukums';

  @override
  String get sortSize => 'Izmērs';

  @override
  String get sortDate => 'Datums';

  @override
  String selectedCount(Object count) {
    return 'Atlasīti: $count';
  }

  @override
  String deleteTitle(Object count) {
    return 'Dzēst $count vienumu(s)?';
  }

  @override
  String get deleteBody =>
      'Pārvieto uz miskasti, lai vēlāk varētu atjaunot, vai dzēs uz visiem laikiem.';

  @override
  String get cancel => 'Atcelt';

  @override
  String get ok => 'Labi';

  @override
  String get close => 'Aizvērt';

  @override
  String get deletePermanently => 'Dzēst uz visiem laikiem';

  @override
  String get toRecycleBin => 'Uz miskasti';

  @override
  String get movedToBin => 'Pārvietots uz miskasti';

  @override
  String get deleted => 'Dzēsts';

  @override
  String get moved => 'Pārvietots';

  @override
  String get copied => 'Nokopēts';

  @override
  String get renamed => 'Pārsaukts';

  @override
  String get folderCreated => 'Mape izveidota';

  @override
  String get zipCreated => 'ZIP izveidots';

  @override
  String get noAppToOpen => 'Nav atrasta lietotne šī faila atvēršanai';

  @override
  String get retry => 'Mēģināt vēlreiz';

  @override
  String get emptyFolder => 'Šī mape ir tukša';

  @override
  String get sameFolderError => 'Mērķis ir pašreizējā mape';

  @override
  String get permissionDeniedError =>
      'Piekļuve liegta. Dažas vietas (piem., Android/data vai sistēmas mapes) Android ir ierobežotas un prasa īpašu piekļuvi.';

  @override
  String get typeFolder => 'Mape';

  @override
  String typeFile(Object ext) {
    return 'Fails (.$ext)';
  }

  @override
  String get propType => 'Tips';

  @override
  String get propPath => 'Ceļš';

  @override
  String get propSize => 'Izmērs';

  @override
  String get propModified => 'Mainīts';

  @override
  String get propCreated => 'Izveidots';

  @override
  String get chooseDestination => 'Izvēlies mērķi';

  @override
  String get up => 'Uz augšu';

  @override
  String get noSubfolders => 'Nav apakšmapju';

  @override
  String get selectHere => 'Izvēlēties šeit';

  @override
  String get cannotOpenFolder => 'Nevar atvērt šo mapi';

  @override
  String get fileNamePattern => 'Faila nosaukums vai veids';

  @override
  String get searchHint => 'piem. *.pdf vai report';

  @override
  String get wholeStorage => 'Visa krātuve';

  @override
  String get searchWholeStorage => 'Meklēt visā krātuvē';

  @override
  String get fromDate => 'No datuma';

  @override
  String get toDate => 'Līdz datumam';

  @override
  String get clearDates => 'Notīrīt datumus';

  @override
  String get search => 'Meklēt';

  @override
  String scannedCount(Object count) {
    return 'Pārbaudīti $count vienumi…';
  }

  @override
  String get noResults => 'Vēl nav rezultātu';

  @override
  String get emptyBinQ => 'Iztukšot miskasti?';

  @override
  String get emptyBinBody => 'Visi vienumi tiks neatgriezeniski dzēsti.';

  @override
  String get emptyBin => 'Iztukšot';

  @override
  String get binEmptied => 'Miskaste iztukšota';

  @override
  String get binEmpty => 'Miskaste ir tukša';

  @override
  String get restore => 'Atjaunot';

  @override
  String get restored => 'Atjaunots';

  @override
  String get deleteForeverQ => 'Dzēst uz visiem laikiem?';

  @override
  String get extractAll => 'Izpakot visu';

  @override
  String get archiveEmpty => 'Arhīvs ir tukšs';

  @override
  String archiveReadError(Object error) {
    return 'Neizdevās nolasīt arhīvu: $error';
  }

  @override
  String extractedTo(Object path) {
    return 'Izpakots uz $path';
  }

  @override
  String extractFailed(Object error) {
    return 'Izpakošana neizdevās: $error';
  }

  @override
  String cannotPlay(Object error) {
    return 'Nevar atskaņot: $error';
  }

  @override
  String get pcReconnecting =>
      'Dators nav sasniedzams — savienojums tiek atjaunots automātiski…';

  @override
  String get pcRejected =>
      'Dators vairs neatpazīst šo telefonu. Noskenē QR kodu vēlreiz.';

  @override
  String get pcUnreachableHint =>
      'Nevar sasniegt datoru. Pārliecinies, ka Nova Transfer ir atvērts, abas ierīces ir vienā Wi-Fi un Windows ugunsmūris atļauj Nova Transfer.';

  @override
  String get otherDevices => 'Citas ierīces';

  @override
  String get otherDevicesHint =>
      'Savieno citus savus datorus un telefonus, lai ātri pārsūtītu failus. Nova jābūt atvērtai abās ierīcēs; savienotās ierīces atjauno savienojumu pašas.';

  @override
  String get thisDevice => 'Šī ierīce';

  @override
  String get deviceName => 'Ierīces nosaukums';

  @override
  String get devices => 'Ierīces';

  @override
  String get addDevice => 'Pievienot ierīci';

  @override
  String get pairCode => 'Kods';

  @override
  String get deviceAddress => 'Adrese';

  @override
  String get pairCodeWrong =>
      'Nepareizs vai novecojis kods — pārbaudi un mēģini vēlreiz.';

  @override
  String get deviceUnreachable =>
      'Nevar sasniegt ierīci. Vai tajā ir atvērta Nova un tā ir tajā pašā Wi-Fi?';

  @override
  String get noDevices => 'Vēl nav pievienotu ierīču';

  @override
  String get online => 'Tiešsaistē';

  @override
  String get offline => 'Nav tiešsaistē — atver tajā Nova';

  @override
  String get deviceRejected => 'Šī ierīce savienojumu ir noņēmusi';

  @override
  String get removeDevice => 'Noņemt ierīci';

  @override
  String get removeDeviceNote =>
      'Abas ierīces aizmirsīs viena otru. Lai savienotu atkal, vajadzēs jaunu kodu.';

  @override
  String get shareWith => 'Dalīties ar';

  @override
  String get shareAll => 'Visām savienotajām ierīcēm';

  @override
  String get deviceOffline =>
      'Ierīce neatbild — atver tajā Nova un esi tajā pašā Wi-Fi.';

  @override
  String pairedWith(String name) {
    return 'Savienots ar $name';
  }

  @override
  String receivedFrom(String name, String file) {
    return 'Saņemts no $name: $file';
  }

  @override
  String get otherDevicesCard => 'Papildu datori un telefoni';

  @override
  String get scanOtherQr => 'Skenēt otras ierīces QR';

  @override
  String get showMyQr => 'Rādīt šī telefona QR';

  @override
  String get enterAddressCode => 'Ievadīt adresi un kodu';

  @override
  String get pcAddress => 'Datora adrese';

  @override
  String get myQrHint =>
      'Otrā ierīcē atver Nova → Citas ierīces → Pievienot ierīci, tad noskenē šo QR vai ievadi adresi un kodu. Kods derīgs vienu reizi.';

  @override
  String get sharedWithDevices => 'Koplietots no šī telefona';

  @override
  String get shareScopeAll => 'Visas ierīces';

  @override
  String get addShare => 'Koplietot mapi vai failu';

  @override
  String get appsCardSubtitle => 'Izmēri, pēdējā lietošana, atinstalēšana';

  @override
  String get files => 'Faili';

  @override
  String get filesCardSubtitle =>
      'Attēli, video, dokumenti u.c. pa kategorijām';

  @override
  String get uninstall => 'Atinstalēt';

  @override
  String uninstallQ(int count) {
    return 'Atinstalēt $count lietotnes?';
  }

  @override
  String get uninstallNote =>
      'Android katrai lietotnei prasīs apstiprinājumu. Atinstalējot tiek izdzēsta arī lietotnes kešatmiņa un privātie dati; mapes, ko tā atstājusi atmiņā, pēc tam piedāvāsim izdzēst.';

  @override
  String uninstalledCount(int count) {
    return 'Atinstalētas $count lietotnes';
  }

  @override
  String get total => 'Kopā';

  @override
  String get appInfo => 'Lietotnes informācija';

  @override
  String get appInfoNote =>
      'Android iestatījumos var iztīrīt šīs lietotnes kešatmiņu vai datus';

  @override
  String get cleaner => 'Tīrīšana';

  @override
  String get sortBySize => 'Izmērs';

  @override
  String get sortByLastUsed => 'Pēdējā lietošana (vecākās vispirms)';

  @override
  String get sortByName => 'Nosaukums';

  @override
  String get sortByDate => 'Datums';

  @override
  String appsSummary(int count, String size) {
    return '$count lietotnes · $size';
  }

  @override
  String get cacheTotal => 'Kešatmiņa';

  @override
  String get usageAccessTitle => 'Atļauj \"Piekļuve lietojumam\"';

  @override
  String get usageAccessNote =>
      'Vajadzīgs, lai rādītu pilnu lietotņu izmēru, kešatmiņu un kad lietotne pēdējo reizi lietota.';

  @override
  String get allow => 'Atļaut';

  @override
  String get neverUsed => 'Nesen nav lietota';

  @override
  String get lastUsedUnknown => 'Pēdējā lietošana: atļauj piekļuvi lietojumam';

  @override
  String get lastUsed => 'Pēd. lietota';

  @override
  String get leftoversTitle => 'Atstātās mapes';

  @override
  String get leftoversNote =>
      'Šīs mapes piederēja noņemtajām lietotnēm. Noņem atzīmi tam, ko gribi paturēt.';

  @override
  String get keep => 'Paturēt';

  @override
  String deletedCount(int count) {
    return 'Izdzēsti $count vienumi';
  }

  @override
  String get rescan => 'Skenēt vēlreiz';

  @override
  String get clearAllCaches => 'Iztīrīt visu lietotņu kešatmiņu';

  @override
  String get clearAllCachesQ => 'Iztīrīt visu lietotņu kešatmiņu?';

  @override
  String get clearAllCachesNote =>
      'Android lūgs apstiprināt. Lietotnes saglabā datus un pieteikšanos — tiek dzēsti tikai pagaidu faili, kas vajadzības gadījumā izveidosies no jauna.';

  @override
  String get clearAllCachesUnavailable =>
      'Vajag Android 11+ un \"Piekļuvi visiem failiem\". Vecākā Android atver lietotnes informāciju un iztīri kešatmiņu tur.';

  @override
  String get clear => 'Iztīrīt';

  @override
  String deleteJunkQ(int count) {
    return 'Dzēst $count vienumus?';
  }

  @override
  String get deleteJunkNote =>
      'Tas ir neatgriezeniski — vienumi netiek pārvietoti uz atkritni.';

  @override
  String get junkThumbs => 'Sīktēlu kešatmiņa';

  @override
  String get junkTemp => 'Pagaidu faili';

  @override
  String get junkCacheDirs => 'Kešatmiņas mapes';

  @override
  String get junkTempDirs => '\"Temp\" mapes (pārbaudi pirms dzēšanas)';

  @override
  String get junkLogs => 'Žurnālfaili';

  @override
  String get junkEmpty => 'Tukšas mapes';

  @override
  String get junkLeftovers => 'Atstājušas atinstalētās lietotnes';

  @override
  String get junkNova => 'Nova pagaidu faili';

  @override
  String get deleteSelected => 'Dzēst atzīmētos';

  @override
  String get scanning => 'Skenē…';

  @override
  String get appCaches => 'Lietotņu kešatmiņa';

  @override
  String get appCachesNote =>
      'Pieskaries lietotnei, lai atvērtu tās iestatījumus un iztīrītu tikai to.';

  @override
  String get junkFiles => 'Nevajadzīgi faili';

  @override
  String get selectNone => 'Noņemt atzīmes';

  @override
  String get noJunk => 'Nav ko tīrīt — lieliski!';

  @override
  String get catImages => 'Attēli';

  @override
  String get catVideos => 'Video';

  @override
  String get catAudio => 'Audio';

  @override
  String get catDocuments => 'Dokumenti';

  @override
  String get catArchives => 'Arhīvi';

  @override
  String get catApks => 'Instalācijas faili (APK)';

  @override
  String get catLarge => 'Lieli faili (100 MB+)';

  @override
  String get catOther => 'Citi faili';

  @override
  String moveToBinQ(int count) {
    return 'Pārvietot $count failus uz atkritni?';
  }

  @override
  String get moveToBinNote => 'Tos varēs atjaunot no atkritnes.';

  @override
  String movedToBinN(int count) {
    return '$count pārvietoti uz atkritni';
  }

  @override
  String moveFilesQ(int count) {
    return 'Pārvietot $count failus šeit?';
  }

  @override
  String get move => 'Pārvietot';

  @override
  String movedCount(int count) {
    return 'Pārvietoti $count faili';
  }

  @override
  String get pcAddressHelp =>
      'Izmanto adresi un kodu no Nova Transfer → Savienojums (nevis \"Citas ierīces\").';

  @override
  String get pcAddressBad =>
      'Ievadi datora adresi, piem., 192.168.1.10 vai 192.168.1.10:48320';

  @override
  String get pcOtherDevicesCode =>
      'Šī adrese/kods ir no \"Citas ierīces\". Savam datoram izmanto Nova Transfer → Savienojums; papildu ierīcēm — Nova → Citas ierīces.';
}

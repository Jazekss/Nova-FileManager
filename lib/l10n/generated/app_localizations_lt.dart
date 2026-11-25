// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get appTitle => 'Nova File Manager';

  @override
  String get navHome => 'Pradžia';

  @override
  String get navFiles => 'Failai';

  @override
  String get navSearch => 'Paieška';

  @override
  String get permTitle => 'Reikalinga prieiga prie saugyklos';

  @override
  String get permBody =>
      'Nova reikalinga prieiga „Visos bylos\", kad būtų galima naršyti, kopijuoti ir perkelti failus vidinėje atmintyje ir SD kortelėje.\n\nNet ir su ja Android blokuoja prieigą prie kitų programų Android/data aplankų, o tikriems sistemos failams reikia root.';

  @override
  String get permGrant => 'Suteikti prieigą';

  @override
  String get permContinueLimited => 'Tęsti su ribota prieiga';

  @override
  String get settings => 'Nustatymai';

  @override
  String get appearance => 'Išvaizda';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Šviesi';

  @override
  String get themeDark => 'Tamsi';

  @override
  String get sizeUnits => 'Dydžio vienetai';

  @override
  String get unitAuto => 'Auto';

  @override
  String get showHidden => 'Rodyti paslėptus failus';

  @override
  String get showHiddenSubtitle => 'Failai ir aplankai, prasidedantys tašku';

  @override
  String get language => 'Kalba';

  @override
  String get languageSystem => 'Sistemos kalba';

  @override
  String get about => 'Apie';

  @override
  String versionLabel(Object version) {
    return 'Versija $version';
  }

  @override
  String get developerLine => 'Sukūrė JKdizains — jkdizains.lv';

  @override
  String get developerThanks => 'Sukurta vieno žmogaus. Ačiū už palaikymą!';

  @override
  String get coffeeButton => 'Pavaišink mane kava';

  @override
  String get storage => 'Saugykla';

  @override
  String get internalStorage => 'Vidinė atmintis';

  @override
  String get sdCard => 'SD kortelė';

  @override
  String get save => 'Išsaugoti';

  @override
  String get saved => 'Išsaugota';

  @override
  String get fileTooLarge => 'Failas per didelis redagavimui';

  @override
  String get change => 'Keisti';

  @override
  String get renameExtWarnTitle => 'Keisti plėtinį?';

  @override
  String renameExtWarnBody(String oldExt, String newExt) {
    return 'Pakeitus $oldExt į $newExt, kitos programos gali neatidaryti failo.';
  }

  @override
  String get shareWifi => 'Bendrinti per Wi-Fi';

  @override
  String get wifiTransfer => 'Wi-Fi perdavimas';

  @override
  String get wifiCardSubtitle => 'Siųsti ir gauti failus iš kompiuterio';

  @override
  String get wifiOpenHint =>
      'Atidarykite šį adresą kompiuteryje (tas pats Wi-Fi tinklas)';

  @override
  String get wifiSharedFiles => 'Bendrinami failai';

  @override
  String wifiUploadNote(String path) {
    return 'Įkėlimai saugomi į $path';
  }

  @override
  String wifiReceived(String name) {
    return 'Gauta: $name';
  }

  @override
  String get wifiStop => 'Sustabdyti bendrinimą';

  @override
  String get vault => 'Seifas';

  @override
  String get vaultCardSubtitle => 'Šifruoti privatūs failai';

  @override
  String get vaultUnlockReason => 'Atrakinti seifą';

  @override
  String get vaultSetPin => 'Nustatykite PIN (4–8 skaitmenys)';

  @override
  String get vaultEnterPin => 'Įveskite seifo PIN';

  @override
  String get vaultUnlock => 'Atrakinti';

  @override
  String get vaultUseBiometric => 'Naudoti biometriką';

  @override
  String get vaultPinTooShort => 'PIN turi būti bent 4 skaitmenų';

  @override
  String get vaultWrongPin => 'Neteisingas PIN';

  @override
  String get vaultEmpty => 'Seifas tuščias';

  @override
  String get vaultEmptyHint =>
      'Perkelkite failus čia: failo kontekstinis meniu → Į seifą';

  @override
  String get vaultExport => 'Eksportuoti iš seifo';

  @override
  String get movedToVault => 'Perkelta į seifą';

  @override
  String get exported => 'Eksportuota';

  @override
  String get moveToVault => 'Į seifą';

  @override
  String get convertTo => 'Konvertuoti į';

  @override
  String get converted => 'Konvertuota';

  @override
  String get convertFailed => 'Failo nepavyko konvertuoti';

  @override
  String get download => 'Atsisiųsti';

  @override
  String get downloaded => 'Atsisiųsta';

  @override
  String get upload => 'Įkelti';

  @override
  String get uploaded => 'Įkelta';

  @override
  String get signOut => 'Atsijungti';

  @override
  String get driveIntro =>
      'Prisijunkite, kad galėtumėte naršyti ir tvarkyti Google Drive failus.';

  @override
  String get driveScopeNote =>
      'Nova naudoja mažiausią Drive leidimą: mato tik programos sukurtus arba per ją atvertus failus.';

  @override
  String get driveSignIn => 'Prisijungti su Google';

  @override
  String get driveSignInFailed => 'Prisijungimas atšauktas arba nepavyko';

  @override
  String get driveTrashQ => 'Perkelti į Drive šiukšliadėžę?';

  @override
  String get comingSoon => 'Netrukus';

  @override
  String get sharedToPc => 'Bendrinta į PC';

  @override
  String get sharedFromPc => 'Bendrinta iš PC';

  @override
  String get pairWithPc => 'Susieti su kompiuteriu';

  @override
  String get pcPairHint =>
      'Kompiuteryje atidarykite Nova File Manager Desktop ir ryšio meniu parodykite susiejimo QR.';

  @override
  String get invalidPairLink => 'Neteisinga susiejimo nuoroda';

  @override
  String get uploadHere => 'Įkelti čia';

  @override
  String get sharePhoneFolder => 'Bendrinti telefono aplanką';

  @override
  String get pairFailed => 'Susiejimas nepavyko';

  @override
  String get pair => 'Susieti';

  @override
  String get disconnect => 'Atsieti';

  @override
  String get scanQr => 'Skaityti QR';

  @override
  String get pcShare => 'PC bendrinimas';

  @override
  String get enterManually => 'Įvesti ranka';

  @override
  String get enterPairLink => 'Įveskite susiejimo nuorodą';

  @override
  String get refresh => 'Atnaujinti';

  @override
  String get pressAgainToExit =>
      'Paspauskite „atgal“ dar kartą, kad išeitumėte';

  @override
  String get shareThumbs => 'Miniatiūros PC bendrinime';

  @override
  String get shareThumbsNote =>
      'Rodo paveikslėlių/video/APK peržiūras — sąrašas kraunasi lėčiau.';

  @override
  String get noStorage => 'Saugyklų nerasta';

  @override
  String get notAvailable => 'Neprieinama';

  @override
  String get noData => 'Nėra duomenų';

  @override
  String freeOf(Object free, Object total) {
    return '$free laisva iš $total';
  }

  @override
  String get installedApps => 'Įdiegtos programos';

  @override
  String get recycleBin => 'Šiukšliadėžė';

  @override
  String binItems(Object count, Object size) {
    return '$count elementai · $size';
  }

  @override
  String get quickAccess => 'Greita prieiga';

  @override
  String get androidLimits => 'Android apribojimai';

  @override
  String get limitData =>
      'Kitų programų Android/data ir Android/obb aplankai yra užblokuoti Android 11+, net turint prieigą prie visų failų.';

  @override
  String get limitSystem =>
      'Tikriems sistemos failams (/system, /data) reikia root — ši programa root nenaudoja.';

  @override
  String get limitSd =>
      'Kai kuriuose įrenginiuose rašymui į SD kortelę gali reikėti prieigos per sistemos dialogą.';

  @override
  String get fileManager => 'Failų tvarkyklė';

  @override
  String get newFolder => 'Naujas aplankas';

  @override
  String get folderName => 'Aplanko pavadinimas';

  @override
  String get select => 'Pasirinkti';

  @override
  String get selectAll => 'Pasirinkti viską';

  @override
  String get openWith => 'Atidaryti su';

  @override
  String get rename => 'Pervardyti';

  @override
  String get copyTo => 'Kopijuoti į...';

  @override
  String get moveTo => 'Perkelti į...';

  @override
  String get createZip => 'Sukurti ZIP';

  @override
  String get properties => 'Ypatybės';

  @override
  String get delete => 'Ištrinti';

  @override
  String get view => 'Rodinys';

  @override
  String get viewDetailed => 'Išsamus sąrašas';

  @override
  String get viewSmall => 'Mažos piktogramos';

  @override
  String get viewLarge => 'Didelės piktogramos';

  @override
  String get sort => 'Rikiuoti';

  @override
  String get sortName => 'Pavadinimas';

  @override
  String get sortSize => 'Dydis';

  @override
  String get sortDate => 'Data';

  @override
  String selectedCount(Object count) {
    return 'Pasirinkta: $count';
  }

  @override
  String deleteTitle(Object count) {
    return 'Ištrinti $count elementą(-us)?';
  }

  @override
  String get deleteBody =>
      'Perkelkite į šiukšliadėžę, kad vėliau galėtumėte atkurti, arba ištrinkite visam laikui.';

  @override
  String get cancel => 'Atšaukti';

  @override
  String get ok => 'Gerai';

  @override
  String get close => 'Uždaryti';

  @override
  String get deletePermanently => 'Ištrinti visam laikui';

  @override
  String get toRecycleBin => 'Į šiukšliadėžę';

  @override
  String get movedToBin => 'Perkelta į šiukšliadėžę';

  @override
  String get deleted => 'Ištrinta';

  @override
  String get moved => 'Perkelta';

  @override
  String get copied => 'Nukopijuota';

  @override
  String get renamed => 'Pervardyta';

  @override
  String get folderCreated => 'Aplankas sukurtas';

  @override
  String get zipCreated => 'ZIP sukurtas';

  @override
  String get noAppToOpen => 'Nerasta programa šiam failui atidaryti';

  @override
  String get retry => 'Bandyti dar kartą';

  @override
  String get emptyFolder => 'Šis aplankas tuščias';

  @override
  String get sameFolderError => 'Paskirtis yra dabartinis aplankas';

  @override
  String get permissionDeniedError =>
      'Prieiga uždrausta. Kai kurios vietos (pvz., Android/data ar sistemos aplankai) yra apribotos Android ir reikalauja specialios prieigos.';

  @override
  String get typeFolder => 'Aplankas';

  @override
  String typeFile(Object ext) {
    return 'Failas (.$ext)';
  }

  @override
  String get propType => 'Tipas';

  @override
  String get propPath => 'Kelias';

  @override
  String get propSize => 'Dydis';

  @override
  String get propModified => 'Pakeistas';

  @override
  String get propCreated => 'Sukurtas';

  @override
  String get chooseDestination => 'Pasirinkite paskirtį';

  @override
  String get up => 'Aukštyn';

  @override
  String get noSubfolders => 'Nėra poaplankių';

  @override
  String get selectHere => 'Pasirinkti čia';

  @override
  String get cannotOpenFolder => 'Nepavyksta atidaryti aplanko';

  @override
  String get fileNamePattern => 'Failo pavadinimas ar šablonas';

  @override
  String get searchHint => 'pvz., *.pdf arba ataskaita';

  @override
  String get wholeStorage => 'Visa saugykla';

  @override
  String get searchWholeStorage => 'Ieškoti visoje saugykloje';

  @override
  String get fromDate => 'Nuo datos';

  @override
  String get toDate => 'Iki datos';

  @override
  String get clearDates => 'Išvalyti datas';

  @override
  String get search => 'Ieškoti';

  @override
  String scannedCount(Object count) {
    return 'Nuskaityta $count elementų…';
  }

  @override
  String get noResults => 'Kol kas nėra rezultatų';

  @override
  String get emptyBinQ => 'Ištuštinti šiukšliadėžę?';

  @override
  String get emptyBinBody =>
      'Visi elementai bus visam laikui ištrinti. To negalima atšaukti.';

  @override
  String get emptyBin => 'Ištuštinti';

  @override
  String get binEmptied => 'Šiukšliadėžė ištuštinta';

  @override
  String get binEmpty => 'Šiukšliadėžė tuščia';

  @override
  String get restore => 'Atkurti';

  @override
  String get restored => 'Atkurtas';

  @override
  String get deleteForeverQ => 'Ištrinti visam laikui?';

  @override
  String get extractAll => 'Išskleisti viską';

  @override
  String get archiveEmpty => 'Archyvas tuščias';

  @override
  String archiveReadError(Object error) {
    return 'Nepavyko perskaityti archyvo: $error';
  }

  @override
  String extractedTo(Object path) {
    return 'Išskleista į $path';
  }

  @override
  String extractFailed(Object error) {
    return 'Išskleidimas nepavyko: $error';
  }

  @override
  String cannotPlay(Object error) {
    return 'Nepavyksta paleisti: $error';
  }

  @override
  String get pcReconnecting =>
      'Kompiuteris nepasiekiamas — jungiamasi automatiškai…';

  @override
  String get pcRejected =>
      'Kompiuteris nebeatpažįsta šio telefono. Nuskaitykite QR kodą dar kartą.';

  @override
  String get pcUnreachableHint =>
      'Nepavyksta pasiekti kompiuterio. Įsitikinkite, kad Nova Transfer atidaryta, abu įrenginiai tame pačiame Wi-Fi, o Windows užkarda leidžia Nova Transfer.';

  @override
  String get otherDevices => 'Kiti įrenginiai';

  @override
  String get otherDevicesHint =>
      'Susiekite kitus kompiuterius ir telefonus, kad greitai perkeltumėte failus. Nova turi būti atidaryta abiejuose įrenginiuose; susieti įrenginiai prisijungia patys.';

  @override
  String get thisDevice => 'Šis įrenginys';

  @override
  String get deviceName => 'Įrenginio pavadinimas';

  @override
  String get devices => 'Įrenginiai';

  @override
  String get addDevice => 'Pridėti įrenginį';

  @override
  String get pairCode => 'Kodas';

  @override
  String get deviceAddress => 'Adresas';

  @override
  String get pairCodeWrong =>
      'Neteisingas arba pasibaigęs kodas — patikrinkite ir bandykite dar kartą.';

  @override
  String get deviceUnreachable =>
      'Nepavyksta pasiekti įrenginio. Ar jame atidaryta Nova ir jis tame pačiame Wi-Fi?';

  @override
  String get noDevices => 'Įrenginių dar nėra';

  @override
  String get online => 'Prisijungęs';

  @override
  String get offline => 'Neprisijungęs — atidarykite jame Nova';

  @override
  String get deviceRejected => 'Šis įrenginys pašalino susiejimą';

  @override
  String get removeDevice => 'Pašalinti įrenginį';

  @override
  String get removeDeviceNote =>
      'Abu įrenginiai pamirš vienas kitą. Norint vėl susieti, reikės naujo kodo.';

  @override
  String get shareWith => 'Bendrinti su';

  @override
  String get shareAll => 'Visais susietais įrenginiais';

  @override
  String get deviceOffline =>
      'Įrenginys neatsako — atidarykite jame Nova tame pačiame Wi-Fi.';

  @override
  String pairedWith(String name) {
    return 'Susieta su $name';
  }

  @override
  String receivedFrom(String name, String file) {
    return 'Gauta iš $name: $file';
  }

  @override
  String get otherDevicesCard => 'Papildomi kompiuteriai ir telefonai';

  @override
  String get scanOtherQr => 'Nuskaityti kito įrenginio QR';

  @override
  String get showMyQr => 'Rodyti šio telefono QR';

  @override
  String get enterAddressCode => 'Įvesti adresą ir kodą';

  @override
  String get pcAddress => 'Kompiuterio adresas';

  @override
  String get myQrHint =>
      'Kitame įrenginyje atidarykite Nova → Kiti įrenginiai → Pridėti įrenginį, tada nuskaitykite šį QR arba įveskite adresą ir kodą. Kodas veikia vieną kartą.';

  @override
  String get sharedWithDevices => 'Bendrinama iš šio telefono';

  @override
  String get shareScopeAll => 'Visi įrenginiai';

  @override
  String get addShare => 'Bendrinti aplanką ar failą';

  @override
  String get appsCardSubtitle => 'Dydžiai, paskutinis naudojimas, šalinimas';

  @override
  String get files => 'Failai';

  @override
  String get filesCardSubtitle =>
      'Nuotraukos, vaizdo įrašai, dokumentai pagal kategorijas';

  @override
  String get uninstall => 'Pašalinti';

  @override
  String uninstallQ(int count) {
    return 'Pašalinti $count programas?';
  }

  @override
  String get uninstallNote =>
      'Android paprašys patvirtinti kiekvieną programą. Pašalinus ištrinama ir programos talpykla bei privatūs duomenys; paliktus aplankus vėliau pasiūlysime ištrinti.';

  @override
  String uninstalledCount(int count) {
    return 'Pašalinta programų: $count';
  }

  @override
  String get total => 'Iš viso';

  @override
  String get appInfo => 'Programos informacija';

  @override
  String get appInfoNote =>
      'Android nustatymuose galite išvalyti šios programos talpyklą ar duomenis';

  @override
  String get cleaner => 'Valymas';

  @override
  String get sortBySize => 'Dydis';

  @override
  String get sortByLastUsed => 'Paskutinis naudojimas (seniausios pirmos)';

  @override
  String get sortByName => 'Pavadinimas';

  @override
  String get sortByDate => 'Data';

  @override
  String appsSummary(int count, String size) {
    return '$count programos · $size';
  }

  @override
  String get cacheTotal => 'Talpykla';

  @override
  String get usageAccessTitle => 'Leiskite „Naudojimo prieiga“';

  @override
  String get usageAccessNote =>
      'Reikia, kad būtų rodomas visas programų dydis, talpykla ir paskutinio naudojimo laikas.';

  @override
  String get allow => 'Leisti';

  @override
  String get neverUsed => 'Neseniai nenaudota';

  @override
  String get lastUsedUnknown =>
      'Paskutinis naudojimas: leiskite naudojimo prieigą';

  @override
  String get lastUsed => 'Pask. naudota';

  @override
  String get leftoversTitle => 'Palikę aplankai';

  @override
  String get leftoversNote =>
      'Šie aplankai priklausė pašalintoms programoms. Nuimkite žymę nuo to, ką norite palikti.';

  @override
  String get keep => 'Palikti';

  @override
  String deletedCount(int count) {
    return 'Ištrinta: $count';
  }

  @override
  String get rescan => 'Skenuoti iš naujo';

  @override
  String get clearAllCaches => 'Išvalyti visų programų talpyklą';

  @override
  String get clearAllCachesQ => 'Išvalyti visų programų talpyklą?';

  @override
  String get clearAllCachesNote =>
      'Android paprašys patvirtinti. Programos išsaugo duomenis ir prisijungimus — ištrinami tik laikini failai.';

  @override
  String get clearAllCachesUnavailable =>
      'Reikia Android 11+ ir prieigos prie visų failų. Senesniame Android atidarykite programos informaciją.';

  @override
  String get clear => 'Išvalyti';

  @override
  String deleteJunkQ(int count) {
    return 'Ištrinti $count elementus?';
  }

  @override
  String get deleteJunkNote =>
      'Tai negrįžtama — elementai nepatenka į šiukšlinę.';

  @override
  String get junkThumbs => 'Miniatiūrų talpyklos';

  @override
  String get junkTemp => 'Laikini failai';

  @override
  String get junkCacheDirs => 'Talpyklos aplankai';

  @override
  String get junkTempDirs => '„Temp“ aplankai (patikrinkite)';

  @override
  String get junkLogs => 'Žurnalų failai';

  @override
  String get junkEmpty => 'Tušti aplankai';

  @override
  String get junkLeftovers => 'Paliko pašalintos programos';

  @override
  String get junkNova => 'Nova laikini failai';

  @override
  String get deleteSelected => 'Ištrinti pažymėtus';

  @override
  String get scanning => 'Skenuojama…';

  @override
  String get appCaches => 'Programų talpyklos';

  @override
  String get appCachesNote =>
      'Bakstelėkite programą, kad atidarytumėte jos nustatymus ir išvalytumėte tik ją.';

  @override
  String get junkFiles => 'Nereikalingi failai';

  @override
  String get selectNone => 'Nieko nežymėti';

  @override
  String get noJunk => 'Nėra ką valyti — puiku!';

  @override
  String get catImages => 'Nuotraukos';

  @override
  String get catVideos => 'Vaizdo įrašai';

  @override
  String get catAudio => 'Garso įrašai';

  @override
  String get catDocuments => 'Dokumentai';

  @override
  String get catArchives => 'Archyvai';

  @override
  String get catApks => 'Diegimo failai (APK)';

  @override
  String get catLarge => 'Dideli failai (100 MB+)';

  @override
  String get catOther => 'Kiti failai';

  @override
  String moveToBinQ(int count) {
    return 'Perkelti $count failus į šiukšlinę?';
  }

  @override
  String get moveToBinNote => 'Juos galėsite atkurti iš šiukšlinės.';

  @override
  String movedToBinN(int count) {
    return '$count perkelta į šiukšlinę';
  }

  @override
  String moveFilesQ(int count) {
    return 'Perkelti $count failus čia?';
  }

  @override
  String get move => 'Perkelti';

  @override
  String movedCount(int count) {
    return 'Perkelta failų: $count';
  }

  @override
  String get pcAddressHelp =>
      'Naudokite adresą ir kodą iš Nova Transfer → Ryšys (ne „Kiti įrenginiai“).';

  @override
  String get pcAddressBad =>
      'Įveskite adresą, pvz., 192.168.1.10 arba 192.168.1.10:48320';

  @override
  String get pcOtherDevicesCode =>
      'Šis adresas/kodas yra iš „Kiti įrenginiai“. Savo kompiuteriui naudokite Nova Transfer → Ryšys.';
}

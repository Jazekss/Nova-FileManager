// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get appTitle => 'Nova File Manager';

  @override
  String get navHome => 'Avaleht';

  @override
  String get navFiles => 'Failid';

  @override
  String get navSearch => 'Otsi';

  @override
  String get permTitle => 'Vajalik on salvestusruumi juurdepääs';

  @override
  String get permBody =>
      'Nova vajab „Kõigi failide juurdepääsu\", et sirvida, kopeerida ja teisaldada faile sisemälus ja SD-kaardil.\n\nIsegi sellega blokeerib Android juurdepääsu teiste rakenduste Android/data kaustadele ja tõelised süsteemifailid nõuavad rooti.';

  @override
  String get permGrant => 'Anna juurdepääs';

  @override
  String get permContinueLimited => 'Jätka piiratud juurdepääsuga';

  @override
  String get settings => 'Seaded';

  @override
  String get appearance => 'Välimus';

  @override
  String get themeSystem => 'Süsteem';

  @override
  String get themeLight => 'Hele';

  @override
  String get themeDark => 'Tume';

  @override
  String get sizeUnits => 'Suuruse ühikud';

  @override
  String get unitAuto => 'Auto';

  @override
  String get showHidden => 'Näita peidetud faile';

  @override
  String get showHiddenSubtitle => 'Punktiga algavad failid ja kaustad';

  @override
  String get language => 'Keel';

  @override
  String get languageSystem => 'Süsteemi keel';

  @override
  String get about => 'Teave';

  @override
  String versionLabel(Object version) {
    return 'Versioon $version';
  }

  @override
  String get developerLine => 'Arendaja: JKdizains — jkdizains.lv';

  @override
  String get developerThanks => 'Arendanud üks inimene. Tänan toetuse eest!';

  @override
  String get coffeeButton => 'Kingi mulle kohv';

  @override
  String get storage => 'Salvestusruum';

  @override
  String get internalStorage => 'Sisemälu';

  @override
  String get sdCard => 'SD-kaart';

  @override
  String get save => 'Salvesta';

  @override
  String get saved => 'Salvestatud';

  @override
  String get fileTooLarge => 'Fail on liiga suur muutmiseks';

  @override
  String get change => 'Muuda';

  @override
  String get renameExtWarnTitle => 'Muuta laiendit?';

  @override
  String renameExtWarnBody(String oldExt, String newExt) {
    return 'Laiendi $oldExt muutmine $newExt-ks võib muuta faili teistes rakendustes kasutamatuks.';
  }

  @override
  String get shareWifi => 'Jaga Wi-Fi kaudu';

  @override
  String get wifiTransfer => 'Wi-Fi ülekanne';

  @override
  String get wifiCardSubtitle => 'Saada ja võta vastu faile arvutiga';

  @override
  String get wifiOpenHint => 'Ava see aadress arvutis (sama Wi-Fi võrk)';

  @override
  String get wifiSharedFiles => 'Jagatud failid';

  @override
  String wifiUploadNote(String path) {
    return 'Üleslaadimised salvestatakse kausta $path';
  }

  @override
  String wifiReceived(String name) {
    return 'Võetud vastu: $name';
  }

  @override
  String get wifiStop => 'Lõpeta jagamine';

  @override
  String get vault => 'Seif';

  @override
  String get vaultCardSubtitle => 'Krüpteeritud privaatsed failid';

  @override
  String get vaultUnlockReason => 'Ava seif';

  @override
  String get vaultSetPin => 'Sea PIN (4–8 numbrit)';

  @override
  String get vaultEnterPin => 'Sisesta seifi PIN';

  @override
  String get vaultUnlock => 'Ava';

  @override
  String get vaultUseBiometric => 'Kasuta biomeetriat';

  @override
  String get vaultPinTooShort => 'PIN peab olema vähemalt 4 numbrit';

  @override
  String get vaultWrongPin => 'Vale PIN';

  @override
  String get vaultEmpty => 'Seif on tühi';

  @override
  String get vaultEmptyHint =>
      'Teisalda failid siia: faili kontekstimenüü → Seifi';

  @override
  String get vaultExport => 'Ekspordi seifist';

  @override
  String get movedToVault => 'Teisaldatud seifi';

  @override
  String get exported => 'Eksporditud';

  @override
  String get moveToVault => 'Seifi';

  @override
  String get convertTo => 'Teisenda';

  @override
  String get converted => 'Teisendatud';

  @override
  String get convertFailed => 'Faili ei saanud teisendada';

  @override
  String get download => 'Laadi alla';

  @override
  String get downloaded => 'Alla laaditud';

  @override
  String get upload => 'Laadi üles';

  @override
  String get uploaded => 'Üles laaditud';

  @override
  String get signOut => 'Logi välja';

  @override
  String get driveIntro =>
      'Logi sisse, et sirvida ja hallata oma Google Drive\'i faile.';

  @override
  String get driveScopeNote =>
      'Nova kasutab väikseimat Drive\'i luba: näeb ainult rakenduse loodud või selle kaudu avatud faile.';

  @override
  String get driveSignIn => 'Logi sisse Google\'iga';

  @override
  String get driveSignInFailed => 'Sisselogimine katkestati või ebaõnnestus';

  @override
  String get driveTrashQ => 'Teisalda Drive\'i prügikasti?';

  @override
  String get comingSoon => 'Varsti';

  @override
  String get sharedToPc => 'Jagatud PC-sse';

  @override
  String get sharedFromPc => 'Jagatud PC-st';

  @override
  String get pairWithPc => 'Seo arvutiga';

  @override
  String get pcPairHint =>
      'Ava arvutis Nova File Manager Desktop ja näita ühenduse menüüst sidumise QR-i.';

  @override
  String get invalidPairLink => 'Vigane sidumislink';

  @override
  String get uploadHere => 'Laadi siia';

  @override
  String get sharePhoneFolder => 'Jaga telefoni kausta';

  @override
  String get pairFailed => 'Sidumine ebaõnnestus';

  @override
  String get pair => 'Seo';

  @override
  String get disconnect => 'Katkesta';

  @override
  String get scanQr => 'Skanni QR';

  @override
  String get pcShare => 'PC jagamine';

  @override
  String get enterManually => 'Sisesta käsitsi';

  @override
  String get enterPairLink => 'Sisesta sidumislink';

  @override
  String get refresh => 'Värskenda';

  @override
  String get pressAgainToExit => 'Väljudes vajuta uuesti tagasi';

  @override
  String get shareThumbs => 'Pisipildid PC jagamises';

  @override
  String get shareThumbsNote =>
      'Näitab pildi/video/APK eelvaateid — nimekiri laeb aeglasemalt.';

  @override
  String get noStorage => 'Salvestusruume ei leitud';

  @override
  String get notAvailable => 'Pole saadaval';

  @override
  String get noData => 'Andmed puuduvad';

  @override
  String freeOf(Object free, Object total) {
    return '$free vaba $total-st';
  }

  @override
  String get installedApps => 'Installitud rakendused';

  @override
  String get recycleBin => 'Prügikast';

  @override
  String binItems(Object count, Object size) {
    return '$count üksust · $size';
  }

  @override
  String get quickAccess => 'Kiirpääs';

  @override
  String get androidLimits => 'Androidi piirangud';

  @override
  String get limitData =>
      'Teiste rakenduste Android/data ja Android/obb kaustad on Android 11+ poolt blokeeritud isegi täieliku failijuurdepääsuga.';

  @override
  String get limitSystem =>
      'Tõelised süsteemifailid (/system, /data) nõuavad rooti — see rakendus rooti ei kasuta.';

  @override
  String get limitSd =>
      'Mõnes seadmes võib SD-kaardile kirjutamine nõuda juurdepääsu süsteemi dialoogi kaudu.';

  @override
  String get fileManager => 'Failihaldur';

  @override
  String get newFolder => 'Uus kaust';

  @override
  String get folderName => 'Kausta nimi';

  @override
  String get select => 'Vali';

  @override
  String get selectAll => 'Vali kõik';

  @override
  String get openWith => 'Ava rakendusega';

  @override
  String get rename => 'Nimeta ümber';

  @override
  String get copyTo => 'Kopeeri...';

  @override
  String get moveTo => 'Teisalda...';

  @override
  String get createZip => 'Loo ZIP';

  @override
  String get properties => 'Atribuudid';

  @override
  String get delete => 'Kustuta';

  @override
  String get view => 'Vaade';

  @override
  String get viewDetailed => 'Detailne loend';

  @override
  String get viewSmall => 'Väikesed ikoonid';

  @override
  String get viewLarge => 'Suured ikoonid';

  @override
  String get sort => 'Sorteeri';

  @override
  String get sortName => 'Nimi';

  @override
  String get sortSize => 'Suurus';

  @override
  String get sortDate => 'Kuupäev';

  @override
  String selectedCount(Object count) {
    return 'Valitud: $count';
  }

  @override
  String deleteTitle(Object count) {
    return 'Kustutada $count üksus(t)?';
  }

  @override
  String get deleteBody =>
      'Teisalda prügikasti, et saaksid need hiljem taastada, või kustuta jäädavalt.';

  @override
  String get cancel => 'Tühista';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Sulge';

  @override
  String get deletePermanently => 'Kustuta jäädavalt';

  @override
  String get toRecycleBin => 'Prügikasti';

  @override
  String get movedToBin => 'Teisaldatud prügikasti';

  @override
  String get deleted => 'Kustutatud';

  @override
  String get moved => 'Teisaldatud';

  @override
  String get copied => 'Kopeeritud';

  @override
  String get renamed => 'Ümber nimetatud';

  @override
  String get folderCreated => 'Kaust loodud';

  @override
  String get zipCreated => 'ZIP loodud';

  @override
  String get noAppToOpen => 'Faili avamiseks pole sobivat rakendust';

  @override
  String get retry => 'Proovi uuesti';

  @override
  String get emptyFolder => 'See kaust on tühi';

  @override
  String get sameFolderError => 'Sihtkoht on praegune kaust';

  @override
  String get permissionDeniedError =>
      'Juurdepääs keelatud. Mõned kohad (nt Android/data või süsteemikaustad) on Androidi poolt piiratud ja nõuavad erijuurdepääsu.';

  @override
  String get typeFolder => 'Kaust';

  @override
  String typeFile(Object ext) {
    return 'Fail (.$ext)';
  }

  @override
  String get propType => 'Tüüp';

  @override
  String get propPath => 'Tee';

  @override
  String get propSize => 'Suurus';

  @override
  String get propModified => 'Muudetud';

  @override
  String get propCreated => 'Loodud';

  @override
  String get chooseDestination => 'Vali sihtkoht';

  @override
  String get up => 'Üles';

  @override
  String get noSubfolders => 'Alamkaustu pole';

  @override
  String get selectHere => 'Vali siin';

  @override
  String get cannotOpenFolder => 'Kausta ei saa avada';

  @override
  String get fileNamePattern => 'Failinimi või muster';

  @override
  String get searchHint => 'nt *.pdf või aruanne';

  @override
  String get wholeStorage => 'Kogu salvestusruum';

  @override
  String get searchWholeStorage => 'Otsi kogu salvestusruumist';

  @override
  String get fromDate => 'Alates kuupäevast';

  @override
  String get toDate => 'Kuni kuupäevani';

  @override
  String get clearDates => 'Tühjenda kuupäevad';

  @override
  String get search => 'Otsi';

  @override
  String scannedCount(Object count) {
    return 'Skannitud $count üksust…';
  }

  @override
  String get noResults => 'Tulemusi veel pole';

  @override
  String get emptyBinQ => 'Tühjendada prügikast?';

  @override
  String get emptyBinBody =>
      'Kõik üksused kustutatakse jäädavalt. Seda ei saa tagasi võtta.';

  @override
  String get emptyBin => 'Tühjenda';

  @override
  String get binEmptied => 'Prügikast tühjendatud';

  @override
  String get binEmpty => 'Prügikast on tühi';

  @override
  String get restore => 'Taasta';

  @override
  String get restored => 'Taastatud';

  @override
  String get deleteForeverQ => 'Kustutada jäädavalt?';

  @override
  String get extractAll => 'Paki kõik lahti';

  @override
  String get archiveEmpty => 'Arhiiv on tühi';

  @override
  String archiveReadError(Object error) {
    return 'Arhiivi ei saanud lugeda: $error';
  }

  @override
  String extractedTo(Object path) {
    return 'Lahti pakitud kausta $path';
  }

  @override
  String extractFailed(Object error) {
    return 'Lahtipakkimine ebaõnnestus: $error';
  }

  @override
  String cannotPlay(Object error) {
    return 'Esitamine ebaõnnestus: $error';
  }

  @override
  String get pcReconnecting =>
      'Arvuti pole kättesaadav — ühendan automaatselt uuesti…';

  @override
  String get pcRejected =>
      'Arvuti ei tunne seda telefoni enam ära. Skanni QR-kood uuesti.';

  @override
  String get pcUnreachableHint =>
      'Arvutiga ei saa ühendust. Veendu, et Nova Transfer on avatud, mõlemad seadmed on samas Wi-Fis ja Windowsi tulemüür lubab Nova Transferi.';
}

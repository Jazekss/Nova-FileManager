// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appTitle => 'Nova File Manager';

  @override
  String get navHome => 'Hjem';

  @override
  String get navFiles => 'Filer';

  @override
  String get navSearch => 'Søk';

  @override
  String get permTitle => 'Lagringstilgang kreves';

  @override
  String get permBody =>
      'Nova trenger «Tilgang til alle filer» for å bla gjennom, kopiere og flytte filer på internminne og SD-kort.\n\nSelv med det blokkerer Android tilgang til andre appers Android/data-mapper, og ekte systemfiler krever root.';

  @override
  String get permGrant => 'Gi tilgang';

  @override
  String get permContinueLimited => 'Fortsett med begrenset tilgang';

  @override
  String get settings => 'Innstillinger';

  @override
  String get appearance => 'Utseende';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Lys';

  @override
  String get themeDark => 'Mørk';

  @override
  String get sizeUnits => 'Størrelsesenheter';

  @override
  String get unitAuto => 'Auto';

  @override
  String get showHidden => 'Vis skjulte filer';

  @override
  String get showHiddenSubtitle => 'Filer og mapper som begynner med punktum';

  @override
  String get language => 'Språk';

  @override
  String get languageSystem => 'Systemspråk';

  @override
  String get about => 'Om';

  @override
  String versionLabel(Object version) {
    return 'Versjon $version';
  }

  @override
  String get developerLine => 'Utviklet av JKdizains — jkdizains.lv';

  @override
  String get developerThanks => 'Utviklet av én person. Takk for støtten!';

  @override
  String get coffeeButton => 'Kjøp meg en kaffe';

  @override
  String get storage => 'Lagring';

  @override
  String get internalStorage => 'Internminne';

  @override
  String get sdCard => 'SD-kort';

  @override
  String get save => 'Lagre';

  @override
  String get saved => 'Lagret';

  @override
  String get fileTooLarge => 'Filen er for stor til å redigeres';

  @override
  String get change => 'Endre';

  @override
  String get renameExtWarnTitle => 'Endre filtype?';

  @override
  String renameExtWarnBody(String oldExt, String newExt) {
    return 'Endring fra $oldExt til $newExt kan gjøre at andre apper ikke kan åpne filen.';
  }

  @override
  String get shareWifi => 'Del via Wi-Fi';

  @override
  String get wifiTransfer => 'Wi-Fi-overføring';

  @override
  String get wifiCardSubtitle => 'Send og motta filer med en datamaskin';

  @override
  String get wifiOpenHint =>
      'Åpne denne adressen på datamaskinen (samme Wi-Fi)';

  @override
  String get wifiSharedFiles => 'Delte filer';

  @override
  String wifiUploadNote(String path) {
    return 'Opplastinger lagres i $path';
  }

  @override
  String wifiReceived(String name) {
    return 'Mottatt: $name';
  }

  @override
  String get wifiStop => 'Stopp deling';

  @override
  String get vault => 'Hvelv';

  @override
  String get vaultCardSubtitle => 'Krypterte private filer';

  @override
  String get vaultUnlockReason => 'Lås opp hvelvet';

  @override
  String get vaultSetPin => 'Angi PIN-kode (4–8 sifre)';

  @override
  String get vaultEnterPin => 'Skriv inn hvelv-PIN';

  @override
  String get vaultUnlock => 'Lås opp';

  @override
  String get vaultUseBiometric => 'Bruk biometri';

  @override
  String get vaultPinTooShort => 'PIN må være minst 4 sifre';

  @override
  String get vaultWrongPin => 'Feil PIN';

  @override
  String get vaultEmpty => 'Hvelvet er tomt';

  @override
  String get vaultEmptyHint =>
      'Flytt filer hit: filens kontekstmeny → Flytt til hvelv';

  @override
  String get vaultExport => 'Eksporter fra hvelv';

  @override
  String get movedToVault => 'Flyttet til hvelv';

  @override
  String get exported => 'Eksportert';

  @override
  String get moveToVault => 'Flytt til hvelv';

  @override
  String get convertTo => 'Konverter til';

  @override
  String get converted => 'Konvertert';

  @override
  String get convertFailed => 'Kunne ikke konvertere filen';

  @override
  String get download => 'Last ned';

  @override
  String get downloaded => 'Lastet ned';

  @override
  String get upload => 'Last opp';

  @override
  String get uploaded => 'Lastet opp';

  @override
  String get signOut => 'Logg ut';

  @override
  String get driveIntro =>
      'Logg inn for å bla gjennom og administrere Google Drive-filene dine.';

  @override
  String get driveScopeNote =>
      'Nova bruker den minste Drive-tillatelsen: den ser bare filer appen har opprettet eller åpnet via den.';

  @override
  String get driveSignIn => 'Logg inn med Google';

  @override
  String get driveSignInFailed => 'Innlogging avbrutt eller mislyktes';

  @override
  String get driveTrashQ => 'Flytt til Drive-papirkurven?';

  @override
  String get comingSoon => 'Kommer snart';

  @override
  String get sharedToPc => 'Delt til PC';

  @override
  String get sharedFromPc => 'Delt fra PC';

  @override
  String get pairWithPc => 'Koble til datamaskinen';

  @override
  String get pcPairHint =>
      'Åpne Nova File Manager Desktop på PC-en og vis sammenkoblings-QR i tilkoblingsmenyen.';

  @override
  String get invalidPairLink => 'Ugyldig koblingslenke';

  @override
  String get uploadHere => 'Last opp hit';

  @override
  String get sharePhoneFolder => 'Del telefonmappe';

  @override
  String get pairFailed => 'Kobling mislyktes';

  @override
  String get pair => 'Koble til';

  @override
  String get disconnect => 'Koble fra';

  @override
  String get scanQr => 'Skann QR';

  @override
  String get pcShare => 'PC-deling';

  @override
  String get enterManually => 'Skriv inn manuelt';

  @override
  String get enterPairLink => 'Skriv inn koblingslenke';

  @override
  String get refresh => 'Oppdater';

  @override
  String get pressAgainToExit => 'Trykk tilbake igjen for å avslutte';

  @override
  String get shareThumbs => 'Miniatyrer i PC-deling';

  @override
  String get shareThumbsNote =>
      'Viser bilde-/video-/APK-forhåndsvisninger — listen lastes saktere.';

  @override
  String get noStorage => 'Ingen lagringsvolumer funnet';

  @override
  String get notAvailable => 'Ikke tilgjengelig';

  @override
  String get noData => 'Ingen data';

  @override
  String freeOf(Object free, Object total) {
    return '$free ledig av $total';
  }

  @override
  String get installedApps => 'Installerte apper';

  @override
  String get recycleBin => 'Papirkurv';

  @override
  String binItems(Object count, Object size) {
    return '$count elementer · $size';
  }

  @override
  String get quickAccess => 'Hurtigtilgang';

  @override
  String get androidLimits => 'Android-begrensninger';

  @override
  String get limitData =>
      'Android/data- og Android/obb-mappene til andre apper er blokkert av Android 11+, selv med tilgang til alle filer.';

  @override
  String get limitSystem =>
      'Ekte systemfiler (/system, /data) krever root — denne appen bruker ikke root.';

  @override
  String get limitSd =>
      'På enkelte enheter kan skriving til SD-kort kreve tilgang via systemvelgeren.';

  @override
  String get fileManager => 'Filbehandler';

  @override
  String get newFolder => 'Ny mappe';

  @override
  String get folderName => 'Mappenavn';

  @override
  String get select => 'Velg';

  @override
  String get selectAll => 'Velg alle';

  @override
  String get openWith => 'Åpne med';

  @override
  String get rename => 'Gi nytt navn';

  @override
  String get copyTo => 'Kopier til...';

  @override
  String get moveTo => 'Flytt til...';

  @override
  String get createZip => 'Opprett ZIP';

  @override
  String get properties => 'Egenskaper';

  @override
  String get delete => 'Slett';

  @override
  String get view => 'Visning';

  @override
  String get viewDetailed => 'Detaljert liste';

  @override
  String get viewSmall => 'Små ikoner';

  @override
  String get viewLarge => 'Store ikoner';

  @override
  String get sort => 'Sorter';

  @override
  String get sortName => 'Navn';

  @override
  String get sortSize => 'Størrelse';

  @override
  String get sortDate => 'Dato';

  @override
  String selectedCount(Object count) {
    return '$count valgt';
  }

  @override
  String deleteTitle(Object count) {
    return 'Slette $count element(er)?';
  }

  @override
  String get deleteBody =>
      'Flytt til papirkurven for å kunne gjenopprette dem senere, eller slett permanent.';

  @override
  String get cancel => 'Avbryt';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Lukk';

  @override
  String get deletePermanently => 'Slett permanent';

  @override
  String get toRecycleBin => 'Til papirkurv';

  @override
  String get movedToBin => 'Flyttet til papirkurven';

  @override
  String get deleted => 'Slettet';

  @override
  String get moved => 'Flyttet';

  @override
  String get copied => 'Kopiert';

  @override
  String get renamed => 'Navn endret';

  @override
  String get folderCreated => 'Mappe opprettet';

  @override
  String get zipCreated => 'ZIP opprettet';

  @override
  String get noAppToOpen => 'Fant ingen app for å åpne denne filen';

  @override
  String get retry => 'Prøv igjen';

  @override
  String get emptyFolder => 'Denne mappen er tom';

  @override
  String get sameFolderError => 'Målet er gjeldende mappe';

  @override
  String get permissionDeniedError =>
      'Tilgang nektet. Noen steder (f.eks. Android/data eller systemmapper) er begrenset av Android og krever spesiell tilgang.';

  @override
  String get typeFolder => 'Mappe';

  @override
  String typeFile(Object ext) {
    return 'Fil (.$ext)';
  }

  @override
  String get propType => 'Type';

  @override
  String get propPath => 'Bane';

  @override
  String get propSize => 'Størrelse';

  @override
  String get propModified => 'Endret';

  @override
  String get propCreated => 'Opprettet';

  @override
  String get chooseDestination => 'Velg mål';

  @override
  String get up => 'Opp';

  @override
  String get noSubfolders => 'Ingen undermapper';

  @override
  String get selectHere => 'Velg her';

  @override
  String get cannotOpenFolder => 'Kan ikke åpne mappen';

  @override
  String get fileNamePattern => 'Filnavn eller mønster';

  @override
  String get searchHint => 'f.eks. *.pdf eller rapport';

  @override
  String get wholeStorage => 'Hele lagringen';

  @override
  String get searchWholeStorage => 'Søk i hele lagringen';

  @override
  String get fromDate => 'Fra dato';

  @override
  String get toDate => 'Til dato';

  @override
  String get clearDates => 'Fjern datoer';

  @override
  String get search => 'Søk';

  @override
  String scannedCount(Object count) {
    return 'Skannet $count elementer…';
  }

  @override
  String get noResults => 'Ingen resultater ennå';

  @override
  String get emptyBinQ => 'Tømme papirkurven?';

  @override
  String get emptyBinBody =>
      'Alle elementer slettes permanent. Dette kan ikke angres.';

  @override
  String get emptyBin => 'Tøm';

  @override
  String get binEmptied => 'Papirkurv tømt';

  @override
  String get binEmpty => 'Papirkurven er tom';

  @override
  String get restore => 'Gjenopprett';

  @override
  String get restored => 'Gjenopprettet';

  @override
  String get deleteForeverQ => 'Slette permanent?';

  @override
  String get extractAll => 'Pakk ut alt';

  @override
  String get archiveEmpty => 'Arkivet er tomt';

  @override
  String archiveReadError(Object error) {
    return 'Kunne ikke lese arkivet: $error';
  }

  @override
  String extractedTo(Object path) {
    return 'Pakket ut til $path';
  }

  @override
  String extractFailed(Object error) {
    return 'Utpakking feilet: $error';
  }

  @override
  String cannotPlay(Object error) {
    return 'Kan ikke spille: $error';
  }

  @override
  String get pcReconnecting => 'PC-en svarer ikke — kobler til automatisk…';

  @override
  String get pcRejected =>
      'PC-en kjenner ikke lenger igjen telefonen. Skann QR-koden på nytt.';

  @override
  String get pcUnreachableHint =>
      'Får ikke kontakt med PC-en. Sjekk at Nova Transfer er åpen, at begge enhetene er på samme Wi-Fi og at Windows-brannmuren tillater Nova Transfer.';

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
  String get otherDevicesCard => 'Ekstra datamaskiner og telefoner';

  @override
  String get scanOtherQr => 'Skann QR-koden på den andre enheten';

  @override
  String get showMyQr => 'Vis QR-koden til denne telefonen';

  @override
  String get enterAddressCode => 'Skriv inn adresse og kode';

  @override
  String get pcAddress => 'PC-adresse';

  @override
  String get myQrHint =>
      'På den andre enheten: åpne Nova → Andre enheter → Legg til enhet, og skann denne QR-koden eller skriv inn adresse og kode. Koden virker én gang.';

  @override
  String get sharedWithDevices => 'Delt fra denne telefonen';

  @override
  String get shareScopeAll => 'Alle enheter';

  @override
  String get addShare => 'Del en mappe eller fil';

  @override
  String get appsCardSubtitle => 'Størrelser, sist brukt, avinstaller';

  @override
  String get files => 'Filer';

  @override
  String get filesCardSubtitle =>
      'Bilder, video, dokumenter m.m. etter kategori';

  @override
  String get uninstall => 'Avinstaller';

  @override
  String uninstallQ(int count) {
    return 'Avinstallere $count apper?';
  }

  @override
  String get uninstallNote =>
      'Android ber deg bekrefte hver app. Avinstallering fjerner også appens hurtigbuffer og private data; mapper den etterlot tilbys slettet etterpå.';

  @override
  String uninstalledCount(int count) {
    return '$count apper avinstallert';
  }

  @override
  String get total => 'Totalt';

  @override
  String get appInfo => 'Appinfo';

  @override
  String get appInfoNote =>
      'Tøm appens hurtigbuffer eller data i Android-innstillinger';

  @override
  String get cleaner => 'Opprydding';

  @override
  String get sortBySize => 'Størrelse';

  @override
  String get sortByLastUsed => 'Sist brukt (eldste først)';

  @override
  String get sortByName => 'Navn';

  @override
  String get sortByDate => 'Dato';

  @override
  String appsSummary(int count, String size) {
    return '$count apper · $size';
  }

  @override
  String get cacheTotal => 'Hurtigbuffer';

  @override
  String get usageAccessTitle => 'Tillat «Brukstilgang»';

  @override
  String get usageAccessNote =>
      'Trengs for å vise full appstørrelse, hurtigbuffer og når appen sist ble brukt.';

  @override
  String get allow => 'Tillat';

  @override
  String get neverUsed => 'Ikke brukt nylig';

  @override
  String get lastUsedUnknown => 'Sist brukt: tillat brukstilgang';

  @override
  String get lastUsed => 'Sist brukt';

  @override
  String get leftoversTitle => 'Mapper som ble igjen';

  @override
  String get leftoversNote =>
      'Disse mappene tilhørte de fjernede appene. Fjern haken for det du vil beholde.';

  @override
  String get keep => 'Behold';

  @override
  String deletedCount(int count) {
    return '$count elementer slettet';
  }

  @override
  String get rescan => 'Skann på nytt';

  @override
  String get clearAllCaches => 'Tøm hurtigbuffer for alle apper';

  @override
  String get clearAllCachesQ => 'Tømme hurtigbuffer for alle apper?';

  @override
  String get clearAllCachesNote =>
      'Android ber deg bekrefte. Appene beholder data og innlogging — bare midlertidige filer fjernes.';

  @override
  String get clearAllCachesUnavailable =>
      'Krever Android 11+ og tilgang til alle filer. På eldre Android: åpne appinfo.';

  @override
  String get clear => 'Tøm';

  @override
  String deleteJunkQ(int count) {
    return 'Slette $count elementer?';
  }

  @override
  String get deleteJunkNote =>
      'Dette er permanent — elementene går ikke til papirkurven.';

  @override
  String get junkThumbs => 'Miniatyrbuffer';

  @override
  String get junkTemp => 'Midlertidige filer';

  @override
  String get junkCacheDirs => 'Buffermapper';

  @override
  String get junkTempDirs => '«Temp»-mapper (sjekk først)';

  @override
  String get junkLogs => 'Loggfiler';

  @override
  String get junkEmpty => 'Tomme mapper';

  @override
  String get junkLeftovers => 'Etterlatt av avinstallerte apper';

  @override
  String get junkNova => 'Novas midlertidige filer';

  @override
  String get deleteSelected => 'Slett valgte';

  @override
  String get scanning => 'Skanner…';

  @override
  String get appCaches => 'Apphurtigbuffer';

  @override
  String get appCachesNote =>
      'Trykk på en app for å åpne innstillingene og tømme bare den.';

  @override
  String get junkFiles => 'Unødvendige filer';

  @override
  String get selectNone => 'Velg ingen';

  @override
  String get noJunk => 'Ingenting å rydde — flott!';

  @override
  String get catImages => 'Bilder';

  @override
  String get catVideos => 'Videoer';

  @override
  String get catAudio => 'Lyd';

  @override
  String get catDocuments => 'Dokumenter';

  @override
  String get catArchives => 'Arkiver';

  @override
  String get catApks => 'Installasjonsfiler (APK)';

  @override
  String get catLarge => 'Store filer (100 MB+)';

  @override
  String get catOther => 'Andre filer';

  @override
  String moveToBinQ(int count) {
    return 'Flytte $count filer til papirkurven?';
  }

  @override
  String get moveToBinNote => 'Du kan gjenopprette dem fra papirkurven.';

  @override
  String movedToBinN(int count) {
    return '$count flyttet til papirkurven';
  }

  @override
  String moveFilesQ(int count) {
    return 'Flytte $count filer hit?';
  }

  @override
  String get move => 'Flytt';

  @override
  String movedCount(int count) {
    return '$count filer flyttet';
  }

  @override
  String get pcAddressHelp =>
      'Bruk adresse og kode fra Nova Transfer → Tilkobling (ikke «Andre enheter»).';

  @override
  String get pcAddressBad =>
      'Skriv adressen, f.eks. 192.168.1.10 eller 192.168.1.10:48320';

  @override
  String get pcOtherDevicesCode =>
      'Denne adressen/koden hører til «Andre enheter». For din egen PC: Nova Transfer → Tilkobling.';
}

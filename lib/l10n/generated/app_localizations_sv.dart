// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Nova File Manager';

  @override
  String get navHome => 'Hem';

  @override
  String get navFiles => 'Filer';

  @override
  String get navSearch => 'Sök';

  @override
  String get permTitle => 'Lagringsåtkomst krävs';

  @override
  String get permBody =>
      'Nova behöver behörigheten \"Åtkomst till alla filer\" för att bläddra, kopiera och flytta filer på internminnet och SD-kortet.\n\nÄven med den blockerar Android åtkomst till andra appars Android/data-mappar, och riktiga systemfiler kräver root.';

  @override
  String get permGrant => 'Ge åtkomst';

  @override
  String get permContinueLimited => 'Fortsätt med begränsad åtkomst';

  @override
  String get settings => 'Inställningar';

  @override
  String get appearance => 'Utseende';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Ljus';

  @override
  String get themeDark => 'Mörk';

  @override
  String get sizeUnits => 'Storhetsenheter';

  @override
  String get unitAuto => 'Auto';

  @override
  String get showHidden => 'Visa dolda filer';

  @override
  String get showHiddenSubtitle => 'Filer och mappar som börjar med en punkt';

  @override
  String get language => 'Språk';

  @override
  String get languageSystem => 'Systemspråk';

  @override
  String get about => 'Om';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get developerLine => 'Utvecklad av JKdizains — jkdizains.lv';

  @override
  String get developerThanks =>
      'Utvecklad av en enda person. Tack för ditt stöd!';

  @override
  String get coffeeButton => 'Bjud mig på en kaffe';

  @override
  String get storage => 'Lagring';

  @override
  String get internalStorage => 'Internminne';

  @override
  String get sdCard => 'SD-kort';

  @override
  String get save => 'Spara';

  @override
  String get saved => 'Sparad';

  @override
  String get fileTooLarge => 'Filen är för stor att redigera';

  @override
  String get change => 'Ändra';

  @override
  String get renameExtWarnTitle => 'Ändra filändelse?';

  @override
  String renameExtWarnBody(String oldExt, String newExt) {
    return 'Att ändra $oldExt till $newExt kan göra att andra appar inte kan öppna filen.';
  }

  @override
  String get shareWifi => 'Dela via Wi-Fi';

  @override
  String get wifiTransfer => 'Wi-Fi-överföring';

  @override
  String get wifiCardSubtitle => 'Skicka och ta emot filer med en dator';

  @override
  String get wifiOpenHint => 'Öppna adressen på datorn (samma Wi-Fi)';

  @override
  String get wifiSharedFiles => 'Delade filer';

  @override
  String wifiUploadNote(String path) {
    return 'Uppladdningar sparas i $path';
  }

  @override
  String wifiReceived(String name) {
    return 'Mottagen: $name';
  }

  @override
  String get wifiStop => 'Stoppa delning';

  @override
  String get vault => 'Valv';

  @override
  String get vaultCardSubtitle => 'Krypterade privata filer';

  @override
  String get vaultUnlockReason => 'Lås upp valvet';

  @override
  String get vaultSetPin => 'Ange PIN-kod (4–8 siffror)';

  @override
  String get vaultEnterPin => 'Ange valvets PIN-kod';

  @override
  String get vaultUnlock => 'Lås upp';

  @override
  String get vaultUseBiometric => 'Använd biometri';

  @override
  String get vaultPinTooShort => 'PIN måste vara minst 4 siffror';

  @override
  String get vaultWrongPin => 'Fel PIN';

  @override
  String get vaultEmpty => 'Valvet är tomt';

  @override
  String get vaultEmptyHint =>
      'Flytta filer hit: filens snabbmeny → Flytta till valv';

  @override
  String get vaultExport => 'Exportera från valv';

  @override
  String get movedToVault => 'Flyttad till valv';

  @override
  String get exported => 'Exporterad';

  @override
  String get moveToVault => 'Flytta till valv';

  @override
  String get convertTo => 'Konvertera till';

  @override
  String get converted => 'Konverterad';

  @override
  String get convertFailed => 'Kunde inte konvertera filen';

  @override
  String get download => 'Ladda ner';

  @override
  String get downloaded => 'Nedladdad';

  @override
  String get upload => 'Ladda upp';

  @override
  String get uploaded => 'Uppladdad';

  @override
  String get signOut => 'Logga ut';

  @override
  String get driveIntro =>
      'Logga in för att bläddra och hantera dina Google Drive-filer.';

  @override
  String get driveScopeNote =>
      'Nova använder den minsta Drive-behörigheten: den ser bara filer som appen skapat eller öppnat via den.';

  @override
  String get driveSignIn => 'Logga in med Google';

  @override
  String get driveSignInFailed => 'Inloggning avbröts eller misslyckades';

  @override
  String get driveTrashQ => 'Flytta till Drive-papperskorgen?';

  @override
  String get comingSoon => 'Kommer snart';

  @override
  String get sharedToPc => 'Delat till PC';

  @override
  String get sharedFromPc => 'Delat från PC';

  @override
  String get pairWithPc => 'Para ihop med datorn';

  @override
  String get pcPairHint =>
      'Öppna Nova File Manager Desktop på datorn och visa parkopplings-QR i anslutningsmenyn.';

  @override
  String get invalidPairLink => 'Ogiltig kopplingslänk';

  @override
  String get uploadHere => 'Ladda upp hit';

  @override
  String get sharePhoneFolder => 'Dela telefonmapp';

  @override
  String get pairFailed => 'Koppling misslyckades';

  @override
  String get pair => 'Para ihop';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get scanQr => 'Skanna QR';

  @override
  String get pcShare => 'PC-delning';

  @override
  String get enterManually => 'Ange manuellt';

  @override
  String get enterPairLink => 'Ange kopplingslänk';

  @override
  String get refresh => 'Uppdatera';

  @override
  String get pressAgainToExit => 'Tryck tillbaka igen för att avsluta';

  @override
  String get shareThumbs => 'Miniatyrer i PC-delning';

  @override
  String get shareThumbsNote =>
      'Visar bild-/video-/APK-förhandsvisningar — listan laddas långsammare.';

  @override
  String get noStorage => 'Inga lagringsenheter hittades';

  @override
  String get notAvailable => 'Inte tillgänglig';

  @override
  String get noData => 'Ingen data';

  @override
  String freeOf(Object free, Object total) {
    return '$free ledigt av $total';
  }

  @override
  String get installedApps => 'Installerade appar';

  @override
  String get recycleBin => 'Papperskorg';

  @override
  String binItems(Object count, Object size) {
    return '$count objekt · $size';
  }

  @override
  String get quickAccess => 'Snabbåtkomst';

  @override
  String get androidLimits => 'Android-begränsningar';

  @override
  String get limitData =>
      'Android/data- och Android/obb-mappar för andra appar blockeras av Android 11+, även med åtkomst till alla filer.';

  @override
  String get limitSystem =>
      'Riktiga systemfiler (/system, /data) kräver root — den här appen använder inte root.';

  @override
  String get limitSd =>
      'På vissa enheter kan skrivning till SD-kort kräva åtkomst via systemväljaren.';

  @override
  String get fileManager => 'Filhanterare';

  @override
  String get newFolder => 'Ny mapp';

  @override
  String get folderName => 'Mappnamn';

  @override
  String get select => 'Markera';

  @override
  String get selectAll => 'Markera alla';

  @override
  String get openWith => 'Öppna med';

  @override
  String get rename => 'Byt namn';

  @override
  String get copyTo => 'Kopiera till...';

  @override
  String get moveTo => 'Flytta till...';

  @override
  String get createZip => 'Skapa ZIP';

  @override
  String get properties => 'Egenskaper';

  @override
  String get delete => 'Ta bort';

  @override
  String get view => 'Vy';

  @override
  String get viewDetailed => 'Detaljerad lista';

  @override
  String get viewSmall => 'Små ikoner';

  @override
  String get viewLarge => 'Stora ikoner';

  @override
  String get sort => 'Sortera';

  @override
  String get sortName => 'Namn';

  @override
  String get sortSize => 'Storlek';

  @override
  String get sortDate => 'Datum';

  @override
  String selectedCount(Object count) {
    return '$count markerade';
  }

  @override
  String deleteTitle(Object count) {
    return 'Ta bort $count objekt?';
  }

  @override
  String get deleteBody =>
      'Flytta till papperskorgen för att kunna återställa dem senare, eller ta bort permanent.';

  @override
  String get cancel => 'Avbryt';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Stäng';

  @override
  String get deletePermanently => 'Ta bort permanent';

  @override
  String get toRecycleBin => 'Till papperskorgen';

  @override
  String get movedToBin => 'Flyttad till papperskorgen';

  @override
  String get deleted => 'Borttagen';

  @override
  String get moved => 'Flyttad';

  @override
  String get copied => 'Kopierad';

  @override
  String get renamed => 'Namnbytt';

  @override
  String get folderCreated => 'Mapp skapad';

  @override
  String get zipCreated => 'ZIP skapad';

  @override
  String get noAppToOpen => 'Ingen app hittades för att öppna filen';

  @override
  String get retry => 'Försök igen';

  @override
  String get emptyFolder => 'Den här mappen är tom';

  @override
  String get sameFolderError => 'Målet är den aktuella mappen';

  @override
  String get permissionDeniedError =>
      'Åtkomst nekad. Vissa platser (t.ex. Android/data eller systemmappar) är begränsade av Android och kräver särskild åtkomst.';

  @override
  String get typeFolder => 'Mapp';

  @override
  String typeFile(Object ext) {
    return 'Fil (.$ext)';
  }

  @override
  String get propType => 'Typ';

  @override
  String get propPath => 'Sökväg';

  @override
  String get propSize => 'Storlek';

  @override
  String get propModified => 'Ändrad';

  @override
  String get propCreated => 'Skapad';

  @override
  String get chooseDestination => 'Välj mål';

  @override
  String get up => 'Upp';

  @override
  String get noSubfolders => 'Inga undermappar';

  @override
  String get selectHere => 'Välj här';

  @override
  String get cannotOpenFolder => 'Mappen kan inte öppnas';

  @override
  String get fileNamePattern => 'Filnamn eller mönster';

  @override
  String get searchHint => 't.ex. *.pdf eller rapport';

  @override
  String get wholeStorage => 'Hela lagringen';

  @override
  String get searchWholeStorage => 'Sök i hela lagringen';

  @override
  String get fromDate => 'Från datum';

  @override
  String get toDate => 'Till datum';

  @override
  String get clearDates => 'Rensa datum';

  @override
  String get search => 'Sök';

  @override
  String scannedCount(Object count) {
    return 'Genomsökt $count objekt…';
  }

  @override
  String get noResults => 'Inga resultat ännu';

  @override
  String get emptyBinQ => 'Tömma papperskorgen?';

  @override
  String get emptyBinBody =>
      'Alla objekt tas bort permanent. Detta kan inte ångras.';

  @override
  String get emptyBin => 'Töm';

  @override
  String get binEmptied => 'Papperskorgen tömd';

  @override
  String get binEmpty => 'Papperskorgen är tom';

  @override
  String get restore => 'Återställ';

  @override
  String get restored => 'Återställd';

  @override
  String get deleteForeverQ => 'Ta bort permanent?';

  @override
  String get extractAll => 'Packa upp allt';

  @override
  String get archiveEmpty => 'Arkivet är tomt';

  @override
  String archiveReadError(Object error) {
    return 'Kunde inte läsa arkivet: $error';
  }

  @override
  String extractedTo(Object path) {
    return 'Packat upp till $path';
  }

  @override
  String extractFailed(Object error) {
    return 'Uppackning misslyckades: $error';
  }

  @override
  String cannotPlay(Object error) {
    return 'Kan inte spela upp: $error';
  }

  @override
  String get pcReconnecting => 'Datorn nås inte — återansluter automatiskt…';

  @override
  String get pcRejected =>
      'Datorn känner inte längre igen telefonen. Skanna QR-koden igen.';

  @override
  String get pcUnreachableHint =>
      'Når inte datorn. Kontrollera att Nova Transfer är öppen, att båda enheterna är på samma Wi-Fi och att Windows-brandväggen tillåter Nova Transfer.';
}

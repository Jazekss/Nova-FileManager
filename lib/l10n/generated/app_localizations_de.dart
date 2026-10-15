// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Nova File Manager';

  @override
  String get navHome => 'Start';

  @override
  String get navFiles => 'Dateien';

  @override
  String get navSearch => 'Suche';

  @override
  String get permTitle => 'Speicherzugriff erforderlich';

  @override
  String get permBody =>
      'Nova benötigt den Zugriff „Alle Dateien“, um Dateien im internen Speicher und auf der SD-Karte zu durchsuchen, zu kopieren und zu verschieben.\n\nSelbst damit blockiert Android den Zugriff auf Android/data-Ordner anderer Apps, und echte Systemdateien erfordern Root.';

  @override
  String get permGrant => 'Zugriff erlauben';

  @override
  String get permContinueLimited => 'Mit eingeschränktem Zugriff fortfahren';

  @override
  String get settings => 'Einstellungen';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get sizeUnits => 'Größeneinheiten';

  @override
  String get unitAuto => 'Auto';

  @override
  String get showHidden => 'Versteckte Dateien anzeigen';

  @override
  String get showHiddenSubtitle =>
      'Dateien und Ordner, die mit einem Punkt beginnen';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get about => 'Über';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get developerLine => 'Entwickelt von JKdizains — jkdizains.lv';

  @override
  String get developerThanks =>
      'Von einer einzigen Person entwickelt. Danke für deine Unterstützung!';

  @override
  String get coffeeButton => 'Spendiere mir einen Kaffee';

  @override
  String get storage => 'Speicher';

  @override
  String get internalStorage => 'Interner Speicher';

  @override
  String get sdCard => 'SD-Karte';

  @override
  String get save => 'Speichern';

  @override
  String get saved => 'Gespeichert';

  @override
  String get fileTooLarge => 'Datei ist zu groß zum Bearbeiten';

  @override
  String get change => 'Ändern';

  @override
  String get renameExtWarnTitle => 'Erweiterung ändern?';

  @override
  String renameExtWarnBody(String oldExt, String newExt) {
    return 'Das Ändern von $oldExt auf $newExt kann dazu führen, dass andere Apps die Datei nicht mehr öffnen.';
  }

  @override
  String get shareWifi => 'Per WLAN teilen';

  @override
  String get wifiTransfer => 'WLAN-Übertragung';

  @override
  String get wifiCardSubtitle =>
      'Dateien mit einem Computer senden und empfangen';

  @override
  String get wifiOpenHint => 'Öffne diese Adresse am Computer (gleiches WLAN)';

  @override
  String get wifiSharedFiles => 'Geteilte Dateien';

  @override
  String wifiUploadNote(String path) {
    return 'Uploads werden in $path gespeichert';
  }

  @override
  String wifiReceived(String name) {
    return 'Empfangen: $name';
  }

  @override
  String get wifiStop => 'Freigabe stoppen';

  @override
  String get vault => 'Tresor';

  @override
  String get vaultCardSubtitle => 'Verschlüsselte private Dateien';

  @override
  String get vaultUnlockReason => 'Tresor entsperren';

  @override
  String get vaultSetPin => 'PIN festlegen (4–8 Ziffern)';

  @override
  String get vaultEnterPin => 'Tresor-PIN eingeben';

  @override
  String get vaultUnlock => 'Entsperren';

  @override
  String get vaultUseBiometric => 'Biometrie verwenden';

  @override
  String get vaultPinTooShort => 'PIN muss mindestens 4 Ziffern haben';

  @override
  String get vaultWrongPin => 'Falsche PIN';

  @override
  String get vaultEmpty => 'Tresor ist leer';

  @override
  String get vaultEmptyHint =>
      'Dateien hierher verschieben: Kontextmenü der Datei → In Tresor verschieben';

  @override
  String get vaultExport => 'Aus Tresor exportieren';

  @override
  String get movedToVault => 'In Tresor verschoben';

  @override
  String get exported => 'Exportiert';

  @override
  String get moveToVault => 'In Tresor verschieben';

  @override
  String get convertTo => 'Konvertieren zu';

  @override
  String get converted => 'Konvertiert';

  @override
  String get convertFailed => 'Datei konnte nicht konvertiert werden';

  @override
  String get download => 'Herunterladen';

  @override
  String get downloaded => 'Heruntergeladen';

  @override
  String get upload => 'Hochladen';

  @override
  String get uploaded => 'Hochgeladen';

  @override
  String get signOut => 'Abmelden';

  @override
  String get driveIntro =>
      'Melde dich an, um deine Google-Drive-Dateien zu durchsuchen und zu verwalten.';

  @override
  String get driveScopeNote =>
      'Nova nutzt die kleinste Drive-Berechtigung: Es sieht nur Dateien, die die App selbst erstellt oder darüber geöffnet hat.';

  @override
  String get driveSignIn => 'Mit Google anmelden';

  @override
  String get driveSignInFailed => 'Anmeldung abgebrochen oder fehlgeschlagen';

  @override
  String get driveTrashQ => 'In den Drive-Papierkorb verschieben?';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get sharedToPc => 'An PC freigegeben';

  @override
  String get pairWithPc => 'Mit dem Computer koppeln';

  @override
  String get pcPairHint =>
      'Öffne Nova File Manager Desktop auf dem PC und zeige den Kopplungs-QR im Verbindungsmenü.';

  @override
  String get invalidPairLink => 'Ungültiger Kopplungslink';

  @override
  String get uploadHere => 'Hier hochladen';

  @override
  String get sharePhoneFolder => 'Telefonordner freigeben';

  @override
  String get pairFailed => 'Kopplung fehlgeschlagen';

  @override
  String get pair => 'Koppeln';

  @override
  String get disconnect => 'Trennen';

  @override
  String get scanQr => 'QR scannen';

  @override
  String get pcShare => 'PC-Freigabe';

  @override
  String get enterManually => 'Link manuell eingeben';

  @override
  String get enterPairLink => 'Kopplungslink eingeben';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get pressAgainToExit => 'Zum Beenden erneut zurück drücken';

  @override
  String get shareThumbs => 'Miniaturen in PC-Freigabe';

  @override
  String get shareThumbsNote =>
      'Zeigt Bild-/Video-/APK-Vorschauen beim PC-Ordner-Browsing — lädt langsamer.';

  @override
  String get noStorage => 'Keine Speicher gefunden';

  @override
  String get notAvailable => 'Nicht verfügbar';

  @override
  String get noData => 'Keine Daten';

  @override
  String freeOf(Object free, Object total) {
    return '$free frei von $total';
  }

  @override
  String get installedApps => 'Installierte Apps';

  @override
  String get recycleBin => 'Papierkorb';

  @override
  String binItems(Object count, Object size) {
    return '$count Elemente · $size';
  }

  @override
  String get quickAccess => 'Schnellzugriff';

  @override
  String get androidLimits => 'Android-Einschränkungen';

  @override
  String get limitData =>
      'Android/data und Android/obb anderer Apps werden von Android 11+ blockiert, auch mit Zugriff auf alle Dateien.';

  @override
  String get limitSystem =>
      'Echte Systemdateien (/system, /data) erfordern Root — diese App nutzt kein Root.';

  @override
  String get limitSd =>
      'Auf manchen Geräten erfordern Schreibzugriffe auf die SD-Karte eine Freigabe über die Systemauswahl.';

  @override
  String get fileManager => 'Dateimanager';

  @override
  String get newFolder => 'Neuer Ordner';

  @override
  String get folderName => 'Ordnername';

  @override
  String get select => 'Auswählen';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get openWith => 'Öffnen mit';

  @override
  String get rename => 'Umbenennen';

  @override
  String get copyTo => 'Kopieren nach...';

  @override
  String get moveTo => 'Verschieben nach...';

  @override
  String get createZip => 'ZIP erstellen';

  @override
  String get properties => 'Eigenschaften';

  @override
  String get delete => 'Löschen';

  @override
  String get view => 'Ansicht';

  @override
  String get viewDetailed => 'Detaillierte Liste';

  @override
  String get viewSmall => 'Kleine Symbole';

  @override
  String get viewLarge => 'Große Symbole';

  @override
  String get sort => 'Sortieren';

  @override
  String get sortName => 'Name';

  @override
  String get sortSize => 'Größe';

  @override
  String get sortDate => 'Datum';

  @override
  String selectedCount(Object count) {
    return '$count ausgewählt';
  }

  @override
  String deleteTitle(Object count) {
    return '$count Element(e) löschen?';
  }

  @override
  String get deleteBody =>
      'In den Papierkorb verschieben, um sie später wiederherzustellen, oder endgültig löschen.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Schließen';

  @override
  String get deletePermanently => 'Endgültig löschen';

  @override
  String get toRecycleBin => 'In den Papierkorb';

  @override
  String get movedToBin => 'In den Papierkorb verschoben';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get moved => 'Verschoben';

  @override
  String get copied => 'Kopiert';

  @override
  String get renamed => 'Umbenannt';

  @override
  String get folderCreated => 'Ordner erstellt';

  @override
  String get zipCreated => 'ZIP erstellt';

  @override
  String get noAppToOpen => 'Keine App zum Öffnen dieser Datei gefunden';

  @override
  String get retry => 'Wiederholen';

  @override
  String get emptyFolder => 'Dieser Ordner ist leer';

  @override
  String get sameFolderError => 'Ziel ist der aktuelle Ordner';

  @override
  String get permissionDeniedError =>
      'Zugriff verweigert. Einige Orte (z. B. Android/data oder Systemordner) sind von Android eingeschränkt und erfordern besonderen Zugriff.';

  @override
  String get typeFolder => 'Ordner';

  @override
  String typeFile(Object ext) {
    return 'Datei (.$ext)';
  }

  @override
  String get propType => 'Typ';

  @override
  String get propPath => 'Pfad';

  @override
  String get propSize => 'Größe';

  @override
  String get propModified => 'Geändert';

  @override
  String get propCreated => 'Erstellt';

  @override
  String get chooseDestination => 'Ziel wählen';

  @override
  String get up => 'Nach oben';

  @override
  String get noSubfolders => 'Keine Unterordner';

  @override
  String get selectHere => 'Hier auswählen';

  @override
  String get cannotOpenFolder => 'Ordner kann nicht geöffnet werden';

  @override
  String get fileNamePattern => 'Dateiname oder Muster';

  @override
  String get searchHint => 'z. B. *.pdf oder bericht';

  @override
  String get wholeStorage => 'Ganzer Speicher';

  @override
  String get searchWholeStorage => 'Ganzen Speicher durchsuchen';

  @override
  String get fromDate => 'Von Datum';

  @override
  String get toDate => 'Bis Datum';

  @override
  String get clearDates => 'Daten löschen';

  @override
  String get search => 'Suchen';

  @override
  String scannedCount(Object count) {
    return '$count Elemente durchsucht…';
  }

  @override
  String get noResults => 'Noch keine Ergebnisse';

  @override
  String get emptyBinQ => 'Papierkorb leeren?';

  @override
  String get emptyBinBody =>
      'Alle Elemente werden endgültig gelöscht. Das kann nicht rückgängig gemacht werden.';

  @override
  String get emptyBin => 'Leeren';

  @override
  String get binEmptied => 'Papierkorb geleert';

  @override
  String get binEmpty => 'Papierkorb ist leer';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get restored => 'Wiederhergestellt';

  @override
  String get deleteForeverQ => 'Endgültig löschen?';

  @override
  String get extractAll => 'Alle entpacken';

  @override
  String get archiveEmpty => 'Archiv ist leer';

  @override
  String archiveReadError(Object error) {
    return 'Archiv konnte nicht gelesen werden: $error';
  }

  @override
  String extractedTo(Object path) {
    return 'Entpackt nach $path';
  }

  @override
  String extractFailed(Object error) {
    return 'Entpacken fehlgeschlagen: $error';
  }

  @override
  String cannotPlay(Object error) {
    return 'Wiedergabe nicht möglich: $error';
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nova File Manager';

  @override
  String get navHome => 'Home';

  @override
  String get navFiles => 'Files';

  @override
  String get navSearch => 'Search';

  @override
  String get permTitle => 'Storage access required';

  @override
  String get permBody =>
      'Nova needs \"All files access\" to browse, copy and move files on internal storage and SD card.\n\nEven with it, Android blocks access to other apps\' Android/data folders, and true system files need root.';

  @override
  String get permGrant => 'Grant access';

  @override
  String get permContinueLimited => 'Continue with limited access';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sizeUnits => 'Size units';

  @override
  String get unitAuto => 'Auto';

  @override
  String get showHidden => 'Show hidden files';

  @override
  String get showHiddenSubtitle => 'Files and folders starting with a dot';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get about => 'About';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get developerLine => 'Developed by JKdizains — jkdizains.lv';

  @override
  String get developerThanks =>
      'Built single-handedly. Thank you for your support!';

  @override
  String get coffeeButton => 'Buy me a coffee';

  @override
  String get storage => 'Storage';

  @override
  String get internalStorage => 'Internal storage';

  @override
  String get sdCard => 'SD card';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get fileTooLarge => 'File is too large to edit';

  @override
  String get change => 'Change';

  @override
  String get renameExtWarnTitle => 'Change extension?';

  @override
  String renameExtWarnBody(String oldExt, String newExt) {
    return 'Changing $oldExt to $newExt may make the file unusable by other apps.';
  }

  @override
  String get shareWifi => 'Share via Wi-Fi';

  @override
  String get wifiTransfer => 'Wi-Fi transfer';

  @override
  String get wifiCardSubtitle => 'Send and receive files with a computer';

  @override
  String get wifiOpenHint =>
      'Open this address on your computer (same Wi-Fi network)';

  @override
  String get wifiSharedFiles => 'Shared files';

  @override
  String wifiUploadNote(String path) {
    return 'Uploads are saved to $path';
  }

  @override
  String wifiReceived(String name) {
    return 'Received: $name';
  }

  @override
  String get wifiStop => 'Stop sharing';

  @override
  String get vault => 'Vault';

  @override
  String get vaultCardSubtitle => 'Encrypted private files';

  @override
  String get vaultUnlockReason => 'Unlock your vault';

  @override
  String get vaultSetPin => 'Set a PIN (4–8 digits)';

  @override
  String get vaultEnterPin => 'Enter vault PIN';

  @override
  String get vaultUnlock => 'Unlock';

  @override
  String get vaultUseBiometric => 'Use biometrics';

  @override
  String get vaultPinTooShort => 'PIN must be at least 4 digits';

  @override
  String get vaultWrongPin => 'Wrong PIN';

  @override
  String get vaultEmpty => 'Vault is empty';

  @override
  String get vaultEmptyHint =>
      'Move files here via a file\'s context menu → Move to Vault';

  @override
  String get vaultExport => 'Export from vault';

  @override
  String get movedToVault => 'Moved to vault';

  @override
  String get exported => 'Exported';

  @override
  String get moveToVault => 'Move to Vault';

  @override
  String get convertTo => 'Convert to';

  @override
  String get converted => 'Converted';

  @override
  String get convertFailed => 'Could not convert this file';

  @override
  String get download => 'Download';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get upload => 'Upload';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get signOut => 'Sign out';

  @override
  String get driveIntro =>
      'Sign in to browse and manage your Google Drive files.';

  @override
  String get driveScopeNote =>
      'Nova uses the smallest Drive permission: it can only see files the app itself created or opened.';

  @override
  String get driveSignIn => 'Sign in with Google';

  @override
  String get driveSignInFailed => 'Sign-in cancelled or failed';

  @override
  String get driveTrashQ => 'Move to Drive trash?';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get sharedToPc => 'Shared to PC';

  @override
  String get sharedFromPc => 'Shared from PC';

  @override
  String get pairWithPc => 'Pair with your computer';

  @override
  String get pcPairHint =>
      'Open Nova File Manager Desktop on your PC and show the pairing QR in the connection menu.';

  @override
  String get invalidPairLink => 'Invalid pairing link';

  @override
  String get uploadHere => 'Upload here';

  @override
  String get sharePhoneFolder => 'Share a phone folder';

  @override
  String get pairFailed => 'Pairing failed';

  @override
  String get pair => 'Pair';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get pcShare => 'PC share';

  @override
  String get enterManually => 'Enter link manually';

  @override
  String get enterPairLink => 'Enter pairing link';

  @override
  String get refresh => 'Refresh';

  @override
  String get pressAgainToExit => 'Press back again to exit';

  @override
  String get shareThumbs => 'Thumbnails in PC share';

  @override
  String get shareThumbsNote =>
      'Shows image/video/APK previews when browsing PC folders — makes list loading slower.';

  @override
  String get noStorage => 'No storage volumes found';

  @override
  String get notAvailable => 'Not available';

  @override
  String get noData => 'No data';

  @override
  String freeOf(Object free, Object total) {
    return '$free free of $total';
  }

  @override
  String get installedApps => 'Installed apps';

  @override
  String get recycleBin => 'Recycle bin';

  @override
  String binItems(Object count, Object size) {
    return '$count items · $size';
  }

  @override
  String get quickAccess => 'Quick access';

  @override
  String get androidLimits => 'Android limits';

  @override
  String get limitData =>
      'Android/data and Android/obb of other apps are blocked by Android 11+, even with All files access.';

  @override
  String get limitSystem =>
      'True system files (/system, /data) require root — this app does not use root.';

  @override
  String get limitSd =>
      'On some devices SD card writes may require granting access via the system picker.';

  @override
  String get fileManager => 'File Manager';

  @override
  String get newFolder => 'New folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get select => 'Select';

  @override
  String get selectAll => 'Select all';

  @override
  String get openWith => 'Open with';

  @override
  String get rename => 'Rename';

  @override
  String get copyTo => 'Copy to...';

  @override
  String get moveTo => 'Move to...';

  @override
  String get createZip => 'Create ZIP';

  @override
  String get properties => 'Properties';

  @override
  String get delete => 'Delete';

  @override
  String get view => 'View';

  @override
  String get viewDetailed => 'Detailed list';

  @override
  String get viewSmall => 'Small icons';

  @override
  String get viewLarge => 'Large icons';

  @override
  String get sort => 'Sort';

  @override
  String get sortName => 'Name';

  @override
  String get sortSize => 'Size';

  @override
  String get sortDate => 'Date';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String deleteTitle(Object count) {
    return 'Delete $count item(s)?';
  }

  @override
  String get deleteBody =>
      'Move to the recycle bin to be able to restore them later, or delete permanently.';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String get toRecycleBin => 'To recycle bin';

  @override
  String get movedToBin => 'Moved to recycle bin';

  @override
  String get deleted => 'Deleted';

  @override
  String get moved => 'Moved';

  @override
  String get copied => 'Copied';

  @override
  String get renamed => 'Renamed';

  @override
  String get folderCreated => 'Folder created';

  @override
  String get zipCreated => 'ZIP created';

  @override
  String get noAppToOpen => 'No app found to open this file';

  @override
  String get retry => 'Retry';

  @override
  String get emptyFolder => 'This folder is empty';

  @override
  String get sameFolderError => 'Destination is the current folder';

  @override
  String get permissionDeniedError =>
      'Permission denied. Some locations (e.g. Android/data or system folders) are restricted by Android and require special access.';

  @override
  String get typeFolder => 'Folder';

  @override
  String typeFile(Object ext) {
    return 'File (.$ext)';
  }

  @override
  String get propType => 'Type';

  @override
  String get propPath => 'Path';

  @override
  String get propSize => 'Size';

  @override
  String get propModified => 'Modified';

  @override
  String get propCreated => 'Created';

  @override
  String get chooseDestination => 'Choose destination';

  @override
  String get up => 'Up';

  @override
  String get noSubfolders => 'No subfolders';

  @override
  String get selectHere => 'Select here';

  @override
  String get cannotOpenFolder => 'Cannot open this folder';

  @override
  String get fileNamePattern => 'File name or pattern';

  @override
  String get searchHint => 'e.g. *.pdf or report';

  @override
  String get wholeStorage => 'Whole storage';

  @override
  String get searchWholeStorage => 'Search whole storage';

  @override
  String get fromDate => 'From date';

  @override
  String get toDate => 'To date';

  @override
  String get clearDates => 'Clear dates';

  @override
  String get search => 'Search';

  @override
  String scannedCount(Object count) {
    return 'Scanned $count items…';
  }

  @override
  String get noResults => 'No results yet';

  @override
  String get emptyBinQ => 'Empty recycle bin?';

  @override
  String get emptyBinBody =>
      'All items will be permanently deleted. This cannot be undone.';

  @override
  String get emptyBin => 'Empty bin';

  @override
  String get binEmptied => 'Bin emptied';

  @override
  String get binEmpty => 'Recycle bin is empty';

  @override
  String get restore => 'Restore';

  @override
  String get restored => 'Restored';

  @override
  String get deleteForeverQ => 'Delete permanently?';

  @override
  String get extractAll => 'Extract all';

  @override
  String get archiveEmpty => 'Archive is empty';

  @override
  String archiveReadError(Object error) {
    return 'Could not read archive: $error';
  }

  @override
  String extractedTo(Object path) {
    return 'Extracted to $path';
  }

  @override
  String extractFailed(Object error) {
    return 'Extract failed: $error';
  }

  @override
  String cannotPlay(Object error) {
    return 'Cannot play: $error';
  }

  @override
  String get pcReconnecting => 'PC not reachable — reconnecting automatically…';

  @override
  String get pcRejected =>
      'The PC no longer recognises this phone. Scan the QR code again.';

  @override
  String get pcUnreachableHint =>
      'Can\'t reach the PC. Make sure Nova Transfer is open, both devices are on the same Wi-Fi, and Windows Firewall allows Nova Transfer.';

  @override
  String get otherDevices => 'Other devices';

  @override
  String get otherDevicesHint =>
      'Link your other computers and phones to move files fast. Nova must be open on both devices; paired devices reconnect by themselves.';

  @override
  String get thisDevice => 'This device';

  @override
  String get deviceName => 'Device name';

  @override
  String get devices => 'Devices';

  @override
  String get addDevice => 'Add device';

  @override
  String get pairCode => 'Code';

  @override
  String get deviceAddress => 'Address';

  @override
  String get pairCodeWrong => 'Wrong or expired code — check it and try again.';

  @override
  String get deviceUnreachable =>
      'Can\'t reach the device. Is Nova open there and on the same Wi-Fi?';

  @override
  String get noDevices => 'No devices yet';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline — open Nova on it';

  @override
  String get deviceRejected => 'This device removed the pairing';

  @override
  String get removeDevice => 'Remove device';

  @override
  String get removeDeviceNote =>
      'Both devices forget each other. To link them again you need a new code.';

  @override
  String get shareWith => 'Share with';

  @override
  String get shareAll => 'All paired devices';

  @override
  String get deviceOffline =>
      'The device isn\'t answering — open Nova on it and keep it on the same Wi-Fi.';

  @override
  String pairedWith(String name) {
    return 'Linked with $name';
  }

  @override
  String receivedFrom(String name, String file) {
    return 'Received from $name: $file';
  }

  @override
  String get otherDevicesCard => 'Extra computers and phones';

  @override
  String get scanOtherQr => 'Scan the other device\'s QR';

  @override
  String get showMyQr => 'Show this phone\'s QR';

  @override
  String get enterAddressCode => 'Enter address and code';

  @override
  String get pcAddress => 'PC address';

  @override
  String get myQrHint =>
      'On the other device open Nova → Other devices → Add device, then scan this QR or type the address and code. The code works once.';

  @override
  String get sharedWithDevices => 'Shared from this phone';

  @override
  String get shareScopeAll => 'All devices';

  @override
  String get addShare => 'Share a folder or file';

  @override
  String get appsCardSubtitle => 'Sizes, last use, uninstall';

  @override
  String get files => 'Files';

  @override
  String get filesCardSubtitle =>
      'Photos, videos, documents and more by category';

  @override
  String get uninstall => 'Uninstall';

  @override
  String uninstallQ(int count) {
    return 'Uninstall $count apps?';
  }

  @override
  String get uninstallNote =>
      'Android asks to confirm each app. Uninstalling also removes the app\'s cache and private data; folders it left in your storage are offered for deletion afterwards.';

  @override
  String uninstalledCount(int count) {
    return '$count apps uninstalled';
  }

  @override
  String get total => 'Total';

  @override
  String get appInfo => 'App info';

  @override
  String get appInfoNote =>
      'Clear this app\'s cache or data in Android settings';

  @override
  String get cleaner => 'Cleaner';

  @override
  String get sortBySize => 'Size';

  @override
  String get sortByLastUsed => 'Last used (oldest first)';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByDate => 'Date';

  @override
  String appsSummary(int count, String size) {
    return '$count apps · $size';
  }

  @override
  String get cacheTotal => 'Cache';

  @override
  String get usageAccessTitle => 'Allow \"Usage access\"';

  @override
  String get usageAccessNote =>
      'Needed to show full app sizes, cache and when each app was last used.';

  @override
  String get allow => 'Allow';

  @override
  String get neverUsed => 'Not used recently';

  @override
  String get lastUsedUnknown => 'Last use: allow Usage access';

  @override
  String get lastUsed => 'Last used';

  @override
  String get leftoversTitle => 'Folders left behind';

  @override
  String get leftoversNote =>
      'These folders belonged to the removed apps. Untick anything you want to keep.';

  @override
  String get keep => 'Keep';

  @override
  String deletedCount(int count) {
    return '$count items deleted';
  }

  @override
  String get rescan => 'Scan again';

  @override
  String get clearAllCaches => 'Clear all app caches';

  @override
  String get clearAllCachesQ => 'Clear all app caches?';

  @override
  String get clearAllCachesNote =>
      'Android will ask you to confirm. Apps keep their data and logins — only temporary files are removed and rebuilt when needed.';

  @override
  String get clearAllCachesUnavailable =>
      'Needs Android 11+ and \"All files access\". On older Android open an app\'s info page to clear its cache.';

  @override
  String get clear => 'Clear';

  @override
  String deleteJunkQ(int count) {
    return 'Delete $count items?';
  }

  @override
  String get deleteJunkNote =>
      'This is permanent — the items do not go to the recycle bin.';

  @override
  String get junkThumbs => 'Thumbnail caches';

  @override
  String get junkTemp => 'Temporary files';

  @override
  String get junkCacheDirs => 'Cache folders';

  @override
  String get junkTempDirs => '\"Temp\" folders (check before deleting)';

  @override
  String get junkLogs => 'Log files';

  @override
  String get junkEmpty => 'Empty folders';

  @override
  String get junkLeftovers => 'Left by uninstalled apps';

  @override
  String get junkNova => 'Nova temporary files';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get scanning => 'Scanning…';

  @override
  String get appCaches => 'App caches';

  @override
  String get appCachesNote =>
      'Tap an app to open its settings and clear only that app.';

  @override
  String get junkFiles => 'Unneeded files';

  @override
  String get selectNone => 'Select none';

  @override
  String get noJunk => 'Nothing to clean — nice!';

  @override
  String get catImages => 'Images';

  @override
  String get catVideos => 'Videos';

  @override
  String get catAudio => 'Audio';

  @override
  String get catDocuments => 'Documents';

  @override
  String get catArchives => 'Archives';

  @override
  String get catApks => 'Installers (APK)';

  @override
  String get catLarge => 'Large files (100 MB+)';

  @override
  String get catOther => 'Other files';

  @override
  String moveToBinQ(int count) {
    return 'Move $count files to the recycle bin?';
  }

  @override
  String get moveToBinNote => 'You can restore them from the recycle bin.';

  @override
  String movedToBinN(int count) {
    return '$count moved to the recycle bin';
  }

  @override
  String moveFilesQ(int count) {
    return 'Move $count files here?';
  }

  @override
  String get move => 'Move';

  @override
  String movedCount(int count) {
    return '$count files moved';
  }

  @override
  String get pcAddressHelp =>
      'Use the address and code from Nova Transfer → Connection (not \"Other devices\").';

  @override
  String get pcAddressBad =>
      'Type the PC address like 192.168.1.10 or 192.168.1.10:48320';

  @override
  String get pcOtherDevicesCode =>
      'That address/code belongs to \"Other devices\". For your own PC use Nova Transfer → Connection; for extra devices use Nova → Other devices.';
}

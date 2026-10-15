import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_et.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('et'),
    Locale('lt'),
    Locale('lv'),
    Locale('nb'),
    Locale('pl'),
    Locale('ru'),
    Locale('sv'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Nova File Manager'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get navFiles;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @permTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage access required'**
  String get permTitle;

  /// No description provided for @permBody.
  ///
  /// In en, this message translates to:
  /// **'Nova needs \"All files access\" to browse, copy and move files on internal storage and SD card.\n\nEven with it, Android blocks access to other apps\' Android/data folders, and true system files need root.'**
  String get permBody;

  /// No description provided for @permGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get permGrant;

  /// No description provided for @permContinueLimited.
  ///
  /// In en, this message translates to:
  /// **'Continue with limited access'**
  String get permContinueLimited;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @sizeUnits.
  ///
  /// In en, this message translates to:
  /// **'Size units'**
  String get sizeUnits;

  /// No description provided for @unitAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get unitAuto;

  /// No description provided for @showHidden.
  ///
  /// In en, this message translates to:
  /// **'Show hidden files'**
  String get showHidden;

  /// No description provided for @showHiddenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Files and folders starting with a dot'**
  String get showHiddenSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(Object version);

  /// No description provided for @developerLine.
  ///
  /// In en, this message translates to:
  /// **'Developed by JKdizains — jkdizains.lv'**
  String get developerLine;

  /// No description provided for @developerThanks.
  ///
  /// In en, this message translates to:
  /// **'Built single-handedly. Thank you for your support!'**
  String get developerThanks;

  /// No description provided for @coffeeButton.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get coffeeButton;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @internalStorage.
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get internalStorage;

  /// No description provided for @sdCard.
  ///
  /// In en, this message translates to:
  /// **'SD card'**
  String get sdCard;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large to edit'**
  String get fileTooLarge;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @renameExtWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Change extension?'**
  String get renameExtWarnTitle;

  /// No description provided for @renameExtWarnBody.
  ///
  /// In en, this message translates to:
  /// **'Changing {oldExt} to {newExt} may make the file unusable by other apps.'**
  String renameExtWarnBody(String oldExt, String newExt);

  /// No description provided for @shareWifi.
  ///
  /// In en, this message translates to:
  /// **'Share via Wi-Fi'**
  String get shareWifi;

  /// No description provided for @wifiTransfer.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi transfer'**
  String get wifiTransfer;

  /// No description provided for @wifiCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send and receive files with a computer'**
  String get wifiCardSubtitle;

  /// No description provided for @wifiOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Open this address on your computer (same Wi-Fi network)'**
  String get wifiOpenHint;

  /// No description provided for @wifiSharedFiles.
  ///
  /// In en, this message translates to:
  /// **'Shared files'**
  String get wifiSharedFiles;

  /// No description provided for @wifiUploadNote.
  ///
  /// In en, this message translates to:
  /// **'Uploads are saved to {path}'**
  String wifiUploadNote(String path);

  /// No description provided for @wifiReceived.
  ///
  /// In en, this message translates to:
  /// **'Received: {name}'**
  String wifiReceived(String name);

  /// No description provided for @wifiStop.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get wifiStop;

  /// No description provided for @vault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vault;

  /// No description provided for @vaultCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted private files'**
  String get vaultCardSubtitle;

  /// No description provided for @vaultUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock your vault'**
  String get vaultUnlockReason;

  /// No description provided for @vaultSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN (4–8 digits)'**
  String get vaultSetPin;

  /// No description provided for @vaultEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter vault PIN'**
  String get vaultEnterPin;

  /// No description provided for @vaultUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get vaultUnlock;

  /// No description provided for @vaultUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get vaultUseBiometric;

  /// No description provided for @vaultPinTooShort.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 digits'**
  String get vaultPinTooShort;

  /// No description provided for @vaultWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get vaultWrongPin;

  /// No description provided for @vaultEmpty.
  ///
  /// In en, this message translates to:
  /// **'Vault is empty'**
  String get vaultEmpty;

  /// No description provided for @vaultEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Move files here via a file\'s context menu → Move to Vault'**
  String get vaultEmptyHint;

  /// No description provided for @vaultExport.
  ///
  /// In en, this message translates to:
  /// **'Export from vault'**
  String get vaultExport;

  /// No description provided for @movedToVault.
  ///
  /// In en, this message translates to:
  /// **'Moved to vault'**
  String get movedToVault;

  /// No description provided for @exported.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exported;

  /// No description provided for @moveToVault.
  ///
  /// In en, this message translates to:
  /// **'Move to Vault'**
  String get moveToVault;

  /// No description provided for @convertTo.
  ///
  /// In en, this message translates to:
  /// **'Convert to'**
  String get convertTo;

  /// No description provided for @converted.
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get converted;

  /// No description provided for @convertFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not convert this file'**
  String get convertFailed;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @driveIntro.
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse and manage your Google Drive files.'**
  String get driveIntro;

  /// No description provided for @driveScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Nova uses the smallest Drive permission: it can only see files the app itself created or opened.'**
  String get driveScopeNote;

  /// No description provided for @driveSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get driveSignIn;

  /// No description provided for @driveSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled or failed'**
  String get driveSignInFailed;

  /// No description provided for @driveTrashQ.
  ///
  /// In en, this message translates to:
  /// **'Move to Drive trash?'**
  String get driveTrashQ;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @sharedToPc.
  ///
  /// In en, this message translates to:
  /// **'Shared to PC'**
  String get sharedToPc;

  /// No description provided for @pairWithPc.
  ///
  /// In en, this message translates to:
  /// **'Pair with your computer'**
  String get pairWithPc;

  /// No description provided for @pcPairHint.
  ///
  /// In en, this message translates to:
  /// **'Open Nova File Manager Desktop on your PC and show the pairing QR in the connection menu.'**
  String get pcPairHint;

  /// No description provided for @invalidPairLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid pairing link'**
  String get invalidPairLink;

  /// No description provided for @uploadHere.
  ///
  /// In en, this message translates to:
  /// **'Upload here'**
  String get uploadHere;

  /// No description provided for @sharePhoneFolder.
  ///
  /// In en, this message translates to:
  /// **'Share a phone folder'**
  String get sharePhoneFolder;

  /// No description provided for @pairFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get pairFailed;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @pcShare.
  ///
  /// In en, this message translates to:
  /// **'PC share'**
  String get pcShare;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter link manually'**
  String get enterManually;

  /// No description provided for @enterPairLink.
  ///
  /// In en, this message translates to:
  /// **'Enter pairing link'**
  String get enterPairLink;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @pressAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressAgainToExit;

  /// No description provided for @shareThumbs.
  ///
  /// In en, this message translates to:
  /// **'Thumbnails in PC share'**
  String get shareThumbs;

  /// No description provided for @shareThumbsNote.
  ///
  /// In en, this message translates to:
  /// **'Shows image/video/APK previews when browsing PC folders — makes list loading slower.'**
  String get shareThumbsNote;

  /// No description provided for @noStorage.
  ///
  /// In en, this message translates to:
  /// **'No storage volumes found'**
  String get noStorage;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @freeOf.
  ///
  /// In en, this message translates to:
  /// **'{free} free of {total}'**
  String freeOf(Object free, Object total);

  /// No description provided for @installedApps.
  ///
  /// In en, this message translates to:
  /// **'Installed apps'**
  String get installedApps;

  /// No description provided for @recycleBin.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin'**
  String get recycleBin;

  /// No description provided for @binItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items · {size}'**
  String binItems(Object count, Object size);

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get quickAccess;

  /// No description provided for @androidLimits.
  ///
  /// In en, this message translates to:
  /// **'Android limits'**
  String get androidLimits;

  /// No description provided for @limitData.
  ///
  /// In en, this message translates to:
  /// **'Android/data and Android/obb of other apps are blocked by Android 11+, even with All files access.'**
  String get limitData;

  /// No description provided for @limitSystem.
  ///
  /// In en, this message translates to:
  /// **'True system files (/system, /data) require root — this app does not use root.'**
  String get limitSystem;

  /// No description provided for @limitSd.
  ///
  /// In en, this message translates to:
  /// **'On some devices SD card writes may require granting access via the system picker.'**
  String get limitSd;

  /// No description provided for @fileManager.
  ///
  /// In en, this message translates to:
  /// **'File Manager'**
  String get fileManager;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @openWith.
  ///
  /// In en, this message translates to:
  /// **'Open with'**
  String get openWith;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @copyTo.
  ///
  /// In en, this message translates to:
  /// **'Copy to...'**
  String get copyTo;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to...'**
  String get moveTo;

  /// No description provided for @createZip.
  ///
  /// In en, this message translates to:
  /// **'Create ZIP'**
  String get createZip;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @viewDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed list'**
  String get viewDetailed;

  /// No description provided for @viewSmall.
  ///
  /// In en, this message translates to:
  /// **'Small icons'**
  String get viewSmall;

  /// No description provided for @viewLarge.
  ///
  /// In en, this message translates to:
  /// **'Large icons'**
  String get viewLarge;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sortSize;

  /// No description provided for @sortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDate;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(Object count);

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} item(s)?'**
  String deleteTitle(Object count);

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'Move to the recycle bin to be able to restore them later, or delete permanently.'**
  String get deleteBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @toRecycleBin.
  ///
  /// In en, this message translates to:
  /// **'To recycle bin'**
  String get toRecycleBin;

  /// No description provided for @movedToBin.
  ///
  /// In en, this message translates to:
  /// **'Moved to recycle bin'**
  String get movedToBin;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @moved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get moved;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @renamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get renamed;

  /// No description provided for @folderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder created'**
  String get folderCreated;

  /// No description provided for @zipCreated.
  ///
  /// In en, this message translates to:
  /// **'ZIP created'**
  String get zipCreated;

  /// No description provided for @noAppToOpen.
  ///
  /// In en, this message translates to:
  /// **'No app found to open this file'**
  String get noAppToOpen;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get emptyFolder;

  /// No description provided for @sameFolderError.
  ///
  /// In en, this message translates to:
  /// **'Destination is the current folder'**
  String get sameFolderError;

  /// No description provided for @permissionDeniedError.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Some locations (e.g. Android/data or system folders) are restricted by Android and require special access.'**
  String get permissionDeniedError;

  /// No description provided for @typeFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get typeFolder;

  /// No description provided for @typeFile.
  ///
  /// In en, this message translates to:
  /// **'File (.{ext})'**
  String typeFile(Object ext);

  /// No description provided for @propType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get propType;

  /// No description provided for @propPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get propPath;

  /// No description provided for @propSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get propSize;

  /// No description provided for @propModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get propModified;

  /// No description provided for @propCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get propCreated;

  /// No description provided for @chooseDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose destination'**
  String get chooseDestination;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get up;

  /// No description provided for @noSubfolders.
  ///
  /// In en, this message translates to:
  /// **'No subfolders'**
  String get noSubfolders;

  /// No description provided for @selectHere.
  ///
  /// In en, this message translates to:
  /// **'Select here'**
  String get selectHere;

  /// No description provided for @cannotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot open this folder'**
  String get cannotOpenFolder;

  /// No description provided for @fileNamePattern.
  ///
  /// In en, this message translates to:
  /// **'File name or pattern'**
  String get fileNamePattern;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. *.pdf or report'**
  String get searchHint;

  /// No description provided for @wholeStorage.
  ///
  /// In en, this message translates to:
  /// **'Whole storage'**
  String get wholeStorage;

  /// No description provided for @searchWholeStorage.
  ///
  /// In en, this message translates to:
  /// **'Search whole storage'**
  String get searchWholeStorage;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get toDate;

  /// No description provided for @clearDates.
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get clearDates;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @scannedCount.
  ///
  /// In en, this message translates to:
  /// **'Scanned {count} items…'**
  String scannedCount(Object count);

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get noResults;

  /// No description provided for @emptyBinQ.
  ///
  /// In en, this message translates to:
  /// **'Empty recycle bin?'**
  String get emptyBinQ;

  /// No description provided for @emptyBinBody.
  ///
  /// In en, this message translates to:
  /// **'All items will be permanently deleted. This cannot be undone.'**
  String get emptyBinBody;

  /// No description provided for @emptyBin.
  ///
  /// In en, this message translates to:
  /// **'Empty bin'**
  String get emptyBin;

  /// No description provided for @binEmptied.
  ///
  /// In en, this message translates to:
  /// **'Bin emptied'**
  String get binEmptied;

  /// No description provided for @binEmpty.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin is empty'**
  String get binEmpty;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get restored;

  /// No description provided for @deleteForeverQ.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get deleteForeverQ;

  /// No description provided for @extractAll.
  ///
  /// In en, this message translates to:
  /// **'Extract all'**
  String get extractAll;

  /// No description provided for @archiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get archiveEmpty;

  /// No description provided for @archiveReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read archive: {error}'**
  String archiveReadError(Object error);

  /// No description provided for @extractedTo.
  ///
  /// In en, this message translates to:
  /// **'Extracted to {path}'**
  String extractedTo(Object path);

  /// No description provided for @extractFailed.
  ///
  /// In en, this message translates to:
  /// **'Extract failed: {error}'**
  String extractFailed(Object error);

  /// No description provided for @cannotPlay.
  ///
  /// In en, this message translates to:
  /// **'Cannot play: {error}'**
  String cannotPlay(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'et',
    'lt',
    'lv',
    'nb',
    'pl',
    'ru',
    'sv',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'et':
      return AppLocalizationsEt();
    case 'lt':
      return AppLocalizationsLt();
    case 'lv':
      return AppLocalizationsLv();
    case 'nb':
      return AppLocalizationsNb();
    case 'pl':
      return AppLocalizationsPl();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

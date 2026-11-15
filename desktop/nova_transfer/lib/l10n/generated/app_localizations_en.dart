// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get pcFolders => 'Shared PC folders';

  @override
  String get phoneFiles => 'Shared from phone';

  @override
  String get addFolder => 'Add folder';

  @override
  String get remove => 'Remove';

  @override
  String get refresh => 'Refresh';

  @override
  String get options => 'Options';

  @override
  String get connection => 'Connection';

  @override
  String get showQr => 'Show pairing QR';

  @override
  String get qrHint => 'Scan this with the Nova app on your phone';

  @override
  String get phoneConnected => 'Phone connected';

  @override
  String get noPhone => 'No phone connected';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeAuto => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Developer';

  @override
  String get buyCoffee => 'Buy me a coffee';

  @override
  String get download => 'Download';

  @override
  String get uploadHere => 'Upload to this folder';

  @override
  String get emptyList => 'Nothing shared yet';

  @override
  String get folderEmpty => 'Folder is empty';

  @override
  String get up => 'Up';

  @override
  String get settings => 'Settings';

  @override
  String get manualCode => 'Or enter manually on the phone:';

  @override
  String get pairUrl => 'Pairing link';

  @override
  String get phoneUnreachable =>
      'Can\'t reach the phone — check it is sharing and on the same Wi-Fi.';

  @override
  String get shareApk => 'Share APK via QR';

  @override
  String get chooseApk => 'Choose .apk file';

  @override
  String get apkQrHint =>
      'Pick an APK first, then scan the QR with your phone camera — the file downloads to Download/.';

  @override
  String get apkScanNow => 'Scan with the phone camera to download this APK.';

  @override
  String get shareThumbs => 'Show thumbnails';

  @override
  String get shareThumbsNote =>
      'Image/video/APK previews — slower list loading.';

  @override
  String get view => 'View';

  @override
  String get rename => 'Rename';

  @override
  String get cancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get managePhone => 'Manage files on phone';

  @override
  String get managePhoneNote =>
      'Select and delete files in the phone\'s shared folders';

  @override
  String get sort => 'Sort';

  @override
  String get sortName => 'Name';

  @override
  String get sortSize => 'Size';

  @override
  String get sortDate => 'Date';

  @override
  String get sortAsc => 'Ascending';

  @override
  String get sortDesc => 'Descending';

  @override
  String get statusReconnecting => 'Reconnecting…';

  @override
  String get statusWaiting => 'Waiting for phone';

  @override
  String get connectTitle => 'Connect your phone';

  @override
  String get connectStep1 => 'On the phone open Nova → PC share';

  @override
  String get connectStep2 => 'Tap “Scan QR” and point the camera at this code';

  @override
  String get connectAuto =>
      'Already paired? Just open Nova on the phone — it reconnects by itself.';

  @override
  String get noNetwork => 'No network connection found on this PC.';

  @override
  String get firewallOk => 'Windows Firewall allows Nova Transfer';

  @override
  String get firewallBlocked =>
      'Windows Firewall is blocking the phone from connecting.';

  @override
  String get firewallUnknown =>
      'If the phone can\'t connect, allow Nova Transfer in Windows Firewall.';

  @override
  String get firewallFix => 'Allow';

  @override
  String get sameWifiHint =>
      'Phone and PC must be on the same network. Guest Wi-Fi often stops devices from seeing each other.';

  @override
  String get phoneShareHint =>
      'Nothing shared yet. On the phone: PC share → ⋮ → Share a phone folder.';

  @override
  String get phoneReconnecting =>
      'Phone isn\'t answering — reconnecting automatically…';

  @override
  String get phoneReconnectHint =>
      'Open Nova on the phone and keep it on the same Wi-Fi — it will reconnect within a few seconds.';

  @override
  String get disconnectNote =>
      'The phone will forget this PC and must scan the QR code again.';

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
  String get myPhone => 'My phone';

  @override
  String get addByAddress => 'Add by address';

  @override
  String get pairOtherHint =>
      'Phone: Nova → Other devices → Add device → scan this QR. Other PC: Other devices → Add by address, then type the address and code.';

  @override
  String get shareOnlyPhone => 'Only my phone';

  @override
  String get shareSelected => 'Only the devices picked below';

  @override
  String get shareNote => 'Your phone always sees every shared folder.';

  @override
  String get scopePhone => 'Phone';

  @override
  String get scopeAll => 'All';

  @override
  String scopeSome(int count) {
    return '+$count devices';
  }

  @override
  String get chooseFolder => 'Choose folder';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get upload => 'Upload';

  @override
  String get manualPair => 'No camera? Type on the phone';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get codeOnce => 'The code works once and changes after use.';

  @override
  String get pickTab => 'Double-click a tab to rename the device';
}

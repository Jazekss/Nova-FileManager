import 'package:flutter/widgets.dart';

import '../../features/file_manager/application/file_browser_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../models/storage_volume.dart';

/// Shortcut for `AppLocalizations.of(context)`.
AppLocalizations l10n(BuildContext context) => AppLocalizations.of(context);

/// Maps error-marker strings produced by controllers to localized text.
/// Unknown/raw messages pass through unchanged.
String localizeError(BuildContext context, String message) {
  switch (message) {
    case FileBrowserController.errorSameFolder:
      return l10n(context).sameFolderError;
    case FileBrowserController.errorPermissionDenied:
      return l10n(context).permissionDeniedError;
    default:
      return message;
  }
}

/// Localized label for a storage volume (platform returns English labels).
String volumeLabel(BuildContext context, StorageVolume volume) =>
    volume.isRemovable ? l10n(context).sdCard : l10n(context).internalStorage;

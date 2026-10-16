import 'package:flutter/material.dart';

import '../../../../core/models/file_entry.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/l10n_ext.dart';
import '../../../../core/widgets/entry_icon.dart';

/// Shared selection checkbox overlay used by all view modes.
class SelectionBadge extends StatelessWidget {
  const SelectionBadge({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 11,
      backgroundColor: selected
          ? Theme.of(context).colorScheme.primary
          : Colors.black45,
      child: Icon(
        selected ? Icons.check : Icons.circle_outlined,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}

/// Detailed list row: thumbnail, name, size/date, and a per-item "⋮" menu.
class FileListTile extends StatelessWidget {
  const FileListTile({
    super.key,
    required this.entry,
    required this.unit,
    required this.selected,
    required this.selectionMode,
    this.highlighted = false,
    this.onTap,
    this.onLongPress,
    this.onMenu,
  });

  final FileEntry entry;
  final SizeUnit unit;
  final bool selected;
  final bool selectionMode;

  /// Soft outline while the entry's context menu is open.
  final bool highlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: highlighted
          ? BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            EntryIcon(entry: entry, size: 44),
            if (selectionMode) SelectionBadge(selected: selected),
          ],
        ),
        title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${entry.isDirectory ? l10n(context).typeFolder : formatBytes(entry.size, unit)}'
          ' · ${formatDateTime(entry.modified)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        selected: selected,
        trailing: selectionMode
            ? null
            : IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: onMenu,
              ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

/// Grid cell — media files get a thumbnail that fills the cell width,
/// other types get a large coloured icon. Small mode shows name only,
/// large mode adds size/date.
class FileGridCell extends StatelessWidget {
  const FileGridCell({
    super.key,
    required this.entry,
    required this.unit,
    required this.selected,
    required this.selectionMode,
    required this.large,
    this.highlighted = false,
    this.onTap,
    this.onLongPress,
  });

  final FileEntry entry;
  final SizeUnit unit;
  final bool selected;
  final bool selectionMode;
  final bool large;

  /// Soft outline while the entry's context menu is open.
  final bool highlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = large ? AppTokens.iconLg : AppTokens.iconMd;
    final isMedia = _isMedia(entry);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? scheme.primaryContainer : null,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: isMedia
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: EntryIcon.fill(entry: entry),
                    )
                  : _iconBlock(scheme, iconSize),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
              child: Column(
                children: [
                  Text(
                    entry.name,
                    maxLines: large ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (large)
                    Text(
                      '${entry.isDirectory ? l10n(context).typeFolder : formatBytes(entry.size, unit)}'
                      ' · ${formatDate(entry.modified)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isMedia(FileEntry e) => EntryIcon.hasThumbnail(e);

  Widget _iconBlock(ColorScheme scheme, double iconSize) {
    return Center(
      child: Stack(
        children: [
          EntryIcon(entry: entry, size: iconSize),
          if (selectionMode)
            Positioned(
              right: 0,
              bottom: 0,
              child: SelectionBadge(selected: selected),
            ),
        ],
      ),
    );
  }
}

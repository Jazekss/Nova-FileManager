import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/file_entry.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/models/storage_volume.dart';
import '../../archive/data/archive_service.dart';
import '../../archive/presentation/archive_viewer_screen.dart';
import '../../drive/data/drive_service.dart';
import '../../drive/presentation/drive_screen.dart';
import '../../media/data/image_convert.dart';
import '../../media/media_router.dart';
import '../../pc_share/presentation/pc_share_screen.dart';
import '../../vault/data/vault_service.dart';
import '../../vault/presentation/vault_screen.dart';
import '../../recycle_bin/application/recycle_bin_controller.dart';
import '../application/file_browser_controller.dart';
import 'widgets/browser_dialogs.dart';
import 'widgets/entry_tile.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileBrowserController>().ensureInitialized();
    });
  }

  Future<void> _openEntry(FileEntry entry) async {
    final browser = context.read<FileBrowserController>();
    if (entry.isDirectory) {
      await browser.navigateTo(entry.path);
      return;
    }
    // Archives open in the built-in viewer.
    if (ArchiveService.isArchive(entry.path)) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArchiveViewerScreen(archivePath: entry.path),
        ),
      );
      return;
    }
    // Media opens in the built-in players when possible.
    if (MediaRouter.canHandle(entry)) {
      final images = browser.entries
          .where((e) => !e.isDirectory && MediaRouter.isImage(e))
          .map((e) => e.path)
          .toList();
      MediaRouter.open(
        context,
        entry,
        images: images,
        onActions: () => _showContextMenu(entry),
      );
      return;
    }
    final opened = await browser.platform.openFile(entry.path);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).noAppToOpen)));
    }
  }

  Future<void> _runOp(Future<String?> Function() op, String doneMsg) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await op();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error != null ? localizeError(context, error) : doneMsg),
      ),
    );
  }

  Future<void> _newFolder() async {
    final browser = context.read<FileBrowserController>();
    final name = await showTextInputDialog(
      context,
      title: l10n(context).newFolder,
      hint: l10n(context).folderName,
    );
    if (name == null || name.isEmpty || !mounted) return;
    await _runOp(() => browser.createFolder(name), l10n(context).folderCreated);
  }

  Future<void> _rename(FileEntry entry) async {
    final browser = context.read<FileBrowserController>();
    final name = await showTextInputDialog(
      context,
      title: l10n(context).rename,
      initialValue: entry.name,
      selectBaseNameOnly: true,
    );
    if (name == null || name.isEmpty || !mounted) return;
    if (name == entry.name) return;
    // Warn when the rename changes the file extension.
    if (!entry.isDirectory && _extensionOf(name) != entry.extension) {
      final ok = await showConfirmDialog(
        context,
        title: l10n(context).renameExtWarnTitle,
        message: l10n(context).renameExtWarnBody(
          '.${entry.extension.isEmpty ? '—' : entry.extension}',
          '.${_extensionOf(name).isEmpty ? '—' : _extensionOf(name)}',
        ),
        confirmLabel: l10n(context).change,
      );
      if (!ok || !mounted) return;
    }
    await _runOp(() => browser.renameEntry(entry, name), l10n(context).renamed);
  }

  static String _extensionOf(String name) {
    final i = name.lastIndexOf('.');
    return i > 0 ? name.substring(i + 1).toLowerCase() : '';
  }

  Future<void> _delete(List<String> paths) async {
    final browser = context.read<FileBrowserController>();
    final bin = context.read<RecycleBinController>();
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n(context).deleteTitle(paths.length)),
        content: Text(l10n(context).deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'forever'),
            child: Text(l10n(context).deletePermanently),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'bin'),
            child: Text(l10n(context).toRecycleBin),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'bin') {
      await _runOp(() async {
        final err = await bin.moveToBin(paths);
        await browser.refresh();
        return err;
      }, l10n(context).movedToBin);
    } else {
      await _runOp(() => browser.deletePaths(paths), l10n(context).deleted);
    }
  }

  Future<void> _createZip(List<String> paths) async {
    final browser = context.read<FileBrowserController>();
    final name = await showTextInputDialog(
      context,
      title: l10n(context).createZip,
      hint: 'archive.zip',
      initialValue: 'archive.zip',
    );
    if (name == null || name.isEmpty || !mounted) return;
    final fileName = name.endsWith('.zip') ? name : '$name.zip';
    await _runOp(() async {
      final err = await ArchiveService.createZip(
        paths,
        '${browser.currentPath}/$fileName',
      );
      await browser.refresh();
      return err;
    }, l10n(context).zipCreated);
  }

  Future<void> _moveToVault(FileEntry entry) async {
    final browser = context.read<FileBrowserController>();
    await _runOp(() async {
      await context.read<VaultService>().moveToVault(entry.path);
      await browser.refresh();
      return null;
    }, l10n(context).movedToVault);
  }

  Future<void> _convertImage(FileEntry entry) async {
    final tr = l10n(context);
    final browser = context.read<FileBrowserController>();
    final fmt = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr.convertTo),
        children: [
          for (final f in ['jpg', 'png', 'webp'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, f),
              child: Text('.${f.toUpperCase()}'),
            ),
        ],
      ),
    );
    if (fmt == null || !mounted) return;
    await _runOp(() async {
      final err = await convertImage(entry.path, fmt);
      await browser.refresh();
      return err == 'unsupported' ? tr.convertFailed : err;
    }, tr.converted);
  }

  Future<void> _copyOrMove(List<String> paths, {required bool move}) async {
    final browser = context.read<FileBrowserController>();
    final dest = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath,
    );
    if (dest == null || !mounted) return;
    await _runOp(
      () => browser.copyOrMove(paths, dest, move: move),
      move ? l10n(context).moved : l10n(context).copied,
    );
  }

  /// Entry whose bottom-sheet menu is open — its tile gets a soft
  /// outline so it's visible among many similar thumbnails.
  String? _menuTargetPath;

  void _showContextMenu(FileEntry entry) {
    final browser = context.read<FileBrowserController>();
    final unit = context.read<SettingsController>().sizeUnit;
    setState(() => _menuTargetPath = entry.path);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.select_all),
                title: Text(l10n(context).select),
                onTap: () {
                  Navigator.pop(sheetContext);
                  browser
                    ..enterSelection()
                    ..toggleSelect(entry);
                },
              ),
              if (!entry.isDirectory)
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: Text(l10n(context).openWith),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openEntry(entry);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: Text(l10n(context).rename),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _rename(entry);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n(context).copyTo),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _copyOrMove([entry.path], move: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move),
                title: Text(l10n(context).moveTo),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _copyOrMove([entry.path], move: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: Text(l10n(context).createZip),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _createZip([entry.path]);
                },
              ),

              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n(context).moveToVault),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _moveToVault(entry);
                },
              ),
              if (MediaRouter.isImage(entry))
                ListTile(
                  leading: const Icon(Icons.transform),
                  title: Text(l10n(context).convertTo),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _convertImage(entry);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n(context).properties),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showPropertiesDialog(context, entry, unit);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n(context).delete),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _delete([entry.path]);
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _menuTargetPath = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<FileBrowserController>();
    final unit = context.watch<SettingsController>().sizeUnit;

    return Scaffold(
      appBar: browser.selectionMode
          ? _selectionAppBar(context, browser)
          : _normalAppBar(context, browser),
      body: Column(
        children: [
          _PathBar(path: browser.currentPath),
          if (browser.operationInProgress) const LinearProgressIndicator(),
          Expanded(child: _buildBody(browser, unit)),
        ],
      ),
    );
  }

  PreferredSizeWidget _normalAppBar(
    BuildContext context,
    FileBrowserController browser,
  ) {
    return AppBar(
      leading: browser.canGoUp
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: browser.goUp,
            )
          : null,
      title: _StorageDropdown(browser: browser),
      actions: [
        IconButton(
          tooltip: l10n(context).newFolder,
          icon: const Icon(Icons.create_new_folder_outlined),
          onPressed: _newFolder,
        ),
        IconButton(
          tooltip: l10n(context).select,
          icon: const Icon(Icons.select_all),
          onPressed: browser.entries.isEmpty ? null : browser.enterSelection,
        ),
        PopupMenuButton<BrowserViewMode>(
          tooltip: l10n(context).view,
          icon: const Icon(Icons.view_list),
          onSelected: browser.setViewMode,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: BrowserViewMode.detailed,
              child: Text(l10n(context).viewDetailed),
            ),
            PopupMenuItem(
              value: BrowserViewMode.smallIcons,
              child: Text(l10n(context).viewSmall),
            ),
            PopupMenuItem(
              value: BrowserViewMode.largeIcons,
              child: Text(l10n(context).viewLarge),
            ),
          ],
        ),
        PopupMenuButton<SortField>(
          tooltip: l10n(context).sort,
          icon: const Icon(Icons.sort),
          onSelected: browser.setSort,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: SortField.name,
              child: Text(l10n(context).sortName),
            ),
            PopupMenuItem(
              value: SortField.size,
              child: Text(l10n(context).sortSize),
            ),
            PopupMenuItem(
              value: SortField.date,
              child: Text(l10n(context).sortDate),
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _selectionAppBar(
    BuildContext context,
    FileBrowserController browser,
  ) {
    final single = browser.selectedPaths.length == 1;
    final paths = browser.selectedPaths.toList();
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: browser.clearSelection,
      ),
      title: Text(l10n(context).selectedCount(browser.selectedPaths.length)),
      actions: [
        IconButton(
          tooltip: l10n(context).selectAll,
          icon: const Icon(Icons.select_all),
          onPressed: browser.selectAll,
        ),
        IconButton(
          tooltip: l10n(context).copyTo,
          icon: const Icon(Icons.copy),
          onPressed: () => _copyOrMove(paths, move: false),
        ),
        IconButton(
          tooltip: l10n(context).moveTo,
          icon: const Icon(Icons.drive_file_move),
          onPressed: () => _copyOrMove(paths, move: true),
        ),
        IconButton(
          tooltip: l10n(context).createZip,
          icon: const Icon(Icons.archive_outlined),
          onPressed: () => _createZip(paths),
        ),
        IconButton(
          tooltip: l10n(context).rename,
          icon: const Icon(Icons.drive_file_rename_outline),
          onPressed: single
              ? () {
                  final entry = browser.entries.firstWhere(
                    (e) => e.path == paths.first,
                  );
                  _rename(entry);
                }
              : null,
        ),
        IconButton(
          tooltip: l10n(context).delete,
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(paths),
        ),
      ],
    );
  }

  Widget _buildBody(FileBrowserController browser, SizeUnit unit) {
    if (browser.loading && browser.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (browser.error != null) {
      return _ErrorState(
        message: localizeError(context, browser.error!),
        onRetry: browser.refresh,
      );
    }
    if (browser.entries.isEmpty) {
      return const _EmptyState();
    }
    void onTap(FileEntry e) {
      if (browser.selectionMode) {
        browser.toggleSelect(e);
      } else {
        _openEntry(e);
      }
    }

    switch (browser.viewMode) {
      case BrowserViewMode.detailed:
        return ListView.builder(
          itemCount: browser.entries.length,
          itemBuilder: (context, i) {
            final e = browser.entries[i];
            return FileListTile(
              entry: e,
              unit: unit,
              selected: browser.selectedPaths.contains(e.path),
              selectionMode: browser.selectionMode,
              highlighted: _menuTargetPath == e.path,
              onTap: () => onTap(e),
              onLongPress: () => _showContextMenu(e),
              onMenu: () => _showContextMenu(e),
            );
          },
        );
      case BrowserViewMode.smallIcons:
      case BrowserViewMode.largeIcons:
        final large = browser.viewMode == BrowserViewMode.largeIcons;
        return GridView.builder(
          padding: const EdgeInsets.all(AppTokens.spacingSm),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: large ? 3 : 5,
            childAspectRatio: large ? 0.75 : 0.9,
          ),
          itemCount: browser.entries.length,
          itemBuilder: (context, i) {
            final e = browser.entries[i];
            return FileGridCell(
              entry: e,
              unit: unit,
              large: large,
              selected: browser.selectedPaths.contains(e.path),
              selectionMode: browser.selectionMode,
              highlighted: _menuTargetPath == e.path,
              onTap: () => onTap(e),
              onLongPress: () => _showContextMenu(e),
            );
          },
        );
    }
  }
}

/// App-bar title: tap opens a dropdown with all storage volumes plus
/// Google Drive (and PC share, when paired).
class _StorageDropdown extends StatelessWidget {
  const _StorageDropdown({required this.browser});

  final FileBrowserController browser;

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    return PopupMenuButton<Object>(
      offset: const Offset(0, kToolbarHeight),
      onSelected: (v) {
        if (v is StorageVolume) {
          browser.switchVolume(v);
        } else if (v == 'drive') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  DriveScreen(service: context.read<DriveService>()),
            ),
          );
        } else if (v == 'vault') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  VaultScreen(service: context.read<VaultService>()),
            ),
          );
        } else if (v == 'pc') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PcShareScreen()),
          );
        }
      },
      itemBuilder: (context) => [
        for (final v in browser.volumes)
          PopupMenuItem(
            value: v,
            child: Row(
              children: [
                Icon(
                  v.isRemovable ? Icons.sd_card : Icons.smartphone,
                  size: 20,
                  color: browser.activeVolume == v
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(volumeLabel(context, v))),
                if (browser.activeVolume == v)
                  Icon(
                    Icons.check,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'drive',
          child: Row(
            children: [
              const Icon(Icons.cloud_outlined, size: 20),
              const SizedBox(width: 8),
              Text('Google Drive · ${tr.comingSoon}'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'vault',
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 20),
              const SizedBox(width: 8),
              Text(tr.vault),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pc',
          child: Row(
            children: [
              const Icon(Icons.desktop_windows_outlined, size: 20),
              const SizedBox(width: 8),
              Text(tr.pcShare),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _displayTitle(context, browser),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  String _displayTitle(BuildContext context, FileBrowserController browser) {
    if (browser.currentPath.isEmpty) return l10n(context).fileManager;
    final volume = browser.activeVolume;
    if (volume != null && browser.currentPath == volume.path) {
      return volumeLabel(context, volume);
    }
    return browser.currentPath.split('/').last;
  }
}

class _PathBar extends StatelessWidget {
  const _PathBar({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingXs,
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        path,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: AppTokens.spacingMd),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.spacingMd),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open, size: 48),
          const SizedBox(height: AppTokens.spacingMd),
          Text(l10n(context).emptyFolder),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../file_manager/application/file_browser_controller.dart';
import '../../file_manager/presentation/widgets/browser_dialogs.dart';
import '../application/recycle_bin_controller.dart';
import '../data/recycle_bin_service.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecycleBinController>().refresh();
    });
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

  Future<void> _moveOut(BinItem item) async {
    final browser = context.read<FileBrowserController>();
    final bin = context.read<RecycleBinController>();
    final dest = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath.isEmpty
          ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
          : browser.currentPath,
    );
    if (dest == null || !mounted) return;
    await _runOp(() => bin.moveOut(item, dest), l10n(context).moved);
  }

  Future<void> _emptyBin() async {
    final ok = await showConfirmDialog(
      context,
      title: l10n(context).emptyBinQ,
      message: l10n(context).emptyBinBody,
      confirmLabel: l10n(context).emptyBin,
    );
    if (!ok || !mounted) return;
    await _runOp(
      () => context.read<RecycleBinController>().empty(),
      l10n(context).binEmptied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bin = context.watch<RecycleBinController>();
    final unit = context.watch<SettingsController>().sizeUnit;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n(context).recycleBin),
        actions: [
          IconButton(
            tooltip: l10n(context).emptyBin,
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: bin.items.isEmpty ? null : _emptyBin,
          ),
        ],
      ),
      body: bin.loading
          ? const Center(child: CircularProgressIndicator())
          : bin.items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_outline, size: 48),
                  const SizedBox(height: AppTokens.spacingMd),
                  Text(l10n(context).binEmpty),
                ],
              ),
            )
          : ListView.builder(
              itemCount: bin.items.length,
              itemBuilder: (context, i) {
                final item = bin.items[i];
                return ListTile(
                  leading: Icon(
                    item.isDirectory ? Icons.folder : Icons.insert_drive_file,
                  ),
                  title: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.originalPath}\n'
                    '${item.isDirectory ? l10n(context).typeFolder : formatBytes(item.size, unit)}'
                    ' · ${formatDateTime(item.deletedAt)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      switch (action) {
                        case 'restore':
                          _runOp(
                            () => context.read<RecycleBinController>().restore(
                              item,
                            ),
                            l10n(context).restored,
                          );
                        case 'move':
                          _moveOut(item);
                        case 'delete':
                          _confirmDelete(item);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'restore',
                        child: Text(l10n(context).restore),
                      ),
                      PopupMenuItem(
                        value: 'move',
                        child: Text(l10n(context).moveTo),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n(context).deletePermanently),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BinItem item) async {
    final ok = await showConfirmDialog(
      context,
      title: l10n(context).deleteForeverQ,
      message: '"${item.name}" — ${l10n(context).deletePermanently}',
    );
    if (!ok || !mounted) return;
    await _runOp(
      () => context.read<RecycleBinController>().deleteForever(item),
      l10n(context).deleted,
    );
  }
}

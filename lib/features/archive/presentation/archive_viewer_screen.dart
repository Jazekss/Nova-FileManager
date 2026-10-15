import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../file_manager/application/file_browser_controller.dart';
import '../../file_manager/presentation/widgets/browser_dialogs.dart';
import '../data/archive_service.dart';

/// Lists archive contents and can extract them to a folder.
class ArchiveViewerScreen extends StatefulWidget {
  const ArchiveViewerScreen({super.key, required this.archivePath});

  final String archivePath;

  @override
  State<ArchiveViewerScreen> createState() => _ArchiveViewerScreenState();
}

class _ArchiveViewerScreenState extends State<ArchiveViewerScreen> {
  List<ArchiveEntryInfo> _entries = [];
  bool _loading = true;
  bool _extracting = false;
  String? _error;

  String get _name =>
      widget.archivePath.substring(widget.archivePath.lastIndexOf('/') + 1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await context.read<ArchiveService>().list(
        widget.archivePath,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10n(context).archiveReadError('$e');
        _loading = false;
      });
    }
  }

  Future<void> _extract() async {
    final browser = context.read<FileBrowserController>();
    final dest = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath.isEmpty
          ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
          : browser.currentPath,
    );
    if (dest == null || !mounted) return;
    setState(() => _extracting = true);
    try {
      await context.read<ArchiveService>().extractAll(widget.archivePath, dest);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n(context).extractedTo(dest))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n(context).extractFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = context.watch<SettingsController>().sizeUnit;
    return Scaffold(
      appBar: AppBar(
        title: Text(_name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: l10n(context).extractAll,
            icon: _extracting
                ? const SizedBox(
                    width: AppTokens.iconSm,
                    height: AppTokens.iconSm,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.unarchive_outlined),
            onPressed: _extracting ? null : _extract,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacingLg),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : _entries.isEmpty
          ? Center(child: Text(l10n(context).archiveEmpty))
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, i) {
                final e = _entries[i];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    e.isDirectory
                        ? Icons.folder_outlined
                        : Icons.insert_drive_file_outlined,
                  ),
                  title: Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: e.isDirectory
                      ? null
                      : Text(formatBytes(e.size, unit)),
                );
              },
            ),
    );
  }
}

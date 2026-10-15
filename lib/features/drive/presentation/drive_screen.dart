import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../file_manager/application/file_browser_controller.dart';
import '../../file_manager/presentation/widgets/browser_dialogs.dart';
import '../data/drive_service.dart';

/// Google Drive browser. Scope is drive.file — the app sees only files it
/// created or the user opened with a Google picker (smallest workable scope;
/// full-Drive browsing needs the restricted drive.readonly scope).
class DriveScreen extends StatefulWidget {
  const DriveScreen({super.key, required this.service});

  final DriveService service;

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  final List<({String id, String name})> _stack = [(id: 'root', name: 'Drive')];
  List<drive.File> _files = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  String get _folderId => _stack.last.id;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.service.trySilentSignIn();
    if (widget.service.isSignedIn) {
      await _load();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final ok = await widget.service.signIn();
    if (!mounted) return;
    if (ok) {
      await _load();
    } else {
      setState(() {
        _loading = false;
        _error =
            '${l10n(context).driveSignInFailed}'
            '${widget.service.lastError != null ? '\n${widget.service.lastError}' : ''}';
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final files = await widget.service.list(_folderId);
      if (!mounted) return;
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() op, String doneMsg) async {
    setState(() => _busy = true);
    try {
      await op();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(doneMsg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(drive.File f) async {
    final browser = context.read<FileBrowserController>();
    final dest = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath.isEmpty
          ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
          : browser.currentPath,
    );
    if (dest == null || !mounted) return;
    await _run(
      () => widget.service.download(f, dest).then((_) {}),
      l10n(context).downloaded,
    );
  }

  Future<void> _upload() async {
    final browser = context.read<FileBrowserController>();
    final path = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath.isEmpty
          ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
          : browser.currentPath,
      pickFiles: true,
    );
    if (path == null || !mounted) return;
    await _run(
      () => widget.service.upload(path, _folderId),
      l10n(context).uploaded,
    );
  }

  Future<void> _newFolder() async {
    final name = await showTextInputDialog(
      context,
      title: l10n(context).newFolder,
      hint: l10n(context).folderName,
    );
    if (name == null || name.isEmpty || !mounted) return;
    await _run(
      () => widget.service.createFolder(name, _folderId).then((_) {}),
      l10n(context).folderCreated,
    );
  }

  Future<void> _rename(drive.File f) async {
    final name = await showTextInputDialog(
      context,
      title: l10n(context).rename,
      initialValue: f.name ?? '',
    );
    if (name == null || name.isEmpty || !mounted) return;
    await _run(() => widget.service.rename(f, name), l10n(context).renamed);
  }

  Future<void> _move(drive.File f) async {
    final dest = await _pickDriveFolder();
    if (dest == null || !mounted) return;
    await _run(() => widget.service.move(f, dest), l10n(context).moved);
  }

  Future<void> _trash(drive.File f) async {
    final ok = await showConfirmDialog(
      context,
      title: l10n(context).driveTrashQ,
      message: '"${f.name}"',
    );
    if (!ok || !mounted) return;
    await _run(() => widget.service.trash(f), l10n(context).deleted);
  }

  /// Simple recursive Drive folder picker for "Move".
  Future<String?> _pickDriveFolder() {
    return showDialog<String>(
      context: context,
      builder: (context) => _DriveFolderPicker(service: widget.service),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    return Scaffold(
      appBar: AppBar(
        leading: _stack.length > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _stack.removeLast();
                  _load();
                },
              )
            : null,
        title: Text(
          widget.service.isSignedIn ? _stack.last.name : 'Google Drive',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.service.isSignedIn)
            IconButton(
              tooltip: tr.signOut,
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await widget.service.signOut();
                setState(() {
                  _files = [];
                  _loading = false;
                });
              },
            ),
        ],
      ),
      floatingActionButton: widget.service.isSignedIn
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'drive_upload',
                  tooltip: tr.upload,
                  onPressed: _busy ? null : _upload,
                  child: const Icon(Icons.upload_file),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                FloatingActionButton.small(
                  heroTag: 'drive_mkdir',
                  tooltip: tr.newFolder,
                  onPressed: _busy ? null : _newFolder,
                  child: const Icon(Icons.create_new_folder_outlined),
                ),
              ],
            )
          : null,
      body: !widget.service.isSignedIn
          ? _buildSignIn(tr)
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacingLg),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : _files.isEmpty
          ? Center(child: Text(tr.emptyFolder))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, i) {
                final f = _files[i];
                final isDir =
                    f.mimeType == 'application/vnd.google-apps.folder';
                return ListTile(
                  leading: Icon(
                    isDir ? Icons.folder : Icons.insert_drive_file_outlined,
                  ),
                  title: Text(
                    f.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: isDir
                      ? null
                      : Text(
                          '${formatBytes(int.tryParse(f.size ?? '') ?? 0, SizeUnit.auto)}'
                          '${f.modifiedTime != null ? ' · ${formatDateTime(f.modifiedTime)}' : ''}',
                        ),
                  onTap: isDir
                      ? () {
                          _stack.add((id: f.id!, name: f.name ?? ''));
                          _load();
                        }
                      : null,
                  trailing: _busy
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (a) {
                            switch (a) {
                              case 'download':
                                _download(f);
                              case 'rename':
                                _rename(f);
                              case 'move':
                                _move(f);
                              case 'delete':
                                _trash(f);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!isDir)
                              PopupMenuItem(
                                value: 'download',
                                child: Text(tr.download),
                              ),
                            PopupMenuItem(
                              value: 'rename',
                              child: Text(tr.rename),
                            ),
                            PopupMenuItem(
                              value: 'move',
                              child: Text(tr.moveTo),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(tr.delete),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }

  Widget _buildSignIn(AppLocalizations tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_outlined, size: 56),
            const SizedBox(height: AppTokens.spacingMd),
            Text(tr.driveIntro, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.spacingMd),
            Text(
              tr.driveScopeNote,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacingLg),
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: Text(tr.driveSignIn),
              onPressed: _signIn,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTokens.spacingMd),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// Navigable Drive-folder picker used by "Move".
class _DriveFolderPicker extends StatefulWidget {
  const _DriveFolderPicker({required this.service});

  final DriveService service;

  @override
  State<_DriveFolderPicker> createState() => _DriveFolderPickerState();
}

class _DriveFolderPickerState extends State<_DriveFolderPicker> {
  final List<({String id, String name})> _stack = [(id: 'root', name: 'Drive')];
  List<drive.File> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final folders = await widget.service.listFolders(_stack.last.id);
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    return AlertDialog(
      title: Text(tr.chooseDestination),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_upward, size: AppTokens.iconSm),
                label: Text(tr.up),
                onPressed: _stack.length <= 1
                    ? null
                    : () {
                        _stack.removeLast();
                        _load();
                      },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _folders.isEmpty
                  ? Center(child: Text(tr.noSubfolders))
                  : ListView(
                      children: [
                        for (final f in _folders)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(f.name ?? ''),
                            onTap: () {
                              _stack.add((id: f.id!, name: f.name ?? ''));
                              _load();
                            },
                          ),
                      ],
                    ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _stack.map((s) => s.name).join(' / '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _stack.last.id),
          child: Text(tr.selectHere),
        ),
      ],
    );
  }
}

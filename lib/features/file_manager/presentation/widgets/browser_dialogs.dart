import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/models/file_entry.dart';
import '../../../../core/models/storage_volume.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/l10n_ext.dart';

/// Text-input dialog used for "new folder" and "rename".
/// When [selectBaseNameOnly] is set, only the part before the last dot is
/// pre-selected, so the extension stays unselected when renaming.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String hint = '',
  bool selectBaseNameOnly = false,
}) {
  final controller = TextEditingController(text: initialValue);
  if (selectBaseNameOnly && initialValue.contains('.')) {
    final dot = initialValue.lastIndexOf('.');
    if (dot > 0) {
      controller.selection = TextSelection(baseOffset: 0, extentOffset: dot);
    }
  }
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(l10n(context).ok),
        ),
      ],
    ),
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel ?? l10n(context).delete),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Properties dialog: name, path, type, size and both timestamps.
void showPropertiesDialog(
  BuildContext context,
  FileEntry entry,
  SizeUnit unit,
) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(entry.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _prop(
            l10n(context).propType,
            entry.isDirectory
                ? l10n(context).typeFolder
                : l10n(context).typeFile(entry.extension),
          ),
          _prop(l10n(context).propPath, entry.path),
          if (!entry.isDirectory)
            _prop(l10n(context).propSize, formatBytes(entry.size, unit)),
          _prop(l10n(context).propModified, formatDateTime(entry.modified)),
          _prop(l10n(context).propCreated, formatDateTime(entry.changed)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n(context).close),
        ),
      ],
    ),
  );
}

Widget _prop(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXs),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      SelectableText(value),
    ],
  ),
);

/// Lets the user pick a destination folder for copy/move.
/// Navigates directories inside the given volumes.
/// When [pickFiles] is set, files are listed too and tapping one returns
/// its path (used for "upload file" pickers).
Future<String?> showFolderPickerDialog(
  BuildContext context, {
  required List<StorageVolume> volumes,
  required String initialPath,
  bool pickFiles = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _FolderPickerDialog(
      volumes: volumes,
      initialPath: initialPath,
      pickFiles: pickFiles,
    ),
  );
}

class _FolderPickerDialog extends StatefulWidget {
  const _FolderPickerDialog({
    required this.volumes,
    required this.initialPath,
    this.pickFiles = false,
  });

  final List<StorageVolume> volumes;
  final String initialPath;
  final bool pickFiles;

  @override
  State<_FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<_FolderPickerDialog> {
  late String _path;
  List<Directory> _dirs = [];
  List<File> _files = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entities = await Directory(_path).list().toList();
      final visible =
          entities
              .where((e) => !e.path.split('/').last.startsWith('.'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      setState(() {
        _dirs = visible.whereType<Directory>().toList();
        _files = widget.pickFiles ? visible.whereType<File>().toList() : [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _dirs = [];
        _files = [];
        _loading = false;
        _error = l10n(context).cannotOpenFolder;
      });
    }
  }

  String get _root {
    for (final v in widget.volumes) {
      if (_path == v.path || _path.startsWith('${v.path}/')) return v.path;
    }
    return widget.volumes.isNotEmpty ? widget.volumes.first.path : '/';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n(context).chooseDestination),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          children: [
            if (widget.volumes.length > 1)
              Wrap(
                spacing: AppTokens.spacingSm,
                children: [
                  for (final v in widget.volumes)
                    ChoiceChip(
                      label: Text(volumeLabel(context, v)),
                      selected: _path.startsWith(v.path),
                      onSelected: (_) {
                        _path = v.path;
                        _load();
                      },
                    ),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_upward, size: AppTokens.iconSm),
                label: Text(l10n(context).up),
                onPressed: _path == _root
                    ? null
                    : () {
                        _path = _path.substring(0, _path.lastIndexOf('/'));
                        _load();
                      },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _dirs.isEmpty && _files.isEmpty
                  ? Center(child: Text(l10n(context).noSubfolders))
                  : ListView(
                      children: [
                        for (final d in _dirs)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(d.path.split('/').last),
                            onTap: () {
                              _path = d.path;
                              _load();
                            },
                          ),
                        for (final f in _files)
                          ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.insert_drive_file_outlined,
                            ),
                            title: Text(f.path.split('/').last),
                            onTap: () => Navigator.pop(context, f.path),
                          ),
                      ],
                    ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _path,
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
          child: Text(l10n(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _path),
          child: Text(l10n(context).selectHere),
        ),
      ],
    );
  }
}

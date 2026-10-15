import 'package:flutter/material.dart' hide SearchController;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/storage_volume.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_icons.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../file_manager/application/file_browser_controller.dart';
import '../../file_manager/presentation/widgets/browser_dialogs.dart';
import '../application/search_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.onReveal});

  /// Opens the file manager at the given path.
  final void Function(String path)? onReveal;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _patternCtrl = TextEditingController();
  StorageVolume? _volume;
  String? _folder;
  DateTime? _from;
  DateTime? _to;

  List<StorageVolume> get _volumes =>
      context.read<FileBrowserController>().volumes;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );
    if (picked == null) return;
    setState(() {
      _from = picked.start;
      _to = picked.end;
    });
  }

  Future<void> _pickFolder() async {
    final volume = _volume ?? (_volumes.isNotEmpty ? _volumes.first : null);
    if (volume == null) return;
    final picked = await showFolderPickerDialog(
      context,
      volumes: _volumes,
      initialPath: volume.path,
    );
    if (picked != null) setState(() => _folder = picked);
  }

  Future<void> _run() async {
    final volume = _volume ?? (_volumes.isNotEmpty ? _volumes.first : null);
    if (volume == null) return;
    FocusScope.of(context).unfocus();
    await context.read<SearchController>().run(
      volume: volume,
      rootPath: _folder ?? volume.path,
      pattern: _patternCtrl.text,
      from: _from,
      to: _to,
    );
  }

  @override
  void dispose() {
    _patternCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchController>();
    final unit = context.watch<SettingsController>().sizeUnit;
    final volumes = _volumes;
    final selectedVolume =
        _volume ?? (volumes.isNotEmpty ? volumes.first : null);

    return Scaffold(
      appBar: AppBar(title: Text(l10n(context).search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            child: Column(
              children: [
                TextField(
                  controller: _patternCtrl,
                  decoration: InputDecoration(
                    labelText: l10n(context).fileNamePattern,
                    hintText: l10n(context).searchHint,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _run(),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                if (volumes.length > 1)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppTokens.spacingSm,
                      children: [
                        for (final v in volumes)
                          ChoiceChip(
                            label: Text(volumeLabel(context, v)),
                            selected: selectedVolume == v,
                            onSelected: (_) => setState(() => _volume = v),
                          ),
                        // Placeholder until Drive integration is verified.
                        ChoiceChip(
                          label: Text('Google Drive'),
                          avatar: const Icon(Icons.cloud_outlined, size: 16),
                          selected: false,
                          onSelected: null,
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.folder_outlined,
                          size: AppTokens.iconSm,
                        ),
                        label: Text(
                          _folder ?? l10n(context).wholeStorage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: _pickFolder,
                      ),
                    ),
                    if (_folder != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: AppTokens.iconSm),
                        tooltip: l10n(context).searchWholeStorage,
                        onPressed: () => setState(() => _folder = null),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.date_range,
                          size: AppTokens.iconSm,
                        ),
                        label: Text(
                          _from == null
                              ? '${l10n(context).fromDate} – ${l10n(context).toDate}'
                              : '${DateFormat('dd.MM.yyyy').format(_from!)} – '
                                    '${_to != null ? DateFormat('dd.MM.yyyy').format(_to!) : '…'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: _pickDateRange,
                      ),
                    ),
                    if (_from != null || _to != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: AppTokens.iconSm),
                        tooltip: l10n(context).clearDates,
                        onPressed: () => setState(() {
                          _from = null;
                          _to = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacingSm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.search),
                    label: Text(l10n(context).search),
                    onPressed: search.scanning ? null : _run,
                  ),
                ),
              ],
            ),
          ),
          if (search.scanning) ...[
            const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppTokens.spacingXs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n(context).scannedCount(search.scannedCount)),
                  const SizedBox(width: AppTokens.spacingMd),
                  TextButton(
                    onPressed: search.cancel,
                    child: Text(l10n(context).cancel),
                  ),
                ],
              ),
            ),
          ],
          Expanded(child: _buildResults(search, unit)),
        ],
      ),
    );
  }

  Widget _buildResults(SearchController search, SizeUnit unit) {
    if (search.results.isEmpty) {
      if (search.scanning) return const SizedBox.shrink();
      return Center(child: Text(l10n(context).noResults));
    }
    return ListView.builder(
      itemCount: search.results.length,
      itemBuilder: (context, i) {
        final e = search.results[i];
        return ListTile(
          leading: Icon(
            FileIcons.iconFor(e),
            color: FileIcons.colorFor(e, Theme.of(context).colorScheme),
          ),
          title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${e.parentPath}\n'
            '${e.isDirectory ? l10n(context).typeFolder : formatBytes(e.size, unit)}'
            ' · ${formatDate(e.modified)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          onTap: () {
            final target = e.isDirectory ? e.path : e.parentPath;
            widget.onReveal?.call(target);
          },
        );
      },
    );
  }
}

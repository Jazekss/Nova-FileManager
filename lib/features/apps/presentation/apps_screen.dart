import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../file_manager/application/file_browser_controller.dart';
import '../data/apps_service.dart';
import 'cleaner_screen.dart';

/// Primary storage root for leftover/junk scans.
String primaryRoot(BuildContext context) {
  final vols = context.read<FileBrowserController>().volumes;
  for (final v in vols) {
    if (v.isPrimary) return v.path;
  }
  return vols.isEmpty ? '/storage/emulated/0' : vols.first.path;
}

/// User-installed apps: version, size, last use; tap a row to
/// uninstall, tick several to uninstall them one after another. After
/// uninstalling, folders the apps left in shared storage are offered
/// for deletion.
class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> with WidgetsBindingObserver {
  List<AppInfo> _apps = [];
  bool _loading = true;
  bool _usage = true;
  String _sort = 'size';
  final Set<String> _sel = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the Usage-access settings page → reload with sizes.
    if (state == AppLifecycleState.resumed && !_busy) _load(quiet: true);
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final usage = await AppsService.hasUsageAccess();
      final apps = await AppsService.list();
      if (!mounted) return;
      setState(() {
        _usage = usage;
        _apps = apps;
        _sel.removeWhere((p) => !apps.any((a) => a.pkg == p));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppInfo> get _sorted {
    final l = [..._apps];
    switch (_sort) {
      case 'name':
        l.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case 'used':
        // Least recently used first — the usual cleanup candidates.
        l.sort(
          (a, b) => (a.lastUsed?.millisecondsSinceEpoch ?? 0).compareTo(
            b.lastUsed?.millisecondsSinceEpoch ?? 0,
          ),
        );
      default:
        l.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    }
    return l;
  }

  String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy HH:mm').format(d);

  /// Waits for the system uninstall dialog to close, then checks.
  Future<bool> _uninstallOne(AppInfo a) async {
    final done = Completer<void>();
    var left = false;
    final l = AppLifecycleListener(
      onStateChange: (s) {
        if (s != AppLifecycleState.resumed) left = true;
        if (s == AppLifecycleState.resumed && left && !done.isCompleted) {
          done.complete();
        }
      },
    );
    try {
      await AppsService.uninstall(a.pkg);
      await done.future.timeout(const Duration(minutes: 3), onTimeout: () {});
    } finally {
      l.dispose();
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return !(await AppsService.isInstalled(a.pkg));
  }

  Future<void> _uninstall(List<AppInfo> apps) async {
    final tr = l10n(context);
    final unit = context.read<SettingsController>().sizeUnit;
    final total = apps.fold<int>(0, (s, a) => s + a.totalBytes);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.uninstallQ(apps.length)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final a in apps)
                      Text('• ${a.name}  (${formatBytes(a.totalBytes, unit)})'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('${tr.total}: ${formatBytes(total, unit)}'),
              const SizedBox(height: 10),
              Text(
                tr.uninstallNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.uninstall),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final root = primaryRoot(context);
    setState(() => _busy = true);
    final removed = <AppInfo>[];
    for (final a in apps) {
      if (await _uninstallOne(a)) removed.add(a);
      if (!mounted) return;
    }
    setState(() {
      _busy = false;
      _sel.clear();
    });
    await _load(quiet: true);
    if (!mounted || removed.isEmpty) return;
    final left = <JunkItem>[];
    for (final a in removed) {
      left.addAll(await AppsService.leftoversOf(root, a.pkg, a.name));
    }
    if (!mounted) return;
    if (left.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.uninstalledCount(removed.length))),
      );
      return;
    }
    await showLeftoversDialog(context, left);
  }

  Future<void> _rowMenu(AppInfo a) async {
    final tr = l10n(context);
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _AppIcon(pkg: a.pkg),
              title: Text(a.name),
              subtitle: Text(a.pkg),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(tr.uninstall),
              onTap: () => Navigator.pop(context, 'uninstall'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(tr.appInfo),
              subtitle: Text(tr.appInfoNote),
              onTap: () => Navigator.pop(context, 'info'),
            ),
          ],
        ),
      ),
    );
    if (v == 'uninstall') await _uninstall([a]);
    if (v == 'info') await AppsService.openInfo(a.pkg);
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    final unit = context.watch<SettingsController>().sizeUnit;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = _apps.fold<int>(0, (s, a) => s + a.totalBytes);
    final cache = _apps.fold<int>(0, (s, a) => s + (a.cacheBytes ?? 0));
    final selected = _apps.where((a) => _sel.contains(a.pkg)).toList();
    final list = _sorted;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.installedApps),
        actions: [
          IconButton(
            tooltip: tr.cleaner,
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CleanerScreen()),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: tr.sort,
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'size',
                checked: _sort == 'size',
                child: Text(tr.sortBySize),
              ),
              CheckedPopupMenuItem(
                value: 'used',
                checked: _sort == 'used',
                child: Text(tr.sortByLastUsed),
              ),
              CheckedPopupMenuItem(
                value: 'name',
                checked: _sort == 'name',
                child: Text(tr.sortByName),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: selected.isEmpty
          ? null
          : SafeArea(
              child: Container(
                color: scheme.surfaceContainer,
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${tr.selectedCount(selected.length)} · '
                        '${formatBytes(selected.fold<int>(0, (s, a) => s + a.totalBytes), unit)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(_sel.clear),
                      child: Text(tr.cancel),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(tr.uninstall),
                      onPressed: _busy ? null : () => _uninstall(selected),
                    ),
                  ],
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: list.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(Icons.apps, color: scheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr.appsSummary(
                                          _apps.length,
                                          formatBytes(total, unit),
                                        ),
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      if (_usage)
                                        Text(
                                          '${tr.cacheTotal}: ${formatBytes(cache, unit)}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!_usage)
                          Card(
                            margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                            color: scheme.secondaryContainer,
                            child: ListTile(
                              leading: const Icon(Icons.query_stats),
                              title: Text(tr.usageAccessTitle),
                              subtitle: Text(tr.usageAccessNote),
                              trailing: FilledButton.tonal(
                                onPressed: AppsService.openUsageAccess,
                                child: Text(tr.allow),
                              ),
                            ),
                          ),
                        if (_busy) const LinearProgressIndicator(),
                      ],
                    );
                  }
                  final a = list[i - 1];
                  final picked = _sel.contains(a.pkg);
                  final line2 = [
                    if (a.version.isNotEmpty) 'v${a.version}',
                    formatBytes(a.totalBytes, unit),
                  ].join(' · ');
                  return ListTile(
                    leading: _AppIcon(pkg: a.pkg),
                    title: Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '$line2\n${a.lastUsed == null ? (_usage ? tr.neverUsed : tr.lastUsedUnknown) : '${tr.lastUsed}: ${_fmtDate(a.lastUsed!)}'}',
                      style: theme.textTheme.bodySmall,
                    ),
                    isThreeLine: true,
                    trailing: Checkbox(
                      value: picked,
                      onChanged: (_) => setState(
                        () => picked ? _sel.remove(a.pkg) : _sel.add(a.pkg),
                      ),
                    ),
                    onTap: _busy ? null : () => _rowMenu(a),
                    onLongPress: () => setState(
                      () => picked ? _sel.remove(a.pkg) : _sel.add(a.pkg),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.pkg});
  final String pkg;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: FutureBuilder<Uint8List?>(
      future: AppsService.icon(pkg),
      builder: (context, s) => s.data == null
          ? const Icon(Icons.android, size: 32)
          : Image.memory(s.data!, gaplessPlayback: true),
    ),
  );
}

/// Lists folders that uninstalled apps left behind; deletes the ticked
/// ones after a confirmation.
Future<void> showLeftoversDialog(
  BuildContext context,
  List<JunkItem> items,
) async {
  final tr = l10n(context);
  final unit = context.read<SettingsController>().sizeUnit;
  final picked = {...items.map((e) => e.path)};
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        title: Text(tr.leftoversTitle),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.leftoversNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final i in items)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: picked.contains(i.path),
                        title: Text(
                          i.path,
                          style: const TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(formatBytes(i.bytes, unit)),
                        onChanged: (v) => setD(
                          () => v == true
                              ? picked.add(i.path)
                              : picked.remove(i.path),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.keep),
          ),
          FilledButton(
            onPressed: picked.isEmpty
                ? null
                : () => Navigator.pop(context, true),
            child: Text(tr.delete),
          ),
        ],
      ),
    ),
  );
  if (go != true) return;
  final n = await deleteJunk(
    items.where((i) => picked.contains(i.path)).toList(),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr.deletedCount(n))));
  }
}

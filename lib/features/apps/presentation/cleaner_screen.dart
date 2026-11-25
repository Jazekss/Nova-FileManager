import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../data/apps_service.dart';
import 'apps_screen.dart';

/// Cache & junk cleaner.
///
/// * App caches: sizes per app (Usage access). Android allows clearing
///   other apps' caches only through its own dialog — "Clear all app
///   caches" (Android 11+) or an app's settings page.
/// * Junk in shared storage: thumbnail caches, temp/log files, cache
///   folders, empty folders, folders of uninstalled apps — tick and
///   delete after a confirmation.
class CleanerScreen extends StatefulWidget {
  const CleanerScreen({super.key});

  @override
  State<CleanerScreen> createState() => _CleanerScreenState();
}

class _CleanerScreenState extends State<CleanerScreen>
    with WidgetsBindingObserver {
  bool _scanning = true;
  bool _usage = false;
  List<AppInfo> _apps = [];
  List<JunkItem> _junk = [];
  final Set<String> _picked = {};

  /// Safe-by-default: obvious junk pre-ticked; empty folders and
  /// leftovers of uninstalled apps only when the user ticks them.
  static const _autoKinds = {'thumbs', 'cache', 'temp', 'nova'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the system "clear cache" dialog / settings → rescan.
    if (state == AppLifecycleState.resumed && !_scanning) _scan();
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final root = primaryRoot(context);
    try {
      final usage = await AppsService.hasUsageAccess();
      final apps = usage ? await AppsService.list() : <AppInfo>[];
      final junk = await AppsService.scanJunk(
        root,
        novaTemp: Directory.systemTemp.path,
      );
      if (!mounted) return;
      setState(() {
        _usage = usage;
        _apps = apps.where((a) => (a.cacheBytes ?? 0) > 0).toList()
          ..sort((a, b) => (b.cacheBytes ?? 0).compareTo(a.cacheBytes ?? 0));
        _junk = junk;
        _picked
          ..clear()
          ..addAll(
            junk.where((j) => _autoKinds.contains(j.kind)).map((j) => j.path),
          );
        _scanning = false;
      });
    } catch (_) {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _clearAll() async {
    final tr = l10n(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.clearAllCachesQ),
        content: Text(tr.clearAllCachesNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.clear),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final started = await AppsService.clearAllCaches();
    if (!started && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr.clearAllCachesUnavailable)));
    }
  }

  Future<void> _deletePicked() async {
    final tr = l10n(context);
    final unit = context.read<SettingsController>().sizeUnit;
    final items = _junk.where((j) => _picked.contains(j.path)).toList();
    final bytes = items.fold<int>(0, (s, j) => s + j.bytes);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.deleteJunkQ(items.length)),
        content: Text('${formatBytes(bytes, unit)}\n\n${tr.deleteJunkNote}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final n = await deleteJunk(items);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr.deletedCount(n))));
    _scan();
  }

  String _kindLabel(String k) {
    final tr = l10n(context);
    return switch (k) {
      'thumbs' => tr.junkThumbs,
      'temp' => tr.junkTemp,
      'cache' => tr.junkCacheDirs,
      'tempdir' => tr.junkTempDirs,
      'log' => tr.junkLogs,
      'empty' => tr.junkEmpty,
      'leftover' => tr.junkLeftovers,
      _ => tr.junkNova,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    final unit = context.watch<SettingsController>().sizeUnit;
    final theme = Theme.of(context);
    final cacheTotal = _apps.fold<int>(0, (s, a) => s + (a.cacheBytes ?? 0));
    final pickedBytes = _junk
        .where((j) => _picked.contains(j.path))
        .fold<int>(0, (s, j) => s + j.bytes);
    final groups = <String, List<JunkItem>>{};
    for (final j in _junk) {
      groups.putIfAbsent(j.kind, () => []).add(j);
    }
    final root = primaryRoot(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.cleaner),
        actions: [
          IconButton(
            tooltip: tr.rescan,
            icon: const Icon(Icons.refresh),
            onPressed: _scanning ? null : _scan,
          ),
        ],
      ),
      bottomNavigationBar: _picked.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(
                    '${tr.deleteSelected} (${formatBytes(pickedBytes, unit)})',
                  ),
                  onPressed: _deletePicked,
                ),
              ),
            ),
      body: _scanning
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(tr.scanning),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(tr.appCaches, style: theme.textTheme.titleSmall),
                ),
                if (!_usage)
                  ListTile(
                    leading: const Icon(Icons.query_stats),
                    title: Text(tr.usageAccessTitle),
                    subtitle: Text(tr.usageAccessNote),
                    trailing: FilledButton.tonal(
                      onPressed: AppsService.openUsageAccess,
                      child: Text(tr.allow),
                    ),
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.cached),
                    title: Text(
                      '${tr.cacheTotal}: ${formatBytes(cacheTotal, unit)}',
                    ),
                    subtitle: Text(tr.appCachesNote),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: Text(tr.clearAllCaches),
                      onPressed: _clearAll,
                    ),
                  ),
                  for (final a in _apps.take(30))
                    ListTile(
                      dense: true,
                      title: Text(a.name),
                      trailing: Text(formatBytes(a.cacheBytes ?? 0, unit)),
                      onTap: () => AppsService.openInfo(a.pkg),
                    ),
                ],
                const Divider(height: 28),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr.junkFiles,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (_junk.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() {
                            if (_picked.length == _junk.length) {
                              _picked.clear();
                            } else {
                              _picked.addAll(_junk.map((j) => j.path));
                            }
                          }),
                          child: Text(
                            _picked.length == _junk.length
                                ? tr.selectNone
                                : tr.selectAll,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_junk.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(tr.noJunk),
                  ),
                for (final e in groups.entries)
                  ExpansionTile(
                    leading: Checkbox(
                      tristate: true,
                      value: e.value.every((j) => _picked.contains(j.path))
                          ? true
                          : e.value.any((j) => _picked.contains(j.path))
                          ? null
                          : false,
                      onChanged: (v) => setState(() {
                        final all = e.value.every(
                          (j) => _picked.contains(j.path),
                        );
                        for (final j in e.value) {
                          all ? _picked.remove(j.path) : _picked.add(j.path);
                        }
                      }),
                    ),
                    title: Text(_kindLabel(e.key)),
                    subtitle: Text(
                      '${e.value.length} · ${formatBytes(e.value.fold<int>(0, (s, j) => s + j.bytes), unit)}',
                    ),
                    children: [
                      for (final j in e.value.take(200))
                        CheckboxListTile(
                          dense: true,
                          value: _picked.contains(j.path),
                          title: Text(
                            j.path.startsWith(root)
                                ? j.path.substring(root.length)
                                : j.path,
                            style: const TextStyle(fontSize: 12),
                          ),
                          subtitle: j.bytes > 0
                              ? Text(formatBytes(j.bytes, unit))
                              : null,
                          onChanged: (v) => setState(
                            () => v == true
                                ? _picked.add(j.path)
                                : _picked.remove(j.path),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}

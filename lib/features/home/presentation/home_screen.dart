import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/storage_volume.dart';
import '../../../core/platform/storage_platform.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../recycle_bin/application/recycle_bin_controller.dart';
import '../../recycle_bin/presentation/recycle_bin_screen.dart';
import '../../apps/presentation/apps_screen.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../devices/presentation/other_devices_screen.dart';
import '../../pc_share/presentation/pc_share_screen.dart';
import '../../vault/data/vault_service.dart';
import '../../vault/presentation/vault_screen.dart';

/// Home tab: storage overview card, app count and quick-access shortcuts.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenFolder});

  /// Called when the user taps a quick-access folder; opens it in the
  /// File Manager tab.
  final void Function(String path)? onOpenFolder;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<StorageVolume> _volumes = [];
  final Map<String, StorageStats> _stats = {};
  int? _appCount;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Refresh after the first frame — notifyListeners during build is illegal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshAll();
    });
  }

  void _refreshAll() {
    context.read<RecycleBinController>().refresh();
    _load();
  }

  Future<void> _load() async {
    final platform = context.read<StoragePlatform>();
    setState(() => _loading = true);
    try {
      final volumes = await platform.getVolumes();
      final stats = <String, StorageStats>{};
      for (final v in volumes) {
        try {
          stats[v.path] = await platform.getStats(v.path);
        } catch (_) {
          // StatFs can fail on unmounted volumes; skip.
        }
      }
      int? count;
      try {
        count = await platform.getInstalledAppCount();
      } catch (_) {
        count = null;
      }
      if (!mounted) return;
      setState(() {
        _volumes = volumes;
        _stats
          ..clear()
          ..addAll(stats);
        _appCount = count;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = context.watch<SettingsController>().sizeUnit;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n(context).appTitle),
        actions: [
          IconButton(
            tooltip: l10n(context).settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          children: [
            _StorageCard(
              volumes: _volumes,
              stats: _stats,
              unit: unit,
              loading: _loading,
            ),
            const SizedBox(height: AppTokens.spacingMd),
            // Order: Installed apps, Files, PC share, Other devices,
            // Vault, Recycle bin — the rest stays below.
            _NavCard(
              icon: Icons.apps,
              title: l10n(context).installedApps,
              subtitle: _appCount == null
                  ? l10n(context).appsCardSubtitle
                  : '${l10n(context).appsCardSubtitle} · $_appCount',
              page: () => const AppsScreen(),
            ),
            _NavCard(
              icon: Icons.folder_copy_outlined,
              title: l10n(context).files,
              subtitle: l10n(context).filesCardSubtitle,
              page: () => const CategoriesScreen(),
            ),
            _NavCard(
              icon: Icons.desktop_windows_outlined,
              title: l10n(context).pcShare,
              subtitle: l10n(context).pairWithPc,
              page: () => const PcShareScreen(),
            ),
            _NavCard(
              icon: Icons.devices_other_outlined,
              title: l10n(context).otherDevices,
              subtitle: l10n(context).otherDevicesCard,
              page: () => const OtherDevicesScreen(),
            ),
            _NavCard(
              icon: Icons.lock_outline,
              title: l10n(context).vault,
              subtitle: l10n(context).vaultCardSubtitle,
              page: () => VaultScreen(service: context.read<VaultService>()),
            ),
            _BinCard(unit: unit),
            const SizedBox(height: AppTokens.spacingMd),
            if (widget.onOpenFolder != null)
              _QuickAccess(
                volume: _volumes.isEmpty ? null : _volumes.first,
                onOpenFolder: widget.onOpenFolder!,
              ),
            const SizedBox(height: AppTokens.spacingMd),
            const _LimitsCard(),
          ],
        ),
      ),
    );
  }
}

/// One home entry: icon, title, subtitle, chevron → [page].
class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() page;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.spacingSm),
    child: Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => page())),
      ),
    ),
  );
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({
    required this.volumes,
    required this.stats,
    required this.unit,
    required this.loading,
  });

  final List<StorageVolume> volumes;
  final Map<String, StorageStats> stats;
  final SizeUnit unit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n(context).storage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingMd),
            if (loading && volumes.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (volumes.isEmpty)
              Text(l10n(context).noStorage)
            else
              Row(
                children: [
                  for (final v in volumes) ...[
                    Expanded(
                      child: _VolumeStat(
                        volume: v,
                        stats: stats[v.path],
                        unit: unit,
                      ),
                    ),
                    if (v != volumes.last)
                      const SizedBox(width: AppTokens.spacingMd),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _VolumeStat extends StatelessWidget {
  const _VolumeStat({
    required this.volume,
    required this.stats,
    required this.unit,
  });

  final StorageVolume volume;
  final StorageStats? stats;
  final SizeUnit unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              volume.isRemovable ? Icons.sd_card : Icons.smartphone,
              size: AppTokens.iconSm,
            ),
            const SizedBox(width: AppTokens.spacingXs),
            Expanded(
              child: Text(
                volumeLabel(context, volume),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingSm),
        if (stats == null)
          Text(
            volume.isRemovable
                ? l10n(context).notAvailable
                : l10n(context).noData,
            style: TextStyle(color: scheme.onSurfaceVariant),
          )
        else ...[
          LinearProgressIndicator(
            value: stats!.usedFraction,
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            formatBytes(stats!.freeBytes, unit),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            l10n(context).freeOf(
              formatBytes(stats!.freeBytes, unit),
              formatBytes(stats!.totalBytes, unit),
            ),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _BinCard extends StatelessWidget {
  const _BinCard({required this.unit});

  final SizeUnit unit;

  @override
  Widget build(BuildContext context) {
    final bin = context.watch<RecycleBinController>();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.delete_outline),
        title: Text(l10n(context).recycleBin),
        subtitle: Text(
          l10n(context)
              .binItems(bin.items.length, formatBytes(bin.totalBytes, unit)),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RecycleBinScreen()),
        ),
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.volume, required this.onOpenFolder});

  final StorageVolume? volume;
  final void Function(String path) onOpenFolder;

  static const _dirs = [
    ('Download', Icons.download),
    ('DCIM', Icons.photo_camera),
    ('Documents', Icons.description),
    ('Pictures', Icons.photo),
    ('Music', Icons.music_note),
    ('Movies', Icons.movie),
  ];

  @override
  Widget build(BuildContext context) {
    if (volume == null) return const SizedBox.shrink();
    final root = volume!.path;
    final existing = _dirs
        .where((d) => Directory('$root/${d.$1}').existsSync())
        .toList();
    if (existing.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n(context).quickAccess,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTokens.spacingSm),
        Wrap(
          spacing: AppTokens.spacingSm,
          runSpacing: AppTokens.spacingSm,
          children: [
            for (final (name, icon) in existing)
              ActionChip(
                avatar: Icon(icon, size: AppTokens.iconSm),
                label: Text(name),
                onPressed: () => onOpenFolder('$root/$name'),
              ),
          ],
        ),
      ],
    );
  }
}

class _LimitsCard extends StatelessWidget {
  const _LimitsCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppTokens.iconSm,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Text(
                  l10n(context).androidLimits,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              '• ${l10n(context).limitData}\n'
              '• ${l10n(context).limitSystem}\n'
              '• ${l10n(context).limitSd}',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

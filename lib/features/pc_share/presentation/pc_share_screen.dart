import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../file_manager/application/file_browser_controller.dart';
import '../../file_manager/presentation/widgets/browser_dialogs.dart';
import '../../transfer/data/wifi_share_server.dart';
import '../data/pc_client.dart';

/// Pair with Nova File Manager Desktop, then browse the PC's shared
/// folders: download files to the phone, upload phone files to a chosen
/// PC folder, and optionally share phone files back to the PC panel.
class PcShareScreen extends StatefulWidget {
  const PcShareScreen({super.key});

  @override
  State<PcShareScreen> createState() => _PcShareScreenState();
}

class _PcShareScreenState extends State<PcShareScreen> {
  final _client = PcClient();
  final _linkController = TextEditingController();

  bool _ready = false;
  List<PcEntry> _entries = [];
  final List<String> _crumbs = []; // dir path stack; '' = shared roots
  bool _loading = false;
  String? _error;
  final Map<String, Uint8List?> _thumbCache = {};

  /// Phone-side share server registered to the PC's right panel.
  WifiShareServer? _shareServer;

  String get _currentDir => _crumbs.isEmpty ? '' : _crumbs.last;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _client.load();
    if (!mounted) return;
    setState(() => _ready = true);
    if (_client.isPaired) _refresh();
  }

  @override
  void dispose() {
    _linkController.dispose();
    // Note: _shareServer intentionally keeps running — the phone stays
    // shared until the user explicitly disconnects or closes the app.
    super.dispose();
  }

  // --- Pairing ---

  Future<void> _pairWith(String link) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await _client.pair(link);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err == 'invalid_link'
            ? l10n(context).invalidPairLink
            : '${l10n(context).pairFailed}: $err';
      });
      return;
    }
    setState(() => _loading = false);
    _refresh();
  }

  Future<void> _scanQr() async {
    final link = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const _QrScanPage()));
    if (link != null) _pairWith(link);
  }

  Future<void> _manualPair() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n(context).enterPairLink),
        content: TextField(
          controller: _linkController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'novapair://…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n(context).pair),
          ),
        ],
      ),
    );
    final link = _linkController.text.trim();
    if (link.isNotEmpty) _pairWith(link);
  }

  Future<void> _unpair() async {
    await _shareServer?.stop();
    _shareServer = null;
    await _client.unpair();
    if (!mounted) return;
    setState(() {
      _entries = [];
      _crumbs.clear();
    });
  }

  // --- Browsing ---

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _client.list(_currentDir);
      if (!mounted) return;
      setState(() {
        _entries = list;
        _loading = false;
      });
    } on StateError catch (e) {
      if (e.message == 'unpaired') {
        await _client.unpair();
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n(context).pairFailed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _download(PcEntry e) async {
    final browser = context.read<FileBrowserController>();
    final dest = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath.isEmpty
          ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
          : browser.currentPath,
    );
    if (dest == null || !mounted) return;
    try {
      await _client.download(e, dest);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).downloaded)));
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$err')));
    }
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
    try {
      await _client.upload(path, _currentDir);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).uploaded)));
      _refresh();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  /// Shares the currently browsed phone folder's files to the PC's right
  /// panel by starting the existing Wi-Fi share server and registering
  /// its URL with the desktop.
  Future<void> _sharePhoneFolder() async {
    final browser = context.read<FileBrowserController>();
    final dir = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath.isEmpty
          ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
          : browser.currentPath,
    );
    if (dir == null || !mounted) return;
    final files = Directory(dir)
        .listSync()
        .whereType<File>()
        .where((f) => !f.path.split('/').last.startsWith('.'))
        .map(
          (f) => SharedFile(
            path: f.path,
            downloadName: f.path.split('/').last,
            size: f.lengthSync(),
          ),
        )
        .toList();
    final uploadDir = '${browser.volumes.first.path}/Download/Nova';
    _shareServer ??= WifiShareServer(
      uploadDir: Directory(uploadDir),
      onUnpair: () {
        // PC asked to disconnect.
        _shareServer?.stop();
        _shareServer = null;
        if (mounted) _unpair();
      },
    );
    await _shareServer!.stop();
    _shareServer = WifiShareServer(
      uploadDir: Directory(uploadDir),
      onUnpair: () {
        _shareServer = null;
        if (mounted) _unpair();
      },
    );
    await _shareServer!.start(files);
    await _client.registerPhoneUrl(_shareServer!.url);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n(context).sharedToPc)));
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    return Scaffold(
      appBar: AppBar(
        leading: _crumbs.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _crumbs.removeLast();
                  _refresh();
                },
              )
            : null,
        title: Text(
          _client.isPaired
              ? (_currentDir.isEmpty ? tr.pcShare : _currentDir)
              : tr.pcShare,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_client.isPaired)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'share_folder') _sharePhoneFolder();
                if (v == 'unpair') _unpair();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share_folder',
                  child: Text(tr.sharePhoneFolder),
                ),
                PopupMenuItem(value: 'unpair', child: Text(tr.disconnect)),
              ],
            ),
        ],
      ),
      floatingActionButton: _client.isPaired && _currentDir.isNotEmpty
          ? FloatingActionButton.small(
              tooltip: tr.uploadHere,
              onPressed: _upload,
              child: const Icon(Icons.upload_file),
            )
          : null,
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : !_client.isPaired
          ? _buildPairing(tr)
          : _buildList(tr),
    );
  }

  Widget _buildPairing(AppLocalizations tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.desktop_windows_outlined, size: 56),
            const SizedBox(height: AppTokens.spacingMd),
            Text(tr.pairWithPc, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.spacingMd),
            Text(
              tr.pcPairHint,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacingLg),
            FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(tr.scanQr),
              onPressed: _loading ? null : _scanQr,
            ),
            const SizedBox(height: AppTokens.spacingSm),
            TextButton(
              onPressed: _loading ? null : _manualPair,
              child: Text(tr.enterManually),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTokens.spacingMd),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(AppLocalizations tr) {
    if (_loading && _entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppTokens.spacingMd),
              OutlinedButton(onPressed: _refresh, child: Text(tr.refresh)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _entries.isEmpty
          ? ListView(children: [Center(child: Text(tr.emptyFolder))])
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, i) {
                final e = _entries[i];
                final thumbs = context.watch<SettingsController>().shareThumbs;
                return ListTile(
                  leading: thumbs && !e.isDir
                      ? FutureBuilder<Uint8List?>(
                          future: _thumbCache.containsKey(e.path)
                              ? Future.value(_thumbCache[e.path])
                              : _client
                                    .thumb(e)
                                    .then((b) => _thumbCache[e.path] = b),
                          builder: (context, snap) {
                            final bytes = snap.data;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: bytes != null
                                  ? Image.memory(
                                      bytes,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.insert_drive_file_outlined,
                                      size: 44,
                                    ),
                            );
                          },
                        )
                      : Icon(
                          e.isDir
                              ? Icons.folder
                              : Icons.insert_drive_file_outlined,
                        ),
                  title: Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: e.isDir
                      ? null
                      : Text(formatBytes(e.size, SizeUnit.auto)),
                  onTap: e.isDir
                      ? () {
                          _crumbs.add(e.path);
                          _refresh();
                        }
                      : () => _download(e),
                  trailing: e.isDir
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _download(e),
                        ),
                );
              },
            ),
    );
  }
}

/// Full-screen QR scanner for novapair:// links.
class _QrScanPage extends StatelessWidget {
  const _QrScanPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n(context).scanQr)),
      body: MobileScanner(
        onDetect: (capture) {
          for (final code in capture.barcodes) {
            final raw = code.rawValue;
            if (raw != null && raw.startsWith('novapair://')) {
              Navigator.pop(context, raw);
              return;
            }
          }
        },
      ),
    );
  }
}

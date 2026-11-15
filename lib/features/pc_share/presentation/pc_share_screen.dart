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
import '../../media/presentation/audio_player_screen.dart';
import '../../media/presentation/video_player_screen.dart';
import '../../devices/presentation/other_devices_screen.dart';
import '../application/pc_link_service.dart';
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
  late final PcLinkService _link = context.read<PcLinkService>();
  PcClient get _client => _link.client;
  final _linkController = TextEditingController();

  /// Last onlineEpoch seen — a new one means the link came back.
  int _epoch = -1;
  List<PcEntry> _entries = [];
  final List<String> _crumbs = []; // dir path stack; '' = shared roots
  bool _loading = false;
  String? _error;
  final Map<String, Uint8List?> _thumbCache = {};

  /// list / medium / large — persisted in SettingsController.pcShareView.
  String get _viewMode => context.watch<SettingsController>().pcShareView;

  /// Entry whose bottom-sheet menu is open — drawn with a soft outline.
  String? _menuPath;

  /// Selected entries (lightbox checkmarks / tap-toggle) — paths.
  final Set<String> _selected = {};

  static const _imgExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
  static const _videoExts = {'mp4', 'mkv', 'avi', 'mov', 'webm', '3gp'};
  static const _audioExts = {
    'mp3',
    'wav',
    'ogg',
    'oga',
    'opus',
    'm4a',
    'aac',
    'flac',
  };

  static String _ext(PcEntry e) =>
      e.name.contains('.') ? e.name.split('.').last.toLowerCase() : '';

  String get _currentDir => _crumbs.isEmpty ? '' : _crumbs.last;

  @override
  void initState() {
    super.initState();
    _epoch = _link.onlineEpoch;
    _link.addListener(_onLink);
    final browser = context.read<FileBrowserController>();
    if (browser.volumes.isNotEmpty) {
      _link.uploadDir = '${browser.volumes.first.path}/Download/Nova';
    }
    if (_client.isPaired) {
      _refresh();
      // Opening the screen is a good moment to check the link now.
      _link.tick();
    }
  }

  /// Link came back online (Wi-Fi back, PC restarted, IP changed) →
  /// reload the listing so the user never has to tap "Refresh".
  void _onLink() {
    if (!mounted) return;
    final back = _link.onlineEpoch != _epoch;
    _epoch = _link.onlineEpoch;
    // Link (re)established, or online again while an old error is
    // still shown → reload so the error never sticks.
    if (_client.isPaired &&
        !_loading &&
        (back || (_error != null && _link.status == PcLinkStatus.online))) {
      _refresh();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _link.removeListener(_onLink);
    _linkController.dispose();
    // The share server lives in PcLinkService and keeps running — the
    // phone stays shared until the user explicitly disconnects.
    super.dispose();
  }

  // --- Pairing ---

  Future<void> _pairWith(String link, {String? code}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await _link.pair(link, code: code);
    if (!mounted) return;
    if (err != null) {
      final tr = l10n(context);
      setState(() {
        _loading = false;
        _error = switch (err) {
          'invalid_link' => tr.invalidPairLink,
          'bad_code' => tr.pairCodeWrong,
          'rejected' => tr.pcRejected,
          _ => '${tr.pcUnreachableHint} ($link)',
        };
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

  /// Address + one-time code shown on the PC (or a pasted full link).
  Future<void> _manualPair() async {
    final codeCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final tr = l10n(context);
        return AlertDialog(
          title: Text(tr.enterPairLink),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _linkController,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: tr.pcAddress,
                  hintText: '192.168.1.10:48320',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: tr.pairCode,
                  hintText: 'ABCD-EFGH-JKMN',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr.pair),
            ),
          ],
        );
      },
    );
    final link = _linkController.text.trim();
    final code = codeCtl.text.trim();
    codeCtl.dispose();
    if (ok != true || link.isEmpty) return;
    _pairWith(link, code: link.startsWith('novapair://') ? null : code);
  }

  Future<void> _unpair() async {
    await _link.unpair();
    if (!mounted) return;
    setState(() {
      _entries = [];
      _crumbs.clear();
      _error = null;
    });
  }

  // --- Preview (stream, without saving) ---

  /// Image lightbox over ALL images of the current folder: swipe or use
  /// the arrows to switch, the check icon marks entries for a batch
  /// download — marks stay after the lightbox closes.
  /// Bytes come over the sealed channel and live only in memory.
  Future<void> _previewImage(PcEntry e) async {
    final images = _entries
        .where((x) => !x.isDir && _imgExts.contains(_ext(x)))
        .toList();
    var idx = images.indexOf(e);
    if (idx < 0) return;
    final controller = PageController(initialPage: idx);
    var zoomed = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) {
          final cur = images[idx];
          return Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                PageView.builder(
                  controller: controller,
                  // Zoomed in → one-finger pan moves the picture, not the
                  // page; swipe between images works again at 1x.
                  physics: zoomed ? const NeverScrollableScrollPhysics() : null,
                  itemCount: images.length,
                  onPageChanged: (i) => setD(() {
                    idx = i;
                    zoomed = false;
                  }),
                  itemBuilder: (context, i) => Center(
                    child: FutureBuilder<Uint8List?>(
                      future: _client.fetch(images[i]),
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const CircularProgressIndicator();
                        }
                        final bytes = snap.data;
                        if (bytes == null) {
                          return const Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 64,
                          );
                        }
                        return _ZoomableImage(
                          bytes: bytes,
                          onZoomChanged: (z) {
                            if (z != zoomed) setD(() => zoomed = z);
                          },
                        );
                      },
                    ),
                  ),
                ),
                // Prev / next — swipe also works; arrows make it obvious.
                if (idx > 0)
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: () => controller.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                  ),
                if (idx < images.length - 1)
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: () => controller.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // File name + position over the image.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        '${cur.name}  ·  ${idx + 1} / ${images.length}',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 8,
                  child: Row(
                    children: [
                      // Mark for batch download — persists after close.
                      IconButton(
                        tooltip: l10n(context).select,
                        icon: Icon(
                          _selected.contains(cur.path)
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(
                          () => setD(
                            () => _selected.contains(cur.path)
                                ? _selected.remove(cur.path)
                                : _selected.add(cur.path),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n(context).download,
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          _download(cur);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Audio preview: fetched through the sealed channel into a temp file
  /// and played in the built-in audio player — same flow as video.
  Future<void> _previewAudio(PcEntry e) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await _client.fetch(e);
      if (!mounted) return;
      Navigator.pop(context);
      if (bytes == null) throw 'fetch';
      final tmp = Directory.systemTemp.createTempSync('nova_audio');
      final f = File('${tmp.path}/${e.name}');
      await f.writeAsBytes(bytes);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AudioPlayerScreen(path: f.path),
        ),
      );
      f.parent.delete(recursive: true).ignore();
    } catch (err) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  /// Video preview: fetched through the sealed channel into a temp file
  /// (not into user folders) and opened in the built-in player.
  Future<void> _previewVideo(PcEntry e) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await _client.fetch(e);
      if (!mounted) return;
      Navigator.pop(context);
      if (bytes == null) throw 'fetch';
      final tmp = Directory.systemTemp.createTempSync('nova_preview');
      final f = File('${tmp.path}/${e.name}');
      await f.writeAsBytes(bytes);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoPlayerScreen(path: f.path),
        ),
      );
      f.delete().ignore();
    } catch (err) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  /// Tap on a file: images and videos preview without downloading,
  /// everything else downloads as before. While a selection is active
  /// (lightbox checkmarks / tap-toggle), taps toggle membership.
  Future<void> _openEntry(PcEntry e) async {
    if (e.isDir) {
      _crumbs.add(e.path);
      await _refresh();
      return;
    }
    if (_selected.isNotEmpty) {
      setState(
        () => _selected.contains(e.path)
            ? _selected.remove(e.path)
            : _selected.add(e.path),
      );
      return;
    }
    final ext = _ext(e);
    if (_imgExts.contains(ext)) {
      await _previewImage(e);
    } else if (_videoExts.contains(ext)) {
      await _previewVideo(e);
    } else if (_audioExts.contains(ext)) {
      await _previewAudio(e);
    } else {
      await _download(e);
    }
  }

  /// Bottom-sheet actions for a file — the tile is outlined while open.
  Future<void> _entryMenu(PcEntry e) async {
    setState(() => _menuPath = e.path);
    final ext = _ext(e);
    final isMedia =
        _imgExts.contains(ext) ||
        _videoExts.contains(ext) ||
        _audioExts.contains(ext);
    final tr = l10n(context);
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _selected.contains(e.path)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                ),
                title: Text(tr.select),
                onTap: () {
                  Navigator.pop(context);
                  setState(
                    () => _selected.contains(e.path)
                        ? _selected.remove(e.path)
                        : _selected.add(e.path),
                  );
                },
              ),
              if (isMedia)
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text(tr.view),
                  onTap: () {
                    Navigator.pop(context);
                    _clearSelectAndOpen(e);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(tr.download),
                onTap: () {
                  Navigator.pop(context);
                  _download(e);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: Text(tr.rename),
                onTap: () {
                  Navigator.pop(context);
                  _renameEntry(e);
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _menuPath = null);
    }
  }

  /// Opens a file bypassing the selection toggle (used from the ⋮ menu).
  Future<void> _clearSelectAndOpen(PcEntry e) async {
    setState(() => _selected.clear());
    await _openEntry(e);
  }

  /// Batch-downloads every selected entry into a picked folder.
  Future<void> _downloadSelected() async {
    final browser = context.read<FileBrowserController>();
    final dest = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath.isEmpty
          ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
          : browser.currentPath,
    );
    if (dest == null || !mounted) return;
    final picked = _entries.where((e) => _selected.contains(e.path)).toList();
    var ok = 0;
    for (final e in picked) {
      try {
        await _client.download(e, dest);
        ok++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _selected.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n(context).downloaded} ($ok)')),
    );
  }

  Future<void> _renameEntry(PcEntry e) async {
    final controller = TextEditingController(text: e.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n(context).rename),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n(context).save),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == e.name) return;
    try {
      await _client.rename(e, newName);
      if (mounted) _refresh();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$err')));
      }
    }
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
        _selected.clear();
      });
    } on StateError {
      // Pairing is kept — a 403 is no longer treated as "forget the PC".
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n(context).pcRejected;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n(context).pcUnreachableHint;
      });
      // Kick a reconnect (fallback IPs / discovery) — when it succeeds
      // the listing reloads by itself via _onLink.
      _link.tick();
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

  /// Multi-select picker (checkbox selects, tapping a folder opens it)
  /// then shares all picked folders/files to the PC's right panel.
  /// New picks are merged with the already-shared roots, and the set is
  /// persisted so a phone-side restart re-shares them.
  Future<void> _sharePhoneFolder() async {
    final browser = context.read<FileBrowserController>();
    final paths = await showMultiPickDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath.isEmpty
          ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
          : browser.currentPath,
      title: l10n(context).sharePhoneFolder,
    );
    if (paths == null || !mounted) return;
    try {
      await _link.setShareRoots({..._link.shareRoots, ...paths}.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).sharedToPc)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  /// Stops sharing a single root; the rest keep serving. Removing the
  /// last one shuts the share server down and unregisters from the PC.
  Future<void> _removeShareRoot(String path) async {
    try {
      await _link.setShareRoots(
        _link.shareRoots.where((r) => r != path).toList(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  /// Thin strip under the app bar while the PC isn't answering — shows
  /// that reconnecting runs by itself, plus a manual retry.
  Widget _statusStrip(AppLocalizations tr) {
    final st = _link.status;
    if (!_client.isPaired || st == PcLinkStatus.online) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final rejected = st == PcLinkStatus.rejected;
    return Material(
      color: rejected ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Row(
          children: [
            if (!rejected)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.link_off, size: 18, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                rejected ? tr.pcRejected : tr.pcReconnecting,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (rejected)
              TextButton(onPressed: _unpair, child: Text(tr.scanQr))
            else
              TextButton(
                onPressed: () => _link.tick(force: true),
                child: Text(tr.refresh),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    return PopScope(
      canPop: _crumbs.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        // System back climbs the crumb stack first; at shared roots the
        // route pops back to the file manager/home.
        if (!didPop && _crumbs.isNotEmpty) {
          _crumbs.removeLast();
          _refresh();
        }
      },
      child: Scaffold(
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
              IconButton(
                tooltip: l10n(context).view,
                icon: Icon(
                  _viewMode == 'list'
                      ? Icons.view_agenda_outlined
                      : _viewMode == 'medium'
                      ? Icons.grid_view
                      : Icons.view_comfy_alt,
                ),
                onPressed: () => context
                    .read<SettingsController>()
                    .setPcShareView(switch (_viewMode) {
                      'list' => 'medium',
                      'medium' => 'large',
                      _ => 'list',
                    }),
              ),
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
        // Batch bar — shown while lightbox/menu checkmarks are active.
        bottomNavigationBar: _selected.isEmpty
            ? null
            : SafeArea(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(tr.selectedCount(_selected.length)),
                      const Spacer(),
                      IconButton(
                        tooltip: tr.download,
                        icon: const Icon(Icons.download),
                        onPressed: _downloadSelected,
                      ),
                      IconButton(
                        tooltip: tr.close,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _selected.clear()),
                      ),
                    ],
                  ),
                ),
              ),
        body: !_client.isPaired
            ? _buildPairing(tr)
            : Column(
                children: [
                  _statusStrip(tr),
                  Expanded(child: _buildList(tr)),
                ],
              ),
      ),
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
      child: _currentDir.isEmpty
          ? _buildRootsView(tr)
          : _entries.isEmpty
          ? ListView(children: [Center(child: Text(tr.emptyFolder))])
          : _viewMode == 'list'
          ? ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, i) => _listTile(_entries[i]),
            )
          : LayoutBuilder(
              builder: (context, c) => GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _viewMode == 'large' ? 180 : 110,
                  childAspectRatio: 0.78,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _entries.length,
                itemBuilder: (context, i) => _gridCell(_entries[i]),
              ),
            ),
    );
  }

  /// Roots level: on top the folders the PC shared to the phone, below
  /// them the folders/files the phone shares back to the PC.
  Widget _buildRootsView(AppLocalizations tr) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _sectionHeader(tr.sharedFromPc),
        if (_entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingLg,
              vertical: AppTokens.spacingSm,
            ),
            child: Text(
              tr.emptyFolder,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else if (_viewMode == 'list')
          ..._entries.map(_listTile)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _viewMode == 'large' ? 180 : 110,
              childAspectRatio: 0.78,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _entries.length,
            itemBuilder: (context, i) => _gridCell(_entries[i]),
          ),
        const Divider(height: 28),
        _sectionHeader(tr.sharedToPc, onAdd: _sharePhoneFolder),
        if (_link.shareRoots.isEmpty)
          ListTile(
            dense: true,
            leading: const Icon(Icons.create_new_folder_outlined),
            title: Text(tr.sharePhoneFolder),
            onTap: _sharePhoneFolder,
          )
        else
          for (final r in _link.shareRoots) _shareRootTile(r),
        const Divider(height: 28),
        ListTile(
          leading: const Icon(Icons.devices_other_outlined),
          title: Text(tr.otherDevices),
          subtitle: Text(tr.otherDevicesCard),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OtherDevicesScreen()),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n(context).sharePhoneFolder,
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }

  /// One shared phone root: folder or file icon, basename + full path,
  /// trailing button removes just this share.
  Widget _shareRootTile(String path) {
    final isDir =
        FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
    return ListTile(
      dense: true,
      leading: Icon(
        isDir ? Icons.folder_shared_outlined : Icons.insert_drive_file_outlined,
      ),
      title: Text(
        path.split('/').last,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        path,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        tooltip: l10n(context).wifiStop,
        onPressed: () => _removeShareRoot(path),
      ),
    );
  }

  /// Shared thumbnail loader (cached per path).
  Widget _thumb(PcEntry e, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: FutureBuilder<Uint8List?>(
        future: _thumbCache.containsKey(e.path)
            ? Future.value(_thumbCache[e.path])
            : _client.thumb(e).then((b) => _thumbCache[e.path] = b),
        builder: (context, snap) {
          final bytes = snap.data;
          if (bytes == null) {
            return Icon(
              e.isDir ? Icons.folder : Icons.insert_drive_file_outlined,
              size: size,
            );
          }
          return Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  /// Soft outline drawn on the tile whose menu is open or which is
  /// marked selected — helps spot items among similar thumbnails.
  BoxDecoration _hlDecoration(PcEntry e) =>
      _menuPath == e.path || _selected.contains(e.path)
      ? BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        )
      : const BoxDecoration();

  Widget _listTile(PcEntry e) {
    final thumbs = context.watch<SettingsController>().shareThumbs;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: _hlDecoration(e),
      child: ListTile(
        leading: _selected.contains(e.path)
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : thumbs && !e.isDir
            ? _thumb(e, 44)
            : Icon(e.isDir ? Icons.folder : Icons.insert_drive_file_outlined),
        title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: e.isDir ? null : Text(formatBytes(e.size, SizeUnit.auto)),
        onTap: () => _openEntry(e),
        onLongPress: e.isDir ? null : () => _entryMenu(e),
        trailing: e.isDir
            ? null
            : IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _entryMenu(e),
              ),
      ),
    );
  }

  Widget _gridCell(PcEntry e) {
    final thumbs = context.watch<SettingsController>().shareThumbs;
    final iconSize = _viewMode == 'large' ? 120.0 : 60.0;
    return Container(
      decoration: _hlDecoration(e),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEntry(e),
        onLongPress: e.isDir ? null : () => _entryMenu(e),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: thumbs
                        ? _thumb(e, iconSize)
                        : Icon(
                            e.isDir
                                ? Icons.folder
                                : Icons.insert_drive_file_outlined,
                            size: iconSize,
                          ),
                  ),
                  if (_selected.contains(e.path))
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                e.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
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

/// Zoomable image that reports whether it is currently zoomed — the
/// parent pager locks its scroll physics while zoomed so panning the
/// picture doesn't flip to the next/previous image.
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.bytes, required this.onZoomChanged});

  final Uint8List bytes;
  final void Function(bool zoomed) onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final _controller = TransformationController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_notify);
  }

  void _notify() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.001;
    widget.onZoomChanged(zoomed);
  }

  @override
  void dispose() {
    _controller.removeListener(_notify);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      maxScale: 8,
      child: Image.memory(widget.bytes),
    );
  }
}

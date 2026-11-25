import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nova_link/nova_link.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/utils/file_icons.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../file_manager/application/file_browser_controller.dart';
import '../../file_manager/presentation/widgets/browser_dialogs.dart';
import '../application/mesh_service.dart';

/// "Other devices": paired computers and phones besides "my PC", the
/// folders this phone shares with them, and pairing (scan / show QR /
/// address + code).
class OtherDevicesScreen extends StatefulWidget {
  const OtherDevicesScreen({super.key});

  @override
  State<OtherDevicesScreen> createState() => _OtherDevicesScreenState();
}

class _OtherDevicesScreenState extends State<OtherDevicesScreen> {
  late final MeshService _mesh = context.read<MeshService>();
  (String, String)? _shownReceived;

  @override
  void initState() {
    super.initState();
    _mesh.addListener(_onMesh);
    _mesh.node.tick();
  }

  @override
  void dispose() {
    _mesh.removeListener(_onMesh);
    super.dispose();
  }

  void _onMesh() {
    if (!mounted) return;
    final r = _mesh.lastReceived;
    if (r != null && r != _shownReceived) {
      _shownReceived = r;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n(context).receivedFrom(r.$2, SafePath.baseName(r.$1)),
          ),
        ),
      );
    }
    setState(() {});
  }

  String _err(AppLocalizations tr, Object e) {
    final code = e is PairError ? e.code : '$e';
    return switch (code) {
      'bad_code' || 'expired' || 'too_many' => tr.pairCodeWrong,
      'closed' => tr.pairCodeWrong,
      'invalid_link' => tr.invalidPairLink,
      _ => tr.deviceUnreachable,
    };
  }

  Future<void> _run(Future<MeshPeer> Function() pair) async {
    final tr = l10n(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final p = await pair();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr.pairedWith(p.name))));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_err(tr, e))));
    }
  }

  Future<void> _addDevice() async {
    final tr = l10n(context);
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text(tr.scanOtherQr),
              onTap: () => Navigator.pop(context, 'scan'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: Text(tr.showMyQr),
              onTap: () => Navigator.pop(context, 'show'),
            ),
            ListTile(
              leading: const Icon(Icons.keyboard_outlined),
              title: Text(tr.enterAddressCode),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || v == null) return;
    if (v == 'scan') {
      final link = await Navigator.of(
        context,
      ).push<String>(MaterialPageRoute(builder: (_) => const _LinkScanPage()));
      if (link != null) await _run(() => _mesh.node.pairWithLink(link));
    } else if (v == 'show') {
      await _showMyQr();
    } else {
      await _manual();
    }
  }

  Future<void> _showMyQr() async {
    _mesh.node.pairing.open();
    await showDialog<void>(
      context: context,
      builder: (context) => _MyQrDialog(node: _mesh.node),
    );
    _mesh.node.pairing.close();
  }

  Future<void> _manual() async {
    final addr = TextEditingController();
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final tr = l10n(context);
        return AlertDialog(
          title: Text(tr.enterAddressCode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addr,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: tr.deviceAddress,
                  hintText: '192.168.1.10:48330',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: code,
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
    final a = addr.text.trim();
    final c = code.text.trim();
    addr.dispose();
    code.dispose();
    if (ok != true || a.isEmpty) return;
    // Lenient: "http://1.2.3.4:48330/", "1.2.3.4 : 48330", "1,2,3,4".
    final m = RegExp(
      r'(\d{1,3}[.,]\d{1,3}[.,]\d{1,3}[.,]\d{1,3})(?:\s*:\s*(\d{1,5}))?',
    ).firstMatch(a);
    if (m == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).invalidPairLink)));
      return;
    }
    await _run(
      () => _mesh.node.pairWith(
        m.group(1)!.replaceAll(',', '.'),
        int.tryParse(m.group(2) ?? '') ?? 48330,
        c,
      ),
    );
  }

  Future<String?> _askName(String title, String initial) async {
    final ctl = TextEditingController(text: initial);
    final v = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctl, autofocus: true, maxLength: 60),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctl.text.trim()),
            child: Text(l10n(context).save),
          ),
        ],
      ),
    );
    ctl.dispose();
    return v;
  }

  Future<void> _peerMenu(MeshPeer p) async {
    final tr = l10n(context);
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(tr.rename),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: Text(tr.removeDevice),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (v == 'rename') {
      final n = await _askName(tr.rename, p.name);
      if (n != null) await _mesh.node.rename(p, n);
    } else if (v == 'remove') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${tr.removeDevice}: ${p.name}'),
          content: Text(tr.removeDeviceNote),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr.removeDevice),
            ),
          ],
        ),
      );
      if (ok == true) await _mesh.node.remove(p);
    }
  }

  Future<void> _addShare() async {
    final browser = context.read<FileBrowserController>();
    final paths = await showMultiPickDialog(
      context,
      volumes: browser.volumes,
      initialPath: browser.currentPath.isEmpty
          ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
          : browser.currentPath,
      title: l10n(context).addShare,
    );
    if (paths == null || paths.isEmpty || !mounted) return;
    final scope = await showShareScopeDialog(context, _mesh.peers);
    if (scope == null) return;
    await _mesh.addShares(paths, all: scope.$1, ids: scope.$2);
  }

  Future<void> _editShare(MeshShare s) async {
    final scope = await showShareScopeDialog(
      context,
      _mesh.peers,
      all: s.all,
      ids: s.ids,
    );
    if (scope != null) {
      await _mesh.updateShare(s, all: scope.$1, ids: scope.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final node = _mesh.node;
    return Scaffold(
      appBar: AppBar(title: Text(tr.otherDevices)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_link),
        label: Text(tr.addDevice),
        onPressed: _addDevice,
      ),
      body: RefreshIndicator(
        onRefresh: node.tick,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                tr.otherDevicesHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.smartphone),
              title: Text(node.name),
              subtitle: Text(tr.thisDevice),
              trailing: const Icon(Icons.edit_outlined, size: 20),
              onTap: () async {
                final n = await _askName(tr.deviceName, node.name);
                if (n != null) await node.setName(n);
              },
            ),
            const Divider(),
            _header(tr.devices),
            if (_mesh.peers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(tr.noDevices, style: theme.textTheme.bodySmall),
              )
            else
              for (final p in _mesh.peers)
                ListTile(
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        p.kind == 'pc'
                            ? Icons.desktop_windows_outlined
                            : Icons.smartphone_outlined,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: _Dot(
                          color: p.online
                              ? Colors.green
                              : p.rejected
                              ? scheme.error
                              : scheme.outline,
                        ),
                      ),
                    ],
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                    p.rejected
                        ? tr.deviceRejected
                        : p.online
                        ? tr.online
                        : tr.offline,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _peerMenu(p),
                  ),
                  onLongPress: () => _peerMenu(p),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PeerBrowseScreen(peer: p),
                    ),
                  ),
                ),
            const Divider(),
            _header(tr.sharedWithDevices, onAdd: _addShare),
            if (_mesh.shares.isEmpty)
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: Text(tr.addShare),
                onTap: _addShare,
              )
            else
              for (final s in _mesh.shares)
                ListTile(
                  leading: Icon(
                    FileSystemEntity.isDirectorySync(s.path)
                        ? Icons.folder_shared_outlined
                        : Icons.insert_drive_file_outlined,
                  ),
                  title: Text(
                    SafePath.baseName(s.path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    s.all
                        ? tr.shareScopeAll
                        : _mesh.peers
                              .where((p) => s.ids.contains(p.id))
                              .map((p) => p.name)
                              .join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _editShare(s),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _mesh.removeShare(s),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _header(String title, {VoidCallback? onAdd}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (onAdd != null)
          IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
      ],
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Theme.of(context).colorScheme.surface),
    ),
  );
}

/// Share with every paired device or only with picked ones.
/// Returns (all, ids) or null when cancelled.
Future<(bool, Set<String>)?> showShareScopeDialog(
  BuildContext context,
  List<MeshPeer> peers, {
  bool all = true,
  Set<String>? ids,
}) {
  var everyone = all;
  final picked = {...?ids};
  return showDialog<(bool, Set<String>)>(
    context: context,
    builder: (context) {
      final tr = l10n(context);
      return StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: Text(tr.shareWith),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr.shareAll),
                  value: everyone,
                  onChanged: (v) => setD(() => everyone = v),
                ),
                if (!everyone)
                  for (final p in peers)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.name),
                      value: picked.contains(p.id),
                      onChanged: (v) => setD(
                        () =>
                            v == true ? picked.add(p.id) : picked.remove(p.id),
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
              onPressed: () => Navigator.pop(context, (everyone, picked)),
              child: Text(tr.save),
            ),
          ],
        ),
      );
    },
  );
}

/// This phone's pairing QR + address + one-time code. Pairing closes
/// when the dialog does.
class _MyQrDialog extends StatelessWidget {
  const _MyQrDialog({required this.node});
  final MeshNode node;

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    return StreamBuilder<void>(
      stream: node.changes,
      builder: (context, _) {
        // Close by itself once a device has paired (code rotated).
        final link = node.pairLink;
        final code = node.pairing.code;
        return AlertDialog(
          title: Text(tr.showMyQr),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (link != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: QrImageView(data: link, size: 220),
                  ),
                const SizedBox(height: 12),
                SelectableText(
                  '${tr.deviceAddress}: ${node.address ?? '—'}',
                  textAlign: TextAlign.center,
                ),
                if (code != null)
                  SelectableText(
                    '${tr.pairCode}: ${PairCode.format(code)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 8),
                Text(
                  tr.myQrHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr.close),
            ),
          ],
        );
      },
    );
  }
}

/// Scanner accepting `novalink://` pairing links.
class _LinkScanPage extends StatelessWidget {
  const _LinkScanPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n(context).scanOtherQr)),
      body: MobileScanner(
        onDetect: (capture) {
          for (final c in capture.barcodes) {
            final raw = c.rawValue;
            if (raw != null && raw.startsWith('novalink://')) {
              Navigator.pop(context, raw);
              return;
            }
          }
        },
      ),
    );
  }
}

/// Browse the folders a paired device shares with this phone:
/// download files, upload phone files into its folders.
class PeerBrowseScreen extends StatefulWidget {
  const PeerBrowseScreen({super.key, required this.peer});
  final MeshPeer peer;

  @override
  State<PeerBrowseScreen> createState() => _PeerBrowseScreenState();
}

class _PeerBrowseScreenState extends State<PeerBrowseScreen> {
  late final MeshService _mesh = context.read<MeshService>();
  final List<String> _crumbs = [];
  List<MeshEntry> _entries = [];
  bool _loading = true;
  String? _error;

  String get _dir => _crumbs.isEmpty ? '' : _crumbs.last;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _mesh.node.list(widget.peer, _dir);
      list.sort(
        (a, b) => a.isDir != b.isDir
            ? (a.isDir ? -1 : 1)
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n(context).deviceOffline;
      });
    }
  }

  final Map<String, Future<Uint8List?>> _thumbs = {};

  /// Typed icon, or the remote thumbnail (with a play badge on videos).
  Widget _leading(MeshEntry e) {
    final scheme = Theme.of(context).colorScheme;
    final icon = Icon(
      FileIcons.iconForName(e.name, isDir: e.isDir),
      color: FileIcons.colorForName(e.name, scheme, isDir: e.isDir),
    );
    if (e.isDir || !context.read<SettingsController>().shareThumbs) {
      return icon;
    }
    return SizedBox(
      width: 44,
      height: 44,
      child: FutureBuilder<Uint8List?>(
        future: _thumbs.putIfAbsent(
          e.path,
          () => _mesh.node.fetchThumb(widget.peer, e.path),
        ),
        builder: (context, s) => s.data == null
            ? Center(child: icon)
            : ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      s.data!,
                      fit: BoxFit.cover,
                      cacheWidth: 120,
                      errorBuilder: (_, _, _) => Center(child: icon),
                    ),
                    if (FileIcons.isVideoName(e.name))
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.play_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  String _startPath() {
    final browser = context.read<FileBrowserController>();
    return browser.currentPath.isEmpty
        ? (browser.volumes.isEmpty ? '/' : browser.volumes.first.path)
        : browser.currentPath;
  }

  Future<void> _download(MeshEntry e) async {
    final tr = l10n(context);
    final browser = context.read<FileBrowserController>();
    final dest = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: _startPath(),
    );
    if (dest == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text('${e.name} …')));
    try {
      final bytes = await _mesh.node.download(widget.peer, e.path);
      final dot = e.name.lastIndexOf('.');
      var out = '$dest/${e.name}';
      for (var n = 1; File(out).existsSync(); n++) {
        out = dot > 0
            ? '$dest/${e.name.substring(0, dot)} ($n)${e.name.substring(dot)}'
            : '$dest/${e.name} ($n)';
      }
      await File(out).writeAsBytes(bytes);
      messenger.showSnackBar(SnackBar(content: Text(tr.downloaded)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(tr.deviceOffline)));
    }
  }

  Future<void> _upload() async {
    final tr = l10n(context);
    final browser = context.read<FileBrowserController>();
    final path = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: _startPath(),
      pickFiles: true,
    );
    if (path == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _mesh.node.upload(
        widget.peer,
        _dir,
        SafePath.baseName(path),
        await File(path).readAsBytes(),
      );
      messenger.showSnackBar(SnackBar(content: Text(tr.uploaded)));
      _load();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(tr.deviceOffline)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    return PopScope(
      canPop: _crumbs.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _crumbs.isNotEmpty) {
          _crumbs.removeLast();
          _load();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _crumbs.isEmpty ? widget.peer.name : SafePath.baseName(_dir),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: tr.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
          ],
        ),
        floatingActionButton: _dir.isEmpty
            ? null
            : FloatingActionButton.small(
                tooltip: tr.uploadHere,
                onPressed: _upload,
                child: const Icon(Icons.upload_file),
              ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _load, child: Text(tr.refresh)),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: _entries.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text(tr.emptyFolder)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (context, i) {
                          final e = _entries[i];
                          return ListTile(
                            leading: _leading(e),
                            title: Text(
                              e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: e.isDir
                                ? null
                                : Text(formatBytes(e.size, SizeUnit.auto)),
                            trailing: e.isDir
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () => _download(e),
                                  ),
                            onTap: () {
                              if (e.isDir) {
                                _crumbs.add(e.path);
                                _load();
                              } else {
                                _download(e);
                              }
                            },
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

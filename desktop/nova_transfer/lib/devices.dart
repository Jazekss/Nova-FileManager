import 'dart:io';
import 'dart:isolate';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:nova_link/nova_link.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'l10n/generated/app_localizations.dart';

AppLocalizations _t(BuildContext c) => AppLocalizations.of(c)!;

/// JPEG thumbnail for an image file (decoded in a worker isolate).
Future<List<int>?> desktopThumb(String path) async {
  const exts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
  if (!exts.contains(path.toLowerCase().split('.').last)) return null;
  try {
    return await Isolate.run(() {
      final d = img.decodeImage(File(path).readAsBytesSync());
      if (d == null) return null;
      final t = img.copyResize(
        d,
        width: d.width >= d.height ? 160 : null,
        height: d.height > d.width ? 160 : null,
      );
      return img.encodeJpg(t, quality: 80);
    });
  } catch (_) {
    return null;
  }
}

void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(_t(context).copied)));
}

/// Address + one-time code with copy buttons.
class CodeBox extends StatelessWidget {
  const CodeBox({super.key, required this.address, required this.code});
  final String? address;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final t = _t(context);
    final scheme = Theme.of(context).colorScheme;
    Widget row(String label, String? value, {bool big = false}) => Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
        Expanded(
          child: SelectableText(
            value ?? '—',
            style: TextStyle(
              fontFamily: 'Consolas',
              fontSize: big ? 17 : 14,
              fontWeight: big ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: big ? 1.5 : 0,
            ),
          ),
        ),
        if (value != null)
          IconButton(
            tooltip: t.copy,
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copy(context, value),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          row(t.deviceAddress, address),
          row(t.pairCode, code, big: true),
        ],
      ),
    );
  }
}

String _scopeLabel(AppLocalizations t, String scope) => scope == 'all'
    ? t.scopeAll
    : scope.startsWith('ids:')
    ? t.scopeSome(
        scope.substring(4).split(',').where((e) => e.isNotEmpty).length,
      )
    : t.scopePhone;

/// Small chip showing who sees a shared PC folder.
class ScopeChip extends StatelessWidget {
  const ScopeChip({super.key, required this.scope, required this.onTap});
  final String scope;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = scope != 'phone';
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: wide
              ? scheme.tertiaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              wide ? Icons.devices_other : Icons.smartphone,
              size: 12,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _scopeLabel(_t(context), scope),
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Add folder": pick a folder and who may see it in one dialog.
/// Returns (path, scope) — or only a new scope when [path] is given.
Future<(String, String)?> showShareFolderDialog(
  BuildContext context, {
  required List<MeshPeer> peers,
  String? path,
  String scope = 'phone',
}) {
  String? picked = path;
  var mode = scope == 'all'
      ? 'all'
      : scope.startsWith('ids:')
      ? 'ids'
      : 'phone';
  final ids = scope.startsWith('ids:')
      ? scope.substring(4).split(',').where((e) => e.isNotEmpty).toSet()
      : <String>{};
  return showDialog<(String, String)>(
    context: context,
    builder: (context) {
      final t = _t(context);
      return StatefulBuilder(
        builder: (context, setD) {
          Widget option(String v, String label) => RadioListTile<String>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: v,
            title: Text(label),
          );
          return AlertDialog(
            title: Text(path == null ? t.addFolder : t.shareWith),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (path == null) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: Text(
                          picked ?? t.chooseFolder,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          final d = await FilePickerPlatform.instance
                              .getDirectoryPath(dialogTitle: t.chooseFolder);
                          if (d != null) setD(() => picked = d);
                        },
                      ),
                      const SizedBox(height: 14),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(path, overflow: TextOverflow.ellipsis),
                      ),
                    Text(
                      t.shareWith,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    RadioGroup<String>(
                      groupValue: mode,
                      onChanged: (v) => setD(() => mode = v ?? 'phone'),
                      child: Column(
                        children: [
                          option('phone', t.shareOnlyPhone),
                          option('all', t.shareAll),
                          if (peers.isNotEmpty) option('ids', t.shareSelected),
                        ],
                      ),
                    ),
                    if (mode == 'ids')
                      for (final p in peers)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(left: 24),
                          value: ids.contains(p.id),
                          title: Text(p.name),
                          secondary: Icon(
                            p.kind == 'pc'
                                ? Icons.desktop_windows_outlined
                                : Icons.smartphone,
                            size: 18,
                          ),
                          onChanged: (v) => setD(
                            () => v == true ? ids.add(p.id) : ids.remove(p.id),
                          ),
                        ),
                    const SizedBox(height: 6),
                    Text(
                      t.shareNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: picked == null
                    ? null
                    : () => Navigator.pop(context, (
                        picked!,
                        switch (mode) {
                          'all' => 'all',
                          'ids' =>
                            ids.isEmpty ? 'phone' : 'ids:${ids.join(',')}',
                          _ => 'phone',
                        },
                      )),
                child: Text(path == null ? t.add : t.save),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Tab strip above the right panel: "My phone" + one tab per paired
/// device. Double-click renames a device.
class DeviceTabs extends StatelessWidget {
  const DeviceTabs({
    super.key,
    required this.peers,
    required this.selected,
    required this.phoneOnline,
    required this.onSelect,
    required this.onRename,
  });

  final List<MeshPeer> peers;
  final String? selected;
  final bool phoneOnline;
  final void Function(String? id) onSelect;
  final void Function(MeshPeer) onRename;

  @override
  Widget build(BuildContext context) {
    final t = _t(context);
    final scheme = Theme.of(context).colorScheme;
    Widget tab({
      required String label,
      required IconData icon,
      required bool active,
      required bool online,
      required VoidCallback onTap,
      VoidCallback? onDouble,
    }) {
      final dot = online ? Colors.green.shade600 : scheme.outlineVariant;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Tooltip(
          message: onDouble == null ? '' : t.pickTab,
          waitDuration: const Duration(seconds: 1),
          child: Material(
            color: active ? scheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              onDoubleTap: onDouble,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
        children: [
          tab(
            label: t.myPhone,
            icon: Icons.smartphone,
            active: selected == null,
            online: phoneOnline,
            onTap: () => onSelect(null),
          ),
          for (final p in peers)
            tab(
              label: p.name,
              icon: p.kind == 'pc'
                  ? Icons.desktop_windows_outlined
                  : Icons.phone_android,
              active: selected == p.id,
              online: p.online,
              onTap: () => onSelect(p.id),
              onDouble: () => onRename(p),
            ),
        ],
      ),
    );
  }
}

/// Files a paired device shares with this PC: browse, download to a
/// picked folder, upload PC files into its folders.
class PeerPanel extends StatefulWidget {
  const PeerPanel({
    super.key,
    required this.node,
    required this.peer,
    required this.thumbs,
  });

  final MeshNode node;
  final MeshPeer peer;
  final bool thumbs;

  @override
  State<PeerPanel> createState() => _PeerPanelState();
}

class _PeerPanelState extends State<PeerPanel> {
  final List<String> _crumbs = [];
  List<MeshEntry> _entries = [];
  bool _loading = false;
  String? _error;
  final Map<String, Future<Uint8List?>> _thumbs = {};
  bool _wasOnline = false;

  String get _dir => _crumbs.isEmpty ? '' : _crumbs.last;

  @override
  void initState() {
    super.initState();
    _wasOnline = widget.peer.online;
    _load();
  }

  @override
  void didUpdateWidget(PeerPanel old) {
    super.didUpdateWidget(old);
    // Came back online → reload instead of leaving an error up.
    if (widget.peer.online && !_wasOnline && !_loading) _load();
    _wasOnline = widget.peer.online;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.node.list(widget.peer, _dir);
      list.sort(
        (a, b) => a.isDir != b.isDir
            ? (a.isDir ? -1 : 1)
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _entries = list;
        _thumbs.clear();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _t(context).deviceOffline;
      });
    }
  }

  void _snack(String s) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
    }
  }

  Future<void> _download(MeshEntry e) async {
    final t = _t(context);
    final dir = await FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: t.download,
    );
    if (dir == null) return;
    try {
      final bytes = await widget.node.download(widget.peer, e.path);
      final sep = Platform.pathSeparator;
      final name = SafePath.safeFileName(e.name) ?? 'file';
      final dot = name.lastIndexOf('.');
      var out = '$dir$sep$name';
      for (var n = 1; File(out).existsSync(); n++) {
        out = dot > 0
            ? '$dir$sep${name.substring(0, dot)} ($n)${name.substring(dot)}'
            : '$dir$sep$name ($n)';
      }
      await File(out).writeAsBytes(bytes);
      _snack('$name → $dir');
    } catch (_) {
      _snack(t.deviceOffline);
    }
  }

  Future<void> _upload() async {
    final t = _t(context);
    final res = await FilePickerPlatform.instance.pickFiles(
      dialogTitle: t.upload,
    );
    final files = res.map((f) => f.path).whereType<String>().toList();
    if (files.isEmpty) return;
    var ok = 0;
    for (final f in files) {
      try {
        await widget.node.upload(
          widget.peer,
          _dir,
          SafePath.baseName(f),
          await File(f).readAsBytes(),
        );
        ok++;
      } catch (_) {}
    }
    _snack('${t.upload}: $ok / ${files.length}');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
          child: Row(
            children: [
              if (_crumbs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  tooltip: t.back,
                  onPressed: () {
                    _crumbs.removeLast();
                    _load();
                  },
                ),
              Expanded(
                child: Text(
                  _crumbs.isEmpty ? widget.peer.name : SafePath.baseName(_dir),
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_dir.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.upload, size: 18),
                  label: Text(t.upload),
                  onPressed: _upload,
                ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: t.refresh,
                onPressed: _load,
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: _loading && _entries.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 36, color: scheme.outline),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _load,
                          child: Text(t.refresh),
                        ),
                      ],
                    ),
                  ),
                )
              : _entries.isEmpty
              ? Center(child: Text(t.emptyList))
              : ListView.builder(
                  padding: const EdgeInsets.all(6),
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final e = _entries[i];
                    Widget leading = Icon(
                      e.isDir
                          ? Icons.folder_rounded
                          : Icons.insert_drive_file_outlined,
                      color: e.isDir ? scheme.primary : scheme.onSurfaceVariant,
                    );
                    if (widget.thumbs && !e.isDir) {
                      leading = SizedBox(
                        width: 36,
                        height: 36,
                        child: FutureBuilder<Uint8List?>(
                          future: _thumbs.putIfAbsent(
                            e.path,
                            () => widget.node.fetchThumb(widget.peer, e.path),
                          ),
                          builder: (context, s) => s.data == null
                              ? leading
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    s.data!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => leading,
                                  ),
                                ),
                        ),
                      );
                    }
                    return ListTile(
                      leading: leading,
                      title: Text(e.name, overflow: TextOverflow.ellipsis),
                      subtitle: e.isDir
                          ? null
                          : Text('${(e.size / 1024).toStringAsFixed(1)} KB'),
                      trailing: e.isDir
                          ? null
                          : IconButton(
                              tooltip: t.download,
                              icon: const Icon(Icons.download, size: 18),
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
      ],
    );
  }
}

/// "Other devices": pairing QR + address + code, add by address, and
/// the list of paired devices (rename / remove). Pairing is open only
/// while this dialog is.
class DevicesDialog extends StatefulWidget {
  const DevicesDialog({super.key, required this.node});
  final MeshNode node;

  @override
  State<DevicesDialog> createState() => _DevicesDialogState();
}

class _DevicesDialogState extends State<DevicesDialog> {
  final _addr = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _msg;

  MeshNode get node => widget.node;

  @override
  void initState() {
    super.initState();
    node.pairing.open();
  }

  @override
  void dispose() {
    node.pairing.close();
    _addr.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _addByAddress() async {
    final t = _t(context);
    final m = RegExp(r'^([0-9]{1,3}(?:\.[0-9]{1,3}){3})(?::([0-9]{1,5}))?$')
        .firstMatch(_addr.text.trim());
    if (m == null) {
      setState(() => _msg = t.deviceUnreachable);
      return;
    }
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final p = await node.pairWith(
        m.group(1)!,
        int.tryParse(m.group(2) ?? '') ?? 48331,
        _code.text,
      );
      _addr.clear();
      _code.clear();
      if (mounted) setState(() => _msg = t.pairedWith(p.name));
    } on PairError catch (e) {
      if (mounted) {
        setState(
          () => _msg = e.code == 'unreachable'
              ? t.deviceUnreachable
              : t.pairCodeWrong,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _msg = t.deviceUnreachable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(MeshPeer p) async {
    final v = await renameDeviceDialog(context, p.name);
    if (v != null) await node.rename(p, v);
  }

  Future<void> _remove(MeshPeer p) async {
    final t = _t(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${t.removeDevice}: ${p.name}'),
        content: Text(t.removeDeviceNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.removeDevice),
          ),
        ],
      ),
    );
    if (ok == true) await node.remove(p);
  }

  @override
  Widget build(BuildContext context) {
    final t = _t(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return StreamBuilder<void>(
      stream: node.changes,
      builder: (context, _) {
        final link = node.pairLink;
        final code = node.pairing.code;
        return AlertDialog(
          title: Text(t.otherDevices),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: this PC's pairing QR / address / code.
                  SizedBox(
                    width: 270,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.addDevice, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 10),
                        if (link != null)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: QrImageView(data: link, size: 190),
                            ),
                          ),
                        const SizedBox(height: 10),
                        CodeBox(
                          address: node.address,
                          code: code == null ? null : PairCode.format(code),
                        ),
                        const SizedBox(height: 8),
                        Text(t.pairOtherHint, style: small),
                        const SizedBox(height: 4),
                        Text(t.codeOnce, style: small),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right: devices + add by address.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.devices,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: Text(node.name),
                              onPressed: () async {
                                final v = await renameDeviceDialog(
                                  context,
                                  node.name,
                                  title: t.deviceName,
                                );
                                if (v != null) await node.setName(v);
                              },
                            ),
                          ],
                        ),
                        if (node.peers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(t.noDevices, style: small),
                          ),
                        for (final p in node.peers)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              p.kind == 'pc'
                                  ? Icons.desktop_windows_outlined
                                  : Icons.phone_android,
                              color: p.online
                                  ? Colors.green.shade600
                                  : scheme.outline,
                            ),
                            title: Text(p.name),
                            subtitle: Text(
                              p.rejected
                                  ? t.deviceRejected
                                  : p.online
                                  ? t.online
                                  : t.offline,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: t.rename,
                                  icon: const Icon(Icons.edit, size: 16),
                                  onPressed: () => _rename(p),
                                ),
                                IconButton(
                                  tooltip: t.removeDevice,
                                  icon: const Icon(Icons.link_off, size: 16),
                                  onPressed: () => _remove(p),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 24),
                        Text(t.addByAddress, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addr,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: t.deviceAddress,
                            hintText: '192.168.1.20:48331',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: t.pairCode,
                            hintText: 'ABCD-EFGH-JKMN',
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addByAddress(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: Text(_msg ?? '', style: small)),
                            _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : FilledButton.tonal(
                                    onPressed: _addByAddress,
                                    child: Text(t.add),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.close),
            ),
          ],
        );
      },
    );
  }
}

Future<String?> renameDeviceDialog(
  BuildContext context,
  String current, {
  String? title,
}) async {
  final ctl = TextEditingController(text: current);
  final t = _t(context);
  final v = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title ?? t.rename),
      content: TextField(
        controller: ctl,
        autofocus: true,
        maxLength: 60,
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ctl.text.trim()),
          child: Text(t.save),
        ),
      ],
    ),
  );
  ctl.dispose();
  return v;
}

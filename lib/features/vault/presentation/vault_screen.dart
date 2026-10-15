import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../file_manager/application/file_browser_controller.dart';
import '../../file_manager/presentation/widgets/browser_dialogs.dart';
import '../data/vault_service.dart';

/// Encrypted vault: PIN (first launch = setup) or biometrics to unlock,
/// then list / open / export / delete encrypted items.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key, required this.service});

  final VaultService service;

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _pinController = TextEditingController();
  bool _unlocked = false;
  bool _needsSetup = false;
  bool _busy = false;
  String? _error;
  List<File> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final needsSetup = !await widget.service.hasPin();
    if (mounted) setState(() => _needsSetup = needsSetup);
    if (!needsSetup) _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final auth = LocalAuthentication();
    final reason = l10n(context).vaultUnlockReason;
    try {
      if (!await auth.canCheckBiometrics && !await auth.isDeviceSupported()) {
        return;
      }
      final ok = await auth.authenticate(localizedReason: reason);
      if (ok && mounted) _unlock();
    } catch (_) {
      // Biometric unavailable/cancelled — user can still enter the PIN.
    }
  }

  Future<void> _onPinSubmit() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _error = l10n(context).vaultPinTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    if (_needsSetup) {
      await widget.service.setPin(pin);
    } else if (!await widget.service.verifyPin(pin)) {
      setState(() {
        _busy = false;
        _error = l10n(context).vaultWrongPin;
      });
      return;
    }
    _unlock();
  }

  void _unlock() {
    _refresh();
    setState(() {
      _unlocked = true;
      _busy = false;
    });
  }

  void _refresh() {
    setState(() => _items = widget.service.list().cast<File>());
  }

  Future<void> _open(File item) async {
    try {
      final tmp = await widget.service.decryptToTemp(item);
      if (!mounted) return;
      // Open with the system picker — decrypted copy lives in private cache
      // and is removed when the vault locks (dispose).
      final browser = context.read<FileBrowserController>();
      final opened = await browser.platform.openFile(tmp);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n(context).noAppToOpen)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _export(File item) async {
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
      await widget.service.export(item, dest);
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n(context).exported)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(File item) async {
    final ok = await showConfirmDialog(
      context,
      title: l10n(context).deleteForeverQ,
      message: '"${VaultService.displayName(item)}"',
    );
    if (!ok) return;
    await widget.service.deleteItem(item);
    _refresh();
  }

  @override
  void dispose() {
    widget.service.clearTemp();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr.vault)),
      body: !_unlocked ? _buildLock(context, tr) : _buildList(context, tr),
    );
  }

  Widget _buildLock(BuildContext context, AppLocalizations tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56),
            const SizedBox(height: AppTokens.spacingMd),
            Text(
              _needsSetup ? tr.vaultSetPin : tr.vaultEnterPin,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingMd),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _onPinSubmit(),
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            FilledButton.icon(
              icon: Icon(_needsSetup ? Icons.check : Icons.lock_open),
              label: Text(_needsSetup ? tr.vaultSetPin : tr.vaultUnlock),
              onPressed: _busy ? null : _onPinSubmit,
            ),
            if (!_needsSetup)
              TextButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: Text(tr.vaultUseBiometric),
                onPressed: _tryBiometric,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations tr) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.enhanced_encryption_outlined, size: 48),
            const SizedBox(height: AppTokens.spacingMd),
            Text(tr.vaultEmpty),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              tr.vaultEmptyHint,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];
        return ListTile(
          leading: const Icon(Icons.lock),
          title: Text(
            VaultService.displayName(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(formatBytes(item.lengthSync(), SizeUnit.auto)),
          onTap: () => _open(item),
          trailing: PopupMenuButton<String>(
            onSelected: (a) {
              if (a == 'export') _export(item);
              if (a == 'delete') _delete(item);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'export', child: Text(tr.vaultExport)),
              PopupMenuItem(value: 'delete', child: Text(tr.deletePermanently)),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/platform/permissions.dart';
import '../../core/platform/storage_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';

/// Checks for storage access on startup. Without "All files access" the app
/// explains what is needed and links to the system settings page.
class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  late final StoragePermissions _permissions;
  bool? _granted;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissions = StoragePermissions(context.read<StoragePlatform>());
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when the user comes back from the system settings page.
    if (state == AppLifecycleState.resumed && _granted == false) {
      _check();
    }
  }

  Future<void> _check() async {
    final granted = await _permissions.isGranted();
    if (!mounted) return;
    setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_granted == true || _skipped) return widget.child;
    if (_granted == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.folder_shared, size: 72),
              const SizedBox(height: AppTokens.spacingLg),
              Text(
                l10n(context).permTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacingMd),
              Text(l10n(context).permBody, textAlign: TextAlign.center),
              const SizedBox(height: AppTokens.spacingLg),
              FilledButton.icon(
                icon: const Icon(Icons.settings),
                label: Text(l10n(context).permGrant),
                onPressed: () async {
                  await _permissions.request();
                  await _check();
                },
              ),
              TextButton(
                onPressed: () => setState(() => _skipped = true),
                child: Text(l10n(context).permContinueLimited),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

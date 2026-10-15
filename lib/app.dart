import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/settings/settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/l10n_ext.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/file_manager/application/file_browser_controller.dart';
import 'features/file_manager/presentation/file_manager_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/permissions/permission_gate.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return MaterialApp(
      onGenerateTitle: (context) => l10n(context).appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PermissionGate(child: MainShell()),
      routes: {'/settings': (_) => const SettingsScreen()},
    );
  }
}

/// Bottom navigation shell: Home, File Manager, Search.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  DateTime? _lastBackPress;

  void _openInFileManager(String path) {
    context.read<FileBrowserController>().navigateTo(path);
    setState(() => _tab = 1);
  }

  /// Back button order: sub-screens (pushed routes pop themselves),
  /// Files tab goes up a folder, other tabs return to Home, and Home
  /// asks for a second press within 2 s before the app exits.
  void _onBack() {
    final browser = context.read<FileBrowserController>();
    if (_tab == 1 && browser.canGoUp) {
      browser.goUp();
      return;
    }
    if (_tab != 0) {
      setState(() => _tab = 0);
      return;
    }
    final now = DateTime.now();
    final recent =
        _lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2);
    if (recent) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n(context).pressAgainToExit)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(onOpenFolder: _openInFileManager),
            const FileManagerScreen(),
            SearchScreen(onReveal: _openInFileManager),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              label: l10n(context).navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder),
              label: l10n(context).navFiles,
            ),
            NavigationDestination(
              icon: const Icon(Icons.search),
              label: l10n(context).navSearch,
            ),
          ],
        ),
      ),
    );
  }
}

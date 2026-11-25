import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_file_manager/app.dart';
import 'package:nova_file_manager/core/platform/storage_platform.dart';
import 'package:nova_file_manager/core/settings/settings_controller.dart';
import 'package:nova_file_manager/features/archive/data/archive_service.dart';
import 'package:nova_file_manager/features/file_manager/application/file_browser_controller.dart';
import 'package:nova_file_manager/features/recycle_bin/application/recycle_bin_controller.dart';
import 'package:nova_file_manager/features/recycle_bin/data/recycle_bin_service.dart';
import 'package:nova_file_manager/features/search/application/search_controller.dart'
    as search;
import 'package:nova_file_manager/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_browser_controller_test.dart' show FakeStoragePlatform;

void main() {
  late Directory tmp;

  // Real dart:io calls must live outside testWidgets (FakeAsync zone).
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('nova_widget_test');
  });

  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  testWidgets('main shell shows bottom navigation and home', (tester) async {
    final settings = SettingsController();
    await settings.load();
    final platform = FakeStoragePlatform(tmp.path.replaceAll('\\', '/'));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StoragePlatform>.value(value: platform),
          Provider<ArchiveService>(create: (_) => ArchiveService(platform)),
          ChangeNotifierProvider<SettingsController>.value(value: settings),
          ChangeNotifierProvider<FileBrowserController>(
            create: (_) => FileBrowserController(platform, settings),
          ),
          ChangeNotifierProvider<search.SearchController>(
            create: (_) => search.SearchController(settings),
          ),
          ChangeNotifierProvider<RecycleBinController>(
            create: (_) => RecycleBinController(
              RecycleBinService(binDir: '${tmp.path}/bin'),
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainShell(),
        ),
      ),
    );
    // Pump a few frames so async volume/directory loading settles.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Files'),
      ),
      findsOneWidget,
    );
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Nova File Manager'), findsOneWidget);
  });
}

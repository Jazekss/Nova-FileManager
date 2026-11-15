import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nova_link/nova_link.dart' show LanStream;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/platform/storage_platform.dart';
import 'core/settings/settings_controller.dart';
import 'features/archive/data/archive_service.dart';
import 'features/file_manager/application/file_browser_controller.dart';
import 'features/devices/application/mesh_service.dart';
import 'features/pc_share/application/pc_link_service.dart';
import 'features/recycle_bin/application/recycle_bin_controller.dart';
import 'features/recycle_bin/data/recycle_bin_service.dart';
import 'features/drive/data/drive_service.dart';
import 'features/search/application/search_controller.dart' as search;
import 'features/vault/data/vault_service.dart';

const _storage = MethodChannel('dev.nova.nova_file_manager/storage');

Future<Uint8List> _aes(
  bool enc,
  Uint8List key,
  Uint8List nonce,
  Uint8List data,
  Uint8List aad,
) async {
  final r = await _storage.invokeMethod<Uint8List>('aesGcm', {
    'enc': enc,
    'key': key,
    'nonce': nonce,
    'data': data,
    'aad': aad,
  });
  if (r == null) throw StateError('aes');
  return r;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Transfer frames use Android's hardware AES-GCM (pure Dart is ~10×
  // slower and made PC previews crawl).
  LanStream.nativeSeal = (k, n, d, a) => _aes(true, k, n, d, a);
  LanStream.nativeOpen = (k, n, d, a) => _aes(false, k, n, d, a);
  final settings = SettingsController();
  await settings.load();

  final platform = MethodChannelStoragePlatform();

  // Recycle bin lives in the app-private external files dir.
  final extDir = await getExternalStorageDirectory();
  final binRoot = extDir?.path ?? (await getApplicationSupportDirectory()).path;
  final binService = RecycleBinService(binDir: '$binRoot/recycle_bin');
  await binService.init();

  // Vault lives in app-private internal storage (invisible to other apps).
  final supportDir = await getApplicationSupportDirectory();
  final cacheDir = await getTemporaryDirectory();
  final vaultService = VaultService(
    vaultDir: '${supportDir.path}/vault',
    cacheDir: cacheDir.path,
  );

  // PC link reconnects in the background from app start — opening the
  // app is enough to get back in touch with the paired desktop.
  final pcLink = PcLinkService();
  pcLink.init();
  // Other devices (extra PCs/phones) — reconnect while Nova is open.
  final mesh = MeshService();
  mesh.init();

  runApp(
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
          create: (_) => RecycleBinController(binService),
        ),
        Provider<VaultService>.value(value: vaultService),
        Provider<DriveService>(create: (_) => DriveService()),
        ChangeNotifierProvider<PcLinkService>.value(value: pcLink),
        ChangeNotifierProvider<MeshService>.value(value: mesh),
      ],
      child: const NovaApp(),
    ),
  );
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/generated/app_localizations.dart';
import 'lan_crypto.dart';
import 'server.dart';
import 'settings.dart';

const _coffeeUrl = 'https://www.buymeacoffee.com/jazeks';
const _devUrl = 'https://jkdizains.lv';
const _appVersion = '1.0.0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = DesktopSettings();
  await settings.load();
  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: const NovaDesktopApp(),
    ),
  );
}

class NovaDesktopApp extends StatelessWidget {
  const NovaDesktopApp({super.key});

  /// Same seed + radius tokens as the Android app's AppTheme.
  static const _seed = Color(0xFF3D5AFE);
  static const _cardRadius = 16.0;

  static const supported = [
    Locale('en'),
    Locale('lv'),
    Locale('lt'),
    Locale('et'),
    Locale('nb'),
    Locale('sv'),
    Locale('pl'),
    Locale('de'),
    Locale('ru'),
  ];

  static const languageNames = {
    'en': 'English',
    'lv': 'Latviešu',
    'lt': 'Lietuvių',
    'et': 'Eesti',
    'nb': 'Norsk',
    'sv': 'Svenska',
    'pl': 'Polski',
    'de': 'Deutsch',
    'ru': 'Русский',
  };

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DesktopSettings>();
    return MaterialApp(
      title: 'Nova Transfer',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      locale: settings.languageCode == null
          ? null
          : Locale(settings.languageCode!),
      supportedLocales: supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const DesktopHome(),
    );
  }
}

AppLocalizations tr(BuildContext context) => AppLocalizations.of(context)!;

class _RemoteEntry {
  const _RemoteEntry({
    required this.name,
    required this.index,
    required this.isDir,
    this.size = 0,
  });
  final String name;
  final int index;
  final bool isDir;
  final int size;
}

class DesktopHome extends StatefulWidget {
  const DesktopHome({super.key});

  @override
  State<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends State<DesktopHome> {
  late final PairServer _server = PairServer(
    token: context.read<DesktopSettings>().pairToken,
    onPhoneChanged: (url) {
      _phoneUrl = url;
      if (mounted) setState(() {});
      if (url != null) _refreshPhoneList();
    },
  );

  String? _phoneUrl;
  List<_RemoteEntry> _phoneFiles = [];
  String? _phoneError;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    final settings = context.read<DesktopSettings>();
    _server.sharedRoots = settings.sharedFolders;
    // Persist the token so the pairing link stays identical next launch.
    if (settings.pairToken != _server.token) {
      settings.savePairToken(_server.token);
    }
    _server.start();
    // Poll the phone registration so the right panel updates even if the
    // /api/pair callback fired before the widget was ready.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _checkPhone());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _server.stop();
    super.dispose();
  }

  Future<void> _checkPhone() async {
    // Server knows the registered phone URL directly.
    if (_phoneUrl != _server.phoneUrl) {
      setState(() {
        _phoneUrl = _server.phoneUrl;
        _phoneFiles = [];
      });
      if (_phoneUrl != null) _refreshPhoneList();
    }
  }

  /// The registered phoneUrl carries `?k=<shareToken>` — requests to the
  /// phone are HMAC-signed and answers are AES-GCM sealed.
  (String base, String key) get _phoneParts {
    final u = Uri.parse(_phoneUrl!);
    return (
      'http://${u.host}:${u.port}',
      u.queryParameters['k'] ?? '',
    );
  }

  /// Signed GET against the phone share server → decrypted bytes.
  /// Returns null for 204 (no thumbnail).
  Future<Uint8List?> _phoneGet(String path) async {
    final (base, key) = _phoneParts;
    final ts = LanCrypto.now();
    final sig = LanCrypto.sign(key, 'GET', path, ts);
    final res = await http
        .get(Uri.parse('$base$path?ts=$ts&sig=$sig'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 204) return null;
    if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
    final plain = await LanCrypto.open(key, res.bodyBytes);
    if (plain == null) throw 'decrypt_failed';
    return plain;
  }

  Future<void> _phonePost(String path, Object body) async {
    final (base, key) = _phoneParts;
    final ts = LanCrypto.now();
    final sig = LanCrypto.sign(key, 'POST', path, ts);
    final packed = await LanCrypto.seal(key, utf8.encode(jsonEncode(body)));
    await http
        .post(
          Uri.parse('$base$path?ts=$ts&sig=$sig'),
          body: packed,
        )
        .timeout(const Duration(seconds: 5));
  }

  Future<Uint8List?> _phoneThumb(int index) =>
      _phoneUrl == null ? Future.value() : _phoneGet('/api/thumb?i=$index');

  Future<void> _refreshPhoneList() async {
    if (_phoneUrl == null) return;
    try {
      final bytes = await _phoneGet('/api/list');
      if (bytes == null) throw 'empty';
      final list = (jsonDecode(utf8.decode(bytes)) as List)
          .map(
            (e) => _RemoteEntry(
              name: e['name'] as String,
              index: e['i'] as int,
              isDir: false,
              size: e['size'] as int,
            ),
          )
          .toList();
      if (mounted) {
        setState(() {
          _phoneFiles = list;
          _phoneError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phoneFiles = [];
          _phoneError = tr(context).phoneUnreachable;
        });
      }
    }
  }

  Future<void> _downloadPhoneFile(_RemoteEntry f) async {
    try {
      if (!mounted) return;
      final dir = await FilePickerPlatform.instance.getDirectoryPath(
        dialogTitle: tr(context).download,
      );
      if (dir == null) return;
      final bytes = await _phoneGet('/f/${f.index}');
      if (bytes == null) throw 'empty';
      final sep = Platform.pathSeparator;
      var out = '$dir$sep${f.name}';
      var n = 1;
      while (File(out).existsSync()) {
        final dot = f.name.lastIndexOf('.');
        out = dot > 0
            ? '$dir$sep${f.name.substring(0, dot)} ($n)${f.name.substring(dot)}'
            : '$dir$sep${f.name} ($n)';
        n++;
      }
      await File(out).writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${f.name} → $dir')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _disconnect() async {
    final url = _phoneUrl;
    if (url != null) {
      try {
        // Tell the phone's share server to drop the pairing too.
        await _phonePost('/api/unpair', {});
      } catch (_) {}
    }
    setState(() {
      _phoneUrl = null;
      _phoneFiles = [];
    });
  }

  Future<void> _addFolder() async {
    final dir = await FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: tr(context).addFolder,
    );
    if (dir == null || !mounted) return;
    final settings = context.read<DesktopSettings>();
    final list = [..._server.sharedRoots];
    if (!list.contains(dir)) list.add(dir);
    _server.sharedRoots = list;
    await settings.setSharedFolders(list);
    if (mounted) setState(() {});
  }

  Future<void> _removeFolder(String path) async {
    final list = [..._server.sharedRoots]..remove(path);
    _server.sharedRoots = list;
    await context.read<DesktopSettings>().setSharedFolders(list);
    setState(() {});
  }

  void _showConnectionDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).connection),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_server.ip != null) ...[
                // White card so camera QR scanning works in dark theme too.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: _server.pairUrl,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(context).qrHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${tr(context).pairUrl}: ${_server.pairUrl}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _phoneUrl != null
                        ? Icons.smartphone
                        : Icons.smartphone_outlined,
                    color: _phoneUrl != null ? Colors.green : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _phoneUrl != null
                          ? '${tr(context).phoneConnected}\n$_phoneUrl'
                          : tr(context).noPhone,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (_phoneUrl != null)
            TextButton(
              onPressed: () {
                _disconnect();
                Navigator.pop(context);
              },
              child: Text(tr(context).disconnect),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// "APK with QR" — pick an .apk, then show a QR with an http:// link.
  /// The phone's camera/browser downloads it into Download/.
  void _showApkQrDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        String? picked = _server.sharedApk;
        return StatefulBuilder(
          builder: (context, setD) => AlertDialog(
            title: Text(tr(context).shareApk),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(context).apkQrHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.android),
                    label: Text(
                      picked ?? tr(context).chooseApk,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      final res = await FilePickerPlatform.instance.pickFiles(
                        dialogTitle: tr(context).chooseApk,
                        type: FileType.custom,
                        allowedExtensions: ['apk'],
                      );
                      final path =
                          res.isEmpty ? null : res.first.path;
                      if (path != null) {
                        _server.sharedApk = path;
                        setD(() => picked = path);
                      }
                    },
                  ),
                  if (picked != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data:
                            'http://${_server.ip}:${_server.port}'
                            '/apk?token=${_server.token}',
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context).apkScanNow,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _server.sharedApk = null;
                  Navigator.pop(context);
                },
                child: Text(tr(context).remove),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettings() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final settings = context.watch<DesktopSettings>();
        return AlertDialog(
          title: Text(tr(context).settings),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr(context).language),
                DropdownButton<String?>(
                  isExpanded: true,
                  value: settings.languageCode,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(tr(context).themeAuto),
                    ),
                    for (final l in NovaDesktopApp.supported)
                      DropdownMenuItem(
                        value: l.languageCode,
                        child: Text(
                          NovaDesktopApp.languageNames[l.languageCode] ??
                              l.languageCode,
                        ),
                      ),
                  ],
                  onChanged: (v) => settings.setLanguage(v),
                ),
                const SizedBox(height: 12),
                Text(tr(context).theme),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(tr(context).themeAuto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(tr(context).themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(tr(context).themeDark),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => settings.setTheme(s.first),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(context).shareThumbs),
                  subtitle: Text(
                    tr(context).shareThumbsNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: settings.showThumbs,
                  onChanged: settings.setShowThumbs,
                ),
                const Divider(height: 28),
                Text('${tr(context).version}: $_appVersion'),
                InkWell(
                  onTap: () => launchUrl(Uri.parse(_devUrl)),
                  child: Text(
                    '${tr(context).developer}: JKdizains',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: SvgPicture.asset(
                    'assets/coffee.svg',
                    width: 18,
                    height: 18,
                  ),
                  label: Text(tr(context).buyCoffee),
                  onPressed: () => launchUrl(Uri.parse(_coffeeUrl)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DesktopSettings>();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset('assets/icon.png'),
        ),
        titleSpacing: 0,
        title: Text(
          'Nova Transfer',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: FilledButton.tonalIcon(
              icon: Icon(
                _phoneUrl != null ? Icons.link : Icons.qr_code_2,
                color: _phoneUrl != null ? Colors.green : null,
              ),
              label: Text(
                _phoneUrl != null
                    ? tr(context).phoneConnected
                    : tr(context).connection,
              ),
              onPressed: _showConnectionDialog,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: tr(context).options,
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'apk') _showApkQrDialog();
              if (v == 'settings') _showSettings();
              if (v == 'coffee') launchUrl(Uri.parse(_coffeeUrl));
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'apk',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.qr_code_2),
                  title: Text(tr(context).shareApk),
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.settings),
                  title: Text(tr(context).settings),
                ),
              ),
              PopupMenuItem(
                value: 'coffee',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.coffee),
                  title: Text(tr(context).buyCoffee),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PcPanel(
              folders: settings.sharedFolders,
              onAdd: _addFolder,
              onRemove: _removeFolder,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _PhonePanel(
              connected: _phoneUrl != null,
              files: _phoneFiles,
              error: _phoneError,
              thumbs: settings.showThumbs,
              fetchThumb: _phoneThumb,
              onRefresh: _refreshPhoneList,
              onDownload: _downloadPhoneFile,
              onDisconnect: _disconnect,
            ),
          ),
        ],
      ),
    );
  }
}

/// Left panel: PC folders shared with the phone.
class _PcPanel extends StatelessWidget {
  const _PcPanel({
    required this.folders,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> folders;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr(context).pcFolders,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: tr(context).addFolder,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        Expanded(
          child: folders.isEmpty
              ? Center(child: Text(tr(context).emptyList))
              : ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (context, i) {
                    final f = folders[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder_shared_outlined),
                      title: Text(f, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: tr(context).remove,
                        onPressed: () => onRemove(f),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Right panel: files the phone shared while paired.
class _PhonePanel extends StatelessWidget {
  const _PhonePanel({
    required this.connected,
    required this.files,
    required this.error,
    required this.thumbs,
    required this.fetchThumb,
    required this.onRefresh,
    required this.onDownload,
    required this.onDisconnect,
  });

  final bool connected;
  final List<_RemoteEntry> files;
  final String? error;
  final bool thumbs;
  final Future<Uint8List?> Function(int index) fetchThumb;
  final VoidCallback onRefresh;
  final void Function(_RemoteEntry) onDownload;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr(context).phoneFiles,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: tr(context).refresh,
                onPressed: connected ? onRefresh : null,
              ),
              if (connected)
                IconButton(
                  icon: const Icon(Icons.link_off),
                  tooltip: tr(context).disconnect,
                  onPressed: onDisconnect,
                ),
            ],
          ),
        ),
        Expanded(
          child: !connected
              ? Center(child: Text(tr(context).noPhone))
              : error != null
              ? Center(child: Text(error!))
              : files.isEmpty
              ? Center(child: Text(tr(context).emptyList))
              : RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, i) {
                      final f = files[i];
                      return ListTile(
                        dense: true,
                        leading: thumbs
                            ? FutureBuilder<Uint8List?>(
                                future: fetchThumb(f.index),
                                builder: (context, snap) {
                                  final b = snap.data;
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: b != null
                                        ? Image.memory(
                                            b,
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.smartphone),
                                  );
                                },
                              )
                            : const Icon(Icons.smartphone),
                        title: Text(f.name, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${(f.size / 1024).toStringAsFixed(1)} KB',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: tr(context).download,
                          onPressed: () => onDownload(f),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

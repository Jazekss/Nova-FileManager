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
    required this.path,
    required this.isDir,
    this.size = 0,
  });
  final String name;
  final String path;
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
      _phoneCrumbs.clear();
      _sel.clear();
      context.read<DesktopSettings>().setPhoneUrl(url);
      if (mounted) setState(() {});
      if (url != null) _refreshPhoneList();
    },
  );

  String? _phoneUrl;
  List<_RemoteEntry> _phoneFiles = [];
  String? _phoneError;
  Timer? _poll;

  /// Dir navigation inside the phone's shared roots — '' = the roots.
  final List<String> _phoneCrumbs = [];
  String get _phoneDir => _phoneCrumbs.isEmpty ? '' : _phoneCrumbs.last;

  /// Marked files (lightbox checkmarks / tile checkboxes) — paths.
  final Set<String> _sel = {};

  /// Left pane width — persisted via DesktopSettings.paneWidth.
  late double _paneW = context.read<DesktopSettings>().paneWidth;

  /// Path of the phone file whose ⋮ menu is open (gets a soft outline).
  String? _menuPath;

  @override
  void initState() {
    super.initState();
    final settings = context.read<DesktopSettings>();
    _server.sharedRoots = settings.sharedFolders;
    // Persist the token so the pairing link stays identical next launch.
    if (settings.pairToken != _server.token) {
      settings.savePairToken(_server.token);
    }
    // Restore the last registered phone — its share server may still be
    // running, so the panel reconnects without the phone re-registering.
    if (settings.phoneUrl != null) {
      _server.restorePhoneUrl(settings.phoneUrl);
      _phoneUrl = settings.phoneUrl;
    }
    _server.start().then((_) {
      if (_phoneUrl != null) _refreshPhoneList();
    });
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
    return ('http://${u.host}:${u.port}', u.queryParameters['k'] ?? '');
  }

  /// Signed GET against the phone share server → decrypted bytes.
  /// Returns null for 204 (no thumbnail).
  Future<Uint8List?> _phoneGet(String path) async {
    final (base, key) = _phoneParts;
    // Sign the path WITHOUT the query string — the server verifies
    // req.uri.path only.
    final signPath = path.split('?').first;
    final ts = LanCrypto.now();
    final sig = LanCrypto.sign(key, 'GET', signPath, ts);
    final sep = path.contains('?') ? '&' : '?';
    final res = await http
        .get(Uri.parse('$base$path${sep}ts=$ts&sig=$sig'))
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
        .post(Uri.parse('$base$path?ts=$ts&sig=$sig'), body: packed)
        .timeout(const Duration(seconds: 5));
  }

  Future<Uint8List?> _phoneThumb(String path) => _phoneUrl == null
      ? Future.value()
      : _phoneGet('/api/thumb?path=${Uri.encodeQueryComponent(path)}');

  /// Browsable listing: roots when _phoneDir is '', otherwise the dir's
  /// contents — the phone exposes whole shared folders, not a flat list.
  Future<void> _refreshPhoneList() async {
    if (_phoneUrl == null) return;
    try {
      final d = _phoneDir;
      final bytes = await _phoneGet(
        '/api/list${d.isEmpty ? '' : '?dir=${Uri.encodeQueryComponent(d)}'}',
      );
      if (bytes == null) throw 'empty';
      final list = (jsonDecode(utf8.decode(bytes)) as List)
          .map(
            (e) => _RemoteEntry(
              name: e['name'] as String,
              path: e['path'] as String,
              isDir: e['isDir'] as bool,
              size: (e['size'] as int?) ?? 0,
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

  /// Downloads a phone file into [dir] (already picked).
  Future<void> _phoneDownloadTo(_RemoteEntry f, String dir) async {
    final bytes = await _phoneGet(
      '/api/dl?path=${Uri.encodeQueryComponent(f.path)}',
    );
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
  }

  Future<void> _downloadPhoneFile(_RemoteEntry f) async {
    try {
      if (!mounted) return;
      final dir = await FilePickerPlatform.instance.getDirectoryPath(
        dialogTitle: tr(context).download,
      );
      if (dir == null) return;
      await _phoneDownloadTo(f, dir);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${f.name} → $dir')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  /// Downloads every selected phone file into one picked folder.
  Future<void> _downloadSelected() async {
    if (!mounted) return;
    final dir = await FilePickerPlatform.instance.getDirectoryPath(
      dialogTitle: tr(context).download,
    );
    if (dir == null) return;
    var ok = 0;
    for (final p in _sel.toList()) {
      final f = _phoneFiles.firstWhere(
        (e) => e.path == p,
        orElse: () =>
            _RemoteEntry(name: p.split('/').last, path: p, isDir: false),
      );
      if (f.isDir) continue;
      try {
        await _phoneDownloadTo(f, dir);
        ok++;
      } catch (_) {}
    }
    setState(() => _sel.clear());
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$ok → $dir')));
    }
  }

  /// Deletes the marked files/folders on the phone (shared roots only)
  /// — gated by the "Manage files on phone" settings switch.
  Future<void> _deleteSelected() async {
    final paths = _sel.toList();
    var ok = 0;
    for (final p in paths) {
      try {
        await _phonePost('/api/delete', {'path': p});
        ok++;
      } catch (_) {}
    }
    setState(() => _sel.clear());
    _refreshPhoneList();
    if (mounted && ok < paths.length) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${paths.length - ok} failed')));
    }
  }

  Future<void> _deletePhoneFile(_RemoteEntry f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).delete),
        content: Text(f.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context).delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _phonePost('/api/delete', {'path': f.path});
      _refreshPhoneList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  static const _imgExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
  static const _videoExts = {'mp4', 'mkv', 'avi', 'mov', 'webm', '3gp'};

  static String _ext(_RemoteEntry f) =>
      f.name.contains('.') ? f.name.split('.').last.toLowerCase() : '';

  /// Lightbox over ALL images in the current phone dir — arrows/swipe
  /// switch between them, check icon marks files for a batch download;
  /// marks persist after closing. Videos open in the system player.
  Future<void> _previewPhoneFile(_RemoteEntry f) async {
    final ext = _ext(f);
    if (_imgExts.contains(ext)) {
      final images = _phoneFiles
          .where((x) => !x.isDir && _imgExts.contains(_ext(x)))
          .toList();
      var idx = images.indexOf(f);
      if (idx < 0) idx = 0;
      final controller = PageController(initialPage: idx);
      await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setD) {
            final cur = images[idx];
            void dl() => _downloadPhoneFile(cur);
            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Center(
                    child: PageView.builder(
                      controller: controller,
                      itemCount: images.length,
                      onPageChanged: (i) => setD(() => idx = i),
                      itemBuilder: (context, i) => FutureBuilder<Uint8List?>(
                        future: _phoneGet(
                          '/api/dl?path='
                          '${Uri.encodeQueryComponent(images[i].path)}',
                        ),
                        builder: (context, snap) =>
                            snap.connectionState != ConnectionState.done
                            ? const CircularProgressIndicator()
                            : snap.data == null
                            ? const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                                size: 64,
                              )
                            : GestureDetector(
                                // Right-click downloads the image.
                                onSecondaryTap: () {
                                  Navigator.pop(context);
                                  dl();
                                },
                                child: InteractiveViewer(
                                  maxScale: 8,
                                  child: Image.memory(snap.data!),
                                ),
                              ),
                      ),
                    ),
                  ),
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
                    top: 8,
                    left: 8,
                    child: IconButton(
                      tooltip: tr(context).back,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        // Mark for batch download — persists after close.
                        IconButton(
                          tooltip: 'Select',
                          icon: Icon(
                            _sel.contains(cur.path)
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(
                            () => setD(
                              () => _sel.contains(cur.path)
                                  ? _sel.remove(cur.path)
                                  : _sel.add(cur.path),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: tr(context).download,
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                            dl();
                          },
                        ),
                        IconButton(
                          tooltip: tr(context).close,
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
      return;
    }
    if (_videoExts.contains(ext)) {
      try {
        final bytes = await _phoneGet(
          '/api/dl?path=${Uri.encodeQueryComponent(f.path)}',
        );
        if (bytes == null) throw 'fetch';
        final tmp = Directory.systemTemp.createTempSync('nova_preview');
        final file = File('${tmp.path}\\${f.name}');
        await file.writeAsBytes(bytes);
        // Open with the system's default video player.
        await Process.start(file.path, [], runInShell: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Future<void> _renamePhoneFile(_RemoteEntry f) async {
    final controller = TextEditingController(text: f.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).rename),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == f.name) return;
    try {
      await _phonePost('/api/rename', {'path': f.path, 'name': newName});
      _refreshPhoneList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
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
      _phoneCrumbs.clear();
      _sel.clear();
    });
    if (mounted) context.read<DesktopSettings>().setPhoneUrl(null);
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
                      final path = res.isEmpty ? null : res.first.path;
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

  /// Click on the green "Connected" button — confirm disconnect; the
  /// phone gets /api/unpair so it drops its side too.
  void _confirmDisconnect() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).disconnect),
        content: Text('$_phoneUrl'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _disconnect();
            },
            child: Text(tr(context).disconnect),
          ),
        ],
      ),
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
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(context).managePhone),
                  subtitle: Text(
                    tr(context).managePhoneNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: settings.managePhone,
                  onChanged: settings.setManagePhone,
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
            child: _phoneUrl != null
                // Green "Connected" button — click asks to disconnect,
                // which also unpairs the phone side.
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.smartphone),
                    label: Text(tr(context).phoneConnected),
                    onPressed: _confirmDisconnect,
                  )
                : FilledButton.tonalIcon(
                    icon: const Icon(Icons.qr_code_2),
                    label: Text(tr(context).connection),
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
          SizedBox(
            width: _paneW,
            child: _PcPanel(
              folders: settings.sharedFolders,
              onAdd: _addFolder,
              onRemove: _removeFolder,
            ),
          ),
          // Draggable divider — width persists via DesktopSettings.
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (d) => setState(
                () => _paneW = (_paneW + d.delta.dx).clamp(180.0, 700.0),
              ),
              onPanEnd: (_) =>
                  context.read<DesktopSettings>().setPaneWidth(_paneW),
              child: Container(
                width: 9,
                color: Theme.of(context).colorScheme.outlineVariant
                    .withValues(alpha: 0.4),
              ),
            ),
          ),
          Expanded(
            child: _PhonePanel(
              connected: _phoneUrl != null,
              files: _phoneFiles,
              error: _phoneError,
              thumbs: settings.showThumbs,
              viewMode: settings.viewMode,
              menuPath: _menuPath,
              crumbs: _phoneCrumbs,
              selected: _sel,
              managePhone: settings.managePhone,
              fetchThumb: _phoneThumb,
              onViewMode: (m) => context.read<DesktopSettings>().setViewMode(m),
              onMenuOpen: (p) => setState(() => _menuPath = p),
              onOpenDir: (d) {
                _phoneCrumbs.add(d);
                _refreshPhoneList();
              },
              onUp: _phoneCrumbs.isEmpty
                  ? null
                  : () {
                      _phoneCrumbs.removeLast();
                      _refreshPhoneList();
                    },
              onPreview: _previewPhoneFile,
              onRename: _renamePhoneFile,
              onDelete: _deletePhoneFile,
              onToggleSelect: (f) => setState(
                () => _sel.contains(f.path)
                    ? _sel.remove(f.path)
                    : _sel.add(f.path),
              ),
              onDownloadSelected: _downloadSelected,
              onDeleteSelected: _deleteSelected,
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
                    final name = f
                        .split(Platform.pathSeparator)
                        .lastWhere((s) => s.isNotEmpty, orElse: () => f);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder_shared_outlined),
                      title: Text(name, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        f,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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

/// Right panel: files the phone shared while paired — Explorer-style
/// adaptive layout: list, small or large icon grid depending on width.
/// Dirs are browsable via crumbs; checkboxes (Manage-files setting)
/// select items for batch download/delete.
class _PhonePanel extends StatelessWidget {
  const _PhonePanel({
    required this.connected,
    required this.files,
    required this.error,
    required this.thumbs,
    required this.viewMode,
    required this.menuPath,
    required this.crumbs,
    required this.selected,
    required this.managePhone,
    required this.fetchThumb,
    required this.onViewMode,
    required this.onMenuOpen,
    required this.onOpenDir,
    required this.onUp,
    required this.onPreview,
    required this.onRename,
    required this.onDelete,
    required this.onToggleSelect,
    required this.onDownloadSelected,
    required this.onDeleteSelected,
    required this.onRefresh,
    required this.onDownload,
    required this.onDisconnect,
  });

  final bool connected;
  final List<_RemoteEntry> files;
  final String? error;
  final bool thumbs;
  final String viewMode;
  final String? menuPath;
  final List<String> crumbs;
  final Set<String> selected;
  final bool managePhone;
  final Future<Uint8List?> Function(String path) fetchThumb;
  final void Function(String) onViewMode;
  final void Function(String?) onMenuOpen;
  final void Function(String) onOpenDir;
  final VoidCallback? onUp;
  final void Function(_RemoteEntry) onPreview;
  final void Function(_RemoteEntry) onRename;
  final void Function(_RemoteEntry) onDelete;
  final void Function(_RemoteEntry) onToggleSelect;
  final VoidCallback onDownloadSelected;
  final VoidCallback onDeleteSelected;
  final VoidCallback onRefresh;
  final void Function(_RemoteEntry) onDownload;
  final VoidCallback onDisconnect;

  static const _imgExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
  static const _videoExts = {'mp4', 'mkv', 'avi', 'mov', 'webm', '3gp'};

  static bool _previewable(_RemoteEntry f) {
    final ext = f.name.contains('.')
        ? f.name.split('.').last.toLowerCase()
        : '';
    return _imgExts.contains(ext) || _videoExts.contains(ext);
  }

  void _tap(_RemoteEntry f) {
    if (f.isDir) {
      onOpenDir(f.path);
    } else if (_previewable(f)) {
      onPreview(f);
    } else {
      onDownload(f);
    }
  }

  Widget _thumbOrIcon(_RemoteEntry f, double size) {
    if (f.isDir) return Icon(Icons.folder, size: size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: thumbs
          ? FutureBuilder<Uint8List?>(
              future: fetchThumb(f.path),
              builder: (context, snap) {
                final b = snap.data;
                if (b == null) {
                  return Icon(Icons.insert_drive_file_outlined, size: size);
                }
                return Image.memory(
                  b,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                );
              },
            )
          : Icon(Icons.insert_drive_file_outlined, size: size),
    );
  }

  Widget _menu(BuildContext context, _RemoteEntry f) {
    return PopupMenuButton<String>(
      tooltip: '',
      icon: const Icon(Icons.more_vert, size: 18),
      onOpened: () => onMenuOpen(f.path),
      onCanceled: () => onMenuOpen(null),
      onSelected: (v) {
        onMenuOpen(null);
        if (v == 'preview') onPreview(f);
        if (v == 'download') onDownload(f);
        if (v == 'rename') onRename(f);
        if (v == 'delete') onDelete(f);
      },
      itemBuilder: (context) => [
        if (!f.isDir && _previewable(f))
          PopupMenuItem(
            value: 'preview',
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.visibility_outlined),
              title: Text(tr(context).view),
            ),
          ),
        if (!f.isDir)
          PopupMenuItem(
            value: 'download',
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.download),
              title: Text(tr(context).download),
            ),
          ),
        PopupMenuItem(
          value: 'rename',
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.drive_file_rename_outline),
            title: Text(tr(context).rename),
          ),
        ),
        if (managePhone)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.delete_outline),
              title: Text(tr(context).delete),
            ),
          ),
      ],
    );
  }

  BoxDecoration _hl(BuildContext context, _RemoteEntry f) =>
      menuPath == f.path || selected.contains(f.path)
      ? BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        )
      : const BoxDecoration();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (crumbs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: tr(context).back,
                  onPressed: onUp,
                ),
              Expanded(
                child: Text(
                  crumbs.isEmpty
                      ? tr(context).phoneFiles
                      : crumbs.last.split('/').last,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SegmentedButton<String>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(
                    value: 'list',
                    icon: Icon(Icons.view_list, size: 16),
                  ),
                  ButtonSegment(
                    value: 'small',
                    icon: Icon(Icons.grid_view, size: 16),
                  ),
                  ButtonSegment(
                    value: 'large',
                    icon: Icon(Icons.view_comfy_alt, size: 16),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (s) => onViewMode(s.first),
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
        // Batch bar for marked items — download to a PC folder or
        // delete on the phone (Manage-files setting).
        if (selected.isNotEmpty)
          Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('${selected.length} ✓'),
                const Spacer(),
                IconButton(
                  tooltip: tr(context).download,
                  icon: const Icon(Icons.download),
                  onPressed: onDownloadSelected,
                ),
                if (managePhone)
                  IconButton(
                    tooltip: tr(context).delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDeleteSelected,
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
                  child: viewMode == 'list'
                      ? ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (context, i) =>
                              _listTile(context, files[i]),
                        )
                      : LayoutBuilder(
                          builder: (context, c) => GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: viewMode == 'large'
                                      ? 200
                                      : 110,
                                  childAspectRatio: 0.75,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemCount: files.length,
                            itemBuilder: (context, i) =>
                                _gridCell(context, files[i]),
                          ),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _listTile(BuildContext context, _RemoteEntry f) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: _hl(context, f),
      child: ListTile(
        dense: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (managePhone)
              SizedBox(
                width: 24,
                child: Checkbox(
                  value: selected.contains(f.path),
                  onChanged: (_) => onToggleSelect(f),
                ),
              ),
            _thumbOrIcon(f, 36),
          ],
        ),
        title: Text(f.name, overflow: TextOverflow.ellipsis),
        subtitle: f.isDir
            ? null
            : Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
        onTap: () => _tap(f),
        trailing: _menu(context, f),
      ),
    );
  }

  Widget _gridCell(BuildContext context, _RemoteEntry f) {
    final iconSize = viewMode == 'large' ? 140.0 : 60.0;
    return Container(
      decoration: _hl(context, f),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _tap(f),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(child: _thumbOrIcon(f, iconSize)),
                  Positioned(right: 0, top: 0, child: _menu(context, f)),
                  if (managePhone)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Checkbox(
                          value: selected.contains(f.path),
                          onChanged: (_) => onToggleSelect(f),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                f.name,
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

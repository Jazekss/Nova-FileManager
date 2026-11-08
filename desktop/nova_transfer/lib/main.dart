import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/generated/app_localizations.dart';
import 'firewall.dart';
import 'lan_crypto.dart';
import 'server.dart';
import 'settings.dart';

const _coffeeUrl = 'https://www.buymeacoffee.com/jazeks';
const _devUrl = 'https://jkdizains.lv';
const _appVersion = '1.0.0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
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
  static const _cardRadius = 14.0;

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

  /// Calm desktop theme: compact density, soft grey canvas with white
  /// outlined panels, thin dividers and smaller headings.
  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme;
    return base.copyWith(
      visualDensity: VisualDensity.compact,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      textTheme: text.copyWith(
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: text.titleSmall?.copyWith(
          fontSize: 12,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        horizontalTitleGap: 10,
        minLeadingWidth: 20,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: 420,
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

/// What the PC knows about the phone right now.
enum _PhoneState { waiting, online, reconnecting }

class _RemoteEntry {
  const _RemoteEntry({
    required this.name,
    required this.path,
    required this.isDir,
    this.size = 0,
    this.mtime = 0,
  });
  final String name;
  final String path;
  final bool isDir;
  final int size;

  /// Modified time, ms since epoch (0 when unknown).
  final int mtime;
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
      _phoneOk = false;
      _phoneCrumbs.clear();
      _sel.clear();
      _thumbCache.clear();
      context.read<DesktopSettings>().setPhoneUrl(url);
      if (mounted) setState(() {});
      if (url != null) _refreshPhoneList();
    },
  );

  String? _phoneUrl;
  List<_RemoteEntry> _phoneFiles = [];
  String? _phoneError;
  Timer? _poll;

  /// Last phone listing succeeded — false while reconnecting.
  bool _phoneOk = false;
  bool _listing = false;

  /// Phone clock minus PC clock, learnt from the phone's 403 replies.
  int _phoneSkew = 0;

  /// Windows Firewall verdict for this exe (checked in the background).
  FirewallState _fw = FirewallState.unknown;
  bool _fwFixing = false;

  _PhoneState get _phoneState {
    if (_phoneUrl != null && _phoneOk) return _PhoneState.online;
    if (_server.phoneOnline) return _PhoneState.online;
    if (_phoneUrl != null) return _PhoneState.reconnecting;
    return _PhoneState.waiting;
  }

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
      if (mounted) setState(() {});
      if (_phoneUrl != null) _refreshPhoneList();
    });
    // Poll: phone registration, phone liveness, auto-retry of an
    // unreachable phone and fresh PC addresses for the QR.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _checkPhone());
    _checkFirewall();
  }

  Future<void> _checkFirewall() async {
    final st = await FirewallHelper.check();
    if (mounted) setState(() => _fw = st);
  }

  Future<void> _fixFirewall() async {
    setState(() => _fwFixing = true);
    final st = await FirewallHelper.fix();
    if (!mounted) return;
    setState(() {
      _fw = st;
      _fwFixing = false;
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _server.stop();
    super.dispose();
  }

  bool _lastOnline = false;

  Future<void> _checkPhone() async {
    if (!mounted) return;
    final ipsChanged = await _server.refreshIps();
    // Server knows the registered phone URL directly.
    if (_phoneUrl != _server.phoneUrl) {
      setState(() {
        _phoneUrl = _server.phoneUrl;
        _phoneOk = false;
        _phoneFiles = [];
        _thumbCache.clear();
      });
      if (_phoneUrl != null) _refreshPhoneList();
    } else if (_phoneUrl != null && !_phoneOk) {
      // Unreachable phone → keep retrying quietly; the phone's own
      // heartbeat also re-registers a fresh URL when its IP changed.
      _refreshPhoneList();
    }
    final online = _server.phoneOnline;
    if (online != _lastOnline || ipsChanged) {
      _lastOnline = online;
      setState(() {});
    }
  }

  /// The registered phoneUrl carries `?k=<shareToken>` — requests to the
  /// phone are HMAC-signed and answers are AES-GCM sealed.
  (String base, String key) get _phoneParts {
    final u = Uri.parse(_phoneUrl!);
    return ('http://${u.host}:${u.port}', u.queryParameters['k'] ?? '');
  }

  /// Signed GET against the phone share server → decrypted bytes.
  /// The signature covers the query params too, and every request
  /// carries a unique nonce. Returns null for 204 (no thumbnail).
  Future<Uint8List?> _phoneGet(
    String path, {
    Map<String, String> query = const {},
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final (base, key) = _phoneParts;
    final params = {'nonce': LanCrypto.nonce(), ...query};
    final ts = LanCrypto.now() + _phoneSkew;
    final sig = LanCrypto.sign(key, 'GET', path, ts, params);
    final res = await http
        .get(
          Uri.parse('$base$path')
              .replace(queryParameters: {...params, 'ts': '$ts', 'sig': sig}),
        )
        .timeout(timeout);
    if (res.statusCode == 403 && _learnPhoneSkew(res)) {
      return _phoneGet(path, query: query, timeout: timeout);
    }
    if (res.statusCode == 204) return null;
    if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
    final plain = await LanCrypto.open(key, res.bodyBytes);
    if (plain == null) throw 'decrypt_failed';
    return plain;
  }

  /// The phone's 403 carries its clock — adopt a large difference once
  /// so a wrong clock on either device doesn't break the link.
  bool _learnPhoneSkew(http.Response res) {
    final t = int.tryParse(res.headers[LanCrypto.timeHeader] ?? '');
    if (t == null) return false;
    final diff = t - LanCrypto.now();
    if ((diff - _phoneSkew).abs() < 30) return false;
    _phoneSkew = diff;
    return true;
  }

  Future<void> _phonePost(String path, Object body) async {
    final (base, key) = _phoneParts;
    final params = {'nonce': LanCrypto.nonce()};
    final ts = LanCrypto.now() + _phoneSkew;
    final sig = LanCrypto.sign(key, 'POST', path, ts, params);
    final packed = await LanCrypto.seal(key, utf8.encode(jsonEncode(body)));
    await http
        .post(
          Uri.parse('$base$path')
              .replace(queryParameters: {...params, 'ts': '$ts', 'sig': sig}),
          body: packed,
        )
        .timeout(const Duration(seconds: 10));
  }

  /// Thumbnail futures keyed by path — without this every rebuild
  /// re-fires an HTTP fetch per visible item, which is what made the
  /// image list feel slow. Cleared on refresh / phone change.
  final Map<String, Future<Uint8List?>> _thumbCache = {};

  Future<Uint8List?> _phoneThumb(String path) => _phoneUrl == null
      ? Future.value()
      : _thumbCache.putIfAbsent(
          path,
          () => _phoneGet(
            '/api/thumb',
            query: {'path': path},
          ).then((b) => b, onError: (_) => null),
        );

  /// Browsable listing: roots when _phoneDir is '', otherwise the dir's
  /// contents — the phone exposes whole shared folders, not a flat list.
  Future<void> _refreshPhoneList() async {
    if (_phoneUrl == null || _listing) return;
    _listing = true;
    try {
      final d = _phoneDir;
      final bytes = await _phoneGet(
        '/api/list',
        query: d.isEmpty ? const {} : {'dir': d},
        timeout: const Duration(seconds: 10),
      );
      if (bytes == null) throw 'empty';
      final list = (jsonDecode(utf8.decode(bytes)) as List)
          .map(
            (e) => _RemoteEntry(
              name: e['name'] as String,
              path: e['path'] as String,
              isDir: e['isDir'] as bool,
              size: (e['size'] as int?) ?? 0,
              mtime: (e['mtime'] as int?) ?? 0,
            ),
          )
          .toList();
      if (mounted) {
        setState(() {
          _thumbCache.clear();
          _phoneFiles = list;
          _phoneError = null;
          _phoneOk = true;
        });
      }
    } catch (e) {
      // Keep the last listing visible; the poll retries every few
      // seconds and the header shows "Reconnecting…".
      if (mounted) {
        setState(() {
          _phoneOk = false;
          _phoneError = tr(context).phoneUnreachable;
        });
      }
    } finally {
      _listing = false;
    }
  }

  /// Downloads a phone file into [dir] (already picked). Large files
  /// get a generous timeout — the sealed channel encrypts on both ends.
  Future<void> _phoneDownloadTo(_RemoteEntry f, String dir) async {
    final bytes = await _phoneGet(
      '/api/dl',
      query: {'path': f.path},
      timeout: const Duration(minutes: 5),
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

  static String _ext(_RemoteEntry f) =>
      f.name.contains('.') ? f.name.split('.').last.toLowerCase() : '';

  /// Lightbox over ALL images in the current phone dir — arrows/swipe
  /// switch between them, check icon marks files for a batch download;
  /// marks persist after closing. When zoomed in, panning the picture
  /// no longer flips the page (pager scroll locks while scale > 1).
  /// Audio plays in a small in-app player, video in an in-app player.
  Future<void> _previewPhoneFile(_RemoteEntry f) async {
    final ext = _ext(f);
    if (_imgExts.contains(ext)) {
      final images = _phoneFiles
          .where((x) => !x.isDir && _imgExts.contains(_ext(x)))
          .toList();
      var idx = images.indexOf(f);
      if (idx < 0) idx = 0;
      final controller = PageController(initialPage: idx);
      var zoomed = false;
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
                      physics: zoomed
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      itemCount: images.length,
                      onPageChanged: (i) => setD(() {
                        idx = i;
                        zoomed = false;
                      }),
                      itemBuilder: (context, i) => FutureBuilder<Uint8List?>(
                        future: _phoneGet(
                          '/api/dl',
                          query: {'path': images[i].path},
                          timeout: const Duration(minutes: 2),
                        ),
                        builder: (context, snap) =>
                            snap.connectionState != ConnectionState.done
                            ? const Center(child: CircularProgressIndicator())
                            : snap.data == null
                            ? const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                              )
                            : GestureDetector(
                                // Right-click downloads the image.
                                onSecondaryTap: () {
                                  Navigator.pop(context);
                                  dl();
                                },
                                child: _ZoomableImage(
                                  bytes: snap.data!,
                                  onZoomChanged: (z) {
                                    if (z != zoomed) setD(() => zoomed = z);
                                  },
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
                  // File name + position, always readable over the image.
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
    if (_audioExts.contains(ext)) {
      // Small in-app audio player — bytes come over the sealed channel.
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final bytes = await _phoneGet(
          '/api/dl',
          query: {'path': f.path},
          timeout: const Duration(minutes: 2),
        );
        if (bytes == null) throw 'fetch';
        if (!mounted) return;
        Navigator.pop(context);
        await showDialog<void>(
          context: context,
          builder: (context) => _AudioPreviewDialog(name: f.name, bytes: bytes),
        );
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
      return;
    }
    if (_videoExts.contains(ext)) {
      // In-app video player — the file is fetched over the sealed
      // channel, written to a temp file for the player, then wiped.
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final bytes = await _phoneGet(
          '/api/dl',
          query: {'path': f.path},
          timeout: const Duration(minutes: 5),
        );
        if (bytes == null) throw 'fetch';
        final tmp = Directory.systemTemp.createTempSync('nova_preview');
        final file = File('${tmp.path}\\${f.name}');
        await file.writeAsBytes(bytes);
        if (!mounted) return;
        Navigator.pop(context);
        await showDialog<void>(
          context: context,
          builder: (context) => _VideoPreviewDialog(file: file),
        );
        file.parent.delete(recursive: true).ignore();
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
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
    // Phones that share nothing get the news on their next heartbeat.
    _server.kickPhone();
    _server.restorePhoneUrl(null);
    setState(() {
      _phoneUrl = null;
      _phoneOk = false;
      _phoneError = null;
      _phoneFiles = [];
      _phoneCrumbs.clear();
      _sel.clear();
      _thumbCache.clear();
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
          width: 360,
          child: SingleChildScrollView(
            child: _ConnectPane(
              server: _server,
              firewall: _fw,
              fixingFirewall: _fwFixing,
              onFixFirewall: () async {
                Navigator.pop(context);
                await _fixFirewall();
              },
              compact: true,
            ),
          ),
        ),
        actions: [
          if (_phoneState != _PhoneState.waiting)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _disconnect();
              },
              child: Text(tr(context).disconnect),
            ),
          FilledButton.tonal(
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
                        _server.rotateApkToken();
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
                            '/apk?k=${_server.apkToken}',
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
        content: Text(tr(context).disconnectNote),
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
    final state = _phoneState;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            state: state,
            phoneIp:
                _server.lastPhoneIp ??
                (_phoneUrl == null ? null : Uri.tryParse(_phoneUrl!)?.host),
            onStatusTap: state == _PhoneState.online
                ? _confirmDisconnect
                : _showConnectionDialog,
            onMenu: (v) {
              if (v == 'connection') _showConnectionDialog();
              if (v == 'apk') _showApkQrDialog();
              if (v == 'settings') _showSettings();
              if (v == 'coffee') launchUrl(Uri.parse(_coffeeUrl));
            },
          ),
          if (_fw == FirewallState.blocked)
            _FirewallBanner(fixing: _fwFixing, onFix: _fixFirewall),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _paneW,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: _PcPanel(
                        folders: settings.sharedFolders,
                        onAdd: _addFolder,
                        onRemove: _removeFolder,
                      ),
                    ),
                  ),
                  // Draggable gap — width persists via DesktopSettings.
                  _ResizeHandle(
                    onDrag: (dx) => setState(
                      () => _paneW = (_paneW + dx).clamp(200.0, 640.0),
                    ),
                    onEnd: () =>
                        context.read<DesktopSettings>().setPaneWidth(_paneW),
                  ),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: _phoneUrl == null
                          ? (state == _PhoneState.online
                                ? _PhoneIdlePane()
                                : Center(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(24),
                                      child: SizedBox(
                                        width: 380,
                                        child: _ConnectPane(
                                          server: _server,
                                          firewall: _fw,
                                          fixingFirewall: _fwFixing,
                                          onFixFirewall: _fixFirewall,
                                        ),
                                      ),
                                    ),
                                  ))
                          : _PhonePanel(
                              connected: true,
                              reconnecting: !_phoneOk,
                              onShowQr: _showConnectionDialog,
                              files: _phoneFiles,
                              error: _phoneError,
                              thumbs: settings.showThumbs,
                              viewMode: settings.viewMode,
                              menuPath: _menuPath,
                              crumbs: _phoneCrumbs,
                              selected: _sel,
                              managePhone: settings.managePhone,
                              sortField: settings.phoneSortField,
                              sortAsc: settings.phoneSortAsc,
                              onSort: (f, asc) => context
                                  .read<DesktopSettings>()
                                  .setPhoneSort(f, asc),
                              fetchThumb: _phoneThumb,
                              onViewMode: (m) => context
                                  .read<DesktopSettings>()
                                  .setViewMode(m),
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
                              onDisconnect: _confirmDisconnect,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim top bar: logo + name, live phone status pill, overflow menu.
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.phoneIp,
    required this.onStatusTap,
    required this.onMenu,
  });

  final _PhoneState state;
  final String? phoneIp;
  final VoidCallback onStatusTap;
  final void Function(String) onMenu;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    PopupMenuItem<String> item(String v, IconData icon, String label) =>
        PopupMenuItem(
          value: v,
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
      child: Row(
        children: [
          Image.asset('assets/icon.png', width: 28, height: 28),
          const SizedBox(width: 10),
          Text('Nova Transfer', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          _StatusPill(
            state: state,
            label: switch (state) {
              _PhoneState.online =>
                phoneIp == null
                    ? t.phoneConnected
                    : '${t.phoneConnected} · $phoneIp',
              _PhoneState.reconnecting => t.statusReconnecting,
              _PhoneState.waiting => t.statusWaiting,
            },
            onTap: onStatusTap,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: t.options,
            icon: const Icon(Icons.more_horiz),
            onSelected: onMenu,
            itemBuilder: (context) => [
              item('connection', Icons.qr_code_2, t.connection),
              item('apk', Icons.android, t.shareApk),
              item('settings', Icons.tune, t.settings),
              const PopupMenuDivider(),
              item('coffee', Icons.coffee_outlined, t.buyCoffee),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.state,
    required this.label,
    required this.onTap,
  });

  final _PhoneState state;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (state) {
      _PhoneState.online =>
        dark ? Colors.greenAccent.shade400 : Colors.green.shade600,
      _PhoneState.reconnecting => Colors.amber.shade700,
      _PhoneState.waiting => scheme.outline,
    };
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == _PhoneState.reconnecting)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: color,
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when Windows Firewall drops inbound connections to this app.
class _FirewallBanner extends StatelessWidget {
  const _FirewallBanner({required this.fixing, required this.onFix});

  final bool fixing;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: scheme.onErrorContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr(context).firewallBlocked,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
              fixing
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FilledButton(
                      onPressed: onFix,
                      child: Text(tr(context).firewallFix),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gap between the two panels that resizes the left one.
class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({required this.onDrag, required this.onEnd});

  final void Function(double dx) onDrag;
  final VoidCallback onEnd;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => widget.onDrag(d.delta.dx),
        onPanEnd: (_) => widget.onEnd(),
        child: SizedBox(
          width: 12,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 3,
              height: _hover ? 48 : 28,
              decoration: BoxDecoration(
                color: _hover ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// QR + short steps + network/firewall help — shown inline in the phone
/// panel while no phone is connected, and inside the Connection dialog.
class _ConnectPane extends StatelessWidget {
  const _ConnectPane({
    required this.server,
    required this.firewall,
    required this.fixingFirewall,
    required this.onFixFirewall,
    this.compact = false,
  });

  final PairServer server;
  final FirewallState firewall;
  final bool fixingFirewall;
  final VoidCallback onFixFirewall;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    Widget step(int n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              '$n',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Text(
            t.connectTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
        ],
        if (server.ip == null)
          Text(t.noNetwork, textAlign: TextAlign.center)
        else
          Center(
            // White card so camera QR scanning works in dark theme too.
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: QrImageView(
                data: server.pairUrl,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        const SizedBox(height: 16),
        step(1, t.connectStep1),
        step(2, t.connectStep2),
        const SizedBox(height: 4),
        Text(t.connectAuto, style: small, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.lan_outlined, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                server.ips.isEmpty
                    ? '—'
                    : server.ips.map((ip) => '$ip:${server.port}').join('   '),
                style: small,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              firewall == FirewallState.blocked
                  ? Icons.gpp_maybe_outlined
                  : Icons.verified_user_outlined,
              size: 16,
              color: firewall == FirewallState.blocked
                  ? scheme.error
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(switch (firewall) {
                FirewallState.ok => t.firewallOk,
                FirewallState.blocked => t.firewallBlocked,
                FirewallState.unknown => t.firewallUnknown,
              }, style: small),
            ),
            if (firewall != FirewallState.ok)
              fixingFirewall
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: onFixFirewall,
                      child: Text(t.firewallFix),
                    ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wifi, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(t.sameWifiHint, style: small)),
          ],
        ),
      ],
    );
  }
}

/// Phone is online but shares nothing yet.
class _PhoneIdlePane extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smartphone, size: 40, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              tr(context).phoneConnected,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              tr(context).phoneShareHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 6, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr(context).pcFolders,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: tr(context).addFolder,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: folders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 36,
                          color: scheme.outline,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr(context).emptyList,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(tr(context).addFolder),
                          onPressed: onAdd,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(6),
                  itemCount: folders.length,
                  itemBuilder: (context, i) {
                    final f = folders[i];
                    final name = f
                        .split(Platform.pathSeparator)
                        .lastWhere((s) => s.isNotEmpty, orElse: () => f);
                    return ListTile(
                      leading: Icon(
                        Icons.folder_rounded,
                        color: scheme.primary,
                        size: 22,
                      ),
                      title: Text(name, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        f,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        tooltip: tr(context).remove,
                        onPressed: () => onRemove(f),
                      ),
                      onTap: () => launchUrl(Uri.file(f)),
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
    required this.reconnecting,
    required this.onShowQr,
    required this.files,
    required this.error,
    required this.thumbs,
    required this.viewMode,
    required this.menuPath,
    required this.crumbs,
    required this.selected,
    required this.managePhone,
    required this.sortField,
    required this.sortAsc,
    required this.onSort,
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

  /// Phone stopped answering — the last listing stays visible under a
  /// "Reconnecting…" strip while the PC retries in the background.
  final bool reconnecting;
  final VoidCallback onShowQr;
  final List<_RemoteEntry> files;
  final String? error;
  final bool thumbs;
  final String viewMode;
  final String? menuPath;
  final List<String> crumbs;
  final Set<String> selected;
  final bool managePhone;

  /// name|size|date + direction — persisted via DesktopSettings.
  final String sortField;
  final bool sortAsc;
  final void Function(String field, bool asc) onSort;
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

  static bool _previewable(_RemoteEntry f) {
    final ext = f.name.contains('.')
        ? f.name.split('.').last.toLowerCase()
        : '';
    return _imgExts.contains(ext) ||
        _videoExts.contains(ext) ||
        _audioExts.contains(ext);
  }

  /// Dirs always first, then the chosen field — date desc is the
  /// default so freshly shared items appear on top.
  List<_RemoteEntry> _sorted() {
    final list = [...files];
    int cmp(_RemoteEntry a, _RemoteEntry b) {
      final d = (b.isDir ? 1 : 0) - (a.isDir ? 1 : 0);
      if (d != 0) return d;
      var c = switch (sortField) {
        'size' => a.size.compareTo(b.size),
        'date' => a.mtime.compareTo(b.mtime),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      if (c == 0) {
        c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return sortAsc ? c : -c;
    }

    list.sort(cmp);
    return list;
  }

  /// Sort popup: field radio-items + a direction toggle.
  Widget _sortMenu(BuildContext context) {
    PopupMenuEntry<String> item(String field, String label) =>
        CheckedPopupMenuItem(
          value: field,
          checked: sortField == field,
          child: Text(label),
        );
    return PopupMenuButton<String>(
      tooltip: tr(context).sort,
      icon: const Icon(Icons.sort, size: 18),
      onSelected: (v) {
        if (v == '_dir') {
          onSort(sortField, !sortAsc);
        } else if (v == sortField) {
          onSort(sortField, !sortAsc);
        } else {
          // New field — sensible default direction per field.
          onSort(v, v == 'name');
        }
      },
      itemBuilder: (context) => [
        item('name', tr(context).sortName),
        item('size', tr(context).sortSize),
        item('date', tr(context).sortDate),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: '_dir',
          child: ListTile(
            dense: true,
            leading: Icon(
              sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
            ),
            title: Text(sortAsc ? tr(context).sortAsc : tr(context).sortDesc),
          ),
        ),
      ],
    );
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

  Widget _thumbOrIcon(BuildContext context, _RemoteEntry f, double size) {
    final scheme = Theme.of(context).colorScheme;
    if (f.isDir) {
      return Icon(Icons.folder, size: size, color: scheme.primary);
    }
    final fileIcon = Icon(
      Icons.insert_drive_file_outlined,
      size: size,
      color: scheme.onSurfaceVariant,
    );
    if (!thumbs) return fileIcon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: FutureBuilder<Uint8List?>(
        future: fetchThumb(f.path),
        builder: (context, snap) {
          final b = snap.data;
          if (b == null) return fileIcon;
          return Image.memory(
            b,
            width: size,
            height: size,
            fit: BoxFit.cover,
            // Undecodable bytes used to leave an empty box.
            errorBuilder: (context, error, stack) => fileIcon,
          );
        },
      ),
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
    final sorted = _sorted();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          child: Row(
            children: [
              if (crumbs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  tooltip: tr(context).back,
                  onPressed: onUp,
                )
              else
                const SizedBox(width: 4),
              Expanded(
                child: Text(
                  crumbs.isEmpty
                      ? tr(context).phoneFiles
                      : crumbs.last.split('/').last,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _sortMenu(context),
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
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: tr(context).refresh,
                onPressed: connected ? onRefresh : null,
              ),
              if (connected)
                IconButton(
                  icon: const Icon(Icons.link_off, size: 20),
                  tooltip: tr(context).disconnect,
                  onPressed: onDisconnect,
                ),
            ],
          ),
        ),
        const Divider(),
        if (reconnecting && files.isNotEmpty)
          Container(
            color: Colors.amber.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(context).phoneReconnecting,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
              : reconnecting && files.isEmpty
              ? _reconnectingView(context)
              : sorted.isEmpty
              ? Center(child: Text(tr(context).emptyList))
              : RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: viewMode == 'list'
                      ? ListView.builder(
                          itemCount: sorted.length,
                          itemBuilder: (context, i) =>
                              _listTile(context, sorted[i]),
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
                            itemCount: sorted.length,
                            itemBuilder: (context, i) =>
                                _gridCell(context, sorted[i]),
                          ),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _reconnectingView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 16),
            Text(
              tr(context).phoneReconnecting,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              tr(context).phoneReconnectHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: Text(tr(context).showQr),
                  onPressed: onShowQr,
                ),
                TextButton(
                  onPressed: onDisconnect,
                  child: Text(tr(context).disconnect),
                ),
              ],
            ),
          ],
        ),
      ),
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
            _thumbOrIcon(context, f, 36),
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
                  Center(child: _thumbOrIcon(context, f, iconSize)),
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

/// Small in-app audio player for a phone-shared file (sealed bytes
/// already in memory).
class _AudioPreviewDialog extends StatefulWidget {
  const _AudioPreviewDialog({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  @override
  State<_AudioPreviewDialog> createState() => _AudioPreviewDialogState();
}

class _AudioPreviewDialogState extends State<_AudioPreviewDialog> {
  final _player = AudioPlayer();
  final _subs = <StreamSubscription<dynamic>>[];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _subs.addAll([
      _player.onDurationChanged.listen(
        (d) => mounted ? setState(() => _duration = d) : null,
      ),
      _player.onPositionChanged.listen(
        (p) => mounted ? setState(() => _position = p) : null,
      ),
      _player.onPlayerStateChanged.listen(
        (s) => mounted
            ? setState(() => _playing = s == PlayerState.playing)
            : null,
      ),
    ]);
    try {
      await _player.setSource(BytesSource(widget.bytes));
      await _player.resume();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.music_note),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: _error != null
            ? Text(_error!)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: _position.inMilliseconds
                        .clamp(0, _duration.inMilliseconds)
                        .toDouble(),
                    max: _duration.inMilliseconds
                        .clamp(1, double.infinity)
                        .toDouble(),
                    onChanged: (v) =>
                        _player.seek(Duration(milliseconds: v.round())),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(_fmt(_position)), Text(_fmt(_duration))],
                  ),
                  const SizedBox(height: 8),
                  IconButton.filled(
                    iconSize: 40,
                    icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                    onPressed: () =>
                        _playing ? _player.pause() : _player.resume(),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context).close),
        ),
      ],
    );
  }
}

/// In-app video player (media_kit) for a phone-shared file staged in a
/// temp file — the file itself never leaves the sealed channel.
class _VideoPreviewDialog extends StatefulWidget {
  const _VideoPreviewDialog({required this.file});

  final File file;

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  late final _player = Player();
  late final _controller = VideoController(_player);

  @override
  void initState() {
    super.initState();
    _player.open(Media('file://${widget.file.path.replaceAll('\\', '/')}'));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.file.path.split('\\').last;
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Video(controller: _controller),
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
            left: 0,
            right: 0,
            top: 8,
            child: IgnorePointer(
              child: Text(
                name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

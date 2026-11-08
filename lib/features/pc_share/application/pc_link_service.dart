import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../transfer/data/wifi_share_server.dart';
import '../data/pc_client.dart';

enum PcLinkStatus { unpaired, connecting, online, offline, rejected }

/// App-wide link to the paired desktop. Lives for the whole app session
/// (not just the PC screen), so:
///  * opening the app reconnects automatically — no QR rescan;
///  * a heartbeat every few seconds keeps the PC's "connected" state and
///    the phone-share URL fresh, and re-finds the PC (fallback IPs, UDP
///    discovery) after Wi-Fi drops, DHCP changes or a PC restart;
///  * the phone share server survives leaving the PC screen.
class PcLinkService extends ChangeNotifier with WidgetsBindingObserver {
  PcLinkService();

  static const _keyShareRoots = 'pc_share_roots';
  static const _interval = Duration(seconds: 6);

  final client = PcClient();
  WifiShareServer? _share;
  List<String> shareRoots = [];
  PcLinkStatus status = PcLinkStatus.unpaired;

  /// Where PC uploads into the phone share land — the screen updates it
  /// from the real primary volume once known.
  String uploadDir = '/storage/emulated/0/Download/Nova';

  Timer? _timer;
  bool _busy = false;
  bool _initDone = false;

  /// Bumped whenever the link comes back online — screens refresh on it.
  int onlineEpoch = 0;

  bool get isPaired => client.isPaired;

  Future<void> init() async {
    if (_initDone) return;
    _initDone = true;
    await client.load();
    WidgetsBinding.instance.addObserver(this);
    if (client.isPaired) {
      status = PcLinkStatus.connecting;
      await _restoreShareRoots();
      unawaited(tick());
    }
    _timer = Timer.periodic(_interval, (_) => tick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back in the foreground → check right away instead of waiting for
    // the next timer tick (Android may have paused timers meanwhile).
    if (state == AppLifecycleState.resumed) unawaited(tick());
  }

  void _set(PcLinkStatus s) {
    if (s == PcLinkStatus.online && status != PcLinkStatus.online) {
      onlineEpoch++;
    }
    if (s != status) {
      status = s;
    }
    notifyListeners();
  }

  /// One heartbeat: register (or keep alive) with the PC; on failure find
  /// it again and retry. Safe to call any time — overlapping calls skip.
  Future<void> tick({bool force = false}) async {
    if (!client.isPaired || (_busy && !force)) return;
    _busy = true;
    try {
      if (shareRoots.isNotEmpty && _share == null) {
        await _startServer(shareRoots);
      }
      bool stay;
      try {
        stay = await client.heartbeat(_share?.url);
      } on StateError {
        // Signature refused even after clock correction: reconnect()
        // tells "wrong token" apart from "someone else at that IP".
        final r = await client.reconnect();
        if (r != PcReach.ok) {
          _set(
            r == PcReach.rejected
                ? PcLinkStatus.rejected
                : PcLinkStatus.offline,
          );
          return;
        }
        stay = await client.heartbeat(_share?.url);
      } catch (_) {
        if (status != PcLinkStatus.online) {
          _set(PcLinkStatus.connecting);
        }
        final r = await client.reconnect();
        if (r != PcReach.ok) {
          _set(
            r == PcReach.rejected
                ? PcLinkStatus.rejected
                : PcLinkStatus.offline,
          );
          return;
        }
        stay = await client.heartbeat(_share?.url);
      }
      if (!stay) {
        // PC pressed "Disconnect".
        await unpair(notifyPc: false);
        return;
      }
      _set(PcLinkStatus.online);
    } catch (_) {
      _set(PcLinkStatus.offline);
    } finally {
      _busy = false;
    }
  }

  /// Pairs with a scanned/typed link. Returns null or an error code.
  Future<String?> pair(String link) async {
    _set(PcLinkStatus.connecting);
    final err = await client.pair(link);
    if (err != null) {
      _set(PcLinkStatus.unpaired);
      return err;
    }
    await _restoreShareRoots();
    await tick(force: true);
    return null;
  }

  Future<void> unpair({bool notifyPc = true}) async {
    await _share?.stop();
    _share = null;
    if (notifyPc) {
      await client.unpair();
    } else {
      await client.forget();
    }
    shareRoots = [];
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyShareRoots);
    _set(PcLinkStatus.unpaired);
  }

  Future<void> _restoreShareRoots() async {
    try {
      final p = await SharedPreferences.getInstance();
      shareRoots = (p.getStringList(_keyShareRoots) ?? [])
          .where(
            (r) =>
                FileSystemEntity.typeSync(r) != FileSystemEntityType.notFound,
          )
          .toList();
    } catch (_) {}
  }

  Future<void> _startServer(List<String> roots) async {
    await _share?.stop();
    final server = WifiShareServer(
      uploadDir: Directory(uploadDir),
      onUnpair: () {
        // PC asked to disconnect through the share server.
        _share = null;
        unawaited(unpair(notifyPc: false));
      },
    );
    await server.start(roots);
    _share = server;
  }

  /// Shares [roots] with the PC (restarting the share server) and
  /// persists the set so it survives app restarts.
  Future<void> setShareRoots(List<String> roots) async {
    final p = await SharedPreferences.getInstance();
    if (roots.isEmpty) {
      await _share?.stop();
      _share = null;
      shareRoots = [];
      await p.remove(_keyShareRoots);
      await client.registerPhoneUrl(null);
      notifyListeners();
      return;
    }
    await _startServer(roots);
    shareRoots = roots;
    await p.setStringList(_keyShareRoots, roots);
    await client.registerPhoneUrl(_share!.url);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _share?.stop();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/crypto/lan_crypto.dart';

/// LAN helpers for the PC link: picking the phone's Wi-Fi address and
/// finding the paired desktop again via a UDP broadcast probe when its
/// stored address went stale (new DHCP lease, laptop moved networks).
class LanDiscovery {
  LanDiscovery._();

  /// Phone IPv4 addresses, Wi-Fi/hotspot first — the old "first
  /// non-loopback" pick could return the mobile-data interface, which
  /// the PC can never reach.
  static Future<List<String>> localIps() async {
    final List<(int, String)> scored = [];
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in ifaces) {
        final n = iface.name.toLowerCase();
        for (final a in iface.addresses) {
          if (a.isLoopback || a.isLinkLocal) continue;
          var s = 0;
          if (n.startsWith('wlan') ||
              n.startsWith('swlan') ||
              n.startsWith('ap') ||
              n.startsWith('wifi')) {
            s += 20;
          }
          if (n.startsWith('eth') || n.startsWith('rndis')) s += 10;
          if (n.startsWith('rmnet') ||
              n.startsWith('ccmni') ||
              n.startsWith('tun') ||
              n.startsWith('dummy') ||
              n.startsWith('clat') ||
              n.startsWith('v4-')) {
            s -= 100;
          }
          if (_isPrivate(a.address)) s += 5;
          scored.add((s, a.address));
        }
      }
    } catch (_) {}
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return scored.map((e) => e.$2).toSet().toList();
  }

  static bool _isPrivate(String ip) =>
      ip.startsWith('192.168.') ||
      ip.startsWith('10.') ||
      RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip);

  /// Broadcasts `NOVA_DISCOVER` and waits for the desktop whose pair id
  /// matches [pairId]. Returns (host, port) or null after [wait].
  static Future<(String, int)?> find(
    String pairId, {
    Duration wait = const Duration(milliseconds: 2000),
  }) async {
    RawDatagramSocket? sock;
    final done = Completer<(String, int)?>();
    try {
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      sock.broadcastEnabled = true;
      sock.listen((ev) {
        if (ev != RawSocketEvent.read) return;
        final dg = sock?.receive();
        if (dg == null || done.isCompleted) return;
        final parts = utf8
            .decode(dg.data, allowMalformed: true)
            .trim()
            .split('|');
        if (parts.length < 3 || parts[0] != 'NOVA_HERE') return;
        if (parts[1] != pairId) return;
        final port = int.tryParse(parts[2]);
        if (port == null || port <= 0) return;
        done.complete((dg.address.address, port));
      });

      // Limited broadcast plus each private subnet's /24 broadcast — the
      // latter is routed out of the Wi-Fi interface even when mobile data
      // is the default network.
      final targets = <String>{'255.255.255.255'};
      for (final ip in await localIps()) {
        if (!_isPrivate(ip)) continue;
        final p = ip.split('.');
        targets.add('${p[0]}.${p[1]}.${p[2]}.255');
      }
      final probe = utf8.encode(LanCrypto.discoverProbe);
      // UDP may drop a packet — probe a few times inside the window.
      for (var i = 0; i < 3 && !done.isCompleted; i++) {
        for (final t in targets) {
          try {
            sock.send(probe, InternetAddress(t), LanCrypto.discoveryPort);
          } catch (_) {}
        }
        await Future.any([
          done.future,
          Future<void>.delayed(
            Duration(milliseconds: wait.inMilliseconds ~/ 3),
          ),
        ]);
      }
      if (!done.isCompleted) done.complete(null);
      return await done.future;
    } catch (_) {
      return null;
    } finally {
      sock?.close();
    }
  }
}

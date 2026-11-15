import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'lan_crypto.dart';
import 'lan_stream.dart';
import 'pairing.dart';
import 'safe_path.dart';

/// A paired device of the multi-device mesh ("Other devices").
class MeshPeer {
  MeshPeer({
    required this.id,
    required this.remoteName,
    required this.kind,
    required this.key,
    this.alias,
    this.host,
    this.port = 0,
    List<String>? alt,
  }) : alt = alt ?? [];

  final String id;

  /// Name the device gave itself.
  String remoteName;

  /// Local rename ("Tēta dators") — wins over [remoteName].
  String? alias;

  /// 'pc' | 'phone'
  final String kind;

  /// Per-pair 256-bit secret (hex). Never sent anywhere.
  final String key;
  String? host;
  int port;
  List<String> alt;

  DateTime? lastSeen;

  /// The other side no longer knows us (it removed the pairing).
  bool rejected = false;

  String get name => (alias?.trim().isNotEmpty ?? false) ? alias! : remoteName;
  bool get online =>
      lastSeen != null &&
      DateTime.now().difference(lastSeen!) < const Duration(seconds: 20);

  Map<String, Object?> toJson() => {
    'id': id,
    'remoteName': remoteName,
    'alias': alias,
    'kind': kind,
    'key': key,
    'host': host,
    'port': port,
    'alt': alt,
  };

  static MeshPeer fromJson(Map<String, dynamic> j) => MeshPeer(
    id: j['id'] as String,
    remoteName: (j['remoteName'] as String?) ?? '?',
    alias: j['alias'] as String?,
    kind: (j['kind'] as String?) ?? 'phone',
    key: j['key'] as String,
    host: j['host'] as String?,
    port: (j['port'] as num?)?.toInt() ?? 0,
    alt: ((j['alt'] as List?) ?? []).cast<String>(),
  );
}

class MeshEntry {
  const MeshEntry({
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
  final int mtime;
}

class MeshError implements Exception {
  const MeshError(this.code);

  /// offline | rejected | denied | failed
  final String code;
  @override
  String toString() => code;
}

/// Ranks this device's IPv4 addresses: real Wi-Fi/Ethernet first,
/// virtual adapters (Hyper-V, WSL, VPN…) and mobile data last.
class LanAddr {
  LanAddr._();

  static const _virtual = [
    'vethernet',
    'virtualbox',
    'vbox',
    'vmware',
    'hyper-v',
    'wsl',
    'docker',
    'vpn',
    'tap',
    'tun',
    'tailscale',
    'zerotier',
    'hamachi',
    'radmin',
    'wireguard',
    'nordlynx',
    'bluetooth',
    'npcap',
    'loopback',
    'pseudo',
    'rmnet',
    'ccmni',
    'dummy',
    'clat',
    'v4-',
  ];

  static bool isPrivate(String ip) =>
      ip.startsWith('192.168.') ||
      ip.startsWith('10.') ||
      RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip);

  static Future<List<String>> localIps() async {
    final List<(int, String)> scored = [];
    try {
      for (final iface in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      )) {
        final n = iface.name.toLowerCase();
        for (final a in iface.addresses) {
          if (a.isLoopback || a.isLinkLocal) continue;
          var s = 0;
          if (_virtual.any(n.contains)) s -= 100;
          if (n.contains('wi-fi') ||
              n.contains('wifi') ||
              n.startsWith('wlan') ||
              n.startsWith('swlan') ||
              n.startsWith('ap') ||
              n.contains('wireless') ||
              n.contains('bezvadu')) {
            s += 20;
          }
          if (n.startsWith('eth') || n.contains('local area')) s += 15;
          final ip = a.address;
          if (ip.startsWith('192.168.56.')) s -= 50;
          if (ip.startsWith('192.168.')) {
            s += 10;
          } else if (ip.startsWith('10.')) {
            s += 6;
          } else if (isPrivate(ip)) {
            s += 2;
          }
          scored.add((s, ip));
        }
      }
    } catch (_) {}
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return scored.map((e) => e.$2).toSet().toList();
  }

  /// Limited broadcast + /24 broadcast of every private address.
  static Future<Set<String>> broadcastTargets() async {
    final t = <String>{'255.255.255.255'};
    for (final ip in await localIps()) {
      if (!isPrivate(ip)) continue;
      final p = ip.split('.');
      t.add('${p[0]}.${p[1]}.${p[2]}.255');
    }
    return t;
  }
}

/// One Nova device in the mesh: an HTTP node other paired devices talk
/// to, plus the client side for talking to them.
///
/// Security model:
///  * pairing only with a one-time code (QR or typed) through
///    [PairingHost] → every pair gets its own 256-bit key;
///  * every request names the sender (`from`) and is HMAC-signed with
///    that pair's key (timestamp + nonce, replays refused);
///  * every body and response is AES-256-GCM sealed;
///  * a peer only ever sees the folders shared with it, paths are
///    confined with [SafePath]; no delete/rename over the mesh;
///  * discovery broadcasts carry only HMAC tags, never ids or keys.
class MeshNode {
  MeshNode({
    required this.kind,
    required this.load,
    required this.save,
    required this.rootsFor,
    this.thumb,
    this.onReceived,
    this.preferredPort = 48330,
  });

  final String kind;
  final Future<String?> Function() load;
  final Future<void> Function(String json) save;
  final List<String> Function(MeshPeer peer) rootsFor;
  final Future<List<int>?> Function(String path)? thumb;

  /// Called with the saved path after a peer uploaded a file to us.
  final void Function(String path, MeshPeer from)? onReceived;
  final int preferredPort;

  final _changes = StreamController<void>.broadcast();

  /// Fires on any state change (peers, online status, pairing code).
  Stream<void> get changes => _changes.stream;
  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  String id = '';
  String name = '';
  final List<MeshPeer> peers = [];
  List<String> ips = [];

  late final PairingHost pairing = PairingHost(
    myId: id,
    myName: name,
    kind: kind,
    onCodeChanged: _notify,
    onPaired: (info, key) async {
      _addPeer(info, key);
      return {};
    },
  );

  HttpServer? _server;
  RawDatagramSocket? _udp;
  Timer? _timer;
  final Map<String, int> _skew = {};
  final Set<String> _busy = {};
  DateTime _lastDiscovery = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, int> _seenSigs = {};

  int get port => _server?.port ?? 0;
  String? get ip => ips.isEmpty ? null : ips.first;

  /// `novalink://ip:port/CODE?alt=…` while pairing is open.
  String? get pairLink {
    final c = pairing.code;
    if (c == null || ip == null) return null;
    final alt = ips.skip(1).take(3).join(',');
    return 'novalink://$ip:$port/$c${alt.isEmpty ? '' : '?alt=$alt'}';
  }

  /// Short address to type on the other device.
  String? get address => ip == null ? null : '$ip:$port';

  MeshPeer? peerById(String id) {
    for (final p in peers) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------------------------------------------------------------- setup

  Future<void> init({required String defaultName}) async {
    try {
      final raw = await load();
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        id = (j['id'] as String?) ?? '';
        name = (j['name'] as String?) ?? '';
        peers
          ..clear()
          ..addAll(
            ((j['peers'] as List?) ?? []).map(
              (e) => MeshPeer.fromJson((e as Map).cast<String, dynamic>()),
            ),
          );
      }
    } catch (_) {}
    if (id.isEmpty) id = LanCrypto.nonce() + LanCrypto.nonce();
    if (name.isEmpty) name = defaultName;
    pairing
      ..myId = id
      ..myName = name;
    await _persist();
  }

  Future<void> _persist() => save(
    jsonEncode({
      'id': id,
      'name': name,
      'peers': peers.map((p) => p.toJson()).toList(),
    }),
  );

  Future<void> start() async {
    ips = await LanAddr.localIps();
    if (_server == null) {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, preferredPort);
      } catch (_) {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      }
      _server!.listen(_handle);
    }
    await _startUdp();
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) => tick());
    unawaited(tick());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _udp?.close();
    _udp = null;
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> setName(String n) async {
    final t = n.trim();
    if (t.isEmpty) return;
    name = t.length > 60 ? t.substring(0, 60) : t;
    pairing.myName = name;
    await _persist();
    _notify();
    unawaited(tick());
  }

  Future<void> rename(MeshPeer p, String alias) async {
    p.alias = alias.trim().isEmpty ? null : alias.trim();
    await _persist();
    _notify();
  }

  /// Forgets [p] here and tells it to forget us too.
  Future<void> remove(MeshPeer p) async {
    try {
      await _call(p, 'POST', '/api/bye', body: {}, timeout: 3, retry: false);
    } catch (_) {}
    peers.removeWhere((e) => e.id == p.id);
    await _persist();
    _notify();
  }

  void _addPeer(PairPeerInfo info, String key) {
    peers.removeWhere((e) => e.id == info.id);
    peers.add(
      MeshPeer(
        id: info.id,
        remoteName: info.name.isEmpty ? '?' : info.name,
        kind: info.kind,
        key: key,
        host: info.host,
        port: info.port,
      )..lastSeen = DateTime.now(),
    );
    unawaited(_persist());
    _notify();
  }

  // -------------------------------------------------------------- pairing

  /// Pairs using a scanned `novalink://` link. Returns the new peer.
  Future<MeshPeer> pairWithLink(String link) {
    final u = Uri.tryParse(link.trim());
    if (u == null ||
        u.scheme != 'novalink' ||
        u.host.isEmpty ||
        u.pathSegments.isEmpty) {
      throw const PairError('invalid_link');
    }
    final alt = (u.queryParameters['alt'] ?? '')
        .split(',')
        .where((e) => e.isNotEmpty)
        .toList();
    return pairWith(u.host, u.port, u.pathSegments.first, alt: alt);
  }

  /// Pairs with the device at [host]:[port] showing [code]. Tries the
  /// alternative addresses from a QR when the first one is unreachable.
  Future<MeshPeer> pairWith(
    String host,
    int port,
    String code, {
    List<String> alt = const [],
  }) async {
    if (!PairCode.looksValid(code)) throw const PairError('bad_code');
    PairError? last;
    for (final h in [host, ...alt]) {
      try {
        final r = await PairingHost.join(
          host: h,
          port: port,
          code: code,
          myId: id,
          myName: name,
          kind: kind,
          myPort: this.port,
        );
        _addPeer(
          PairPeerInfo(
            id: r.peer.id,
            name: r.peer.name,
            kind: r.peer.kind,
            host: h,
            port: port,
          ),
          r.key,
        );
        final p = peerById(r.peer.id)!;
        p.alt = [host, ...alt].where((e) => e != h).toList();
        unawaited(_persist());
        unawaited(tick());
        return p;
      } on PairError catch (e) {
        last = e;
        if (e.code != 'unreachable') rethrow;
      }
    }
    throw last ?? const PairError('unreachable');
  }

  // ------------------------------------------------------------ heartbeat

  /// Keeps every peer's online state fresh and re-finds moved peers.
  Future<void> tick() async {
    final fresh = await LanAddr.localIps();
    if (fresh.join(',') != ips.join(',')) {
      ips = fresh;
      _notify();
    }
    await Future.wait(peers.toList().map(_beat));
  }

  Future<void> _beat(MeshPeer p) async {
    if (!_busy.add(p.id)) return;
    final wasOnline = p.online;
    final wasRejected = p.rejected;
    try {
      if (!await _hello(p)) {
        if (!p.rejected && await _reach(p)) await _hello(p);
      }
    } finally {
      _busy.remove(p.id);
      if (p.online != wasOnline || p.rejected != wasRejected) _notify();
    }
  }

  Future<bool> _hello(MeshPeer p, {String? base}) async {
    try {
      final r = await _call(
        p,
        'POST',
        '/api/hello',
        body: {'name': name, 'port': port, 'kind': kind},
        timeout: 4,
        base: base,
      );
      final j = jsonDecode(utf8.decode(r!)) as Map<String, dynamic>;
      final n = '${j['name'] ?? ''}'.trim();
      if (n.isNotEmpty && n != p.remoteName) {
        p.remoteName = n.length > 60 ? n.substring(0, 60) : n;
        unawaited(_persist());
      }
      p
        ..lastSeen = DateTime.now()
        ..rejected = false;
      return true;
    } on MeshError catch (e) {
      if (e.code == 'rejected') p.rejected = true;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Alternative addresses, then a tagged UDP broadcast.
  Future<bool> _reach(MeshPeer p) async {
    for (final h in p.alt.where((h) => h != p.host)) {
      if (await _hello(p, base: _base(h, p.port))) {
        _moveTo(p, h, p.port);
        return true;
      }
    }
    final now = DateTime.now();
    if (now.difference(_lastDiscovery) < const Duration(seconds: 12)) {
      return false;
    }
    _lastDiscovery = now;
    final found = await _discover();
    for (final peer in peers) {
      final hit = found[peer.id];
      if (hit != null) _moveTo(peer, hit.$1, hit.$2);
    }
    return found.containsKey(p.id);
  }

  void _moveTo(MeshPeer p, String host, int port) {
    if (p.host == host && p.port == port) return;
    if (p.host != null && !p.alt.contains(p.host)) {
      p.alt = [p.host!, ...p.alt].take(4).toList();
    }
    p.alt.remove(host);
    p.host = host;
    p.port = port;
    unawaited(_persist());
  }

  // ------------------------------------------------------------ discovery

  Future<void> _startUdp() async {
    if (_udp != null) return;
    try {
      final udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        LanCrypto.meshDiscoveryPort,
        reuseAddress: true,
      );
      _udp = udp;
      udp.listen((ev) {
        if (ev != RawSocketEvent.read) return;
        final dg = udp.receive();
        if (dg == null || peers.isEmpty || port == 0) return;
        final parts = utf8.decode(dg.data, allowMalformed: true).split('|');
        if (parts.length != 2 || parts[0] != 'NOVA_MESH?') return;
        final nonce = parts[1];
        if (nonce.length < 8 || nonce.length > 64) return;
        final tags = peers.map((p) => LanCrypto.tag(p.key, nonce)).join(',');
        try {
          udp.send(utf8.encode('NOVA_MESH!|$port|$tags'), dg.address, dg.port);
        } catch (_) {}
      });
    } catch (_) {}
  }

  /// Peer id → (host, port) for every paired device that answered.
  Future<Map<String, (String, int)>> _discover() async {
    final found = <String, (String, int)>{};
    RawDatagramSocket? sock;
    try {
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      sock.broadcastEnabled = true;
      final nonce = LanCrypto.nonce() + LanCrypto.nonce();
      final byTag = {for (final p in peers) LanCrypto.tag(p.key, nonce): p};
      sock.listen((ev) {
        if (ev != RawSocketEvent.read) return;
        final dg = sock?.receive();
        if (dg == null) return;
        final parts = utf8.decode(dg.data, allowMalformed: true).split('|');
        if (parts.length != 3 || parts[0] != 'NOVA_MESH!') return;
        final port = int.tryParse(parts[1]) ?? 0;
        if (port <= 0) return;
        for (final t in parts[2].split(',')) {
          final p = byTag[t];
          if (p != null) found[p.id] = (dg.address.address, port);
        }
      });
      final probe = utf8.encode('NOVA_MESH?|$nonce');
      final targets = await LanAddr.broadcastTargets();
      for (var i = 0; i < 3; i++) {
        for (final t in targets) {
          try {
            sock.send(probe, InternetAddress(t), LanCrypto.meshDiscoveryPort);
          } catch (_) {}
        }
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
    } catch (_) {
    } finally {
      sock?.close();
    }
    return found;
  }

  // --------------------------------------------------------------- client

  static String _base(String host, int port) =>
      'http://${host.contains(':') ? '[$host]' : host}:$port';

  Future<Uint8List?> _call(
    MeshPeer p,
    String method,
    String path, {
    Map<String, String>? q,
    Object? body,
    List<int>? rawBody,
    int timeout = 15,
    String? base,
    bool retry = true,
  }) async {
    if (p.host == null) throw const MeshError('offline');
    final params = {'nonce': LanCrypto.nonce(), 'from': id, ...?q};
    final ts = LanCrypto.now() + (_skew[p.id] ?? 0);
    final sig = LanCrypto.sign(p.key, method, path, ts, params);
    final uri = Uri.parse(
      '${base ?? _base(p.host!, p.port)}$path',
    ).replace(queryParameters: {...params, 'ts': '$ts', 'sig': sig});
    final http.Response res;
    try {
      if (method == 'GET') {
        res = await http.get(uri).timeout(Duration(seconds: timeout));
      } else {
        final plain = rawBody ?? utf8.encode(jsonEncode(body ?? {}));
        res = await http
            .post(uri, body: await LanCrypto.seal(p.key, plain))
            .timeout(Duration(seconds: timeout));
      }
    } catch (_) {
      throw const MeshError('offline');
    }
    if (res.statusCode == 403) {
      if (res.headers['x-nova-unknown'] == '1') {
        throw const MeshError('rejected');
      }
      final t = int.tryParse(res.headers[LanCrypto.timeHeader] ?? '');
      if (retry && t != null) {
        final diff = t - LanCrypto.now();
        if ((diff - (_skew[p.id] ?? 0)).abs() >= 30) {
          _skew[p.id] = diff;
          return _call(
            p,
            method,
            path,
            q: q,
            body: body,
            rawBody: rawBody,
            timeout: timeout,
            base: base,
            retry: false,
          );
        }
      }
      throw const MeshError('denied');
    }
    if (res.statusCode == 204) return null;
    if (res.statusCode != 200) throw const MeshError('failed');
    final plain = await LanCrypto.open(p.key, res.bodyBytes);
    if (plain == null) throw const MeshError('failed');
    p.lastSeen = DateTime.now();
    return plain;
  }

  /// Roots shared with us when [dir] is empty, else that folder.
  Future<List<MeshEntry>> list(MeshPeer p, [String dir = '']) async {
    final b = await _call(
      p,
      'GET',
      '/api/list',
      q: dir.isEmpty ? null : {'dir': dir},
    );
    return (jsonDecode(utf8.decode(b!)) as List)
        .map(
          (e) => MeshEntry(
            name: e['name'] as String,
            path: e['path'] as String,
            isDir: e['isDir'] as bool,
            size: (e['size'] as num?)?.toInt() ?? 0,
            mtime: (e['mtime'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  Future<http.StreamedResponse> _stream(MeshPeer p, String path) async {
    if (p.host == null) throw const MeshError('offline');
    final params = {'nonce': LanCrypto.nonce(), 'from': id, 'path': path};
    final ts = LanCrypto.now() + (_skew[p.id] ?? 0);
    final sig = LanCrypto.sign(p.key, 'GET', '/api/dl', ts, params);
    final uri = Uri.parse(
      '${_base(p.host!, p.port)}/api/dl',
    ).replace(queryParameters: {...params, 'ts': '$ts', 'sig': sig});
    final http.StreamedResponse res;
    try {
      res = await LanStream.get(uri, timeout: const Duration(seconds: 15));
    } catch (_) {
      throw const MeshError('offline');
    }
    if (res.statusCode == 403) throw const MeshError('denied');
    if (res.statusCode != 200) throw const MeshError('failed');
    p.lastSeen = DateTime.now();
    return res;
  }

  /// Whole file in memory (previews).
  Future<Uint8List> download(MeshPeer p, String path) async {
    try {
      return await LanStream.readAll(p.key, await _stream(p, path));
    } on MeshError {
      rethrow;
    } catch (_) {
      throw const MeshError('failed');
    }
  }

  /// Streams a file straight to disk.
  Future<void> downloadTo(MeshPeer p, String path, File out) async {
    try {
      await LanStream.toFile(p.key, await _stream(p, path), out);
    } on MeshError {
      rethrow;
    } catch (_) {
      throw const MeshError('failed');
    }
  }

  Future<Uint8List?> fetchThumb(MeshPeer p, String path) async {
    try {
      return await _call(p, 'GET', '/api/thumb', q: {'path': path});
    } catch (_) {
      return null;
    }
  }

  /// Uploads [bytes] as [fileName] into [dir] of a folder shared with us.
  Future<void> upload(
    MeshPeer p,
    String dir,
    String fileName,
    List<int> bytes,
  ) => _call(
    p,
    'POST',
    '/api/upload',
    q: {'dir': dir, 'name': fileName},
    rawBody: bytes,
    timeout: 600,
  );

  // --------------------------------------------------------------- server

  Future<void> _handle(HttpRequest req) async {
    try {
      if (pairing.handles(req)) {
        await pairing.handle(req);
        return;
      }
      final peer = _auth(req);
      if (peer == null) return;
      final path = req.uri.path;
      if (req.method == 'POST' && path == '/api/hello') {
        final j = jsonDecode(utf8.decode(await _body(req, peer)));
        final n = '${j['name'] ?? ''}'.trim();
        if (n.isNotEmpty) {
          peer.remoteName = n.length > 60 ? n.substring(0, 60) : n;
        }
        final pt = (j['port'] as num?)?.toInt() ?? 0;
        if (pt > 0) peer.port = pt;
        await _send(req, peer, {'name': name});
        return;
      }
      if (req.method == 'POST' && path == '/api/bye') {
        peers.removeWhere((e) => e.id == peer.id);
        await _persist();
        _notify();
        await _send(req, peer, {'ok': true});
        return;
      }
      final roots = rootsFor(peer);
      final q = req.uri.queryParameters;
      if (req.method == 'GET' && path == '/api/list') {
        await _list(req, peer, roots, q['dir'] ?? '');
      } else if (req.method == 'GET' && path == '/api/dl') {
        final f = q['path'] ?? '';
        if (!SafePath.inside(f, roots) || !File(f).existsSync()) {
          await _deny(req, 404);
          return;
        }
        await LanStream.serveFile(req, peer.key, File(f));
      } else if (req.method == 'GET' && path == '/api/thumb') {
        final f = q['path'] ?? '';
        final b = SafePath.inside(f, roots) && File(f).existsSync()
            ? await thumb?.call(f)
            : null;
        if (b == null) {
          await _deny(req, 204);
          return;
        }
        await _sendBytes(req, peer, b);
      } else if (req.method == 'POST' && path == '/api/upload') {
        await _upload(req, peer, roots, q['dir'] ?? '', q['name'] ?? '');
      } else {
        await _deny(req, 404);
      }
    } catch (_) {
      await _deny(req, 500);
    }
  }

  /// Verifies sender + signature; answers 403 itself on failure.
  MeshPeer? _auth(HttpRequest req) {
    final q = req.uri.queryParameters;
    final peer = peerById(q['from'] ?? '');
    final ts = int.tryParse(q['ts'] ?? '') ?? 0;
    final sig = q['sig'] ?? '';
    if (peer == null) {
      req.response
        ..statusCode = 403
        ..headers.set('x-nova-unknown', '1');
      req.response.close();
      return null;
    }
    if (!LanCrypto.verify(peer.key, req.method, req.uri.path, ts, sig, q) ||
        !_fresh(sig)) {
      req.response
        ..statusCode = 403
        ..headers.set(LanCrypto.timeHeader, '${LanCrypto.now()}');
      req.response.close();
      return null;
    }
    final wasOnline = peer.online;
    peer
      ..lastSeen = DateTime.now()
      ..rejected = false;
    final remote = req.connectionInfo?.remoteAddress.address;
    if (remote != null && remote != peer.host) {
      _moveTo(peer, remote, peer.port);
    }
    if (!wasOnline) _notify();
    return peer;
  }

  bool _fresh(String sig) {
    final now = LanCrypto.now();
    _seenSigs.removeWhere((_, t) => (now - t).abs() > LanCrypto.windowSec + 60);
    if (_seenSigs.containsKey(sig)) return false;
    _seenSigs[sig] = now;
    return true;
  }

  Future<Uint8List> _body(HttpRequest req, MeshPeer peer) async {
    final b = BytesBuilder(copy: false);
    await for (final c in req) {
      b.add(c);
    }
    final plain = await LanCrypto.open(peer.key, b.takeBytes());
    if (plain == null) throw 'bad-body';
    return plain;
  }

  Future<void> _send(HttpRequest req, MeshPeer peer, Object data) =>
      _sendBytes(req, peer, utf8.encode(jsonEncode(data)));

  Future<void> _sendBytes(
    HttpRequest req,
    MeshPeer peer,
    List<int> bytes,
  ) async {
    final packed = await LanCrypto.seal(peer.key, bytes);
    req.response.headers
      ..contentType = ContentType.binary
      ..contentLength = packed.length;
    req.response.add(packed);
    await req.response.close();
  }

  Future<void> _deny(HttpRequest req, int status) async {
    try {
      req.response.statusCode = status;
      await req.response.close();
    } catch (_) {}
  }

  Future<void> _list(
    HttpRequest req,
    MeshPeer peer,
    List<String> roots,
    String dir,
  ) async {
    final out = <Map<String, Object?>>[];
    Map<String, Object?> entry(FileSystemEntity e) {
      var size = 0;
      var mtime = 0;
      try {
        final s = e.statSync();
        size = e is File ? s.size : 0;
        mtime = s.modified.millisecondsSinceEpoch;
      } catch (_) {}
      return {
        'name': SafePath.baseName(e.path),
        'path': e.path,
        'isDir': e is Directory,
        'size': size,
        'mtime': mtime,
      };
    }

    if (dir.isEmpty) {
      for (final r in roots) {
        final t = FileSystemEntity.typeSync(r);
        if (t == FileSystemEntityType.directory) out.add(entry(Directory(r)));
        if (t == FileSystemEntityType.file) out.add(entry(File(r)));
      }
    } else {
      if (!SafePath.inside(dir, roots) || !Directory(dir).existsSync()) {
        return _deny(req, 403);
      }
      for (final e in Directory(dir).listSync(followLinks: false)) {
        if (SafePath.baseName(e.path).startsWith('.')) continue;
        if (e is Link) continue;
        out.add(entry(e));
      }
    }
    await _send(req, peer, out);
  }

  Future<void> _upload(
    HttpRequest req,
    MeshPeer peer,
    List<String> roots,
    String dir,
    String fileName,
  ) async {
    final safe = SafePath.safeFileName(fileName);
    if (safe == null ||
        !SafePath.inside(dir, roots) ||
        !Directory(dir).existsSync()) {
      return _deny(req, 403);
    }
    final bytes = await _body(req, peer);
    final sep = Platform.pathSeparator;
    final dot = safe.lastIndexOf('.');
    var out = '$dir$sep$safe';
    for (var n = 1; File(out).existsSync(); n++) {
      out = dot > 0
          ? '$dir$sep${safe.substring(0, dot)} ($n)${safe.substring(dot)}'
          : '$dir$sep$safe ($n)';
    }
    if (!SafePath.inside(out, roots)) return _deny(req, 403);
    await File(out).writeAsBytes(bytes);
    onReceived?.call(out, peer);
    await _send(req, peer, {'ok': true});
  }

  Future<void> dispose() async {
    await stop();
    await _changes.close();
  }
}

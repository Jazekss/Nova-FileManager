import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:nova_link/nova_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../transfer/data/wifi_share_server.dart';

/// A phone folder/file shared over the mesh: with every paired device
/// (`all`) or only with the listed device ids.
class MeshShare {
  MeshShare(this.path, {this.all = true, Set<String>? ids}) : ids = ids ?? {};

  final String path;
  bool all;
  Set<String> ids;

  bool allows(String peerId) => all || ids.contains(peerId);

  Map<String, Object?> toJson() => {
    'path': path,
    'all': all,
    'ids': ids.toList(),
  };

  static MeshShare fromJson(Map<String, dynamic> j) => MeshShare(
    j['path'] as String,
    all: j['all'] as bool? ?? true,
    ids: ((j['ids'] as List?) ?? []).cast<String>().toSet(),
  );
}

/// "Other devices": the phone's node in the multi-device mesh. Runs for
/// the whole app session; paired devices stay saved and reconnect by
/// themselves while Nova is open on both sides.
class MeshService extends ChangeNotifier with WidgetsBindingObserver {
  static const _keyMesh = 'mesh_v1';
  static const _keyShares = 'mesh_shares_v1';

  late final MeshNode node = MeshNode(
    kind: 'phone',
    preferredPort: 48331,
    load: () async =>
        (await SharedPreferences.getInstance()).getString(_keyMesh),
    save: (j) async =>
        (await SharedPreferences.getInstance()).setString(_keyMesh, j),
    rootsFor: (peer) => shares
        .where((s) => s.allows(peer.id))
        .map((s) => s.path)
        .where(
          (p) => FileSystemEntity.typeSync(p) != FileSystemEntityType.notFound,
        )
        .toList(),
    thumb: WifiShareServer.thumbnailFor,
    onReceived: (path, from) {
      lastReceived = (path, from.name);
      notifyListeners();
    },
  );

  List<MeshShare> shares = [];

  /// Last file a peer uploaded to us — screens show a snackbar.
  (String, String)? lastReceived;

  StreamSubscription<void>? _sub;
  bool _started = false;

  List<MeshPeer> get peers => node.peers;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final p = await SharedPreferences.getInstance();
      shares = ((jsonDecode(p.getString(_keyShares) ?? '[]') as List))
          .map((e) => MeshShare.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {}
    await node.init(defaultName: 'Nova ${_shortModel()}');
    _sub = node.changes.listen((_) => notifyListeners());
    WidgetsBinding.instance.addObserver(this);
    try {
      await node.start();
    } catch (_) {}
    notifyListeners();
  }

  static String _shortModel() {
    final h = Platform.localHostname;
    return h.isEmpty || h == 'localhost' ? 'telefons' : h;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(node.tick());
  }

  Future<void> _saveShares() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _keyShares,
      jsonEncode(shares.map((s) => s.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> addShares(
    List<String> paths, {
    required bool all,
    Set<String>? ids,
  }) async {
    for (final path in paths) {
      shares.removeWhere((s) => s.path == path);
      shares.add(MeshShare(path, all: all, ids: {...?ids}));
    }
    await _saveShares();
  }

  Future<void> updateShare(MeshShare s, {required bool all, Set<String>? ids}) {
    s
      ..all = all
      ..ids = {...?ids};
    return _saveShares();
  }

  Future<void> removeShare(MeshShare s) {
    shares.remove(s);
    return _saveShares();
  }

  @override
  void dispose() {
    _sub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    node.dispose();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../data/recycle_bin_service.dart';

class RecycleBinController extends ChangeNotifier {
  RecycleBinController(this._service);

  final RecycleBinService _service;

  List<BinItem> items = [];
  int totalBytes = 0;
  bool loading = false;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    loading = true;
    _notify();
    items = await _service.loadItems();
    totalBytes = items.fold(0, (sum, i) => sum + i.size);
    loading = false;
    _notify();
  }

  /// Moves paths to the bin; returns error text or null.
  Future<String?> moveToBin(List<String> paths) async {
    try {
      await _service.moveToBin(paths);
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> restore(BinItem item) => _run(() => _service.restore(item));

  Future<String?> moveOut(BinItem item, String destDir) =>
      _run(() => _service.moveOut(item, destDir));

  Future<String?> deleteForever(BinItem item) =>
      _run(() => _service.deleteForever(item));

  Future<String?> empty() => _run(_service.empty);

  Future<String?> _run(Future<void> Function() op) async {
    try {
      await op();
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/models/file_entry.dart';
import '../../../core/models/storage_volume.dart';
import '../../../core/platform/storage_platform.dart';
import '../../../core/settings/settings_controller.dart';
import '../data/file_operations.dart';

enum BrowserViewMode { detailed, smallIcons, largeIcons }

enum SortField { name, size, date }

class FileBrowserController extends ChangeNotifier {
  FileBrowserController(this._platform, this._settings) {
    _settings.addListener(_onSettingsChanged);
  }

  final StoragePlatform _platform;
  final SettingsController _settings;

  StoragePlatform get platform => _platform;

  List<StorageVolume> volumes = [];
  StorageVolume? activeVolume;
  String currentPath = '';
  List<FileEntry> entries = [];

  final Set<String> selectedPaths = {};
  bool selectionMode = false;

  BrowserViewMode viewMode = BrowserViewMode.detailed;
  SortField sortField = SortField.name;
  bool sortAscending = true;

  bool loading = false;
  String? error;
  bool operationInProgress = false;
  bool _initialized = false;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool get canGoUp =>
      activeVolume != null &&
      currentPath.isNotEmpty &&
      currentPath != activeVolume!.path;

  /// Loads volumes once; safe to call from widgets on every build.
  Future<void> ensureInitialized() {
    if (_initialized) return Future.value();
    _initialized = true;
    return init();
  }

  /// Loads volumes and navigates to the primary storage root.
  Future<void> init() async {
    loading = true;
    error = null;
    _notify();
    try {
      volumes = await _platform.getVolumes();
      activeVolume = volumes.isEmpty
          ? null
          : volumes.firstWhere((v) => v.isPrimary, orElse: () => volumes.first);
      currentPath = activeVolume?.path ?? '';
      await _loadEntries();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> switchVolume(StorageVolume volume) async {
    if (volume == activeVolume) return;
    activeVolume = volume;
    _resetSelection();
    await navigateTo(volume.path);
  }

  Future<void> navigateTo(String path) async {
    currentPath = path;
    _resetSelection();
    await _loadEntries();
  }

  Future<void> goUp() async {
    if (!canGoUp) return;
    final parent = currentPath.substring(0, currentPath.lastIndexOf('/'));
    await navigateTo(parent.isEmpty ? '/' : parent);
  }

  Future<void> refresh() => _loadEntries();

  void setViewMode(BrowserViewMode mode) {
    viewMode = mode;
    notifyListeners();
  }

  void setSort(SortField field) {
    if (sortField == field) {
      sortAscending = !sortAscending;
    } else {
      sortField = field;
      sortAscending = true;
    }
    _sortEntries();
    notifyListeners();
  }

  void toggleSelect(FileEntry entry) {
    if (!selectedPaths.remove(entry.path)) {
      selectedPaths.add(entry.path);
    }
    notifyListeners();
  }

  void selectAll() {
    selectionMode = true;
    selectedPaths
      ..clear()
      ..addAll(entries.map((e) => e.path));
    notifyListeners();
  }

  void enterSelection() {
    selectionMode = true;
    notifyListeners();
  }

  void clearSelection() {
    _resetSelection();
    notifyListeners();
  }

  void _resetSelection() {
    selectedPaths.clear();
    selectionMode = false;
  }

  // --- Operations ---

  Future<String?> createFolder(String name) async {
    try {
      await FileOperations.createFolder(currentPath, name);
      await _loadEntries();
      return null;
    } catch (e) {
      return _describeError(e);
    }
  }

  Future<String?> renameEntry(FileEntry entry, String newName) async {
    try {
      await FileOperations.rename(entry.path, newName);
      _resetSelection();
      await _loadEntries();
      return null;
    } catch (e) {
      return _describeError(e);
    }
  }

  Future<String?> deletePaths(List<String> paths) async {
    operationInProgress = true;
    _notify();
    try {
      await FileOperations.delete(paths);
      _resetSelection();
      await _loadEntries();
      return null;
    } catch (e) {
      return _describeError(e);
    } finally {
      operationInProgress = false;
      _notify();
    }
  }

  Future<String?> copyOrMove(
    List<String> paths,
    String destDir, {
    required bool move,
  }) async {
    if (destDir == currentPath) return errorSameFolder;
    operationInProgress = true;
    _notify();
    try {
      if (move) {
        await FileOperations.move(paths, destDir);
      } else {
        await FileOperations.copy(paths, destDir);
      }
      _resetSelection();
      await _loadEntries();
      return null;
    } catch (e) {
      return _describeError(e);
    } finally {
      operationInProgress = false;
      _notify();
    }
  }

  // --- Internals ---

  Future<void> _loadEntries() async {
    if (currentPath.isEmpty) {
      entries = [];
      _notify();
      return;
    }
    loading = true;
    error = null;
    _notify();
    try {
      final showHidden = _settings.showHidden;
      final list = <FileEntry>[];
      await for (final entity in Directory(currentPath).list()) {
        final path = entity.path.replaceAll('\\', '/');
        final name = path.substring(path.lastIndexOf('/') + 1);
        if (!showHidden && name.startsWith('.')) continue;
        FileStat stat;
        try {
          stat = await entity.stat();
        } catch (_) {
          // Entry exists but metadata is unreadable (e.g. foreign-owned
          // 0660 file under FUSE): still show it, with unknown details.
          list.add(
            FileEntry(
              name: name,
              path: path,
              isDirectory: entity is Directory,
              size: 0,
            ),
          );
          continue;
        }
        list.add(
          FileEntry(
            name: name,
            path: path,
            isDirectory: entity is Directory,
            size: stat.size,
            modified: stat.modified,
            changed: stat.changed,
          ),
        );
      }
      entries = list;
      _sortEntries();
    } catch (e) {
      error = _describeError(e);
      entries = [];
    } finally {
      loading = false;
      _notify();
    }
  }

  void _sortEntries() {
    int cmp(FileEntry a, FileEntry b) {
      switch (sortField) {
        case SortField.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortField.size:
          return a.size.compareTo(b.size);
        case SortField.date:
          return (a.modified ?? DateTime(1970)).compareTo(
            b.modified ?? DateTime(1970),
          );
      }
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      final result = cmp(a, b);
      return sortAscending ? result : -result;
    });
  }

  /// Marker returned instead of a localized message — the UI maps these to
  /// translated strings (see localizeError in core/utils).
  static const errorSameFolder = '__same_folder__';
  static const errorPermissionDenied = '__perm_denied__';

  String _describeError(Object e) {
    final msg = e.toString();
    if (e is FileSystemException || msg.contains('Permission denied')) {
      return errorPermissionDenied;
    }
    return msg;
  }

  void _onSettingsChanged() {
    // Hidden-file visibility may have changed; refresh the listing.
    if (currentPath.isNotEmpty) _loadEntries();
  }

  @override
  void dispose() {
    _disposed = true;
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}

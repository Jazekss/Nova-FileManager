import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/file_entry.dart';
import '../../../core/platform/storage_platform.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/widgets/entry_icon.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../apps/presentation/apps_screen.dart';
import '../../file_manager/application/file_browser_controller.dart';
import '../../file_manager/data/file_operations.dart';
import '../../file_manager/presentation/widgets/browser_dialogs.dart';
import '../../recycle_bin/application/recycle_bin_controller.dart';

/// A scanned file (path, size, modified ms).
typedef ScanFile = (String path, int size, int mtime);

const _cats = [
  'images',
  'videos',
  'audio',
  'documents',
  'archives',
  'apks',
  'large',
  'other',
];

const _ext = {
  'images': {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
    'avif',
    'svg',
  },
  'videos': {
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    '3gp',
    'm4v',
    'wmv',
    'flv',
    'ts',
    'mpg',
    'mpeg',
  },
  'audio': {
    'mp3',
    'flac',
    'wav',
    'ogg',
    'oga',
    'opus',
    'm4a',
    'aac',
    'wma',
    'amr',
    'mid',
    'midi',
  },
  'documents': {
    'pdf',
    'doc',
    'docx',
    'txt',
    'md',
    'rtf',
    'odt',
    'xls',
    'xlsx',
    'csv',
    'ods',
    'ppt',
    'pptx',
    'odp',
    'epub',
    'html',
    'json',
    'xml',
  },
  'archives': {'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'nvx'},
  'apks': {'apk', 'aab', 'xapk', 'apks'},
};

const _largeBytes = 100 * 1024 * 1024;

/// Walks [root] (hidden folders and Android/ skipped) and sorts every
/// file into a category; files ≥ 100 MB also land in "large".
Map<String, List<ScanFile>> _scan(String root) {
  final out = {for (final c in _cats) c: <ScanFile>[]};
  final stack = [Directory(root)];
  while (stack.isNotEmpty) {
    final dir = stack.removeLast();
    List<FileSystemEntity> list;
    try {
      list = dir.listSync(followLinks: false);
    } catch (_) {
      continue;
    }
    for (final e in list) {
      final name = e.path.substring(e.path.lastIndexOf('/') + 1);
      if (name.startsWith('.')) continue;
      if (e is Directory) {
        if (dir.path == root && name == 'Android') continue;
        stack.add(e);
      } else if (e is File) {
        int size;
        int mtime;
        try {
          final st = e.statSync();
          size = st.size;
          mtime = st.modified.millisecondsSinceEpoch;
        } catch (_) {
          continue;
        }
        final dot = name.lastIndexOf('.');
        final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
        var cat = 'other';
        for (final c in _ext.entries) {
          if (c.value.contains(ext)) {
            cat = c.key;
            break;
          }
        }
        final f = (e.path, size, mtime);
        out[cat]!.add(f);
        if (size >= _largeBytes) out['large']!.add(f);
      }
    }
  }
  return out;
}

String catLabel(AppLocalizations tr, String c) => switch (c) {
  'images' => tr.catImages,
  'videos' => tr.catVideos,
  'audio' => tr.catAudio,
  'documents' => tr.catDocuments,
  'archives' => tr.catArchives,
  'apks' => tr.catApks,
  'large' => tr.catLarge,
  _ => tr.catOther,
};

IconData _catIcon(String c) => switch (c) {
  'images' => Icons.image_outlined,
  'videos' => Icons.movie_outlined,
  'audio' => Icons.music_note_outlined,
  'documents' => Icons.description_outlined,
  'archives' => Icons.archive_outlined,
  'apks' => Icons.android,
  'large' => Icons.sd_storage_outlined,
  _ => Icons.insert_drive_file_outlined,
};

Color _catColor(String c) => switch (c) {
  'images' => Colors.teal,
  'videos' => Colors.deepPurple,
  'audio' => Colors.orange,
  'documents' => Colors.blue,
  'archives' => Colors.brown,
  'apks' => Colors.lightGreen.shade700,
  'large' => Colors.red,
  _ => Colors.blueGrey,
};

/// "Files": internal storage scanned into categories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Map<String, List<ScanFile>>? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rescan());
  }

  Future<void> _rescan() async {
    setState(() => _data = null);
    await context.read<FileBrowserController>().ensureInitialized();
    if (!mounted) return;
    final root = primaryRoot(context);
    final d = await Isolate.run(() => _scan(root));
    if (mounted) setState(() => _data = d);
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    final unit = context.watch<SettingsController>().sizeUnit;
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr.files),
        actions: [
          IconButton(
            tooltip: tr.rescan,
            icon: const Icon(Icons.refresh),
            onPressed: data == null ? null : _rescan,
          ),
        ],
      ),
      body: data == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(tr.scanning),
                ],
              ),
            )
          : GridView.count(
              padding: const EdgeInsets.all(12),
              crossAxisCount: 2,
              childAspectRatio: 1.45,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final c in _cats)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CategoryFilesScreen(
                              category: c,
                              files: [...data[c]!],
                            ),
                          ),
                        );
                        _rescan();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: _catColor(c)
                                  .withValues(alpha: 0.15),
                              child: Icon(_catIcon(c), color: _catColor(c)),
                            ),
                            const Spacer(),
                            Text(
                              catLabel(tr, c),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '${data[c]!.length} · ${formatBytes(data[c]!.fold<int>(0, (s, f) => s + f.$2), unit)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Files of one category: sort, open, tick; move or delete (to the
/// recycle bin) after a confirmation.
class CategoryFilesScreen extends StatefulWidget {
  const CategoryFilesScreen({
    super.key,
    required this.category,
    required this.files,
  });

  final String category;
  final List<ScanFile> files;

  @override
  State<CategoryFilesScreen> createState() => _CategoryFilesScreenState();
}

class _CategoryFilesScreenState extends State<CategoryFilesScreen> {
  late List<ScanFile> _files = widget.files;
  String _sort = 'size';
  final Set<String> _sel = {};
  bool _busy = false;

  List<ScanFile> get _sorted {
    final l = [..._files];
    switch (_sort) {
      case 'date':
        l.sort((a, b) => b.$3.compareTo(a.$3));
      case 'name':
        l.sort(
          (a, b) =>
              _name(a.$1).toLowerCase().compareTo(_name(b.$1).toLowerCase()),
        );
      default:
        l.sort((a, b) => b.$2.compareTo(a.$2));
    }
    return l;
  }

  static String _name(String p) => p.substring(p.lastIndexOf('/') + 1);

  FileEntry _entry(ScanFile f) => FileEntry(
    name: _name(f.$1),
    path: f.$1,
    isDirectory: false,
    size: f.$2,
    modified: DateTime.fromMillisecondsSinceEpoch(f.$3),
  );

  Future<void> _delete() async {
    final tr = l10n(context);
    final unit = context.read<SettingsController>().sizeUnit;
    final paths = _sel.toList();
    final bytes = _files
        .where((f) => _sel.contains(f.$1))
        .fold<int>(0, (s, f) => s + f.$2);
    final ok = await showConfirmDialog(
      context,
      title: tr.moveToBinQ(paths.length),
      message: '${formatBytes(bytes, unit)}\n${tr.moveToBinNote}',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final err = await context.read<RecycleBinController>().moveToBin(paths);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (err == null) {
        _files = _files.where((f) => !_sel.contains(f.$1)).toList();
        _sel.clear();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? tr.movedToBinN(paths.length))),
    );
  }

  Future<void> _move() async {
    final tr = l10n(context);
    final browser = context.read<FileBrowserController>();
    final dest = await showFolderPickerDialog(
      context,
      volumes: browser.volumes,
      initialPath: primaryRoot(context),
    );
    if (dest == null || !mounted) return;
    final paths = _sel.toList();
    final ok = await showConfirmDialog(
      context,
      title: tr.moveFilesQ(paths.length),
      message: dest,
      confirmLabel: tr.move,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    String? err;
    try {
      await FileOperations.move(paths, dest);
    } catch (e) {
      err = '$e';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _files = _files.where((f) => !_sel.contains(f.$1)).toList();
      _sel.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(err ?? tr.movedCount(paths.length))));
  }

  @override
  Widget build(BuildContext context) {
    final tr = l10n(context);
    final unit = context.watch<SettingsController>().sizeUnit;
    final list = _sorted;
    final allPicked = _sel.length == _files.length && _files.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(catLabel(tr, widget.category)),
        actions: [
          IconButton(
            tooltip: allPicked ? tr.selectNone : tr.selectAll,
            icon: Icon(allPicked ? Icons.deselect : Icons.select_all),
            onPressed: () => setState(
              () => allPicked
                  ? _sel.clear()
                  : _sel.addAll(_files.map((f) => f.$1)),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'size',
                checked: _sort == 'size',
                child: Text(tr.sortBySize),
              ),
              CheckedPopupMenuItem(
                value: 'date',
                checked: _sort == 'date',
                child: Text(tr.sortByDate),
              ),
              CheckedPopupMenuItem(
                value: 'name',
                checked: _sort == 'name',
                child: Text(tr.sortByName),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _sel.isEmpty
          ? null
          : SafeArea(
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                child: Row(
                  children: [
                    Expanded(child: Text(tr.selectedCount(_sel.length))),
                    IconButton(
                      tooltip: tr.move,
                      icon: const Icon(Icons.drive_file_move_outlined),
                      onPressed: _busy ? null : _move,
                    ),
                    IconButton(
                      tooltip: tr.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _busy ? null : _delete,
                    ),
                  ],
                ),
              ),
            ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text(tr.emptyFolder))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final f = list[i];
                      final picked = _sel.contains(f.$1);
                      final parent = f.$1.substring(0, f.$1.lastIndexOf('/'));
                      return ListTile(
                        leading: EntryIcon(entry: _entry(f), size: 44),
                        title: Text(
                          _name(f.$1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${formatBytes(f.$2, unit)} · '
                          '${DateFormat('dd.MM.yyyy').format(DateTime.fromMillisecondsSinceEpoch(f.$3))}\n'
                          '${parent.replaceFirst(primaryRoot(context), '')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        isThreeLine: true,
                        trailing: Checkbox(
                          value: picked,
                          onChanged: (_) => setState(
                            () => picked ? _sel.remove(f.$1) : _sel.add(f.$1),
                          ),
                        ),
                        onTap: () => _sel.isNotEmpty
                            ? setState(
                                () =>
                                    picked ? _sel.remove(f.$1) : _sel.add(f.$1),
                              )
                            : context.read<StoragePlatform>().openFile(f.$1),
                        onLongPress: () => setState(
                          () => picked ? _sel.remove(f.$1) : _sel.add(f.$1),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/file_entry.dart';
import '../utils/file_icons.dart';

/// Smart icon/thumbnail for a [FileEntry]:
/// - images → image thumbnail
/// - videos → first-frame thumbnail with a small "play" badge in the
///   corner, so it's instantly recognisable as video
/// - apk/aab → the app's real icon via the native channel
/// - everything else → coloured type icon
///
/// [fill] makes the widget expand to fill its parent (used by grid
/// cells); otherwise it renders inside a fixed [size] box.
class EntryIcon extends StatefulWidget {
  const EntryIcon({super.key, required this.entry, this.size = 40})
    : fill = false;

  const EntryIcon.fill({super.key, required this.entry})
    : size = 0,
      fill = true;

  final FileEntry entry;
  final double size;
  final bool fill;

  static bool isImage(FileEntry e) =>
      !e.isDirectory && _imageExts.contains(e.extension);
  static bool isVideo(FileEntry e) =>
      !e.isDirectory && _videoExts.contains(e.extension);
  static bool isApk(FileEntry e) =>
      !e.isDirectory && _apkExts.contains(e.extension);

  /// Whether this entry renders as a real thumbnail (image or video).
  static bool hasThumbnail(FileEntry e) => isImage(e) || isVideo(e);

  @override
  State<EntryIcon> createState() => _EntryIconState();
}

const _imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
const _videoExts = {'mp4', 'mkv', 'avi', 'mov', 'webm', '3gp'};
const _apkExts = {'apk', 'aab'};

class _EntryIconState extends State<EntryIcon> {
  static const _channel = MethodChannel('dev.nova.nova_file_manager/storage');

  /// In-memory caches keyed by path+mtime.
  static final Map<String, Uint8List> _apkCache = {};
  static final Map<String, Uint8List> _videoCache = {};

  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    if (EntryIcon.isApk(widget.entry)) {
      _loadChannel('apkIcon', _apkCache);
    } else if (EntryIcon.isVideo(widget.entry)) {
      _loadChannel('videoThumb', _videoCache);
    }
  }

  Future<void> _loadChannel(String method, Map<String, Uint8List> cache) async {
    final key =
        '${widget.entry.path}:${widget.entry.modified?.millisecondsSinceEpoch}';
    final cached = cache[key];
    if (cached != null) {
      setState(() => _bytes = cached);
      return;
    }
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(method, {
        'path': widget.entry.path,
      });
      if (!mounted) return;
      if (bytes != null) {
        cache[key] = bytes;
        setState(() => _bytes = bytes);
      }
    } catch (_) {}
  }

  Widget _fallback(ColorScheme scheme) => Icon(
    FileIcons.iconFor(widget.entry),
    size: widget.fill ? 48 : widget.size,
    color: FileIcons.colorFor(widget.entry, scheme),
  );

  Widget _withBadge(Widget child) {
    if (!EntryIcon.isVideo(widget.entry)) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const Positioned(
          right: 4,
          bottom: 4,
          child: CircleAvatar(
            radius: 9,
            backgroundColor: Colors.black54,
            child: Icon(Icons.play_arrow, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = widget.entry;
    Widget child;

    if (EntryIcon.isImage(e)) {
      child = Image.file(
        File(e.path),
        fit: widget.fill ? BoxFit.cover : BoxFit.cover,
        width: widget.fill ? double.infinity : widget.size,
        height: widget.fill ? double.infinity : widget.size,
        cacheWidth: widget.fill ? 400 : (widget.size * 3).toInt(),
        errorBuilder: (context, err, s) => _fallback(scheme),
      );
      child = ClipRRect(
        borderRadius: BorderRadius.circular(widget.fill ? 0 : 6),
        child: child,
      );
    } else if ((EntryIcon.isApk(e) || EntryIcon.isVideo(e)) && _bytes != null) {
      child = Image.memory(
        _bytes!,
        fit: EntryIcon.isVideo(e) ? BoxFit.cover : BoxFit.contain,
        width: widget.fill ? double.infinity : widget.size,
        height: widget.fill ? double.infinity : widget.size,
      );
      child = ClipRRect(
        borderRadius: BorderRadius.circular(widget.fill ? 0 : 6),
        child: child,
      );
    } else {
      child = _fallback(scheme);
    }

    child = _withBadge(child);

    if (widget.fill) return child;
    return SizedBox(width: widget.size, height: widget.size, child: child);
  }
}

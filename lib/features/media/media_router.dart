import 'package:flutter/material.dart';

import '../../core/models/file_entry.dart';
import '../../features/text_editor/presentation/text_editor_screen.dart';
import 'presentation/audio_player_screen.dart';
import 'presentation/image_viewer_screen.dart';
import 'presentation/video_player_screen.dart';

/// Routes media and text files to the built-in viewers/players/editor.
class MediaRouter {
  MediaRouter._();

  static const _image = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
  static const _audio = {'mp3', 'flac', 'wav', 'ogg', 'm4a', 'aac', 'opus'};
  static const _video = {'mp4', 'mkv', 'avi', 'mov', 'webm', '3gp'};
  static const _text = {
    'txt',
    'md',
    'log',
    'csv',
    'tsv',
    'json',
    'xml',
    'html',
    'htm',
    'css',
    'js',
    'mjs',
    'ts',
    'php',
    'py',
    'dart',
    'java',
    'kt',
    'kts',
    'c',
    'h',
    'cpp',
    'cc',
    'cs',
    'go',
    'rs',
    'swift',
    'sh',
    'bat',
    'ps1',
    'ini',
    'cfg',
    'conf',
    'properties',
    'yaml',
    'yml',
    'toml',
    'env',
    'sql',
    'gradle',
    'gitignore',
    'gradle.kts',
    'rb',
    'lua',
    'pl',
  };

  static bool isImage(FileEntry e) =>
      !e.isDirectory && _image.contains(e.extension);
  static bool isAudio(FileEntry e) =>
      !e.isDirectory && _audio.contains(e.extension);
  static bool isVideo(FileEntry e) =>
      !e.isDirectory && _video.contains(e.extension);
  static bool isText(FileEntry e) =>
      !e.isDirectory && _text.contains(e.extension);

  static bool canHandle(FileEntry e) =>
      isImage(e) || isAudio(e) || isVideo(e) || isText(e);

  /// Opens the file in the matching built-in viewer.
  /// [images] should contain sibling image paths for swipe navigation.
  /// [onActions] — when given, the image viewer shows a "⋮" button that
  /// pops the viewer and invokes the callback (used to open the file's
  /// context menu from the file list).
  static void open(
    BuildContext context,
    FileEntry entry, {
    List<String>? images,
    VoidCallback? onActions,
  }) {
    if (isImage(entry)) {
      final list = images ?? [entry.path];
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImageViewerScreen(
            images: list,
            initialIndex: list.indexOf(entry.path).clamp(0, list.length - 1),
            onActions: onActions,
          ),
        ),
      );
    } else if (isAudio(entry)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AudioPlayerScreen(path: entry.path),
        ),
      );
    } else if (isVideo(entry)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoPlayerScreen(path: entry.path),
        ),
      );
    } else if (isText(entry)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TextEditorScreen(path: entry.path),
        ),
      );
    }
  }
}

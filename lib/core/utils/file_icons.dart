import 'package:flutter/material.dart';

import '../models/file_entry.dart';

/// Maps file types to icons and colours.
class FileIcons {
  FileIcons._();

  static const _image = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
    'heic',
    'heif',
    'avif',
  };
  static const _video = {
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
  };
  static const _audio = {
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
  };
  static const _doc = {'pdf', 'doc', 'docx', 'txt', 'md', 'rtf', 'odt'};
  static const _sheet = {'xls', 'xlsx', 'csv', 'ods'};
  static const _archive = {'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz'};
  static const _code = {
    'dart',
    'java',
    'kt',
    'py',
    'js',
    'ts',
    'html',
    'css',
    'json',
    'xml',
    'yaml',
    'c',
    'cpp',
    'h',
    'cs',
    'go',
    'rs',
    'sh',
  };
  static const _apk = {'apk', 'aab'};
  static const _font = {'ttf', 'otf', 'woff', 'woff2'};

  static String extOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  static bool isVideoName(String name) => _video.contains(extOf(name));
  static bool isImageName(String name) => _image.contains(extOf(name));
  static bool isAudioName(String name) => _audio.contains(extOf(name));

  /// Icon by file name — for remote (PC / other device) entries.
  static IconData iconForName(String name, {bool isDir = false}) =>
      isDir ? Icons.folder : _iconForExt(extOf(name));

  static Color colorForName(
    String name,
    ColorScheme scheme, {
    bool isDir = false,
  }) => isDir ? scheme.primary : _colorForExt(extOf(name), scheme);

  static IconData iconFor(FileEntry entry) {
    if (entry.isDirectory) return Icons.folder;
    return _iconForExt(entry.extension);
  }

  static IconData _iconForExt(String ext) {
    if (_image.contains(ext)) return Icons.image;
    if (_video.contains(ext)) return Icons.movie;
    if (_audio.contains(ext)) return Icons.music_note;
    if (_doc.contains(ext)) return Icons.description;
    if (_sheet.contains(ext)) return Icons.table_chart;
    if (_archive.contains(ext)) return Icons.archive;
    if (_code.contains(ext)) return Icons.code;
    if (_apk.contains(ext)) return Icons.android;
    if (_font.contains(ext)) return Icons.font_download;
    return Icons.insert_drive_file;
  }

  static Color colorFor(FileEntry entry, ColorScheme scheme) {
    if (entry.isDirectory) return scheme.primary;
    return _colorForExt(entry.extension, scheme);
  }

  static Color _colorForExt(String ext, ColorScheme scheme) {
    if (_image.contains(ext)) return Colors.teal;
    if (_video.contains(ext)) return Colors.deepPurple;
    if (_audio.contains(ext)) return Colors.orange;
    if (_doc.contains(ext)) return Colors.blue;
    if (_sheet.contains(ext)) return Colors.green;
    if (_archive.contains(ext)) return Colors.brown;
    if (_apk.contains(ext)) return Colors.lightGreen;
    return scheme.onSurfaceVariant;
  }
}

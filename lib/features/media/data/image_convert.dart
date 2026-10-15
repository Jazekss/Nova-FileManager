import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;

/// Converts a raster image to jpg/png/webp, writing a sibling file
/// `name.<ext>` (uniquified) next to the source. Runs in an isolate.
Future<String?> convertImage(String path, String format) async {
  return Isolate.run(() {
    final src = File(path);
    final bytes = src.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return 'unsupported';
    final List<int> out;
    switch (format) {
      case 'jpg':
        out = img.encodeJpg(decoded, quality: 92);
      case 'png':
        out = img.encodePng(decoded);
      case 'webp':
        out = img.encodeWebP(decoded);
      default:
        return 'unsupported';
    }
    final dir = path.substring(0, path.lastIndexOf('/'));
    final name = path.substring(path.lastIndexOf('/') + 1);
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    var dest = '$dir/$base.$format';
    var n = 1;
    while (File(dest).existsSync()) {
      dest = '$dir/$base ($n).$format';
      n++;
    }
    File(dest).writeAsBytesSync(out);
    return null;
  });
}

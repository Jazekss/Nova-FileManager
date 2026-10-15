// ignore_for_file: avoid_print, unnecessary_string_interpolations

import 'dart:collection';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Removes the cream background from assets/icon.png (flood-fill from the
/// borders, tolerant to anti-aliasing), then regenerates:
/// - Android launcher PNG mipmaps (transparent background)
/// - assets/icon.png itself (transparent, used in-app + desktop asset)
/// - Windows .ico for the desktop runner
///
/// Run: dart run tool/make_icons.dart
void main() {
  final src = img.decodePng(File('assets/icon.png').readAsBytesSync())!;
  _stripBackground(src);

  // Save the transparent master back over assets/icon.png and desktop copy.
  final png = img.encodePng(src);
  File('assets/icon.png').writeAsBytesSync(png);
  File('desktop/nova_transfer/assets/icon.png').writeAsBytesSync(png);
  print('icon.png -> transparent bg');

  const mipmap = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  for (final e in mipmap.entries) {
    final r = img.copyResize(src, width: e.value, height: e.value);
    final path = 'android/app/src/main/res/${e.key}/ic_launcher.png';
    File(path).writeAsBytesSync(img.encodePng(r));
    print('$path ${e.value}px');
  }

  final r256 = img.copyResize(src, width: 256, height: 256);
  final ico = img.encodeIco(r256, singleFrame: true);
  const icoPath =
      'desktop/nova_transfer/windows/runner/resources/app_icon.ico';
  File(icoPath).writeAsBytesSync(ico);
  print(icoPath);
  print('done');
}

/// Flood-fills the background colour (sampled at the corners) to
/// transparent, starting from every border pixel.
void _stripBackground(img.Image im) {
  final bg = im.getPixel(0, 0);
  const tolerance = 40;

  bool isBg(img.Pixel p) {
    if (p.a == 0) return false;
    final dr = (p.r - bg.r).abs();
    final dg = (p.g - bg.g).abs();
    final db = (p.b - bg.b).abs();
    return dr + dg + db <= tolerance;
  }

  final q = Queue<int>(); // encodes y * width + x
  final seen = <int>{};
  void push(int x, int y) {
    final k = y * im.width + x;
    if (seen.add(k)) q.add(k);
  }

  for (var x = 0; x < im.width; x++) {
    push(x, 0);
    push(x, im.height - 1);
  }
  for (var y = 0; y < im.height; y++) {
    push(0, y);
    push(im.width - 1, y);
  }
  while (q.isNotEmpty) {
    final k = q.removeFirst();
    final x = k % im.width;
    final y = k ~/ im.width;
    final p = im.getPixel(x, y);
    if (!isBg(p)) continue;
    p.a = 0;
    if (x > 0) push(x - 1, y);
    if (x < im.width - 1) push(x + 1, y);
    if (y > 0) push(x, y - 1);
    if (y < im.height - 1) push(x, y + 1);
  }
}

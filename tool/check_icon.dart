// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart';

void main() {
  final i = decodePng(File('assets/icon.png').readAsBytesSync())!;
  print('${i.width}x${i.height}');
  print('corner(0,0): a=${i.getPixel(0, 0).a} rgb=${i.getPixel(0, 0).r},${i.getPixel(0, 0).g},${i.getPixel(0, 0).b}');
  print('center: a=${i.getPixel(i.width ~/ 2, i.height ~/ 2).a}');
}

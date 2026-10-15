import 'package:flutter_test/flutter_test.dart';
import 'package:nova_file_manager/core/utils/format.dart';

void main() {
  group('formatBytes', () {
    test('auto picks sensible unit', () {
      expect(formatBytes(512, SizeUnit.auto), '512 B');
      expect(formatBytes(2048, SizeUnit.auto), '2.00 KB');
      expect(formatBytes(5 * 1024 * 1024, SizeUnit.auto), '5.00 MB');
      expect(formatBytes(3 * 1024 * 1024 * 1024, SizeUnit.auto), '3.00 GB');
    });

    test('forced units', () {
      expect(formatBytes(2048, SizeUnit.kb), '2.00 KB');
      expect(formatBytes(2048, SizeUnit.mb), contains('MB'));
      expect(formatBytes(1024 * 1024 * 1024, SizeUnit.mb), '1024 MB');
    });
  });
}

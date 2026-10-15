import 'package:flutter_test/flutter_test.dart';
import 'package:nova_file_manager/core/utils/wildcard.dart';

void main() {
  group('wildcardToRegExp', () {
    test('star wildcard matches extension', () {
      final re = wildcardToRegExp('*.pdf');
      expect(re.hasMatch('doc.pdf'), isTrue);
      expect(re.hasMatch('doc.PDF'), isTrue); // case-insensitive by default
      expect(re.hasMatch('doc.pdfx'), isFalse);
      expect(re.hasMatch('pdf.doc'), isFalse);
    });

    test('question mark matches single char', () {
      final re = wildcardToRegExp('a?.txt');
      expect(re.hasMatch('a1.txt'), isTrue);
      expect(re.hasMatch('a12.txt'), isFalse);
    });

    test('plain text matches as substring', () {
      final re = wildcardToRegExp('report');
      expect(re.hasMatch('my report.docx'), isTrue);
      expect(re.hasMatch('REPORT.txt'), isTrue);
      expect(re.hasMatch('other.txt'), isFalse);
    });

    test('special regex chars are escaped', () {
      final re = wildcardToRegExp('a+b.txt');
      expect(re.hasMatch('a+b.txt'), isTrue);
      expect(re.hasMatch('aab.txt'), isFalse);
    });
  });
}

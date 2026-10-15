import 'package:intl/intl.dart';

enum SizeUnit { auto, kb, mb, gb }

String formatBytes(int bytes, SizeUnit unit) {
  const kb = 1024.0;
  const mb = kb * 1024;
  const gb = mb * 1024;

  switch (unit) {
    case SizeUnit.kb:
      return '${_trim(bytes / kb)} KB';
    case SizeUnit.mb:
      return '${_trim(bytes / mb)} MB';
    case SizeUnit.gb:
      return '${_trim(bytes / gb)} GB';
    case SizeUnit.auto:
      if (bytes < kb) return '$bytes B';
      if (bytes < mb) return '${_trim(bytes / kb)} KB';
      if (bytes < gb) return '${_trim(bytes / mb)} MB';
      return '${_trim(bytes / gb)} GB';
  }
}

String _trim(double v) {
  if (v >= 100) return v.toStringAsFixed(0);
  if (v >= 10) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}

final _dateFmt = DateFormat('dd.MM.yyyy');
final _dateTimeFmt = DateFormat('dd.MM.yyyy HH:mm');

String formatDate(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

String formatDateTime(DateTime? d) => d == null ? '—' : _dateTimeFmt.format(d);

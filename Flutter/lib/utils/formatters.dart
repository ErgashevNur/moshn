import 'package:intl/intl.dart';

String formatCurrency(num value) {
  final fmt = NumberFormat.decimalPattern('ru');
  return '${fmt.format(value)} сум';
}

String formatDate(DateTime date) {
  return DateFormat('d MMM yyyy', 'ru').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('d MMM, HH:mm', 'ru').format(date);
}

String formatMileage(num value) {
  final fmt = NumberFormat.decimalPattern('ru');
  return '${fmt.format(value)} км';
}

/// "18 августа" — bron sarlavhasidagi qisqa sana (yilsiz).
/// intl'da tanlangan til ma'lumoti bo'lmasa ru'ga tushadi.
String formatDayMonth(DateTime date, String locale) {
  try {
    return DateFormat('d MMMM', locale).format(date);
  } catch (_) {
    return DateFormat('d MMMM', 'ru').format(date);
  }
}

/// "540 000" — valyuta so'zisiz, faqat raqam (birlik alohida yoziladi).
String formatAmount(num value) => NumberFormat.decimalPattern('ru').format(value);

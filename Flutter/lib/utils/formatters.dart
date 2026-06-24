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

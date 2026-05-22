import 'package:intl/intl.dart';

String formatCurrency(num value) {
  final fmt = NumberFormat.decimalPattern('uz');
  return '${fmt.format(value)} so\'m';
}

String formatDate(DateTime date) {
  return DateFormat('d MMM yyyy', 'uz').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('d MMM, HH:mm', 'uz').format(date);
}

String formatMileage(num value) {
  final fmt = NumberFormat.decimalPattern('uz');
  return '${fmt.format(value)} km';
}

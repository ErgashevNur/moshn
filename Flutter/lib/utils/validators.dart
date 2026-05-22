class Validators {
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'phone_required';
    final v = value.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\+?998\d{9}$').hasMatch(v)) return 'phone_required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'email_required';
    final v = value.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'email_invalid';
    return null;
  }

  static String? password(String? value, {int min = 6}) {
    if (value == null || value.isEmpty) return 'password_required';
    if (value.length < min) return 'password_min';
    return null;
  }

  static String? notEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    return null;
  }
}

String formatPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 3) return '+$digits';
  if (digits.length <= 5) return '+${digits.substring(0, 3)} ${digits.substring(3)}';
  if (digits.length <= 7) {
    return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5)}';
  }
  if (digits.length <= 9) {
    return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
        '${digits.substring(5, 8)} ${digits.substring(8)}';
  }
  return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
      '${digits.substring(5, 8)} ${digits.substring(8, 10)} ${digits.substring(10)}';
}

String normalizePhone(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('255') && digits.length >= 12) {
    return '+${digits.substring(0, 12)}';
  }
  if (digits.startsWith('0') && digits.length == 10) {
    return '+255${digits.substring(1)}';
  }
  if (digits.length == 9) {
    return '+255$digits';
  }
  if (input.startsWith('+')) return input.trim();
  return '+$digits';
}

bool isValidTzPhone(String normalized) {
  return RegExp(r'^\+255\d{9}$').hasMatch(normalized);
}

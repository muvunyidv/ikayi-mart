/// Rwandan mobile: +2507XXXXXXXX, 2507XXXXXXXX, or 07XXXXXXXX (MTN 78/79, Airtel 72/73).
final rwandaPhonePattern = RegExp(r'^(?:\+250|250|0)?(7[2389]\d{7})$');

String compactRwandaPhone(String input) =>
    input.replaceAll(RegExp(r'[\s-]'), '');

/// Returns `+2507XXXXXXXX` or null when the number is not a valid Rwandan mobile.
String? normalizeRwandaPhone(String input) {
  final compact = compactRwandaPhone(input.trim());
  final match = rwandaPhonePattern.firstMatch(compact);
  if (match == null) return null;
  return '+250${match.group(1)}';
}

bool isValidRwandaPhone(String input) => normalizeRwandaPhone(input) != null;

String? rwandaPhoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Phone is required';
  }
  if (!isValidRwandaPhone(value)) {
    return 'Enter a valid Rwandan number (+250 7XX XXX XXX or 07XXXXXXXX)';
  }
  return null;
}

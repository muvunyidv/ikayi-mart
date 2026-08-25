class PasswordRule {
  const PasswordRule({required this.label, required this.met});

  final String label;
  final bool met;
}

class PasswordStrength {
  const PasswordStrength(this.rules);

  final List<PasswordRule> rules;

  bool get isStrong => rules.every((rule) => rule.met);
}

abstract final class PasswordRules {
  static final _upper = RegExp(r'[A-Z]');
  static final _lower = RegExp(r'[a-z]');
  static final _digit = RegExp(r'[0-9]');
  static final _special = RegExp(r'[@$!%*?&]');

  static PasswordStrength evaluate(String password) {
    return PasswordStrength([
      PasswordRule(label: 'At least 8 characters', met: password.length >= 8),
      PasswordRule(
        label: 'At least 1 uppercase letter (A-Z)',
        met: _upper.hasMatch(password),
      ),
      PasswordRule(
        label: 'At least 1 lowercase letter (a-z)',
        met: _lower.hasMatch(password),
      ),
      PasswordRule(
        label: 'At least 1 number (0-9)',
        met: _digit.hasMatch(password),
      ),
      PasswordRule(
        label: 'At least 1 special character (@\$!%*?&)',
        met: _special.hasMatch(password),
      ),
    ]);
  }

  static String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!evaluate(value).isStrong) {
      return 'Password does not meet all requirements';
    }
    return null;
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/password_rules.dart';

/// Live checklist under a password field (green check / red cross).
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = PasswordRules.evaluate(password);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (final rule in strength.rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    rule.met ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: rule.met ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rule.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: rule.met ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

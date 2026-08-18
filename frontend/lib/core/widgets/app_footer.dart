import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '© $year IKAYI MART. All rights reserved.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondary,
              fontSize: 11,
              height: 1.2,
            ),
      ),
    );
  }
}

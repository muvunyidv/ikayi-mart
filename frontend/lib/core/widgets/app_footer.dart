import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final linkStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.primaryOrange,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _showAboutUs(context),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text('About Us', style: linkStyle),
              ),
              Text(
                '·',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
              ),
              TextButton(
                onPressed: () => _showContactUs(context),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text('Contact Us', style: linkStyle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '© $year IKAYIMART. All rights reserved.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondary,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  static void _showAboutUs(BuildContext context) {
    _showInfoSheet(
      context,
      title: 'About Us',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "IKAYIMART is Rwanda's fast 2-step guest marketplace.",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Browse, checkout as a guest — no account required — and track '
            'your order by phone. Most Kigali deliveries arrive within 60 minutes '
            'across Gasabo, Kicukiro, and Nyarugenge.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Step 1: Add items to your cart.\n'
            'Step 2: Guest checkout with Mobile Money or card.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  static void _showContactUs(BuildContext context) {
    _showInfoSheet(
      context,
      title: 'Contact Us',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ContactTile(
            icon: Icons.chat_outlined,
            label: 'Support WhatsApp',
            value: '+250 788 000 000',
          ),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'support@ikayi.app',
          ),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.location_on_outlined,
            label: 'Kigali office',
            value: 'KG 7 Ave, Kigali, Rwanda',
          ),
        ],
      ),
    );
  }

  static void _showInfoSheet(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final isWide = MediaQuery.sizeOf(context).width >= kTabletBreakpoint;
    if (isWide) {
      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(width: 420, child: child),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 16),
              child,
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Copied $value')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryOrange, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 10,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      value,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.copy, size: 16, color: AppColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

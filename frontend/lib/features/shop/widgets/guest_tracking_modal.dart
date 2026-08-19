import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Post-purchase confirmation with guest tracking ID.
class GuestTrackingModal extends StatelessWidget {
  const GuestTrackingModal({
    super.key,
    required this.trackingCode,
    required this.totalRwfLabel,
  });

  final String trackingCode;
  final String totalRwfLabel;

  static Future<void> show(
    BuildContext context, {
    required String trackingCode,
    required String totalRwfLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GuestTrackingModal(
        trackingCode: trackingCode,
        totalRwfLabel: totalRwfLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0x1AFF5722),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.primaryOrange,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Order Placed!',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your guest tracking code is ready. Use it to follow delivery — no account required.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondary,
                ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Text(
                  'GUEST TRACKING ID',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  trackingCode,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.primaryOrange,
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total paid: $totalRwfLabel',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Track at /tracking?code=$trackingCode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.tertiary,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: trackingCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tracking code copied')),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy code'),
        ),
        TextButton(
          onPressed: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.go('/tracking?code=$trackingCode');
          },
          child: const Text('Track order'),
        ),
        ElevatedButton(
          onPressed: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.go('/');
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(140, 48),
          ),
          child: const Text('Back to Shop'),
        ),
      ],
    );
  }
}

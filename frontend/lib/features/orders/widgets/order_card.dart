import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import 'order_item_tile.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.dateLabel});

  final CustomerOrder order;
  final String dateLabel;

  Color get _statusColor => switch (order.status) {
    OrderStatus.delivered => AppColors.success,
    OrderStatus.cancelled => AppColors.error,
    OrderStatus.issueReported => AppColors.error,
    _ => AppColors.primaryOrange,
  };

  @override
  Widget build(BuildContext context) {
    final address = [
      if (order.landmark.trim().isNotEmpty) order.landmark.trim(),
      order.locationLabel,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.displayCode}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(order.status.label),
                backgroundColor: _statusColor.withValues(alpha: 0.12),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                labelStyle: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total amount',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
                ),
              ),
              Text(
                formatRwf(order.grandTotalRwf, suffix: true),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
                ),
              ),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...[
              for (var i = 0; i < order.items.length; i++) ...[
                OrderItemTile(item: order.items[i]),
                if (i < order.items.length - 1) const SizedBox(height: 12),
              ],
            ],
          ],
          if (order.status.isTrackable) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => context.go(
                  Uri(
                    path: '/tracking',
                    queryParameters: {'code': order.trackingCode},
                  ).toString(),
                ),
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('Track Order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

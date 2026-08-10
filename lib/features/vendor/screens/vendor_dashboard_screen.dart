import 'package:flutter/material.dart';

import '../../../core/mock_data/orders_mock.dart';
import '../../../core/mock_data/products_mock.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lowStock = ProductsMock.products.where((p) => p.isLowStock).length;
    final maxRevenue = OrdersMock.weeklyRevenueRwf.reduce(
      (a, b) => a > b ? a : b,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                'Dashboard Overview',
                style: Theme.of(context).textTheme.displayMedium,
              );
              final status = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Store Status'),
                  const SizedBox(width: 8),
                  Switch(value: true, onChanged: (_) {}),
                  Text(
                    'Online',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryOrange,
                        ),
                  ),
                ],
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    status,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  status,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _KpiCard(
                    title: "Today's Revenue (RWF)",
                    value: formatRwf(OrdersMock.todayRevenueRwf),
                    badge: '+12.5%',
                    badgeColor: AppColors.tertiary,
                  ),
                  _KpiCard(
                    title: 'Pending Orders',
                    value: '${OrdersMock.pendingCount}',
                    badge: 'Urgent',
                    badgeColor: AppColors.error,
                  ),
                  _KpiCard(
                    title: 'Low Stock Items',
                    value: '$lowStock',
                    badge: 'Critical',
                    badgeColor: AppColors.error,
                  ),
                  _KpiCard(
                    title: 'Completed Orders',
                    value: '${OrdersMock.completedCount}',
                    badge: 'This Week',
                    badgeColor: AppColors.secondary,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Revenue Trends',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'Daily performance comparison against previous week.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('7 Days'),
                      selected: true,
                      selectedColor: AppColors.primaryOrange,
                      labelStyle: const TextStyle(color: Colors.white),
                      onSelected: (_) {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: _RevenueChartPainter(
                      values: OrdersMock.weeklyRevenueRwf,
                      maxValue: maxRevenue.toDouble(),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: OrdersMock.weekLabels
                      .map(
                        (d) => Text(
                          d,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 12),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 800;
              final alerts = _AlertsBlock();
              final topSellers = _TopSellersBlock();
              if (stack) {
                return Column(
                  children: [
                    alerts,
                    const SizedBox(height: 16),
                    topSellers,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: alerts),
                  const SizedBox(width: 16),
                  Expanded(child: topSellers),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.badge,
    required this.badgeColor,
  });

  final String title;
  final String value;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondary,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Urgent Actions', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          _AlertRow(
            icon: Icons.error_outline,
            color: AppColors.error,
            title: 'Orders Requiring Dispatch',
            subtitle: 'New Order #IKY-9842 — Shipping SLA expires in 2h',
          ),
          _AlertRow(
            icon: Icons.inventory_2_outlined,
            color: AppColors.primaryDeep,
            title: 'Low Stock Warnings',
            subtitle: 'Restock: iPhone 15 Pro Max Case — Only 2 units left',
          ),
          _AlertRow(
            icon: Icons.chat_bubble_outline,
            color: AppColors.tertiary,
            title: 'Unresolved Customer Inquiry',
            subtitle: 'Query regarding missing charger cable',
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontSize: 14)),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                        fontSize: 12,
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

class _TopSellersBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = ProductsMock.products.take(3).toList();
    return Material(
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Top Selling Products',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  'View All',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryOrange,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...top.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 40,
                          height: 40,
                          child: ColoredBox(color: AppColors.surfaceHigh),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontSize: 14),
                          ),
                          Text(
                            p.category,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRwf(p.priceRwf, suffix: true),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  _RevenueChartPainter({required this.values, required this.maxValue});

  final List<int> values;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] / maxValue) * size.height * 0.9;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = AppColors.primaryDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxValue != maxValue;
}

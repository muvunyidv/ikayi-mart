import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/api/ikayi_api.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../state/auth_state.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  OrderStatus? _filter;
  List<CustomerOrder> _orders = [];
  bool _loading = true;
  String? _error;

  static final _dateFormat = DateFormat.yMMMd().add_jm();

  IkayiApi get _api => context.read<IkayiApi>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthState>();
      if (!auth.isLoggedIn) {
        context.go('/login?next=/orders');
        return;
      }
      _refresh();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _api.myOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<CustomerOrder> get _visible {
    if (_filter == null) return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final tabs = <(String, OrderStatus?)>[
      ('All', null),
      ('Pending', OrderStatus.pending),
      ('Processing', OrderStatus.processing),
      ('Shipped', OrderStatus.shipped),
      ('Delivered', OrderStatus.delivered),
      ('Cancelled', OrderStatus.cancelled),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'My Orders',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Newest orders appear first. Track active deliveries from each card.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tabs.map((tab) {
                    final (label, status) = tab;
                    final selected = _filter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: AppColors.primaryOrange,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              _filter == null
                  ? 'You have not placed any orders yet.'
                  : 'No ${_filter!.label.toLowerCase()} orders.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Continue shopping'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        itemCount: _visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _OrderCard(
          order: _visible[index],
          dateLabel: _dateFormat.format(_visible[index].createdAt.toLocal()),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.dateLabel});

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
    final itemsLabel = order.items
        .map((i) => '${i.productName} ×${i.quantity}')
        .join(', ');

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
            children: [
              Expanded(
                child: Text(
                  '#${order.displayCode}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Chip(
                label: Text(order.status.label),
                backgroundColor: _statusColor.withValues(alpha: 0.12),
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            itemsLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${order.locationLabel} · ${formatRwf(order.grandTotalRwf, suffix: true)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondary,
                ),
          ),
          if (order.status.isTrackable) ...[
            const SizedBox(height: 12),
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

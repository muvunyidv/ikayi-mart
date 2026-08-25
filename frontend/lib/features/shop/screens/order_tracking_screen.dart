import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/ikayi_api.dart';
import '../../../core/constants/branding.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/shop_scroll_view.dart';
import '../../orders/widgets/order_item_tile.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const _pollInterval = Duration(seconds: 15);

  final _codeController = TextEditingController();
  CustomerOrder? _order;
  String? _error;
  bool _loading = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final code = widget.initialCode?.trim();
    if (code != null && code.isNotEmpty) {
      _codeController.text = code;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _track(updateUrl: false);
      });
    }
  }

  @override
  void didUpdateWidget(covariant OrderTrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialCode?.trim();
    final prev = oldWidget.initialCode?.trim();
    if (next != null && next.isNotEmpty && next != prev) {
      _codeController.text = next;
      _track(updateUrl: false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isActiveDelivery {
    final status = _order?.status;
    return status == OrderStatus.processing || status == OrderStatus.shipped;
  }

  void _syncPoll() {
    _pollTimer?.cancel();
    if (!_isActiveDelivery) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      _track(updateUrl: false, silent: true);
    });
  }

  Future<void> _track({bool updateUrl = true, bool silent = false}) async {
    final code = _codeController.text.replaceFirst('#', '').trim();
    if (code.isEmpty) {
      if (!silent) {
        setState(() => _error = 'Enter a tracking code');
      }
      return;
    }

    if (updateUrl) {
      context.go(
        Uri(path: '/tracking', queryParameters: {'code': code}).toString(),
      );
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final order = await context.read<IkayiApi>().trackOrder(code);
      if (!mounted) return;
      setState(() {
        _order = order;
        _error = null;
        _loading = false;
      });
      _syncPoll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) _order = null;
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;

    return ShopScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      maxContentWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Track your order',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your guest tracking code to see live delivery status.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: 20),
          Form(
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _codeField()),
                      const SizedBox(width: 12),
                      SizedBox(width: 180, child: _trackButton()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _codeField(),
                      const SizedBox(height: 12),
                      _trackButton(),
                    ],
                  ),
          ),
          if (_loading) ...[
            const SizedBox(height: 32),
            const Center(child: CircularProgressIndicator()),
          ] else if (_error != null && _order == null) ...[
            const SizedBox(height: 24),
            _MessageCard(
              icon: Icons.error_outline,
              color: AppColors.error,
              message: _error!,
            ),
          ] else if (_order != null) ...[
            const SizedBox(height: 28),
            _OrderStatusCard(order: _order!),
          ],
        ],
      ),
    );
  }

  Widget _codeField() {
    return TextFormField(
      controller: _codeController,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Tracking code',
        hintText: 'IKY-9842',
      ),
      onFieldSubmitted: (_) => _track(),
    );
  }

  Widget _trackButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _track,
      child: const Text('Track Order'),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.order});

  final CustomerOrder order;

  static const _steps = <(OrderStatus, String, IconData)>[
    (OrderStatus.pending, 'Order Placed', Icons.receipt_long_outlined),
    (OrderStatus.processing, 'Processing', Icons.inventory_2_outlined),
    (OrderStatus.shipped, 'Out for Delivery', Icons.local_shipping_outlined),
    (OrderStatus.delivered, 'Delivered', Icons.check_circle_outlined),
  ];

  int get _activeIndex {
    return switch (order.status) {
      OrderStatus.pending => 0,
      OrderStatus.processing || OrderStatus.issueReported => 1,
      OrderStatus.shipped => 2,
      OrderStatus.delivered => 3,
      OrderStatus.cancelled => -1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    final vendor = order.items
        .map((i) => i.vendorName?.trim() ?? '')
        .where((n) => n.isNotEmpty)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.displayCode}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.guestName} · ${formatRwf(order.grandTotalRwf, suffix: true)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(order.status.label),
                backgroundColor: AppColors.primaryLight,
                labelStyle: const TextStyle(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (order.status == OrderStatus.cancelled)
            const _MessageCard(
              icon: Icons.cancel_outlined,
              color: AppColors.error,
              message: 'This order was cancelled.',
            )
          else
            Column(
              children: List.generate(_steps.length, (index) {
                final step = _steps[index];
                final done = active >= index;
                final current = active == index;
                return _TimelineRow(
                  label: step.$2,
                  icon: step.$3,
                  done: done,
                  current: current,
                  isLast: index == _steps.length - 1,
                );
              }),
            ),
          if (order.status == OrderStatus.issueReported) ...[
            const SizedBox(height: 16),
            _MessageCard(
              icon: Icons.report_outlined,
              color: AppColors.error,
              message:
                  order.supportTicket ?? 'An issue was reported on this order.',
            ),
          ],
          if (order.status == OrderStatus.shipped) ...[
            const SizedBox(height: 20),
            _DriverCard(
              destination: '${order.landmark} — ${order.locationLabel}',
              partnerName: vendor,
            ),
          ] else if (order.status == OrderStatus.delivered) ...[
            const SizedBox(height: 20),
            _MessageCard(
              icon: Icons.home_outlined,
              color: AppColors.primaryOrange,
              message:
                  'Delivered to ${order.landmark}, ${order.locationLabel}.',
            ),
          ],
          const SizedBox(height: 20),
          Text('Items', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          ...[
            for (var i = 0; i < order.items.length; i++) ...[
              OrderItemTile(item: order.items[i]),
              if (i < order.items.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.icon,
    required this.done,
    required this.current,
    required this.isLast,
  });

  final String label;
  final IconData icon;
  final bool done;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.primaryOrange : AppColors.secondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.primaryOrange : AppColors.surfaceHigh,
              ),
              child: Icon(
                icon,
                size: 18,
                color: done ? Colors.white : AppColors.secondary,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: done ? AppColors.primaryOrange : AppColors.borderSubtle,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: current ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.destination, this.partnerName});

  final String destination;
  final String? partnerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primaryOrange,
            child: Icon(Icons.delivery_dining, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppBranding.name} Courier',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Live tracking · heading to $destination',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                    fontSize: 12,
                  ),
                ),
                if (partnerName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Vendor partner: $partnerName',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

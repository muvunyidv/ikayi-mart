import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/api/ikayi_api.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/auth_state.dart';
import '../../orders/widgets/order_card.dart';

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
    final padding = EdgeInsets.all(isDesktop ? 32 : 16);
    final tabs = <(String, OrderStatus?)>[
      ('All', null),
      ('Pending', OrderStatus.pending),
      ('Processing', OrderStatus.processing),
      ('Shipped', OrderStatus.shipped),
      ('Delivered', OrderStatus.delivered),
      ('Cancelled', OrderStatus.cancelled),
    ];

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        primary: true,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
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
                                  color: selected
                                      ? Colors.white
                                      : AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) =>
                                    setState(() => _filter = status),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ..._bodySlivers(padding),
        ],
      ),
    );
  }

  List<Widget> _bodySlivers(EdgeInsets padding) {
    if (_loading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ];
    }
    if (_visible.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: padding.copyWith(top: 0),
        sliver: SliverList.separated(
          itemCount: _visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = _visible[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: OrderCard(
                  order: order,
                  dateLabel: _dateFormat.format(order.createdAt.toLocal()),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

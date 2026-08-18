import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/ikayi_api.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  OrderStatus? _filter;
  List<CustomerOrder> _orders = [];
  bool _loading = true;
  String? _error;

  IkayiApi get _api => context.read<IkayiApi>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _api.vendorOrders();
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

  Future<void> _setStatus(CustomerOrder order, OrderStatus status) async {
    try {
      final updated = await _api.updateOrderStatus(order.id, status);
      setState(() {
        final i = _orders.indexWhere((o) => o.id == order.id);
        if (i >= 0) _orders[i] = updated;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openSupport(CustomerOrder order) async {
    final replyCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Support — #${order.displayCode}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.supportTicket ??
                      'No open ticket. Guest may still contact support.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: replyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Resolution reply',
                    hintText: 'Write a response to the guest...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = replyCtrl.text.trim();
                Navigator.pop(ctx);
                if (order.supportTicketId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'No open ticket for #${order.displayCode}',
                      ),
                    ),
                  );
                  return;
                }
                if (text.isEmpty) return;
                try {
                  await _api.replyToTicket(
                    ticketId: order.supportTicketId!,
                    resolution: text,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reply sent for #${order.displayCode}'),
                    ),
                  );
                  await _refresh();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 44),
              ),
              child: const Text('Send reply'),
            ),
          ],
        );
      },
    );
    replyCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, OrderStatus?)>[
      ('All', null),
      ('Pending', OrderStatus.pending),
      ('Processing', OrderStatus.processing),
      ('Shipped', OrderStatus.shipped),
      ('Delivered', OrderStatus.delivered),
      ('Issue Reported', OrderStatus.issueReported),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order Management',
            style: Theme.of(context).textTheme.displayMedium,
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                AppColors.surfaceLow,
                              ),
                              columns: const [
                                DataColumn(label: Text('Order ID')),
                                DataColumn(label: Text('Guest')),
                                DataColumn(label: Text('Phone')),
                                DataColumn(label: Text('Location')),
                                DataColumn(label: Text('Items')),
                                DataColumn(label: Text('Total')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Support')),
                              ],
                              rows: _visible.map((order) {
                                final itemsLabel = order.items
                                    .map(
                                      (i) =>
                                          '${i.productName} ×${i.quantity}',
                                    )
                                    .join(', ');
                                return DataRow(
                                  cells: [
                                    DataCell(Text('#${order.displayCode}')),
                                    DataCell(Text(order.guestName)),
                                    DataCell(Text(order.phone)),
                                    DataCell(Text(order.locationLabel)),
                                    DataCell(
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          itemsLabel,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        formatRwf(
                                          order.grandTotalRwf,
                                          suffix: true,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      DropdownButton<OrderStatus>(
                                        value: order.status,
                                        underline: const SizedBox.shrink(),
                                        items: [
                                          for (final s in OrderStatus.values)
                                            if (s != OrderStatus.cancelled ||
                                                order.status ==
                                                    OrderStatus.cancelled)
                                              DropdownMenuItem(
                                                value: s,
                                                enabled:
                                                    s != OrderStatus.cancelled,
                                                child: Text(s.label),
                                              ),
                                        ],
                                        onChanged: (status) {
                                          if (status == null) return;
                                          _setStatus(order, status);
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        tooltip: 'Resolve issue',
                                        onPressed: () => _openSupport(order),
                                        icon: Icon(
                                          Icons.support_agent,
                                          color: order.status ==
                                                  OrderStatus.issueReported
                                              ? AppColors.error
                                              : AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/mock_data/orders_mock.dart';
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
  late List<CustomerOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = List.of(OrdersMock.orders);
  }

  List<CustomerOrder> get _visible {
    if (_filter == null) return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  Future<void> _openSupport(CustomerOrder order) async {
    final replyCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Support — #${order.id}'),
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
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reply sent for #${order.id} (mock)'),
                  ),
                );
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
            child: Container(
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
                          .map((i) => '${i.productName} ×${i.quantity}')
                          .join(', ');
                      return DataRow(
                        cells: [
                          DataCell(Text('#${order.id}')),
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
                              formatRwf(order.grandTotalRwf, suffix: true),
                            ),
                          ),
                          DataCell(
                            DropdownButton<OrderStatus>(
                              value: order.status,
                              underline: const SizedBox.shrink(),
                              items: OrderStatus.values
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (status) {
                                if (status == null) return;
                                setState(() {
                                  final i = _orders.indexWhere(
                                    (o) => o.id == order.id,
                                  );
                                  if (i < 0) return;
                                  final old = _orders[i];
                                  _orders[i] = CustomerOrder(
                                    id: old.id,
                                    guestName: old.guestName,
                                    phone: old.phone,
                                    district: old.district,
                                    sector: old.sector,
                                    landmark: old.landmark,
                                    items: old.items,
                                    deliveryFeeRwf: old.deliveryFeeRwf,
                                    status: status,
                                    createdAt: old.createdAt,
                                    paymentMethod: old.paymentMethod,
                                    supportTicket: old.supportTicket,
                                  );
                                });
                              },
                            ),
                          ),
                          DataCell(
                            IconButton(
                              tooltip: 'Resolve issue',
                              onPressed: () => _openSupport(order),
                              icon: Icon(
                                Icons.support_agent,
                                color: order.status == OrderStatus.issueReported
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

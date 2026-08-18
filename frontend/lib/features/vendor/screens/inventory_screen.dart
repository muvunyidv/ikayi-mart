import 'package:flutter/material.dart';

import '../../../core/mock_data/products_mock.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _query = '';
  String _category = 'All';
  late List<_InventoryRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = ProductsMock.products
        .map(
          (p) => _InventoryRow(product: p, active: p.isActive),
        )
        .toList();
  }

  List<_InventoryRow> get _filtered {
    return _rows.where((row) {
      final matchesCat =
          _category == 'All' || row.product.category == _category;
      final q = _query.toLowerCase();
      final matchesQuery = q.isEmpty ||
          row.product.name.toLowerCase().contains(q) ||
          row.product.id.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();
  }

  Future<void> _showEditor({_InventoryRow? existing}) async {
    final nameCtrl =
        TextEditingController(text: existing?.product.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing?.product.priceRwf.toString() ?? '',
    );
    final stockCtrl = TextEditingController(
      text: existing?.product.stock.toString() ?? '10',
    );
    var category = existing?.product.category ?? 'Electronics';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              title: Text(existing == null ? 'Add New Product' : 'Edit Product'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Price (RWF)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ProductsMock.categories
                          .where((c) => c != 'All')
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModal(() => category = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    final price = int.tryParse(priceCtrl.text) ?? 0;
    final stock = int.tryParse(stockCtrl.text) ?? 0;
    setState(() {
      if (existing == null) {
        final product = Product(
          id: 'p-${DateTime.now().millisecondsSinceEpoch}',
          name: nameCtrl.text.trim().isEmpty ? 'New Product' : nameCtrl.text,
          category: category,
          priceRwf: price,
          imageUrl:
              'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
          vendorName: 'Kigali Tech Store',
          description: 'Newly added product (mock).',
          stock: stock,
        );
        _rows.insert(0, _InventoryRow(product: product, active: true));
      } else {
        final idx = _rows.indexOf(existing);
        _rows[idx] = _InventoryRow(
          product: Product(
            id: existing.product.id,
            name: nameCtrl.text,
            category: category,
            priceRwf: price,
            imageUrl: existing.product.imageUrl,
            vendorName: existing.product.vendorName,
            description: existing.product.description,
            stock: stock,
            badge: existing.product.badge,
            originLabel: existing.product.originLabel,
            gallery: existing.product.gallery,
            variants: existing.product.variants,
            isActive: existing.active,
          ),
          active: existing.active,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inventory Management',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search products / SKU',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ProductsMock.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showEditor(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.add),
                label: const Text('+ Add New Product'),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, color: AppColors.success, size: 18),
                    SizedBox(width: 8),
                    Text('Sync BMS SKU — Connected'),
                  ],
                ),
              ),
            ],
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.sizeOf(context).width - 48,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.surfaceLow,
                    ),
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Active')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: rows.map((row) {
                      final p = row.product;
                      final stockLabel = !p.inStock
                          ? 'Out'
                          : p.isLowStock
                              ? 'Low Stock'
                              : 'In Stock';
                      final stockColor = !p.inStock
                          ? AppColors.error
                          : p.isLowStock
                              ? AppColors.primaryDeep
                              : AppColors.success;
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    p.imageUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: ColoredBox(
                                        color: AppColors.surfaceHigh,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(formatRwf(p.priceRwf, suffix: true))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: stockColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$stockLabel (${p.stock})',
                                style: TextStyle(
                                  color: stockColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Switch(
                              value: row.active,
                              onChanged: (v) {
                                setState(() {
                                  final i = _rows.indexOf(row);
                                  _rows[i] = _InventoryRow(
                                    product: p,
                                    active: v,
                                  );
                                });
                              },
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _showEditor(existing: row),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () {
                                    setState(() => _rows.remove(row));
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
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

class _InventoryRow {
  _InventoryRow({required this.product, required this.active});

  final Product product;
  final bool active;
}

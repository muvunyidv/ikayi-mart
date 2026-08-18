import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/api/ikayi_api.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../../../state/catalog_state.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _query = '';
  String _category = 'All';
  List<_InventoryRow> _rows = [];
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
      final products = await _api.listMyProducts();
      if (!mounted) return;
      setState(() {
        _rows = products
            .map((p) => _InventoryRow(product: p, active: p.isActive))
            .toList();
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
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProductEditorDialog(existing: existing?.product),
    );
    if (saved != true || !mounted) return;
    await context.read<CatalogState>().load();
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _toggleActive(_InventoryRow row, bool active) async {
    try {
      await _api.toggleProductStatus(row.product.id, active);
      if (!mounted) return;
      await context.read<CatalogState>().load();
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _delete(_InventoryRow row) async {
    try {
      await _api.deleteProduct(row.product.id);
      if (!mounted) return;
      await context.read<CatalogState>().load();
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
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
                  items: kCatalogCategories
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
            ],
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
                    : rows.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No products in your catalog yet.\nAdd one with a photo to show it on the shopper storefront.',
                            textAlign: TextAlign.center,
                          ),
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
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                    DataCell(
                                      Text(formatRwf(p.priceRwf, suffix: true)),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: stockColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                                        onChanged: (v) => _toggleActive(row, v),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit',
                                            onPressed: () =>
                                                _showEditor(existing: row),
                                            icon: const Icon(Icons.edit_outlined),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            onPressed: () => _delete(row),
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

class _ProductEditorDialog extends StatefulWidget {
  const _ProductEditorDialog({this.existing});

  final Product? existing;

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

const int _kMaxProductImages = 12;

class _ProductImageDraft {
  const _ProductImageDraft.remote(this.url)
      : bytes = null,
        filename = 'product.jpg';

  const _ProductImageDraft.local({
    required this.bytes,
    required this.filename,
  }) : url = null;

  final Uint8List? bytes;
  final String? url;
  final String filename;
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _descriptionCtrl;
  late String _category;
  late List<_ProductImageDraft> _images;
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _priceCtrl = TextEditingController(
      text: existing?.priceRwf.toString() ?? '',
    );
    _stockCtrl = TextEditingController(
      text: existing?.stock.toString() ?? '10',
    );
    _descriptionCtrl = TextEditingController(text: existing?.description ?? '');
    final cat = existing?.category ?? 'Electronics';
    _category = kCatalogCategories.contains(cat) && cat != 'All'
        ? cat
        : 'Electronics';
    _images = [
      if (existing != null) ...[
        _ProductImageDraft.remote(existing.imageUrl),
        ...existing.gallery
            .where((url) => url.isNotEmpty && url != existing.imageUrl)
            .map(_ProductImageDraft.remote),
      ],
    ];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _kMaxProductImages - _images.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
      limit: remaining,
    );
    if (picked.isEmpty) return;

    final drafts = <_ProductImageDraft>[];
    for (final file in picked) {
      if (_images.length + drafts.length >= _kMaxProductImages) break;
      final bytes = await file.readAsBytes();
      var filename = file.name.trim();
      if (filename.isEmpty) filename = 'product.jpg';
      if (!filename.contains('.')) filename = '$filename.jpg';
      drafts.add(_ProductImageDraft.local(bytes: bytes, filename: filename));
    }
    if (!mounted || drafts.isEmpty) return;
    setState(() {
      _images = [..._images, ...drafts];
      _error = null;
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images = [..._images]..removeAt(index);
    });
  }

  void _setCover(int index) {
    if (index <= 0 || index >= _images.length) return;
    setState(() {
      final next = [..._images];
      final cover = next.removeAt(index);
      next.insert(0, cover);
      _images = next;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim());
    final stock = int.tryParse(_stockCtrl.text.trim());

    if (name.length < 2) {
      setState(() => _error = 'Enter a product name (at least 2 characters).');
      return;
    }
    if (description.length < 8) {
      setState(() => _error = 'Description must be at least 8 characters.');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Enter a valid price in RWF (whole numbers).');
      return;
    }
    if (stock == null || stock < 0) {
      setState(() => _error = 'Enter a valid stock quantity.');
      return;
    }
    if (_images.isEmpty) {
      setState(() => _error = 'Add at least one product photo before saving.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = context.read<IkayiApi>();
      final urls = <String>[];
      for (final image in _images) {
        if (image.url != null) {
          urls.add(image.url!);
          continue;
        }
        urls.add(
          await api.uploadProductImage(
            bytes: image.bytes!,
            filename: image.filename,
          ),
        );
      }

      final imageUrl = urls.first;
      final gallery = urls.skip(1).toList();

      if (_isNew) {
        await api.createProduct(
          name: name,
          category: _category,
          priceRwf: price,
          stock: stock,
          imageUrl: imageUrl,
          description: description,
          gallery: gallery,
        );
      } else {
        await api.updateProduct(
          widget.existing!.id,
          name: name,
          category: _category,
          priceRwf: price,
          stock: stock,
          description: description,
          imageUrl: imageUrl,
          gallery: gallery,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNew ? 'Add New Product' : 'Edit Product'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Product photos',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Add up to $_kMaxProductImages photos. The first one is the cover image shoppers see first.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _images.length; i++)
                    _ProductPhotoTile(
                      image: _images[i],
                      isCover: i == 0,
                      enabled: !_saving,
                      onRemove: () => _removeImage(i),
                      onSetCover: i == 0 ? null : () => _setCover(i),
                    ),
                  if (_images.length < _kMaxProductImages)
                    _AddPhotoTile(
                      onTap: _saving ? null : _pickImages,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_images.length}/$_kMaxProductImages photos',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _saving || _images.length >= _kMaxProductImages
                    ? null
                    : _pickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _images.isEmpty ? 'Choose product photos' : 'Add more photos',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceCtrl,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (RWF)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stockCtrl,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: kCatalogCategories
                    .where((c) => c != 'All')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v != null) setState(() => _category = v);
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionCtrl,
                enabled: !_saving,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  hintText: 'What should buyers know about this product?',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 44),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _ProductPhotoTile extends StatelessWidget {
  const _ProductPhotoTile({
    required this.image,
    required this.isCover,
    required this.enabled,
    required this.onRemove,
    this.onSetCover,
  });

  final _ProductImageDraft image;
  final bool isCover;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback? onSetCover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: enabled ? onSetCover : null,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCover
                          ? AppColors.primaryOrange
                          : AppColors.borderSubtle,
                      width: isCover ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: image.bytes != null
                        ? Image.memory(image.bytes!, fit: BoxFit.cover)
                        : Image.network(
                            image.url!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: AppColors.surfaceHigh,
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (isCover)
            const Positioned(
              left: 6,
              bottom: 6,
              child: _CoverBadge(),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enabled ? onRemove : null,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Cover',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Material(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 28),
                SizedBox(height: 4),
                Text(
                  'Add photos',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

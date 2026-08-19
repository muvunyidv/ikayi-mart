import 'package:flutter/foundation.dart';

import '../core/api/ikayi_api.dart';
import '../core/models/models.dart';

class CatalogState extends ChangeNotifier {
  CatalogState(this._api);

  final IkayiApi _api;

  List<Product> products = const [];
  bool loading = false;
  String? error;

  Product? byId(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Product> byCategory(String category) {
    if (category == 'All') return products;
    return products.where((p) => p.category == category).toList();
  }

  /// Static catalog categories plus any extra values returned by the API.
  List<String> get categoryOptions {
    final extras = products
        .map((p) => p.category)
        .where((c) => c.isNotEmpty && !kCatalogCategories.contains(c))
        .toSet()
        .toList()
      ..sort();
    return [...kCatalogCategories, ...extras];
  }

  /// In-stock products from the same vendor, excluding [product].
  List<Product> moreFromVendor(Product product) {
    return products
        .where(
          (p) =>
              p.vendorName == product.vendorName &&
              p.id != product.id &&
              p.inStock,
        )
        .toList();
  }

  /// Recommended pool: same category first, then the rest of the catalog.
  List<Product> recommendedFor(Product product) {
    final sameCategory = byCategory(
      product.category,
    ).where((p) => p.id != product.id).toList();
    final rest = products
        .where((p) => p.id != product.id && p.category != product.category)
        .toList();
    return [...sameCategory, ...rest];
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await _api.listProducts(limit: 100);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

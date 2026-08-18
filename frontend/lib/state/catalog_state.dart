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

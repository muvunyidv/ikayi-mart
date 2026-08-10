import 'package:flutter/foundation.dart';

import '../core/models/models.dart';

/// Reactive cart for the guest shopper flow.
class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];

  static const int deliveryFeeRwf = 2000;

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  int get subtotalRwf => _items.fold(0, (sum, i) => sum + i.lineTotal);

  int get grandTotalRwf =>
      _items.isEmpty ? 0 : subtotalRwf + deliveryFeeRwf;

  bool get isEmpty => _items.isEmpty;

  void addProduct(
    Product product, {
    int quantity = 1,
    Map<String, String> selectedVariants = const {},
  }) {
    final index = _items.indexWhere(
      (i) =>
          i.product.id == product.id &&
          mapEquals(i.selectedVariants, selectedVariants),
    );

    if (index >= 0) {
      final existing = _items[index];
      _items[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: quantity,
          selectedVariants: selectedVariants,
        ),
      );
    }
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= _items.length) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

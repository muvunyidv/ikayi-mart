import 'package:flutter/foundation.dart';

import '../core/models/models.dart';

class _PromoOffer {
  const _PromoOffer({this.percent = 0, this.fixedRwf = 0, this.freeDelivery = false});

  final int percent;
  final int fixedRwf;
  final bool freeDelivery;
}

const _kPromoOffers = <String, _PromoOffer>{
  'IKAYI10': _PromoOffer(percent: 10),
  'WELCOME': _PromoOffer(fixedRwf: 2000),
  'FREESHIP': _PromoOffer(freeDelivery: true),
};

/// Reactive cart for the guest shopper flow.
class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _promoCode;
  String? _promoError;
  int _discountRwf = 0;
  bool _freeDelivery = false;

  static const int standardDeliveryFeeRwf = 2000;

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  int get subtotalRwf => _items.fold(0, (sum, i) => sum + i.lineTotal);

  int get deliveryFeeRwf =>
      _items.isEmpty ? 0 : (_freeDelivery ? 0 : standardDeliveryFeeRwf);

  int get discountRwf => _items.isEmpty ? 0 : _discountRwf;

  String? get promoCode => _promoCode;

  String? get promoError => _promoError;

  int get grandTotalRwf {
    if (_items.isEmpty) return 0;
    final total = subtotalRwf + deliveryFeeRwf - discountRwf;
    return total < 0 ? 0 : total;
  }

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
    _recomputePromo();
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= _items.length) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
    _recomputePromo();
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    _recomputePromo();
    notifyListeners();
  }

  bool applyPromoCode(String code) {
    final normalized = code.trim().toUpperCase();
    final offer = _kPromoOffers[normalized];
    if (offer == null) {
      _promoCode = null;
      _promoError = 'Invalid promo code';
      _discountRwf = 0;
      _freeDelivery = false;
      notifyListeners();
      return false;
    }
    _promoCode = normalized;
    _promoError = null;
    _applyOffer(offer);
    notifyListeners();
    return true;
  }

  void clearPromo() {
    _promoCode = null;
    _promoError = null;
    _discountRwf = 0;
    _freeDelivery = false;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _promoCode = null;
    _promoError = null;
    _discountRwf = 0;
    _freeDelivery = false;
    notifyListeners();
  }

  void _recomputePromo() {
    if (_promoCode == null) {
      _discountRwf = 0;
      _freeDelivery = false;
      return;
    }
    final offer = _kPromoOffers[_promoCode];
    if (offer == null) {
      _promoCode = null;
      _discountRwf = 0;
      _freeDelivery = false;
      return;
    }
    _applyOffer(offer);
  }

  void _applyOffer(_PromoOffer offer) {
    _freeDelivery = offer.freeDelivery;
    var discount = 0;
    if (offer.percent > 0) {
      discount += (subtotalRwf * offer.percent / 100).round();
    }
    discount += offer.fixedRwf;
    if (discount > subtotalRwf) discount = subtotalRwf;
    _discountRwf = discount;
  }
}

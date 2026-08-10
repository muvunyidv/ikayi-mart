class ProductVariant {
  const ProductVariant({
    required this.name,
    required this.options,
  });

  final String name;
  final List<String> options;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.priceRwf,
    required this.imageUrl,
    required this.vendorName,
    required this.description,
    required this.stock,
    this.badge,
    this.originLabel,
    this.gallery = const [],
    this.variants = const [],
    this.isActive = true,
    this.deliveryNote =
        'Fast Kigali delivery — most orders arrive within 60 minutes in Gasabo, Kicukiro & Nyarugenge.',
    this.warrantyNote =
        'Seller-backed warranty. Chat support available for returns & exchanges.',
  });

  final String id;
  final String name;
  final String category;
  final int priceRwf;
  final String imageUrl;
  final String vendorName;
  final String description;
  final int stock;
  final String? badge;
  final String? originLabel;
  final List<String> gallery;
  final List<ProductVariant> variants;
  final bool isActive;
  final String deliveryNote;
  final String warrantyNote;

  bool get isLowStock => stock > 0 && stock <= 5;
  bool get inStock => stock > 0;

  List<String> get allImages =>
      gallery.isEmpty ? [imageUrl] : [imageUrl, ...gallery];
}

class CartItem {
  const CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedVariants = const {},
  });

  final Product product;
  final int quantity;
  final Map<String, String> selectedVariants;

  int get lineTotal => product.priceRwf * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    Map<String, String>? selectedVariants,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedVariants: selectedVariants ?? this.selectedVariants,
    );
  }
}

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  issueReported,
}

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.processing => 'Processing',
        OrderStatus.shipped => 'Shipped',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.issueReported => 'Issue Reported',
      };
}

class OrderLineItem {
  const OrderLineItem({
    required this.productName,
    required this.quantity,
    required this.unitPriceRwf,
  });

  final String productName;
  final int quantity;
  final int unitPriceRwf;

  int get totalRwf => unitPriceRwf * quantity;
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.guestName,
    required this.phone,
    required this.district,
    required this.sector,
    required this.landmark,
    required this.items,
    required this.deliveryFeeRwf,
    required this.status,
    required this.createdAt,
    this.paymentMethod = 'MTN MoMo',
    this.supportTicket,
  });

  final String id;
  final String guestName;
  final String phone;
  final String district;
  final String sector;
  final String landmark;
  final List<OrderLineItem> items;
  final int deliveryFeeRwf;
  final OrderStatus status;
  final DateTime createdAt;
  final String paymentMethod;
  final String? supportTicket;

  int get itemsTotalRwf =>
      items.fold(0, (sum, item) => sum + item.totalRwf);

  int get grandTotalRwf => itemsTotalRwf + deliveryFeeRwf;

  String get locationLabel => '$sector, $district';
}

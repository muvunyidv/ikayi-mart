class ProductVariant {
  const ProductVariant({required this.name, required this.options});

  final String name;
  final List<String> options;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      name: json['name'] as String,
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
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

  /// Live search match against name, category, description, and vendor.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        vendorName.toLowerCase().contains(q);
  }

  List<String> get allImages =>
      gallery.isEmpty ? [imageUrl] : [imageUrl, ...gallery];

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      priceRwf: (json['priceRwf'] as num).toInt(),
      imageUrl: json['imageUrl'] as String,
      vendorName: json['vendorName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      badge: json['badge'] as String?,
      originLabel: json['originLabel'] as String?,
      gallery: (json['gallery'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      variants: (json['variants'] as List<dynamic>? ?? const [])
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      deliveryNote:
          json['deliveryNote'] as String? ??
          'Fast Kigali delivery — most orders arrive within 60 minutes in Gasabo, Kicukiro & Nyarugenge.',
      warrantyNote:
          json['warrantyNote'] as String? ??
          'Seller-backed warranty. Chat support available for returns & exchanges.',
    );
  }
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
  cancelled,
}

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.processing => 'Processing',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.issueReported => 'Issue Reported',
    OrderStatus.cancelled => 'Cancelled',
  };

  String get apiValue => switch (this) {
    OrderStatus.pending => 'PENDING',
    OrderStatus.processing => 'PROCESSING',
    OrderStatus.shipped => 'SHIPPED',
    OrderStatus.delivered => 'DELIVERED',
    OrderStatus.issueReported => 'ISSUE_REPORTED',
    OrderStatus.cancelled => 'CANCELLED',
  };

  static OrderStatus fromApi(String? value) {
    return switch (value) {
      'PROCESSING' => OrderStatus.processing,
      'SHIPPED' => OrderStatus.shipped,
      'DELIVERED' => OrderStatus.delivered,
      'ISSUE_REPORTED' => OrderStatus.issueReported,
      'CANCELLED' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }
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

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      productName: json['productName'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPriceRwf: (json['unitPriceRwf'] as num?)?.toInt() ?? 0,
    );
  }
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    this.trackingCode = '',
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
    this.supportTicketId,
    this.totalAmountRwf,
  });

  final String id;
  final String trackingCode;
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
  final String? supportTicketId;
  final int? totalAmountRwf;

  int get itemsTotalRwf => items.fold(0, (sum, item) => sum + item.totalRwf);

  int get grandTotalRwf => totalAmountRwf ?? itemsTotalRwf + deliveryFeeRwf;

  String get displayCode => trackingCode.isNotEmpty ? trackingCode : id;

  String get locationLabel => '$sector, $district';

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final ticket = json['supportTicket'];
    String? ticketIssue;
    String? ticketId;
    if (ticket is Map<String, dynamic>) {
      ticketIssue = ticket['issue'] as String?;
      ticketId = ticket['id'] as String?;
    } else if (ticket is String) {
      ticketIssue = ticket;
    }

    return CustomerOrder(
      id: json['id'] as String,
      trackingCode: json['trackingCode'] as String? ?? json['id'] as String,
      guestName: json['guestName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      district: json['district'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => OrderLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryFeeRwf: (json['deliveryFeeRwf'] as num?)?.toInt() ?? 2000,
      status: OrderStatusLabel.fromApi(json['status'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      paymentMethod: _paymentLabel(json['paymentMethod'] as String?),
      supportTicket: ticketIssue,
      supportTicketId: ticketId,
      totalAmountRwf: (json['totalAmountRwf'] as num?)?.toInt(),
    );
  }
}

String _paymentLabel(String? method) {
  return switch (method) {
    'MTN_MOMO' || 'MTN MoMo' => 'MTN MoMo',
    'AIRTEL_MONEY' || 'Airtel Money' => 'Airtel Money',
    'VISA_CARD' || 'Visa / Card' => 'Visa / Card',
    _ => method ?? 'MTN MoMo',
  };
}

class VendorUser {
  const VendorUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.vendorId,
    this.storeName,
    this.isVerified,
    this.isOnline,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? vendorId;
  final String? storeName;
  final bool? isVerified;
  final bool? isOnline;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    final n = name.trim();
    return n.isEmpty
        ? 'V'
        : n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get storeInitials {
    final n = (storeName ?? name).trim();
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return n.isEmpty
        ? 'VS'
        : n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  factory VendorUser.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'];
    return VendorUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'VENDOR',
      vendorId:
          json['vendorId'] as String? ??
          (vendor is Map<String, dynamic> ? vendor['id'] as String? : null),
      storeName:
          json['storeName'] as String? ??
          (vendor is Map<String, dynamic>
              ? vendor['storeName'] as String?
              : null),
      isVerified:
          json['isVerified'] as bool? ??
          (vendor is Map<String, dynamic>
              ? vendor['isVerified'] as bool?
              : null),
      isOnline:
          json['isOnline'] as bool? ??
          (vendor is Map<String, dynamic> ? vendor['isOnline'] as bool? : null),
    );
  }
}

class VendorKpis {
  const VendorKpis({
    required this.todayRevenueRwf,
    required this.pendingOrders,
    required this.lowStockItems,
    required this.completedOrders,
  });

  final int todayRevenueRwf;
  final int pendingOrders;
  final int lowStockItems;
  final int completedOrders;

  factory VendorKpis.fromJson(Map<String, dynamic> json) {
    return VendorKpis(
      todayRevenueRwf: (json['todayRevenueRwf'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      lowStockItems: (json['lowStockItems'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completedOrders'] as num?)?.toInt() ?? 0,
    );
  }
}

class VendorChart {
  const VendorChart({required this.values, required this.labels});

  final List<int> values;
  final List<String> labels;

  factory VendorChart.fromJson(Map<String, dynamic> json) {
    return VendorChart(
      values: (json['values'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      labels: (json['labels'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class GuestCheckoutResult {
  const GuestCheckoutResult({
    required this.trackingCode,
    required this.orderId,
    required this.totalAmountRwf,
    required this.phone,
    required this.paymentMethod,
  });

  final String trackingCode;
  final String orderId;
  final int totalAmountRwf;
  final String phone;
  final String paymentMethod;
}

const kCatalogCategories = <String>[
  'All',
  'Electronics',
  'Apparel',
  'Home',
  'Beauty',
  'Fresh Produce',
];

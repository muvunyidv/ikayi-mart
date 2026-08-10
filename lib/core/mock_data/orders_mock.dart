import '../models/models.dart';

/// Mock customer orders for the vendor dashboard.
abstract final class OrdersMock {
  static final List<CustomerOrder> orders = [
    CustomerOrder(
      id: 'IKY-9842',
      guestName: 'Aline Uwase',
      phone: '+250 788 123 456',
      district: 'Gasabo',
      sector: 'Remera',
      landmark: 'Near MTN Centre, Chez Lando road',
      deliveryFeeRwf: 2000,
      status: OrderStatus.pending,
      paymentMethod: 'MTN MoMo',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      items: const [
        OrderLineItem(
          productName: 'Core-Link Pro Smartwatch',
          quantity: 1,
          unitPriceRwf: 89000,
        ),
      ],
    ),
    CustomerOrder(
      id: 'IKY-9838',
      guestName: 'Eric Niyonsenga',
      phone: '+250 72 555 019',
      district: 'Nyarugenge',
      sector: 'Nyamirambo',
      landmark: 'Opposite Nyamirambo Adventist Church',
      deliveryFeeRwf: 2500,
      status: OrderStatus.processing,
      paymentMethod: 'Airtel Money',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      items: const [
        OrderLineItem(
          productName: 'Urban Canvas Comfort Sneakers',
          quantity: 1,
          unitPriceRwf: 55000,
        ),
        OrderLineItem(
          productName: 'Organic Wildflower Honey 500g',
          quantity: 2,
          unitPriceRwf: 7800,
        ),
      ],
    ),
    CustomerOrder(
      id: 'IKY-9823',
      guestName: 'Diane Mukamana',
      phone: '+250 78 901 234',
      district: 'Kicukiro',
      sector: 'Gatenga',
      landmark: 'KK 15 Ave, blue gate',
      deliveryFeeRwf: 2000,
      status: OrderStatus.shipped,
      paymentMethod: 'Visa / Card',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      items: const [
        OrderLineItem(
          productName: 'Artisan Ceramic Coffee Set',
          quantity: 1,
          unitPriceRwf: 32500,
        ),
      ],
    ),
    CustomerOrder(
      id: 'IKY-9811',
      guestName: 'Jean Paul K.',
      phone: '+250 73 222 110',
      district: 'Gasabo',
      sector: 'Kimironko',
      landmark: 'Kimironko Market parking',
      deliveryFeeRwf: 1500,
      status: OrderStatus.delivered,
      paymentMethod: 'MTN MoMo',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      items: const [
        OrderLineItem(
          productName: 'Gorilla Mountain Arabica Coffee',
          quantity: 3,
          unitPriceRwf: 12500,
        ),
        OrderLineItem(
          productName: 'Pro Sound Wireless Headphones',
          quantity: 1,
          unitPriceRwf: 45000,
        ),
      ],
    ),
    CustomerOrder(
      id: 'IKY-9805',
      guestName: 'Clarisse Ingabire',
      phone: '+250 78 444 778',
      district: 'Gasabo',
      sector: 'Kacyiru',
      landmark: 'Near Ministry of Finance',
      deliveryFeeRwf: 2000,
      status: OrderStatus.issueReported,
      paymentMethod: 'MTN MoMo',
      supportTicket: 'Guest reports missing charger cable in case bundle.',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 10)),
      items: const [
        OrderLineItem(
          productName: 'iPhone 15 Pro Max Case Bundle',
          quantity: 1,
          unitPriceRwf: 35000,
        ),
      ],
    ),
    CustomerOrder(
      id: 'IKY-9798',
      guestName: 'Patrick Habimana',
      phone: '+250 72 333 901',
      district: 'Kicukiro',
      sector: 'Niboye',
      landmark: 'Apartment B3, first floor',
      deliveryFeeRwf: 2000,
      status: OrderStatus.pending,
      paymentMethod: 'Airtel Money',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      items: const [
        OrderLineItem(
          productName: 'SoundMaster Portable Speaker',
          quantity: 1,
          unitPriceRwf: 67500,
        ),
      ],
    ),
    CustomerOrder(
      id: 'IKY-9780',
      guestName: 'Grace Iradukunda',
      phone: '+250 78 112 009',
      district: 'Nyarugenge',
      sector: 'Muhima',
      landmark: 'UTC building, reception desk',
      deliveryFeeRwf: 1500,
      status: OrderStatus.delivered,
      paymentMethod: 'Visa / Card',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      items: const [
        OrderLineItem(
          productName: 'Radiance Vitamin C Serum',
          quantity: 2,
          unitPriceRwf: 18500,
        ),
        OrderLineItem(
          productName: 'Kitenge Midi Wrap Dress',
          quantity: 1,
          unitPriceRwf: 42000,
        ),
      ],
    ),
    CustomerOrder(
      id: 'IKY-9772',
      guestName: 'Samuel Bizimana',
      phone: '+250 73 880 441',
      district: 'Gasabo',
      sector: 'Remera',
      landmark: 'Amahoro Stadium gate A',
      deliveryFeeRwf: 2000,
      status: OrderStatus.processing,
      paymentMethod: 'MTN MoMo',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      items: const [
        OrderLineItem(
          productName: 'Agaseke Peace Basket',
          quantity: 1,
          unitPriceRwf: 28000,
        ),
        OrderLineItem(
          productName: 'Rwandan Green Tea Sampler',
          quantity: 1,
          unitPriceRwf: 9500,
        ),
      ],
    ),
  ];

  /// Mock weekly revenue points (RWF) for vendor chart scaffolding.
  static const List<int> weeklyRevenueRwf = [
    820000,
    1100000,
    950000,
    1400000,
    1250000,
    1680000,
    1520000,
  ];

  static const List<String> weekLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static int get todayRevenueRwf => weeklyRevenueRwf.last;

  static int get pendingCount =>
      orders.where((o) => o.status == OrderStatus.pending).length;

  static int get completedCount =>
      orders.where((o) => o.status == OrderStatus.delivered).length;

  static List<CustomerOrder> byStatus(OrderStatus? status) {
    if (status == null) return orders;
    return orders.where((o) => o.status == status).toList();
  }
}

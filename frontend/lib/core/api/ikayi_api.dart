import '../models/models.dart';
import 'api_client.dart';
import 'api_exception.dart';

class IkayiApi {
  IkayiApi({ApiClient? client}) : client = client ?? ApiClient();

  final ApiClient client;

  void setToken(String? token) => client.token = token;

  Future<List<Product>> listProducts({
    String? category,
    String? search,
    int limit = 100,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (category != null && category.isNotEmpty && category != 'All')
        'category': category,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final data = await client.get('/products', query: query) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? const [];
    return items
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProduct(String idOrSlug) async {
    final data = await client.get('/products/$idOrSlug') as Map<String, dynamic>;
    return Product.fromJson(data);
  }

  Future<List<Product>> listMyProducts() async {
    final data = await client.get('/products/mine') as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? const [];
    return items
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> uploadProductImage({
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await client.postMultipart(
      '/products/upload',
      bytes: bytes,
      filename: filename,
    ) as Map<String, dynamic>;
    final url = data['imageUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw const ApiException('Image upload did not return a URL');
    }
    return url;
  }

  Future<Product> createProduct({
    required String name,
    required String category,
    required int priceRwf,
    required int stock,
    required String imageUrl,
    required String description,
    List<String> gallery = const [],
  }) async {
    final data = await client.post('/products', body: {
      'name': name,
      'category': category,
      'priceRwf': priceRwf,
      'stock': stock,
      'imageUrl': imageUrl,
      'description': description,
      'gallery': gallery,
    }) as Map<String, dynamic>;
    return Product.fromJson(data);
  }

  Future<Product> updateProduct(
    String id, {
    String? name,
    String? category,
    int? priceRwf,
    int? stock,
    String? description,
    String? imageUrl,
    List<String>? gallery,
  }) async {
    final data = await client.put('/products/$id', body: {
      'name': ?name,
      'category': ?category,
      'priceRwf': ?priceRwf,
      'stock': ?stock,
      'description': ?description,
      'imageUrl': ?imageUrl,
      'gallery': ?gallery,
    }) as Map<String, dynamic>;
    return Product.fromJson(data);
  }

  Future<Product> toggleProductStatus(String id, bool isActive) async {
    final data = await client.patch(
      '/products/$id/status',
      body: {'isActive': isActive},
    ) as Map<String, dynamic>;
    return Product.fromJson(data);
  }

  Future<void> deleteProduct(String id) async {
    await client.delete('/products/$id');
  }

  Future<({VendorUser user, String accessToken})> login({
    required String email,
    required String password,
  }) async {
    final data = await client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _authResult(data);
  }

  Future<({VendorUser user, String accessToken})> registerVendor({
    required String email,
    required String password,
    required String name,
    required String storeName,
  }) async {
    final data = await client.post('/auth/register-vendor', body: {
      'email': email,
      'password': password,
      'name': name,
      'storeName': storeName,
    });
    return _authResult(data);
  }

  ({VendorUser user, String accessToken}) _authResult(dynamic data) {
    final map = data as Map<String, dynamic>;
    return (
      user: VendorUser.fromJson(map['user'] as Map<String, dynamic>),
      accessToken: map['accessToken'] as String,
    );
  }

  Future<VendorUser> me() async {
    final data = await client.get('/auth/me') as Map<String, dynamic>;
    return VendorUser.fromJson(data);
  }

  Future<GuestCheckoutResult> guestCheckout({
    required String guestName,
    required String phone,
    required String district,
    required String sector,
    required String landmark,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await client.post('/orders/guest-checkout', body: {
      'guestName': guestName,
      'phone': phone,
      'district': district,
      'sector': sector,
      'landmark': landmark,
      'paymentMethod': paymentMethod,
      'items': items,
    }) as Map<String, dynamic>;
    return GuestCheckoutResult(
      trackingCode: data['trackingCode'] as String,
      orderId: data['orderId'] as String,
      totalAmountRwf: (data['totalAmountRwf'] as num).toInt(),
      phone: data['phone'] as String? ?? phone,
      paymentMethod: data['paymentMethod'] as String? ?? paymentMethod,
    );
  }

  Future<void> initiatePayment({
    required String trackingCode,
    required String phone,
    required String method,
  }) async {
    await client.post('/payments/initiate', body: {
      'trackingCode': trackingCode,
      'phone': phone,
      'method': method,
    });
  }

  Future<CustomerOrder> trackOrder(String code) async {
    final cleaned = code.replaceFirst('#', '').trim();
    final data =
        await client.get('/orders/track/$cleaned') as Map<String, dynamic>;
    return CustomerOrder.fromJson(data);
  }

  Future<List<CustomerOrder>> vendorOrders({OrderStatus? status}) async {
    final data = await client.get(
      '/orders/vendor',
      query: status == null ? null : {'status': status.apiValue},
    );
    final list = data as List<dynamic>;
    return list
        .map((e) => CustomerOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerOrder> updateOrderStatus(String id, OrderStatus status) async {
    final data = await client.patch(
      '/orders/$id/status',
      body: {'status': status.apiValue},
    ) as Map<String, dynamic>;
    return CustomerOrder.fromJson(data);
  }

  Future<void> replyToTicket({
    required String ticketId,
    required String resolution,
  }) async {
    await client.post('/support/reply', body: {
      'ticketId': ticketId,
      'resolution': resolution,
    });
  }

  Future<VendorKpis> vendorKpis() async {
    final data =
        await client.get('/vendor/dashboard/kpis') as Map<String, dynamic>;
    return VendorKpis.fromJson(data);
  }

  Future<VendorChart> vendorChart() async {
    final data =
        await client.get('/vendor/dashboard/chart') as Map<String, dynamic>;
    return VendorChart.fromJson(data);
  }
}

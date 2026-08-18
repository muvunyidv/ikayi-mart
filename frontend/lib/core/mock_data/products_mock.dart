import '../models/models.dart';

/// Realistic Rwanda marketplace catalog (prices in RWF).
abstract final class ProductsMock {
  static const categories = <String>[
    'All',
    'Electronics',
    'Apparel',
    'Home',
    'Beauty',
    'Fresh Produce',
  ];

  static const List<Product> products = [
    Product(
      id: 'p-headphones',
      name: 'Pro Sound Wireless Headphones',
      category: 'Electronics',
      priceRwf: 45000,
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
      gallery: [
        'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=800&q=80',
        'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=800&q=80',
      ],
      vendorName: 'Kigali Tech Store',
      originLabel: 'AUDIO',
      badge: 'HOT SELLER',
      stock: 24,
      description:
          'Over-ear wireless headphones with 40mm drivers, 30-hour battery life, and a foldable design built for Kigali commutes.',
      variants: [
        ProductVariant(name: 'Color', options: ['Black', 'White', 'Navy']),
      ],
    ),
    Product(
      id: 'p-ceramic-set',
      name: 'Artisan Ceramic Coffee Set',
      category: 'Home',
      priceRwf: 32500,
      imageUrl:
          'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=800&q=80',
      gallery: [
        'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80',
      ],
      vendorName: 'Nyamirambo Crafts',
      originLabel: 'ARTISANAL DECOR',
      badge: 'FRESH ARRIVAL',
      stock: 12,
      description:
          'Hand-finished ceramic cups and carafe for four. Perfect for morning coffee or hosting guests in Remera.',
      variants: [
        ProductVariant(name: 'Set Size', options: ['2 pcs', '4 pcs', '6 pcs']),
      ],
    ),
    Product(
      id: 'p-sneakers',
      name: 'Urban Canvas Comfort Sneakers',
      category: 'Apparel',
      priceRwf: 55000,
      imageUrl:
          'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=800&q=80',
      gallery: [
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
      ],
      vendorName: 'Kigali Streetwear',
      originLabel: 'FOOTWEAR',
      stock: 18,
      description:
          'Breathable canvas sneakers with cushioned soles. Everyday comfort for city walking and weekend markets.',
      variants: [
        ProductVariant(
          name: 'Size',
          options: ['39', '40', '41', '42', '43', '44'],
        ),
        ProductVariant(name: 'Color', options: ['White', 'Black', 'Olive']),
      ],
    ),
    Product(
      id: 'p-smartwatch',
      name: 'Core-Link Pro Smartwatch',
      category: 'Electronics',
      priceRwf: 89000,
      imageUrl:
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
      gallery: [
        'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=800&q=80',
      ],
      vendorName: 'Kigali Tech Store',
      originLabel: 'WEARABLES',
      badge: 'HOT SELLER',
      stock: 9,
      description:
          'Fitness tracking, heart-rate monitor, and smartphone notifications with a 7-day battery and water resistance.',
      variants: [
        ProductVariant(name: 'Band', options: ['Black Silicone', 'Steel']),
      ],
    ),
    Product(
      id: 'p-coffee',
      name: 'Gorilla Mountain Arabica Coffee',
      category: 'Fresh Produce',
      priceRwf: 12500,
      imageUrl:
          'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=800&q=80',
      vendorName: 'Kivu Highlands Co-op',
      originLabel: 'KIVU REGION',
      badge: 'FRESH ARRIVAL',
      stock: 48,
      description:
          'Single-origin Arabica from the shores of Lake Kivu. Medium roast with notes of chocolate and citrus.',
      variants: [
        ProductVariant(name: 'Grind', options: ['Whole Bean', 'Ground']),
        ProductVariant(name: 'Weight', options: ['250g', '500g', '1kg']),
      ],
    ),
    Product(
      id: 'p-basket',
      name: 'Agaseke Peace Basket',
      category: 'Home',
      priceRwf: 28000,
      imageUrl:
          'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=800&q=80',
      vendorName: 'Gahaya Links Collective',
      originLabel: 'HANDCRAFTED',
      stock: 15,
      description:
          'Traditional woven Agaseke basket made by women artisans. Ideal as a gift or home accent.',
      variants: [
        ProductVariant(name: 'Size', options: ['Small', 'Medium', 'Large']),
      ],
    ),
    Product(
      id: 'p-serum',
      name: 'Radiance Vitamin C Serum',
      category: 'Beauty',
      priceRwf: 18500,
      imageUrl:
          'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=800&q=80',
      gallery: [
        'https://images.unsplash.com/photo-1570194065650-d99fb4b38b17?w=800&q=80',
      ],
      vendorName: 'Glow Rwanda Beauty',
      originLabel: 'SKINCARE',
      badge: 'SALE -15%',
      stock: 31,
      description:
          'Lightweight brightening serum formulated for tropical climates. Absorbs quickly under sunscreen.',
      variants: [
        ProductVariant(name: 'Size', options: ['30ml', '50ml']),
      ],
    ),
    Product(
      id: 'p-iphone',
      name: 'iPhone 15 Pro Max Case Bundle',
      category: 'Electronics',
      priceRwf: 35000,
      imageUrl:
          'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=800&q=80',
      vendorName: 'Kigali Tech Store',
      originLabel: 'ACCESSORIES',
      stock: 2,
      description:
          'Shock-absorbent case with tempered glass and charging cable — ready for busy Remera days.',
      variants: [
        ProductVariant(name: 'Color', options: ['Clear', 'Matte Black', 'Blue']),
      ],
    ),
    Product(
      id: 'p-tea',
      name: 'Rwandan Green Tea Sampler',
      category: 'Fresh Produce',
      priceRwf: 9500,
      imageUrl:
          'https://images.unsplash.com/photo-1564890369479-c4ba043a466a?w=800&q=80',
      vendorName: 'Mulindi Tea Estate',
      originLabel: 'NORTHERN PROVINCE',
      stock: 40,
      description:
          'Three estate blends in a gift-ready tin. Smooth, floral notes from Rwanda’s highland gardens.',
    ),
    Product(
      id: 'p-dress',
      name: 'Kitenge Midi Wrap Dress',
      category: 'Apparel',
      priceRwf: 42000,
      imageUrl:
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&q=80',
      vendorName: 'Inzozi Fashion House',
      originLabel: 'READY-TO-WEAR',
      stock: 7,
      description:
          'Bold Kitenge print wrap dress with adjustable fit. Perfect for markets, office Fridays, and celebrations.',
      variants: [
        ProductVariant(name: 'Size', options: ['S', 'M', 'L', 'XL']),
      ],
    ),
    Product(
      id: 'p-speakers',
      name: 'SoundMaster Portable Speaker',
      category: 'Electronics',
      priceRwf: 67500,
      imageUrl:
          'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=800&q=80',
      vendorName: 'Kigali Tech Store',
      originLabel: 'AUDIO',
      badge: 'HOT SELLER',
      stock: 11,
      description:
          'IPX7 waterproof Bluetooth speaker with 20W output and 16-hour playtime for lakeside weekends.',
      variants: [
        ProductVariant(name: 'Color', options: ['Charcoal', 'Teal']),
      ],
    ),
    Product(
      id: 'p-honey',
      name: 'Organic Wildflower Honey 500g',
      category: 'Fresh Produce',
      priceRwf: 7800,
      imageUrl:
          'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=800&q=80',
      vendorName: 'Nyungwe Apiaries',
      originLabel: 'WESTERN PROVINCE',
      stock: 55,
      description:
          'Raw, unfiltered honey from Nyungwe forest margins. Rich gold color with floral sweetness.',
    ),
  ];

  static Product? byId(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Product> byCategory(String category) {
    if (category == 'All') return products;
    return products.where((p) => p.category == category).toList();
  }

  static List<Product> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.vendorName.toLowerCase().contains(q),
        )
        .toList();
  }
}

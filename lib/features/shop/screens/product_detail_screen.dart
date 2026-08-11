import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/mock_data/products_mock.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/cart_state.dart';
import '../widgets/product_card.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _imageIndex = 0;
  final Map<String, String> _selectedVariants = {};

  @override
  void initState() {
    super.initState();
    final product = ProductsMock.byId(widget.productId);
    if (product != null) {
      for (final v in product.variants) {
        if (v.options.isNotEmpty) {
          _selectedVariants[v.name] = v.options.first;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ProductsMock.byId(widget.productId);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found')),
      );
    }

    final cart = context.watch<CartState>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final images = product.allImages;
    final recommended = _recommendedProducts(product);

    final gallery = Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              images[_imageIndex.clamp(0, images.length - 1)],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surfaceHigh,
                child: const Icon(Icons.image_outlined, size: 48),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _imageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _imageIndex = index),
                  child: Container(
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryOrange
                            : AppColors.borderSubtle,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: AppColors.surfaceHigh),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            product.category.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  color: AppColors.primaryDeep,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product.name,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          formatRwf(product.priceRwf, suffix: true),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppColors.primaryOrange,
                fontSize: 28,
              ),
        ),
        const SizedBox(height: 16),
        ...product.variants.map((variant) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: variant.options.map((option) {
                    final selected = _selectedVariants[variant.name] == option;
                    return ChoiceChip(
                      label: Text(option),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: AppColors.primaryOrange,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedVariants[variant.name] = option);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        _InfoCard(
          title: 'DESCRIPTION',
          body: product.description,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'DELIVERY & WARRANTY',
          body: '${product.deliveryNote}\n\n${product.warrantyNote}',
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront, color: AppColors.primaryOrange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sold by: ${product.vendorName}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 480;
            final buyNow = ElevatedButton(
              onPressed: () {
                context.read<CartState>().addProduct(
                      product,
                      selectedVariants: Map.of(_selectedVariants),
                    );
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('BUY NOW'),
            );
            final addToCart = OutlinedButton(
              onPressed: () {
                context.read<CartState>().addProduct(
                      product,
                      selectedVariants: Map.of(_selectedVariants),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to cart'),
                    action: SnackBarAction(
                      label: 'Checkout',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('ADD TO CART'),
            );
            final chat = OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat to bargain opens soon (mock)'),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'CHAT TO BARGAIN',
                textAlign: TextAlign.center,
              ),
            );

            if (horizontal) {
              return Row(
                children: [
                  Expanded(child: buyNow),
                  const SizedBox(width: 12),
                  Expanded(child: addToCart),
                  const SizedBox(width: 12),
                  Expanded(child: chat),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buyNow,
                const SizedBox(height: 12),
                addToCart,
                const SizedBox(height: 12),
                chat,
              ],
            );
          },
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leadingWidth: 140,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Shop'),
          style: TextButton.styleFrom(foregroundColor: AppColors.onSurface),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (cart.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your cart is empty')),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              );
            },
            icon: Badge(
              isLabelVisible: cart.itemCount > 0,
              backgroundColor: AppColors.primaryOrange,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: ImigongoBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: gallery),
                        const SizedBox(width: 40),
                        Expanded(child: details),
                      ],
                    )
                  else ...[
                    gallery,
                    const SizedBox(height: 24),
                    details,
                  ],
                  if (recommended.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Text(
                      'RECOMMENDED',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final gap = isDesktop ? 16.0 : 10.0;
                        final cardWidth =
                            (constraints.maxWidth - gap * 2) / 3;
                        final cardHeight = cardWidth / (isDesktop ? 0.72 : 0.68);
                        return SizedBox(
                          height: cardHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < recommended.length; i++) ...[
                                if (i > 0) SizedBox(width: gap),
                                Expanded(
                                  child: ProductCard(
                                    product: recommended[i],
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(
                                            productId: recommended[i].id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Product> _recommendedProducts(Product product) {
    final sameCategory = ProductsMock.byCategory(product.category)
        .where((p) => p.id != product.id)
        .toList();
    if (sameCategory.length >= 3) {
      return sameCategory.take(3).toList();
    }

    final extras = ProductsMock.products
        .where(
          (p) =>
              p.id != product.id &&
              !sameCategory.any((s) => s.id == p.id),
        )
        .toList();
    return [...sameCategory, ...extras].take(3).toList();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

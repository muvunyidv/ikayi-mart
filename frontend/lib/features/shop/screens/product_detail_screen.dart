import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/ikayi_api.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/store_link.dart';
import '../../../state/cart_state.dart';
import '../../../state/catalog_state.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const _recommendedBatchSize = 6;

  int _imageIndex = 0;
  final Map<String, String> _selectedVariants = {};
  Product? _product;
  bool _loading = true;
  String? _error;
  int _recommendedShown = _recommendedBatchSize;
  bool _loadingMore = false;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final primary = PrimaryScrollController.maybeOf(context);
    if (primary == _scrollController) return;
    _scrollController?.removeListener(_onScroll);
    _scrollController = primary;
    _scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients || _loadingMore) return;
    final pos = controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      _loadMoreRecommended();
    }
  }

  void _loadMoreRecommended() {
    final product = _product;
    if (product == null || _loadingMore) return;
    final poolLength = context
        .read<CatalogState>()
        .recommendedFor(product)
        .length;
    if (_recommendedShown >= poolLength) return;
    _loadingMore = true;
    setState(() {
      final next = _recommendedShown + _recommendedBatchSize;
      _recommendedShown = next > poolLength ? poolLength : next;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadingMore = false;
      final controller = _scrollController;
      if (!mounted || controller == null || !controller.hasClients) return;
      final pos = controller.position;
      if (pos.maxScrollExtent <= pos.pixels + 280) {
        _loadMoreRecommended();
      }
    });
  }

  Future<void> _load() async {
    final cached = context.read<CatalogState>().byId(widget.productId);
    if (cached != null) {
      setState(() {
        _applyProduct(cached);
        _loading = false;
      });
    }
    try {
      final product = await context.read<IkayiApi>().getProduct(
        widget.productId,
      );
      if (!mounted) return;
      setState(() {
        _applyProduct(product);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = _product == null;
        _error = _product == null ? e.toString() : null;
      });
    }
  }

  void _applyProduct(Product product) {
    _product = product;
    if (_selectedVariants.isEmpty) {
      for (final v in product.variants) {
        if (v.options.isNotEmpty) {
          _selectedVariants[v.name] = v.options.first;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    if (_loading && product == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (product == null) {
      return Center(child: Text(_error ?? 'Product not found'));
    }

    final catalog = context.watch<CatalogState>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final images = product.allImages;
    final moreFromVendor = catalog.moreFromVendor(product);
    final recommendedPool = catalog.recommendedFor(product);
    final recommended = recommendedPool.take(_recommendedShown).toList();
    final hasMoreRecommended = _recommendedShown < recommendedPool.length;

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
        Text(product.name, style: Theme.of(context).textTheme.displayMedium),
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
                        setState(
                          () => _selectedVariants[variant.name] = option,
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        _InfoCard(title: 'DESCRIPTION', body: product.description),
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
                child: product.vendorName.trim().isEmpty
                    ? Text(
                        'Sold by an IKAYIMART vendor',
                        style: Theme.of(context).textTheme.titleSmall,
                      )
                    : StoreLink(
                        name: product.vendorName,
                        slug: product.vendorSlug,
                        prefix: 'Sold by: ',
                        iconSize: 0,
                        showIcon: false,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.read<CartState>().addProduct(
                    product,
                    selectedVariants: Map.of(_selectedVariants),
                  );
                  context.go('/checkout');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('BUY NOW'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  context.read<CartState>().addProduct(
                    product,
                    selectedVariants: Map.of(_selectedVariants),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      action: SnackBarAction(
                        label: 'View cart',
                        textColor: Colors.white,
                        onPressed: () => context.go('/cart'),
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('ADD TO CART'),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final compactChrome = width < kPhoneBreakpoint;

    return SingleChildScrollView(
      primary: true,
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: compactChrome
                    ? IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back to Shop',
                      )
                    : TextButton.icon(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Shop'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
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
              if (moreFromVendor.isNotEmpty) ...[
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'MORE FROM THIS VENDOR',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    if (product.vendorName.trim().isNotEmpty)
                      StoreLink(
                        name: product.vendorName,
                        slug: product.vendorSlug,
                        showIcon: false,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryOrange,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: moreFromVendor.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = moreFromVendor[index];
                      return SizedBox(
                        width: 180,
                        child: ProductCard(
                          product: item,
                          onTap: () => _openProduct(item),
                        ),
                      );
                    },
                  ),
                ),
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
                    final cols = productCrossAxisCount(
                      constraints.maxWidth,
                      max: 3,
                    );
                    final gap = constraints.maxWidth >= kTabletBreakpoint
                        ? 16.0
                        : 12.0;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recommended.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: gap,
                        crossAxisSpacing: gap,
                        childAspectRatio: productCardAspectRatio(
                          constraints.maxWidth,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final item = recommended[index];
                        return ProductCard(
                          product: item,
                          onTap: () => _openProduct(item),
                        );
                      },
                    );
                  },
                ),
                if (hasMoreRecommended)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openProduct(Product item) {
    context.push('/product/${item.id}');
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

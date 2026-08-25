import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/catalog_state.dart';
import '../../../state/navigation_state.dart';
import '../widgets/hero_ad_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/shopper_sidebar.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final Set<String> _favorites = {};

  List<Product> _filtered(
    List<Product> products,
    String category,
    String query,
  ) {
    final byCat = category == 'All'
        ? products
        : products.where((p) => p.category == category).toList();
    if (query.trim().isEmpty) return byCat;
    return byCat.where((p) => p.matchesQuery(query)).toList();
  }

  void _resetSearch() {
    context.read<NavigationState>().setSearchQuery('');
  }

  void _openProduct(Product product) {
    context.push('/product/${product.id}');
  }

  void _onHeroSlide(HeroPromoSlide slide) {
    final nav = context.read<NavigationState>();
    if (slide.targetCategory != null) {
      nav.setCategory(slide.targetCategory!);
    }
    if (slide.targetPath != null && slide.targetPath!.isNotEmpty) {
      context.go(slide.targetPath!);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationState>();
    final catalog = context.watch<CatalogState>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final query = nav.searchQuery;
    final products = _filtered(catalog.products, nav.selectedCategory, query);
    final crossAxisCount = productCrossAxisCount(width);
    final cardAspectRatio = productCardAspectRatio(width);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop)
          ShopperSidebar(
            selectedCategory: nav.selectedCategory,
            onCategory: nav.setCategory,
            collapsed: nav.shopperSidebarCollapsed,
            onToggle: nav.toggleShopperSidebar,
            categories: catalog.categoryOptions,
          ),
        Expanded(
          child: CustomScrollView(
            primary: true,
            slivers: [
              if (!isDesktop)
                SliverToBoxAdapter(
                  child: _CategoryPills(
                    selected: nav.selectedCategory,
                    onSelected: nav.setCategory,
                    categories: catalog.categoryOptions,
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 24 : 16,
                  isDesktop ? 16 : 8,
                  isDesktop ? 24 : 16,
                  8,
                ),
                sliver: SliverToBoxAdapter(
                  child: HeroAdCarousel(
                    productImageUrls: catalog.products
                        .where((p) => p.imageUrl.isNotEmpty)
                        .map((p) => p.imageUrl)
                        .take(6)
                        .toList(),
                    onSlideTap: _onHeroSlide,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 24 : 16,
                  8,
                  isDesktop ? 24 : 16,
                  8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isDesktop ? 'Featured Marketplace' : 'New Arrivals',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      Text(
                        'VIEW ALL →',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryOrange,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDesktop && catalog.products.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Showing ${products.length} items found in Rwanda',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              if (catalog.loading && catalog.products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (catalog.error != null && catalog.products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(catalog.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<CatalogState>().load(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (catalog.products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No products in the marketplace yet.\nAdd one from Vendor Central → Inventory.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 40,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            query.trim().isEmpty
                                ? 'No products match this category.'
                                : 'No products found matching \'${query.trim()}\'',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (query.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _resetSearch,
                              child: const Text('Reset search'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: cardAspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        isFavorite: _favorites.contains(product.id),
                        onFavorite: () {
                          setState(() {
                            if (_favorites.contains(product.id)) {
                              _favorites.remove(product.id);
                            } else {
                              _favorites.add(product.id);
                            }
                          });
                        },
                        onTap: () => _openProduct(product),
                      );
                    }, childCount: products.length),
                  ),
                ),
              if (!isDesktop)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: _PromoBanner(onShop: () => nav.setCategory('All')),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills({
    required this.selected,
    required this.onSelected,
    required this.categories,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final active = cat == selected;
          return ChoiceChip(
            label: Text(cat),
            selected: active,
            onSelected: (_) => onSelected(cat),
            selectedColor: AppColors.primaryOrange,
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.surfaceHigh,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fast Delivery Across Kigali. Order now and get it in 60 minutes.',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onShop,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'SHOP NOW',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.delivery_dining, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}

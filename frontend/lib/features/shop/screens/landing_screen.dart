import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/rwanda_locations.dart';
import '../../../core/mock_data/products_mock.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/cart_state.dart';
import '../../../state/navigation_state.dart';
import '../widgets/product_card.dart';
import 'checkout_screen.dart';
import 'product_detail_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  final Set<String> _favorites = {};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  List<Product> _filtered(String category) {
    final byCat = ProductsMock.byCategory(category);
    if (_query.isEmpty) return byCat;
    final q = _query.toLowerCase();
    return byCat
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.vendorName.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _pickLocation(NavigationState nav) async {
    String district = nav.selectedDistrict;
    String sector = nav.selectedSector;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final sectorOptions = RwandaLocations.sectorsFor(district);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.paddingOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select District / Sector',
                    style: Theme.of(ctx).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: district,
                    decoration: const InputDecoration(labelText: 'District'),
                    items: RwandaLocations.districtNames
                        .map(
                          (d) => DropdownMenuItem(value: d, child: Text(d)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setModal(() {
                        district = v;
                        sector = RwandaLocations.sectorsFor(v).first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: sectorOptions.contains(sector)
                        ? sector
                        : sectorOptions.first,
                    decoration: const InputDecoration(labelText: 'Sector'),
                    items: sectorOptions
                        .map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setModal(() => sector = v);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      nav.setLocation(district: district, sector: sector);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Confirm location'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openProduct(Product product) {
    _scrollToTop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationState>();
    final cart = context.watch<CartState>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final products = _filtered(nav.selectedCategory);
    final crossAxisCount = isDesktop ? 4 : 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ImigongoBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                isDesktop: isDesktop,
                cartCount: cart.itemCount,
                locationLabel: nav.locationLabel,
                searchController: _searchController,
                onSearch: (v) => setState(() => _query = v),
                onLocation: () => _pickLocation(nav),
                onCart: () {
                  if (cart.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Your cart is empty')),
                    );
                    return;
                  }
                  _scrollToTop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                },
                onVendor: () {
                  _scrollToTop();
                  nav.setMode(AppMode.vendor);
                },
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop)
                    SizedBox(
                      width: 240,
                      child: _DesktopFilters(
                        selectedCategory: nav.selectedCategory,
                        onCategory: nav.setCategory,
                      ),
                    ),
                  Expanded(
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        if (!isDesktop)
                          SliverToBoxAdapter(
                            child: _CategoryPills(
                              selected: nav.selectedCategory,
                              onSelected: nav.setCategory,
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
                                    isDesktop
                                        ? 'Featured Marketplace'
                                        : 'New Arrivals',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ),
                                Text(
                                  'VIEW ALL →',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: AppColors.primaryOrange,
                                        fontSize: 13,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isDesktop)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                'Showing ${products.length} items found in Rwanda',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.secondary),
                              ),
                            ),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.all(isDesktop ? 24 : 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: isDesktop ? 0.72 : 0.68,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
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
                              },
                              childCount: products.length,
                            ),
                          ),
                        ),
                        if (!isDesktop)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverToBoxAdapter(
                              child: _PromoBanner(
                                onShop: () => nav.setCategory('All'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isDesktop,
    required this.cartCount,
    required this.locationLabel,
    required this.searchController,
    required this.onSearch,
    required this.onLocation,
    required this.onCart,
    required this.onVendor,
  });

  final bool isDesktop;
  final int cartCount;
  final String locationLabel;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onLocation;
  final VoidCallback onCart;
  final VoidCallback onVendor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLowest,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 16,
        12,
        isDesktop ? 24 : 16,
        12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'IKAYI MART',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: isDesktop ? 20 : 18,
                      letterSpacing: 0.6,
                    ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 24),
                Expanded(
                  child: _SearchField(
                    controller: searchController,
                    onChanged: onSearch,
                    showCategoryPrefix: true,
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: onLocation,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELECT DISTRICT/SECTOR',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontSize: 9),
                            ),
                            Text(
                              locationLabel,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Spacer(),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                ),
              ],
              IconButton(
                tooltip: 'Cart',
                onPressed: onCart,
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  backgroundColor: AppColors.primaryOrange,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              ),
              IconButton(
                tooltip: 'Vendor dashboard',
                onPressed: onVendor,
                icon: const Icon(Icons.storefront_outlined),
              ),
            ],
          ),
          if (!isDesktop) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SearchField(
                    controller: searchController,
                    onChanged: onSearch,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onLocation,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: AppColors.borderSubtle),
                    foregroundColor: AppColors.onSurface,
                  ),
                  icon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primaryOrange,
                    size: 18,
                  ),
                  label: const Text('Location'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    this.showCategoryPrefix = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool showCategoryPrefix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: showCategoryPrefix
            ? 'Search for items...'
            : 'Search across Rwanda...',
        prefixIcon: showCategoryPrefix
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 12),
                  Text('All Categories'),
                  Icon(Icons.expand_more, size: 18),
                  SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 1, thickness: 1),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.search, size: 20),
                ],
              )
            : const Icon(Icons.search),
        suffixIcon: showCategoryPrefix
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryOrange,
                  child: const Icon(Icons.search, color: Colors.white, size: 18),
                ),
              )
            : null,
      ),
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: ProductsMock.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = ProductsMock.categories[index];
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

class _DesktopFilters extends StatelessWidget {
  const _DesktopFilters({
    required this.selectedCategory,
    required this.onCategory,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    final cats = ProductsMock.categories
        .where((c) => c != 'All')
        .toList();
    return Material(
      color: AppColors.surfaceLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categories', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            ...cats.map((cat) {
              final active = selectedCategory == cat;
              return InkWell(
                onTap: () => onCategory(cat),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        active
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: active
                            ? AppColors.primaryOrange
                            : AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            TextButton(
              onPressed: () => onCategory('All'),
              child: const Text('Show all'),
            ),
          ],
        ),
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

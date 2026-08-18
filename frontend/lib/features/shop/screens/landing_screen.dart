import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/ikayi_api.dart';
import '../../../core/constants/rwanda_locations.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/cart_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/navigation_state.dart';
import '../widgets/hero_ad_carousel.dart';
import '../widgets/product_card.dart';
import '../widgets/shopper_sidebar.dart';
import 'checkout_screen.dart';
import 'product_detail_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  String _query = '';
  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogState>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  List<Product> _filtered(List<Product> products, String category) {
    final byCat = category == 'All'
        ? products
        : products.where((p) => p.category == category).toList();
    if (_query.trim().isEmpty) return byCat;
    return byCat.where((p) => p.matchesQuery(_query)).toList();
  }

  void _resetSearch() {
    _searchController.clear();
    setState(() => _query = '');
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
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
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
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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

  Future<void> _trackOrder() async {
    final codeCtrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Track order'),
          content: TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(
              labelText: 'Guest tracking ID',
              hintText: 'IKY-9842',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, codeCtrl.text.trim()),
              child: const Text('Track'),
            ),
          ],
        );
      },
    );
    codeCtrl.dispose();
    if (code == null || code.isEmpty || !mounted) return;

    try {
      final order = await context.read<IkayiApi>().trackOrder(code);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('#${order.displayCode}'),
            content: Text(
              '${order.status.label}\n${order.guestName}\n${order.locationLabel}\n${formatRwf(order.grandTotalRwf, suffix: true)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationState>();
    final cart = context.watch<CartState>();
    final catalog = context.watch<CatalogState>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final products = _filtered(catalog.products, nav.selectedCategory);
    final crossAxisCount = productCrossAxisCount(width);
    final cardAspectRatio = productCardAspectRatio(width);

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
                searchFocusNode: _searchFocus,
                onSearch: (v) => setState(() => _query = v),
                onSearchIcon: () => _searchFocus.requestFocus(),
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
                onTrack: _trackOrder,
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDesktop)
                      ShopperSidebar(
                        selectedCategory: nav.selectedCategory,
                        onCategory: nav.setCategory,
                        collapsed: nav.shopperSidebarCollapsed,
                        onToggle: nav.toggleShopperSidebar,
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
                                onCta: () => nav.setCategory('All'),
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
                                      isDesktop
                                          ? 'Featured Marketplace'
                                          : 'New Arrivals',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
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
                          if (isDesktop && catalog.products.isNotEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Text(
                                  'Showing ${products.length} items found in Rwanda',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.secondary),
                                ),
                              ),
                            ),
                          if (catalog.loading && catalog.products.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (catalog.error != null &&
                              catalog.products.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        catalog.error!,
                                        textAlign: TextAlign.center,
                                      ),
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
                                        _query.trim().isEmpty
                                            ? 'No products match this category.'
                                            : 'No products found matching \'${_query.trim()}\'',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      if (_query.trim().isNotEmpty) ...[
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
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: cardAspectRatio,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
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
    required this.searchFocusNode,
    required this.onSearch,
    required this.onSearchIcon,
    required this.onLocation,
    required this.onCart,
    required this.onVendor,
    required this.onTrack,
  });

  final bool isDesktop;
  final int cartCount;
  final String locationLabel;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearch;
  final VoidCallback onSearchIcon;
  final VoidCallback onLocation;
  final VoidCallback onCart;
  final VoidCallback onVendor;
  final VoidCallback onTrack;

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
                    focusNode: searchFocusNode,
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
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(fontSize: 9),
                            ),
                            Text(
                              locationLabel,
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(fontSize: 13),
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
                  onPressed: onSearchIcon,
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
                tooltip: 'Track order',
                onPressed: onTrack,
                icon: const Icon(Icons.local_shipping_outlined),
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
                    focusNode: searchFocusNode,
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
    this.focusNode,
    this.showCategoryPrefix = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final bool showCategoryPrefix;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
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
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.close, size: 18),
                  )
                : showCategoryPrefix
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryOrange,
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: kCatalogCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = kCatalogCategories[index];
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

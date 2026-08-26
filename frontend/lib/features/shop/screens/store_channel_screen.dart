import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/ikayi_api.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/store_hero_banner.dart';

class StoreChannelScreen extends StatefulWidget {
  const StoreChannelScreen({super.key, required this.slug});

  final String slug;

  @override
  State<StoreChannelScreen> createState() => _StoreChannelScreenState();
}

class _StoreChannelScreenState extends State<StoreChannelScreen> {
  StoreChannel? _store;
  bool _loading = true;
  String? _error;
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant StoreChannelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _category = 'All';
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final store = await context.read<IkayiApi>().getStore(widget.slug);
      if (!mounted) return;
      setState(() {
        _store = store;
        _loading = false;
        _error = null;
        if (!store.filterTabs.contains(_category)) {
          _category = 'All';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  List<Product> get _filtered {
    final store = _store;
    if (store == null) return const [];
    if (_category == 'All') return store.products;
    return store.products.where((p) => p.category == _category).toList();
  }

  void _openProduct(Product product) {
    context.push('/product/${product.id}');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final store = _store;

    if (_loading && store == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (store == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined, size: 48, color: AppColors.secondary),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Store not found',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  child: const Text('Back to shop'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final products = _filtered;
    final tabs = store.filterTabs;
    final padding = isDesktop ? 24.0 : 16.0;

    return CustomScrollView(
      primary: true,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, isDesktop ? 16 : 8, padding, 8),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: width < kPhoneBreakpoint
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
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 8),
          sliver: SliverToBoxAdapter(
            child: StoreHeroBanner(
              storeName: store.storeName,
              description: store.description,
              phone: store.phone,
              contactEmail: store.contactEmail,
              imageUrls: store.bannerImageUrls,
            ),
          ),
        ),
        if (tabs.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = tabs[index];
                  final active = cat == _category;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: active,
                    onSelected: (_) => setState(() => _category = cat),
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
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 8, padding, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              _category == 'All'
                  ? '${store.productCount} item${store.productCount == 1 ? '' : 's'} in this store'
                  : '${products.length} item${products.length == 1 ? '' : 's'} in $_category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
        if (products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No products in this category yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding, 8, padding, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: productCrossAxisCount(width),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: productCardAspectRatio(width),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    showVendor: false,
                    onTap: () => _openProduct(product),
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
      ],
    );
  }
}

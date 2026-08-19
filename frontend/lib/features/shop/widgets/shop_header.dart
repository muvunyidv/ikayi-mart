import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/branding.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/cart_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/navigation_state.dart';

/// Persistent storefront header: brand, search, categories, cart, track, vendor.
class ShopHeader extends StatelessWidget {
  const ShopHeader({
    super.key,
    required this.isDesktop,
    required this.searchController,
    required this.searchFocusNode,
  });

  final bool isDesktop;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  void _goHome(BuildContext context) {
    if (GoRouterState.of(context).uri.path != '/') {
      context.go('/');
    }
  }

  void _onSearchChanged(BuildContext context, String value) {
    context.read<NavigationState>().setSearchQuery(value);
    if (value.trim().isNotEmpty) {
      _goHome(context);
    }
  }

  void _onCategorySelected(BuildContext context, String category) {
    context.read<NavigationState>().setCategory(category);
    _goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final catalog = context.watch<CatalogState>();
    final nav = context.watch<NavigationState>();
    final categories = catalog.categoryOptions;

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
              InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    AppBranding.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: isDesktop ? 20 : 18,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 24),
                Expanded(
                  child: _SearchField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    onChanged: (v) => _onSearchChanged(context, v),
                    showCategoryPrefix: true,
                    categories: categories,
                    selectedCategory: nav.selectedCategory,
                    onCategorySelected: (c) => _onCategorySelected(context, c),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Spacer(),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => searchFocusNode.requestFocus(),
                  icon: const Icon(Icons.search),
                ),
              ],
              IconButton(
                tooltip: 'Cart',
                onPressed: () => context.go('/cart'),
                icon: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  backgroundColor: AppColors.primaryOrange,
                  label: Text('${cart.itemCount}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              ),
              IconButton(
                tooltip: 'Track order',
                onPressed: () => context.go('/tracking'),
                icon: const Icon(Icons.local_shipping_outlined),
              ),
              IconButton(
                tooltip: 'Vendor dashboard',
                onPressed: () {
                  context.read<NavigationState>().setMode(AppMode.vendor);
                  context.go('/vendor');
                },
                icon: const Icon(Icons.storefront_outlined),
              ),
            ],
          ),
          if (!isDesktop) ...[
            const SizedBox(height: 8),
            _SearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: (v) => _onSearchChanged(context, v),
              showCategoryPrefix: true,
              compactCategory: true,
              categories: categories,
              selectedCategory: nav.selectedCategory,
              onCategorySelected: (c) => _onCategorySelected(context, c),
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
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.focusNode,
    this.showCategoryPrefix = false,
    this.compactCategory = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final bool showCategoryPrefix;
  final bool compactCategory;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

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
          onSubmitted: (v) => onChanged(v),
          decoration: InputDecoration(
            hintText: showCategoryPrefix
                ? 'Search for items...'
                : 'Search across Rwanda...',
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            prefixIcon: showCategoryPrefix
                ? _CategoryDropdown(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    compact: compactCategory,
                    onSelected: onCategorySelected,
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
                    child: Material(
                      color: AppColors.primaryOrange,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onChanged(controller.text),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
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

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    this.compact = false,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final bool compact;

  String get _label {
    if (selectedCategory == 'All') {
      return compact ? 'All' : 'All Categories';
    }
    return selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final items = categories.isEmpty ? kCatalogCategories : categories;
    return PopupMenuButton<String>(
      tooltip: 'Browse categories',
      initialValue: items.contains(selectedCategory)
          ? selectedCategory
          : 'All',
      onSelected: onSelected,
      offset: const Offset(0, 40),
      itemBuilder: (context) {
        return items
            .map(
              (cat) => PopupMenuItem<String>(
                value: cat,
                child: Text(cat == 'All' ? 'All Categories' : cat),
              ),
            )
            .toList();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 88 : 140),
              child: Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            ),
            const Icon(Icons.expand_more, size: 18),
            const SizedBox(width: 8),
            const SizedBox(
              height: 24,
              child: VerticalDivider(width: 1, thickness: 1),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.search, size: 20),
          ],
        ),
      ),
    );
  }
}

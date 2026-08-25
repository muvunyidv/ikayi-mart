import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

const _categoryIcons = <String, IconData>{
  'Electronics': Icons.devices_outlined,
  'Apparel': Icons.checkroom_outlined,
  'Home': Icons.chair_outlined,
  'Beauty': Icons.spa_outlined,
  'Fresh Produce': Icons.eco_outlined,
};

/// Desktop category navigation with expanded labels or compact icon-only mode.
class ShopperSidebar extends StatelessWidget {
  const ShopperSidebar({
    super.key,
    required this.selectedCategory,
    required this.onCategory,
    required this.collapsed,
    required this.onToggle,
    this.categories = kCatalogCategories,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategory;
  final bool collapsed;
  final VoidCallback onToggle;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final cats = categories.where((c) => c != 'All').toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: collapsed ? kSidebarCollapsedWidth : kSidebarExpandedWidth,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Material(
        color: AppColors.surfaceLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                collapsed ? 8 : 16,
                16,
                collapsed ? 8 : 8,
                8,
              ),
              child: collapsed
                  ? Center(
                      child: IconButton(
                        tooltip: 'Expand sidebar',
                        onPressed: onToggle,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Categories',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Collapse sidebar',
                          onPressed: onToggle,
                          icon: const Icon(Icons.chevron_left),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12),
                children: [
                  ...cats.map((cat) {
                    final active = selectedCategory == cat;
                    final icon = _categoryIcons[cat] ?? Icons.category_outlined;
                    final row = InkWell(
                      onTap: () => onCategory(cat),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: collapsed ? 0 : 8,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: collapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Icon(
                              icon,
                              size: 22,
                              color: active
                                  ? AppColors.primaryOrange
                                  : AppColors.secondary,
                            ),
                            if (!collapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: active
                                        ? AppColors.onSurface
                                        : AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                    return collapsed ? Tooltip(message: cat, child: row) : row;
                  }),
                  const SizedBox(height: 8),
                  collapsed
                      ? Tooltip(
                          message: 'Show all',
                          child: IconButton(
                            onPressed: () => onCategory('All'),
                            icon: Icon(
                              Icons.apps_outlined,
                              color: selectedCategory == 'All'
                                  ? AppColors.primaryOrange
                                  : AppColors.secondary,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: () => onCategory('All'),
                          child: const Text('Show all'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/auth_state.dart';
import '../../../state/navigation_state.dart';

class VendorSidebar extends StatelessWidget {
  const VendorSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.compact = false,
    this.onToggleCollapse,
  });

  final VendorSection selected;
  final ValueChanged<VendorSection> onSelect;
  final bool compact;
  final VoidCallback? onToggleCollapse;

  static const _items = <(VendorSection, String, IconData)>[
    (VendorSection.dashboard, 'Dashboard', Icons.dashboard_outlined),
    (VendorSection.inventory, 'Inventory', Icons.inventory_2_outlined),
    (VendorSection.orders, 'Orders', Icons.receipt_long_outlined),
    (VendorSection.bmsSync, 'BMS Sync', Icons.sync_outlined),
    (VendorSection.support, 'Support', Icons.support_agent_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    // Solid sidebar (no Imigongo mesh). Stacking full-viewport CustomPaint
    // meshes with the main vendor pane OOMs Chrome on Flutter web.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: compact ? kSidebarCollapsedWidth : kSidebarExpandedWidth,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 8 : 16,
              16,
              compact ? 8 : 8,
              8,
            ),
            child: compact
                ? Column(
                    children: [
                      const Tooltip(
                        message: 'IKAYIMART',
                        child: Icon(
                          Icons.storefront,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      if (onToggleCollapse != null)
                        IconButton(
                          tooltip: 'Expand sidebar',
                          onPressed: onToggleCollapse,
                          icon: const Icon(Icons.chevron_right),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IKAYIMART',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'VENDOR CENTRAL',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppColors.secondary,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (onToggleCollapse != null)
                        IconButton(
                          tooltip: 'Collapse sidebar',
                          onPressed: onToggleCollapse,
                          icon: const Icon(Icons.chevron_left),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          ..._items.map((item) {
            final (section, label, icon) = item;
            final active = selected == section;
            final tile = Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: 2,
              ),
              child: Material(
                color: active ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onSelect(section),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 0 : 14,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: compact
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
                        if (!compact) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
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
                ),
              ),
            );
            return compact ? Tooltip(message: label, child: tile) : tile;
          }),
          const Spacer(),
          _VendorProfileFooter(compact: compact),
        ],
      ),
    );
  }
}

class _VendorProfileFooter extends StatelessWidget {
  const _VendorProfileFooter({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final store = user?.storeName ?? 'Vendor store';
    final verified = user?.isVerified == true;
    final avatar = CircleAvatar(
      radius: compact ? 16 : 18,
      backgroundColor: AppColors.primaryOrange,
      child: Text(
        user?.storeInitials ?? 'VS',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 11),
      ),
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Tooltip(message: store, child: avatar),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontSize: 13),
                  ),
                  Text(
                    verified ? 'Verified Vendor' : 'Vendor',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: verified ? AppColors.success : AppColors.secondary,
                    ),
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/navigation_state.dart';

class VendorSidebar extends StatelessWidget {
  const VendorSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.compact = false,
  });

  final VendorSection selected;
  final ValueChanged<VendorSection> onSelect;
  final bool compact;

  static const _items = <(VendorSection, String, IconData)>[
    (VendorSection.dashboard, 'Dashboard', Icons.dashboard_outlined),
    (VendorSection.inventory, 'Inventory', Icons.inventory_2_outlined),
    (VendorSection.orders, 'Orders', Icons.receipt_long_outlined),
    (VendorSection.bmsSync, 'BMS Sync', Icons.sync_outlined),
    (VendorSection.support, 'Support', Icons.support_agent_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ImigongoBackground(
      variant: ImigongoVariant.light,
      backgroundColor: AppColors.surfaceLowest,
      patternOpacity: 0.07,
      child: SizedBox(
        width: compact ? 72 : 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 20,
                24,
                compact ? 12 : 20,
                8,
              ),
              child: compact
                  ? const Icon(Icons.storefront, color: AppColors.primaryOrange)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IKAYI MART',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'VENDOR CENTRAL',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.secondary,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            ..._items.map((item) {
              final (section, label, icon) = item;
              final active = selected == section;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelect(section),
                      child: Stack(
                        children: [
                          if (active)
                            const Positioned.fill(
                              child: ImigongoBackground(
                                variant: ImigongoVariant.navActive,
                                patternOpacity: 0.2,
                                backgroundColor: AppColors.primaryLight,
                                child: SizedBox.expand(),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 12 : 14,
                              vertical: 12,
                            ),
                            child: Row(
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
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            if (!compact)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryOrange,
                        child: Text(
                          'KT',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kigali Tech Store',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontSize: 13),
                            ),
                            Text(
                              'Verified Vendor',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: AppColors.success,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.settings_outlined, size: 18),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

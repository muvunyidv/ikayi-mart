import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../utils/store_slug.dart';

/// Clickable vendor/store name that deep-links to `/store/:slug`.
class StoreLink extends StatelessWidget {
  const StoreLink({
    super.key,
    required this.name,
    this.slug,
    this.style,
    this.prefix,
    this.iconSize = 14,
    this.showIcon = true,
    this.maxLines = 1,
  });

  final String name;
  final String? slug;
  final TextStyle? style;
  final String? prefix;
  final double iconSize;
  final bool showIcon;
  final int maxLines;

  String get _path => storePathFor(slug: slug, name: name);

  bool get _enabled => name.trim().isNotEmpty && _path.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SizedBox.shrink();

    final label = prefix == null || prefix!.isEmpty ? name : '$prefix$name';
    final textStyle =
        style ??
        Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primaryOrange,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );

    return InkWell(
      onTap: () => context.push(_path),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            if (showIcon) ...[
              Icon(
                Icons.storefront_outlined,
                size: iconSize,
                color: textStyle?.color ?? AppColors.primaryOrange,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/product_thumbnail.dart';
import '../../../state/catalog_state.dart';

/// One ordered SKU: thumbnail, title, quantity, description, line total.
class OrderItemTile extends StatelessWidget {
  const OrderItemTile({super.key, required this.item});

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogState>();
    final product = item.productId != null
        ? catalog.byId(item.productId!)
        : null;
    final title = item.productName.isNotEmpty
        ? item.productName
        : (product?.name ?? 'Product');
    final imageUrl = item.imageUrl.isNotEmpty
        ? item.imageUrl
        : (product?.imageUrl ?? '');
    final description = item.shortDescription.isNotEmpty
        ? item.shortDescription
        : (product?.description ?? '').trim();

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductThumbnail(
          imageUrl: imageUrl,
          width: 72,
          height: 72,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _QuantityBadge(quantity: item.quantity),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatRwf(item.totalRwf, suffix: true),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.primaryOrange,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final productId = item.productId ?? product?.id;
    if (productId == null || productId.isEmpty) return body;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/product/$productId'),
        borderRadius: BorderRadius.circular(10),
        child: body,
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'x$quantity',
        style: const TextStyle(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

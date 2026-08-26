import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/product_thumbnail.dart';
import '../../../core/widgets/store_link.dart';
import '../../../state/cart_state.dart';
import '../widgets/checkout_choice_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo(CartState cart) {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a promo code')));
      return;
    }
    final ok = cart.applyPromoCode(code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Promo ${cart.promoCode} applied'
              : cart.promoError ?? 'Invalid promo code',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;

    if (cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 56,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse the marketplace and add items to get started.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Continue shopping'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = _CartItemsColumn(cart: cart);
    final summary = _CartSummary(
      cart: cart,
      promoController: _promoController,
      onApplyPromo: () => _applyPromo(cart),
      onCheckout: () => CheckoutChoiceSheet.show(context),
    );

    return isDesktop
        ? Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(primary: true, child: items),
                ),
                const SizedBox(width: 32),
                SizedBox(width: 360, child: summary),
              ],
            ),
          )
        : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  primary: true,
                  padding: const EdgeInsets.all(16),
                  child: items,
                ),
              ),
              summary,
            ],
          );
  }
}

class _CartItemsColumn extends StatelessWidget {
  const _CartItemsColumn({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your cart', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: 20),
        ...List.generate(cart.items.length, (index) {
          final item = cart.items[index];
          final variantLabel = item.selectedVariants.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(' · ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductThumbnail(
                      imageUrl: item.product.imageUrl,
                      width: 88,
                      height: 88,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (item.product.vendorName.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          StoreLink(
                            name: item.product.vendorName,
                            slug: item.product.vendorSlug,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                        if (variantLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            variantLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          formatRwf(item.product.priceRwf, suffix: true),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppColors.primaryOrange),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _QtyButton(
                              icon: Icons.remove,
                              onPressed: () =>
                                  cart.updateQuantity(index, item.quantity - 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            _QtyButton(
                              icon: Icons.add,
                              onPressed: () =>
                                  cart.updateQuantity(index, item.quantity + 1),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () => cart.removeAt(index),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 16)),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.cart,
    required this.promoController,
    required this.onApplyPromo,
    required this.onCheckout,
  });

  final CartState cart;
  final TextEditingController promoController;
  final VoidCallback onApplyPromo;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: AppColors.surfaceLowest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Order summary',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              _line('Subtotal', formatRwf(cart.subtotalRwf, suffix: true)),
              const SizedBox(height: 8),
              _line(
                'Delivery',
                cart.deliveryFeeRwf == 0
                    ? 'FREE'
                    : formatRwf(cart.deliveryFeeRwf, suffix: true),
              ),
              if (cart.discountRwf > 0) ...[
                const SizedBox(height: 8),
                _line(
                  'Promo (${cart.promoCode})',
                  '- ${formatRwf(cart.discountRwf, suffix: true)}',
                  valueColor: AppColors.primaryOrange,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: promoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Promo code',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onApplyPromo,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(88, 48),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
              if (cart.promoError != null) ...[
                const SizedBox(height: 6),
                Text(
                  cart.promoError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Try IKAYI10, FREESHIP, or WELCOME',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondary,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Grand total',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    formatRwf(cart.grandTotalRwf, suffix: true),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onCheckout,
                child: const Text('Proceed to Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: valueColor == null ? null : TextStyle(color: valueColor),
        ),
      ],
    );
  }
}

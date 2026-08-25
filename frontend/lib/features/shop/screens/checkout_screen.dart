import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/ikayi_api.dart';
import '../../../core/constants/rwanda_locations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/rwanda_phone.dart';
import '../../../state/cart_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/navigation_state.dart';
import '../../../state/auth_state.dart';

enum _PaymentMethod { mtnMomo, airtelMoney, visaCard }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _landmarkController = TextEditingController();

  String? _district;
  String? _sector;
  _PaymentMethod _payment = _PaymentMethod.mtnMomo;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = context.read<NavigationState>();
      final auth = context.read<AuthState>();
      final user = auth.user;
      setState(() {
        if (auth.isLoggedIn && user != null) {
          _nameController.text = user.name;
          _emailController.text = user.email;
          if (user.phone != null && user.phone!.isNotEmpty) {
            _phoneController.text = user.phone!;
          }
          if (user.landmark != null && user.landmark!.isNotEmpty) {
            _landmarkController.text = user.landmark!;
          }
          final savedDistrict = user.district;
          final savedSector = user.sector;
          if (savedDistrict != null &&
              RwandaLocations.districtNames.contains(savedDistrict)) {
            _district = savedDistrict;
            final sectors = RwandaLocations.sectorsFor(savedDistrict);
            if (savedSector != null && sectors.contains(savedSector)) {
              _sector = savedSector;
            }
          } else {
            _district = nav.selectedDistrict;
            _sector = nav.selectedSector;
          }
        } else {
          _district = nav.selectedDistrict;
          _sector = nav.selectedSector;
        }
      });
      context.read<IkayiApi>().wake();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  String get _apiPaymentMethod => switch (_payment) {
    _PaymentMethod.mtnMomo => 'MTN_MOMO',
    _PaymentMethod.airtelMoney => 'AIRTEL_MONEY',
    _PaymentMethod.visaCard => 'VISA_CARD',
  };

  Future<void> _placeOrder(CartState cart) async {
    if (!_formKey.currentState!.validate()) return;
    if (_district == null || _sector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select district and sector')),
      );
      return;
    }

    setState(() => _placing = true);
    final api = context.read<IkayiApi>();
    final auth = context.read<AuthState>();
    final loggedIn = auth.isLoggedIn;
    try {
      final phone =
          normalizeRwandaPhone(_phoneController.text.trim()) ??
          _phoneController.text.trim();
      final district = _district!;
      final sector = _sector!;
      final landmark = _landmarkController.text.trim();
      final result = await api.guestCheckout(
        guestName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: phone,
        district: district,
        sector: sector,
        landmark: landmark,
        paymentMethod: _apiPaymentMethod,
        isGuest: !loggedIn,
        items: cart.items
            .map(
              (item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
                if (item.selectedVariants.isNotEmpty)
                  'selectedVariants': item.selectedVariants,
              },
            )
            .toList(),
      );
      if (!mounted) return;
      if (loggedIn) {
        auth.applySavedCheckout(
          phone: phone,
          district: district,
          sector: sector,
          landmark: landmark,
        );
        unawaited(auth.refreshProfile());
      }
      final totalLabel = formatRwf(result.totalAmountRwf, suffix: true);
      cart.clear();
      unawaited(context.read<CatalogState>().load());
      setState(() => _placing = false);
      final uri = Uri(
        path: '/order-success',
        queryParameters: {
          'orderId': result.orderId,
          'code': result.trackingCode,
          'email': _emailController.text.trim(),
          'total': totalLabel,
        },
      );
      context.go(uri.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final auth = context.watch<AuthState>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final sectors = _district == null
        ? <String>[]
        : RwandaLocations.sectorsFor(_district!);

    if (cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Your cart is empty'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Continue shopping'),
            ),
          ],
        ),
      );
    }

    final form = Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CHECKOUT — Step 2 of 2',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              auth.isLoggedIn
                  ? 'Review or update your saved shipping details. Changes on this order are saved to your profile.'
                  : 'Guest checkout — email, phone, and delivery address. Payment is simulated for now and issues a tracking code immediately.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                helperText: 'Order confirmation and optional account later',
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+250 7XX XXX XXX',
                helperText: 'Required for MoMo & SMS tracking',
              ),
              validator: rwandaPhoneValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('district-$_district'),
              initialValue: _district,
              decoration: const InputDecoration(labelText: 'District'),
              items: RwandaLocations.districtNames
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _district = v;
                  _sector = null;
                });
              },
              validator: (v) => v == null ? 'Select a district' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('sector-$_district-$_sector'),
              initialValue: sectors.contains(_sector) ? _sector : null,
              decoration: const InputDecoration(labelText: 'Sector'),
              items: sectors
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: _district == null
                  ? null
                  : (v) => setState(() => _sector = v),
              validator: (v) => v == null ? 'Select a sector' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark / Street',
                hintText: 'e.g. Near MTN Centre, Remera',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Text(
              'Payment method',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _PaymentTile(
              title: 'MTN Mobile Money (MoMo)',
              subtitle: 'Test mode — tracking code issued immediately',
              icon: Icons.phone_android,
              selected: _payment == _PaymentMethod.mtnMomo,
              onTap: () => setState(() => _payment = _PaymentMethod.mtnMomo),
            ),
            const SizedBox(height: 8),
            _PaymentTile(
              title: 'Airtel Money',
              subtitle: 'Test mode — tracking code issued immediately',
              icon: Icons.smartphone,
              selected: _payment == _PaymentMethod.airtelMoney,
              onTap: () =>
                  setState(() => _payment = _PaymentMethod.airtelMoney),
            ),
            const SizedBox(height: 8),
            _PaymentTile(
              title: 'Visa / Bank Card',
              subtitle: 'Test mode — tracking code issued immediately',
              icon: Icons.credit_card,
              selected: _payment == _PaymentMethod.visaCard,
              onTap: () => setState(() => _payment = _PaymentMethod.visaCard),
            ),
          ],
        ),
      ),
    );

    final summary = _OrderSummary(
      cart: cart,
      placing: _placing,
      onPlaceOrder: () => _placeOrder(cart),
    );

    return isDesktop
        ? Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(primary: true, child: form),
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
                  child: form,
                ),
              ),
              summary,
            ],
          );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primaryOrange
                  : AppColors.borderSubtle,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primaryOrange : AppColors.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primaryOrange : AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.cart,
    required this.placing,
    required this.onPlaceOrder,
  });

  final CartState cart;
  final bool placing;
  final VoidCallback onPlaceOrder;

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
              ...cart.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.name} × ${item.quantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(formatRwf(item.lineTotal, suffix: true)),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  const Expanded(child: Text('Delivery')),
                  Text(
                    cart.deliveryFeeRwf == 0
                        ? 'FREE'
                        : formatRwf(cart.deliveryFeeRwf, suffix: true),
                  ),
                ],
              ),
              if (cart.discountRwf > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text('Promo (${cart.promoCode})')),
                    Text(
                      '- ${formatRwf(cart.discountRwf, suffix: true)}',
                      style: const TextStyle(color: AppColors.primaryOrange),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
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
                onPressed: placing ? null : onPlaceOrder,
                child: placing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'PAY NOW (${formatRwf(cart.grandTotalRwf, suffix: true)})',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

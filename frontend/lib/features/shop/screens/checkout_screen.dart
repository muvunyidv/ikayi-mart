import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/ikayi_api.dart';
import '../../../core/constants/rwanda_locations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/cart_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/navigation_state.dart';
import '../widgets/guest_tracking_modal.dart';

enum _PaymentMethod { mtnMomo, airtelMoney, visaCard }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
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
      setState(() {
        _district = nav.selectedDistrict;
        _sector = nav.selectedSector;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    try {
      final result = await api.guestCheckout(
        guestName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        district: _district!,
        sector: _sector!,
        landmark: _landmarkController.text.trim(),
        paymentMethod: _apiPaymentMethod,
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
      try {
        await api.initiatePayment(
          trackingCode: result.trackingCode,
          phone: result.phone,
          method: _apiPaymentMethod,
        );
      } catch (_) {
        // Order is already placed; payment prompt is best-effort.
      }
      if (!mounted) return;
      final totalLabel = formatRwf(result.totalAmountRwf, suffix: true);
      cart.clear();
      final catalog = context.read<CatalogState>();
      await catalog.load();
      if (!mounted) return;
      setState(() => _placing = false);
      await GuestTrackingModal.show(
        context,
        trackingCode: result.trackingCode,
        totalRwfLabel: totalLabel,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final sectors = _district == null
        ? <String>[]
        : RwandaLocations.sectorsFor(_district!);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('Your cart is empty'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue shopping'),
              ),
            ],
          ),
        ),
      );
    }

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CHECKOUT — Step 2 of 2',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Guest checkout — no account needed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondary,
                ),
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
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+250 7XX XXX XXX',
              helperText: 'Required for MoMo & SMS guest tracking',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Phone is required';
              if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                return 'Enter a valid Rwanda phone number';
              }
              return null;
            },
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
            subtitle: 'Pay with your MTN MoMo wallet',
            icon: Icons.phone_android,
            selected: _payment == _PaymentMethod.mtnMomo,
            onTap: () => setState(() => _payment = _PaymentMethod.mtnMomo),
          ),
          const SizedBox(height: 8),
          _PaymentTile(
            title: 'Airtel Money',
            subtitle: 'Pay with Airtel Money',
            icon: Icons.smartphone,
            selected: _payment == _PaymentMethod.airtelMoney,
            onTap: () => setState(() => _payment = _PaymentMethod.airtelMoney),
          ),
          const SizedBox(height: 8),
          _PaymentTile(
            title: 'Visa / Bank Card',
            subtitle: 'Debit or credit card',
            icon: Icons.credit_card,
            selected: _payment == _PaymentMethod.visaCard,
            onTap: () => setState(() => _payment = _PaymentMethod.visaCard),
          ),
        ],
      ),
    );

    final summary = _OrderSummary(
      cart: cart,
      placing: _placing,
      onPlaceOrder: () => _placeOrder(cart),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: ImigongoBackground(
        child: isDesktop
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(child: form),
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
                      padding: const EdgeInsets.all(16),
                      child: form,
                    ),
                  ),
                  summary,
                ],
              ),
      ),
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
                color: selected
                    ? AppColors.primaryOrange
                    : AppColors.secondary,
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
                color: selected
                    ? AppColors.primaryOrange
                    : AppColors.secondary,
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
                  Text(formatRwf(CartState.deliveryFeeRwf, suffix: true)),
                ],
              ),
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
                        'PLACE ORDER (TOTAL: ${formatRwf(cart.grandTotalRwf, suffix: true)})',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

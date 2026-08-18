import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/ikayi_api.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/scroll_to_top.dart';
import 'core/widgets/widgets.dart';
import 'features/shop/screens/landing_screen.dart';
import 'features/vendor/screens/inventory_screen.dart';
import 'features/vendor/screens/order_management_screen.dart';
import 'features/vendor/screens/vendor_dashboard_screen.dart';
import 'features/vendor/screens/vendor_login_screen.dart';
import 'features/vendor/widgets/vendor_sidebar.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';
import 'state/catalog_state.dart';
import 'state/navigation_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = IkayiApi();
  final auth = AuthState(api);
  final catalog = CatalogState(api);
  await auth.restore();
  runApp(
    IkayiMartApp(
      api: api,
      auth: auth,
      catalog: catalog,
    ),
  );
}

class IkayiMartApp extends StatelessWidget {
  const IkayiMartApp({
    super.key,
    required this.api,
    required this.auth,
    required this.catalog,
  });

  final IkayiApi api;
  final AuthState auth;
  final CatalogState catalog;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<IkayiApi>.value(value: api),
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<CatalogState>.value(value: catalog),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => NavigationState()),
      ],
      child: MaterialApp(
        title: 'IKAYI MART | E-Commerce & Business Marketplace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorObservers: [ScrollToTopObserver()],
        home: const AppShell(),
      ),
    );
  }
}

/// Responsive shell: consumer storefront or multi-vendor dashboard.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationState>();
    if (nav.mode == AppMode.shopper) {
      return const LandingScreen(key: ValueKey('mode-shopper'));
    }
    return const VendorShell(key: ValueKey('mode-vendor'));
  }
}

class VendorShell extends StatelessWidget {
  const VendorShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.restoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!auth.isLoggedIn) {
      return const VendorLoginScreen();
    }

    final nav = context.watch<NavigationState>();
    final user = auth.user!;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;

    Widget body = switch (nav.vendorSection) {
      VendorSection.dashboard => const VendorDashboardScreen(),
      VendorSection.inventory => const InventoryScreen(),
      VendorSection.orders => const OrderManagementScreen(),
      VendorSection.bmsSync => const _PlaceholderSection(
          title: 'BMS Sync',
          message:
              'SKU sync with your Business Management System is connected (mock).',
        ),
      VendorSection.support => const _PlaceholderSection(
          title: 'Support',
          message:
              'Guest support tickets appear under Order Management → Issue Reported.',
        ),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Vendor Central'),
              actions: [
                TextButton(
                  onPressed: () =>
                      context.read<NavigationState>().setMode(AppMode.shopper),
                  child: const Text('Shop'),
                ),
              ],
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: SafeArea(
                child: VendorSidebar(
                  selected: nav.vendorSection,
                  onSelect: (section) {
                    nav.setVendorSection(section);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            VendorSidebar(
              selected: nav.vendorSection,
              onSelect: nav.setVendorSection,
            ),
          Expanded(
            child: ImigongoBackground(
              child: Column(
                children: [
                  if (isDesktop)
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLowest,
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => context
                                .read<NavigationState>()
                                .setMode(AppMode.shopper),
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('Back to Storefront'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await context.read<AuthState>().logout();
                              if (context.mounted) {
                                context
                                    .read<NavigationState>()
                                    .setMode(AppMode.shopper);
                              }
                            },
                            child: const Text('Log out'),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryOrange,
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey(nav.vendorSection),
                      child: body,
                    ),
                  ),
                  const AppFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_outlined,
                  size: 40,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

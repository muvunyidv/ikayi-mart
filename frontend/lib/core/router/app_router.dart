import 'package:go_router/go_router.dart';

import '../../features/auth/screens/auth_screen.dart';
import '../../features/shop/screens/cart_screen.dart';
import '../../features/shop/screens/checkout_screen.dart';
import '../../features/shop/screens/landing_screen.dart';
import '../../features/shop/screens/my_orders_screen.dart';
import '../../features/shop/screens/order_success_screen.dart';
import '../../features/shop/screens/order_tracking_screen.dart';
import '../../features/shop/screens/product_detail_screen.dart';
import '../../features/shop/screens/shopper_shell.dart';
import '../../features/shop/screens/store_channel_screen.dart';
import '../../features/vendor/screens/vendor_shell.dart';
import '../utils/scroll_to_top.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    observers: [ScrollToTopObserver()],
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShopperShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LandingScreen(),
          ),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) => ProductDetailScreen(
              productId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/store/:slug',
            builder: (context, state) => StoreChannelScreen(
              slug: state.pathParameters['slug'] ?? '',
            ),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: '/order-success',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              return OrderSuccessScreen(
                orderId: q['orderId'] ?? '',
                trackingCode: q['code'] ?? '',
                email: q['email'] ?? '',
                totalRwfLabel: q['total'] ?? '',
              );
            },
          ),
          GoRoute(
            path: '/tracking',
            builder: (context, state) => OrderTrackingScreen(
              initialCode: state.uri.queryParameters['code'],
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const AuthScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const MyOrdersScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/vendor',
        builder: (context, state) => const VendorShell(),
      ),
    ],
  );
}

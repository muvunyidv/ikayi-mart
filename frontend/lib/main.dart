import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api/ikayi_api.dart';
import 'core/constants/branding.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/configure_url_strategy.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';
import 'state/catalog_state.dart';
import 'state/navigation_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  final api = IkayiApi();
  final auth = AuthState(api);
  final catalog = CatalogState(api);
  await auth.restore();
  runApp(IkayiMartApp(api: api, auth: auth, catalog: catalog));
}

class IkayiMartApp extends StatefulWidget {
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
  State<IkayiMartApp> createState() => _IkayiMartAppState();
}

class _IkayiMartAppState extends State<IkayiMartApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<IkayiApi>.value(value: widget.api),
        ChangeNotifierProvider<AuthState>.value(value: widget.auth),
        ChangeNotifierProvider<CatalogState>.value(value: widget.catalog),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => NavigationState()),
      ],
      child: MaterialApp.router(
        title: AppBranding.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}

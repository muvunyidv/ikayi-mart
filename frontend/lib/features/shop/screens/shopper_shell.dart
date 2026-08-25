import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/unclaimed_pointer_scroll.dart';
import '../../../core/widgets/widgets.dart';
import '../../../state/catalog_state.dart';
import '../../../state/navigation_state.dart';
import '../widgets/shop_header.dart';

/// Master storefront chrome: header and footer stay mounted across shop routes.
class ShopperShell extends StatefulWidget {
  const ShopperShell({super.key, required this.child});

  final Widget child;

  @override
  State<ShopperShell> createState() => _ShopperShellState();
}

class _ShopperShellState extends State<ShopperShell> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  NavigationState? _nav;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogState>().load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<NavigationState>();
    if (_nav != nav) {
      _nav?.removeListener(_syncSearchFromNav);
      _nav = nav;
      _nav!.addListener(_syncSearchFromNav);
      _syncSearchFromNav();
    }
  }

  void _syncSearchFromNav() {
    final query = _nav?.searchQuery ?? '';
    if (_searchController.text == query) return;
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  void dispose() {
    _nav?.removeListener(_syncSearchFromNav);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (PointerSignalEvent event) {
          handleUnclaimedPointerScroll(
            event,
            PrimaryScrollController.maybeOf(context),
          );
        },
        child: ImigongoBackground(
          child: SafeArea(
            child: Column(
              children: [
                ShopHeader(
                  isDesktop: isDesktop,
                  searchController: _searchController,
                  searchFocusNode: _searchFocus,
                ),
                Expanded(child: widget.child),
                const AppFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

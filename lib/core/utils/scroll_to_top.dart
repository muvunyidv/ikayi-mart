import 'package:flutter/material.dart';

/// Jumps the [PrimaryScrollController] (all attached positions) to the top.
void scrollAppToTop(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final primary = PrimaryScrollController.maybeOf(context);
    if (primary == null || !primary.hasClients) return;
    for (final position in primary.positions) {
      position.jumpTo(0);
    }
  });
}

/// Resets scroll to the top whenever routes are pushed, popped, or replaced.
class ScrollToTopObserver extends NavigatorObserver {
  void _reset() {
    final navContext = navigator?.context;
    if (navContext == null) return;
    scrollAppToTop(navContext);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _reset();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _reset();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _reset();
}

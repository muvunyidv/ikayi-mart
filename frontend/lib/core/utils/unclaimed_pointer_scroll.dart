import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Forwards a mouse-wheel [PointerScrollEvent] to [controller] only when no
/// descendant [Scrollable] claimed it. Hovering header, footer, sidebar, or
/// empty page background then scrolls the primary page view on Flutter Web.
void handleUnclaimedPointerScroll(
  PointerSignalEvent event,
  ScrollController? controller,
) {
  if (event is! PointerScrollEvent) return;
  if (controller == null || !controller.hasClients) return;

  GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
    if (resolved is! PointerScrollEvent) return;
    final delta = resolved.scrollDelta.dy;
    if (delta == 0) return;
    for (final position in controller.positions) {
      if (!position.hasPixels || !position.hasContentDimensions) continue;
      position.pointerScroll(delta);
    }
  });
}

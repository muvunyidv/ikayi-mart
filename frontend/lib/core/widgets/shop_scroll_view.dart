import 'package:flutter/material.dart';

/// Full-viewport primary scroller so mouse-wheel works over empty side padding.
class ShopScrollView extends StatelessWidget {
  const ShopScrollView({
    super.key,
    required this.child,
    this.padding,
    this.maxContentWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = child;
        if (maxContentWidth != null) {
          content = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth!),
              child: content,
            ),
          );
        }
        return SingleChildScrollView(
          primary: true,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: content,
          ),
        );
      },
    );
  }
}

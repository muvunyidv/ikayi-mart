import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Surface variants for the Imigongo-inspired zig-zag backdrop.
enum ImigongoVariant {
  /// Charcoal/white lines on dark sidebar-like surfaces.
  dark,

  /// Soft grey lines on page / panel backgrounds (default).
  light,

  /// Compact orange-tinted motif for selected nav rows.
  navActive,
}

/// Subtle Rwandan Imigongo-inspired geometric page/shell backdrop.
///
/// Matches the IKAYI BMS motif: continuous horizontal zigzag / chevron strokes
/// stacked so peaks of one row meet valleys of the next, forming a seamless
/// diamond mesh. Nested parallel zigzags add the inner-diamond imprint.
/// Painted with [CustomPainter] only — no assets (Flutter equivalent of an
/// inline SVG `data:image/svg+xml` CSS background).
class ImigongoBackground extends StatelessWidget {
  const ImigongoBackground({
    super.key,
    required this.child,
    this.variant = ImigongoVariant.light,
    this.backgroundColor,
    this.patternOpacity,
  });

  final Widget child;
  final ImigongoVariant variant;
  final Color? backgroundColor;
  final double? patternOpacity;

  Color get _resolvedBackground {
    if (backgroundColor != null) return backgroundColor!;
    return switch (variant) {
      ImigongoVariant.dark => AppColors.inverseSurface,
      ImigongoVariant.light => AppColors.surfaceBackground,
      ImigongoVariant.navActive => AppColors.primaryLight,
    };
  }

  double get _resolvedOpacity {
    if (patternOpacity != null) return patternOpacity!;
    return switch (variant) {
      ImigongoVariant.dark => 0.10,
      // Soft watermark: light grey stroke already near the ground color.
      ImigongoVariant.light => 0.85,
      ImigongoVariant.navActive => 0.18,
    };
  }

  Color get _strokeColor {
    return switch (variant) {
      ImigongoVariant.dark => Colors.white,
      // Matches reference soft grey (~#E2E8F0).
      ImigongoVariant.light => const Color(0xFFE2E8F0),
      ImigongoVariant.navActive => AppColors.primaryOrange,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _resolvedBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(
              painter: _ImigongoPainter(
                variant: variant,
                strokeColor: _strokeColor,
                primaryColor: AppColors.primaryOrange,
                patternOpacity: _resolvedOpacity,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ImigongoPainter extends CustomPainter {
  _ImigongoPainter({
    required this.variant,
    required this.strokeColor,
    required this.primaryColor,
    required this.patternOpacity,
  });

  final ImigongoVariant variant;
  final Color strokeColor;
  final Color primaryColor;
  final double patternOpacity;

  /// Peak-to-peak horizontal wavelength (BMS ~36–40px tile).
  static const double _periodX = 40;

  /// Full diamond height (two row-steps; peak-to-peak vertically).
  static const double _periodY = 40;

  /// Inset for the nested (inner) diamond outline.
  static const double _nest = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    if (variant == ImigongoVariant.navActive) {
      _paintNavActive(canvas, size);
      return;
    }

    _paintChevronMesh(canvas, size);
  }

  /// Continuous horizontal zigzags that tile into a diamond mesh.
  ///
  /// Rows are spaced by half the tile height so each row's valleys sit on the
  /// next row's peaks — seamless both axes (CSS SVG equivalent):
  ///
  /// ```
  /// M0 20 L20 0  L40 20 L60 0  L80 20   // row y = 0
  /// M0 40 L20 20 L40 40 L60 20 L80 40   // row y = 20
  /// ```
  void _paintChevronMesh(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.butt
      ..color = strokeColor.withValues(alpha: patternOpacity);

    final nestedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.butt
      ..color = strokeColor.withValues(alpha: patternOpacity * 0.85);

    final halfX = _periodX / 2;
    final halfY = _periodY / 2;

    _drawZigzagRows(
      canvas,
      size,
      halfX: halfX,
      halfY: halfY,
      rowStep: halfY,
      paint: paint,
    );

    // Second, slightly inset zigzag lattice → nested diamond imprint
    // (Imigongo double-outline), still seamless.
    final inset = _nest.toDouble();
    _drawZigzagRows(
      canvas,
      size,
      halfX: halfX - inset * 0.35,
      halfY: halfY - inset,
      rowStep: halfY,
      paint: nestedPaint,
      yOffset: inset,
      xOffset: inset * 0.35,
    );
  }

  void _drawZigzagRows(
    Canvas canvas,
    Size size, {
    required double halfX,
    required double halfY,
    required double rowStep,
    required Paint paint,
    double yOffset = 0,
    double xOffset = 0,
  }) {
    if (halfX <= 4 || halfY <= 4) return;

    for (double y = yOffset - halfY; y < size.height + halfY; y += rowStep) {
      canvas.drawPath(
        _horizontalZigzag(
          width: size.width,
          // Valley baseline; peaks sit [halfY] above.
          valleyY: y + halfY,
          halfX: halfX,
          amplitude: halfY,
          xOffset: xOffset,
        ),
        paint,
      );
    }
  }

  /// One continuous horizontal chevron: valley → peak → valley → peak → …
  ///
  /// Equivalent to `M0 V L halfX (V-A) L periodX V L …`
  Path _horizontalZigzag({
    required double width,
    required double valleyY,
    required double halfX,
    required double amplitude,
    double xOffset = 0,
  }) {
    final path = Path();
    final period = halfX * 2;
    var x = xOffset - period;
    path.moveTo(x, valleyY);

    while (x < width + period) {
      x += halfX;
      path.lineTo(x, valleyY - amplitude);
      x += halfX;
      path.lineTo(x, valleyY);
    }
    return path;
  }

  void _paintNavActive(Canvas canvas, Size size) {
    final fade = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        [
          primaryColor.withValues(alpha: 0.07),
          primaryColor.withValues(alpha: 0.02),
          primaryColor.withValues(alpha: 0.0),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(Offset.zero & size, fade);

    const zig = 14.0;
    final amplitude = (size.height * 0.28).clamp(4.0, 9.0).toDouble();
    final midY = size.height / 2;

    final mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.round
      ..color = strokeColor.withValues(alpha: patternOpacity);

    canvas.drawPath(_navZigPath(size.width, midY, amplitude, zig), mainPaint);

    final echoPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.round
      ..color = strokeColor.withValues(alpha: patternOpacity * 0.45);

    canvas.drawPath(
      _navZigPath(size.width, midY + 5, amplitude * 0.7, zig),
      echoPaint,
    );
  }

  Path _navZigPath(double width, double midY, double amplitude, double zig) {
    final path = Path();
    var x = -zig;
    var up = true;
    path.moveTo(x, midY);
    while (x < width + zig) {
      final nextX = x + zig;
      final midX = x + zig * 0.5;
      final tipY = midY + (up ? -amplitude : amplitude);
      path.lineTo(midX, tipY);
      path.lineTo(nextX, midY);
      up = !up;
      x = nextX;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _ImigongoPainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.patternOpacity != patternOpacity;
  }
}

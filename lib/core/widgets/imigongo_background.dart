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
/// Painted with native [CustomPainter] paths only — no assets or shaders.
/// Keep opacity low so enterprise UI stays readable.
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
      ImigongoVariant.dark => 0.09,
      ImigongoVariant.light => 0.07,
      ImigongoVariant.navActive => 0.18,
    };
  }

  Color get _strokeColor {
    return switch (variant) {
      ImigongoVariant.dark => Colors.white,
      ImigongoVariant.light => AppColors.onSurface,
      ImigongoVariant.navActive => AppColors.primaryOrange,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _resolvedBackground,
      child: CustomPaint(
        painter: _ImigongoPainter(
          variant: variant,
          strokeColor: _strokeColor,
          primaryColor: AppColors.primaryOrange,
          patternOpacity: _resolvedOpacity,
        ),
        child: child,
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

  static const double _bandHeight = 56;
  static const double _zigWidth = 28;
  static const double _inset = 18;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    if (variant == ImigongoVariant.navActive) {
      _paintNavActive(canvas, size);
      return;
    }

    _paintBands(canvas, size);
    if (variant == ImigongoVariant.light) {
      _paintAccentChevrons(canvas, size);
    }
  }

  void _paintBands(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.round
      ..color = strokeColor.withValues(alpha: patternOpacity);

    for (double y = 0; y < size.height + _bandHeight; y += _bandHeight) {
      final upper = Path();
      var x = -_zigWidth;
      var peak = true;
      upper.moveTo(x, y);
      while (x < size.width + _zigWidth) {
        final nextX = x + _zigWidth;
        final midX = x + _zigWidth * 0.5;
        final peakY = y;
        final troughY = y + _bandHeight * 0.35;
        if (peak) {
          upper.lineTo(midX, peakY);
          upper.lineTo(nextX, troughY);
        } else {
          upper.lineTo(midX, troughY);
          upper.lineTo(nextX, peakY);
        }
        peak = !peak;
        x = nextX;
      }
      canvas.drawPath(upper, paint);

      final lower = Path();
      x = -_zigWidth + _inset;
      peak = false;
      final troughY2 = y + _bandHeight * 0.62;
      final peakY2 = y + _bandHeight * 0.92;
      lower.moveTo(x, troughY2);
      while (x < size.width + _zigWidth) {
        final nextX = x + _zigWidth;
        final midX = x + _zigWidth * 0.5;
        if (peak) {
          lower.lineTo(midX, peakY2);
          lower.lineTo(nextX, troughY2);
        } else {
          lower.lineTo(midX, troughY2);
          lower.lineTo(nextX, peakY2);
        }
        peak = !peak;
        x = nextX;
      }
      canvas.drawPath(lower, paint);
    }
  }

  void _paintAccentChevrons(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeJoin = StrokeJoin.miter
      ..strokeCap = StrokeCap.round
      ..color = primaryColor.withValues(alpha: patternOpacity * 0.9);

    const step = 200.0;
    for (double x = 100; x < size.width; x += step) {
      final y18 = size.height * 0.18;
      final y26 = size.height * 0.26;
      final midY = (y18 + y26) / 2;
      final chevron = Path()
        ..moveTo(x - 8, midY - 6)
        ..lineTo(x, midY + 6)
        ..lineTo(x + 8, midY - 6);
      canvas.drawPath(chevron, paint);
    }
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
    final amplitude =
        (size.height * 0.28).clamp(4.0, 9.0).toDouble();
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

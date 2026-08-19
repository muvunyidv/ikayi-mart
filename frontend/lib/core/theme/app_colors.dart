import 'package:flutter/material.dart';

/// IKAYIMART color tokens — aligned with Stitch design system + brand orange.
abstract final class AppColors {
  // Brand / CTA (spec: #FF5722, Stitch CTA: #FF6600)
  static const Color primaryOrange = Color(0xFFFF5722);
  static const Color primaryContainer = Color(0xFFFF6600);
  static const Color primaryDeep = Color(0xFFA33E00);
  static const Color primaryLight = Color(0xFFFFE8DE);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF561D00);
  static const Color inversePrimary = Color(0xFFFFB596);

  // Surfaces
  static const Color surfaceBackground = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceBright = Color(0xFFF8F9FA);
  static const Color surfaceDim = Color(0xFFD9DADB);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceHigh = Color(0xFFE7E8E9);
  static const Color surfaceHighest = Color(0xFFE1E3E4);
  static const Color surfaceVariant = Color(0xFFE1E3E4);
  static const Color inputFill = Color(0xFFF1F3F5);
  static const Color borderSubtle = Color(0xFFE9ECEF);

  // Text / on-surface
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF5A4136);
  static const Color secondary = Color(0xFF5B5F63);
  static const Color secondaryDark = Color(0xFF212529);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDDE0E5);
  static const Color onSecondaryContainer = Color(0xFF5F6368);

  // Outline
  static const Color outline = Color(0xFF8E7164);
  static const Color outlineVariant = Color(0xFFE3BFB1);

  // Semantic
  static const Color tertiary = Color(0xFF005BC0);
  static const Color tertiaryContainer = Color(0xFF5895FF);
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFDC3545);

  // Inverse
  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFF0F1F2);

  // Shadows
  static const Color cardShadow = Color(0x0D000000); // ~5% black
  static const Color primaryShadow = Color(0x33FF6600); // ~20% orange
}

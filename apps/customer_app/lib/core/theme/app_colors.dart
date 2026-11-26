import 'package:flutter/material.dart';

/// Modern vivid Material 3 light palette (Indigo dominant + Sky Blue & Pink
/// sharp accents on clean `#FAFAFC` / `#F1F5F9` surfaces).
abstract final class AppColors {
  /// Vivid Indigo — dominant brand color.
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryDeep = Color(0xFF3730A3);
  static const Color primarySoft = Color(0xFFE0E7FF);
  static const Color primaryTint = Color(0xFFF5F7FF);

  /// Sharp Sky Blue & Pink accents (secondary / tertiary).
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color secondarySoft = Color(0xFFE0F2FE);
  static const Color tertiary = Color(0xFFEC4899);
  static const Color tertiarySoft = Color(0xFFFCE7F3);

  /// Warm Amber / Flame — food ratings, offers & delivery urgency.
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentWarm = Color(0xFFEA580C);
  static const Color accentDark = Color(0xFFB45309);
  static const Color accentSoft = Color(0xFFFEF3C7);
  static const Color accentTint = Color(0xFFFFFBEB);

  /// Dark Slate — crisp ink & muted copy.
  static const Color slate = Color(0xFF0F172A);
  static const Color slate60 = Color(0xFF475569);
  static const Color slate40 = Color(0xFF94A3B8);

  /// Clean white + container surfaces.
  static const Color background = Color(0xFFFAFAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color cardShadow = Color(0x0A000000);
  static const Color tealGlow = Color(0x244F46E5);

  /// Semantic status colors.
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSoft = Color(0xFFE0F2FE);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);

  /// Mobile wallet brand colors (checkout).
  static const Color bkash = Color(0xFFE2136E);
  static const Color nagad = Color(0xFFF6921E);
}

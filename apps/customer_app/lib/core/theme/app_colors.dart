import 'package:flutter/material.dart';

/// Brand palette from the finalized SRS §3 (UI/UX Design Document).
abstract final class AppColors {
  /// Deep Teal — primary brand color.
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primarySoft = Color(0xFFCCFBF1);

  /// Warm Food Amber — accent for offers, ratings and highlights.
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFB45309);
  static const Color accentSoft = Color(0xFFFEF3C7);

  /// Dark Slate — headings and body text.
  static const Color slate = Color(0xFF0F172A);
  static const Color slate60 = Color(0xFF475569);
  static const Color slate40 = Color(0xFF94A3B8);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);

  /// Mobile wallet brand colors (checkout).
  static const Color bkash = Color(0xFFE2136E);
  static const Color nagad = Color(0xFFF6921E);
}

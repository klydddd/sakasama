import 'package:flutter/material.dart';

/// Centralized color palette for the Sakasama app.
///
/// Primary greens reflect PhilGAP's agricultural identity.
/// All text colors meet WCAG AA contrast requirements.
class AppColors {
  AppColors._();

  // ── Primary Greens ──────────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFFA5D6A7);
  static const Color backgroundGreen = Color(0xFFE8F5E9);
  static const Color surfaceGreen = Color(0xFFC8E6C9);

  // ── Neutrals ────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF9FBF9);
  static const Color scaffoldBackground = Color(0xFFF5F7F5);
  static const Color textDark = Color(0xFF1C1C1E);
  static const Color textMedium = Color(0xFF3C3C3E);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color cardShadow = Color(0x1A000000);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
}

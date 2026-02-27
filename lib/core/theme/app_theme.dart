import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';

/// The Sakasama app theme — green, friendly, elderly-accessible.
///
/// Uses Nunito font, large touch targets, generous spacing,
/// and high-contrast colors for rural Filipino farmers.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.nunitoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ── Colors ────────────────────────────────────────────────────────
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        onPrimary: AppColors.white,
        secondary: AppColors.lightGreen,
        onSecondary: AppColors.darkGreen,
        surface: AppColors.white,
        onSurface: AppColors.textDark,
        error: AppColors.error,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,

      // ── Typography ────────────────────────────────────────────────────
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: AppDimensions.displaySize,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: AppDimensions.headingSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: AppDimensions.titleSize,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: AppDimensions.titleSize,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: AppDimensions.bodySize,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: AppDimensions.bodySize,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: AppDimensions.captionSize,
          fontWeight: FontWeight.w400,
          color: AppColors.textMedium,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: AppDimensions.buttonTextSize,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: AppDimensions.smallTextSize,
          fontWeight: FontWeight.w400,
          color: AppColors.textGrey,
        ),
      ),

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: AppDimensions.titleSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textDark,
          size: AppDimensions.iconSizeSmall,
        ),
      ),

      // ── ElevatedButton ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          minimumSize: const Size(
            double.infinity,
            AppDimensions.primaryButtonHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.cardPadding,
            vertical: AppDimensions.itemSpacing,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: AppDimensions.buttonTextSize,
            fontWeight: FontWeight.w700,
          ),
          elevation: 2,
          shadowColor: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          minimumSize: const Size(
            double.infinity,
            AppDimensions.secondaryButtonHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.cardPadding,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          side: const BorderSide(color: AppColors.primaryGreen, width: 2),
          textStyle: GoogleFonts.nunito(
            fontSize: AppDimensions.bodySize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: GoogleFonts.nunito(
            fontSize: AppDimensions.bodySize,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(48, AppDimensions.secondaryButtonHeight),
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: AppDimensions.smallSpacing,
        ),
      ),

      // ── InputDecoration ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.cardPadding,
          vertical: AppDimensions.cardPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.nunito(
          fontSize: AppDimensions.captionSize,
          color: AppColors.textGrey,
        ),
        hintStyle: GoogleFonts.nunito(
          fontSize: AppDimensions.captionSize,
          color: AppColors.textLight,
        ),
      ),

      // ── BottomNavigationBar ───────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textGrey,
        selectedIconTheme: const IconThemeData(
          size: AppDimensions.iconSizeMedium,
        ),
        unselectedIconTheme: const IconThemeData(
          size: AppDimensions.iconSizeSmall,
        ),
        selectedLabelStyle: GoogleFonts.nunito(
          fontSize: AppDimensions.smallTextSize,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: AppDimensions.smallTextSize,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── FloatingActionButton ──────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: CircleBorder(),
        largeSizeConstraints: BoxConstraints.tightFor(width: 64, height: 64),
      ),

      // ── Chip ──────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundGreen,
        selectedColor: AppColors.primaryGreen,
        labelStyle: GoogleFonts.nunito(
          fontSize: AppDimensions.captionSize,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: GoogleFonts.nunito(
          fontSize: AppDimensions.captionSize,
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

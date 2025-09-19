import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      dividerColor: Colors.grey[300], // Light theme divider
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(0xFF121212), // Dark scaffold background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E), // Dark app bar
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E1E1E), // Dark card background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A), // Dark input background
      ),
      dividerColor: const Color(0xFF424242), // Dark divider color
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E), // Dark bottom nav
      ),
    );
  }

  // Helper methods for theme-aware colors
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
  }

  // Text Colors
  static Color getTextColor(BuildContext context, {double opacity = 1.0}) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(opacity);
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color getDisabledTextColor(BuildContext context) {
    return Theme.of(context).disabledColor;
  }

  // Interactive Element Colors
  static Color getIconColor(BuildContext context, {double opacity = 1.0}) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(opacity);
  }

  static Color getSecondaryIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  // Subtle border for internal grid lines (lighter than main borders)
  static Color getSubtleBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.grey[700]!
        : Colors.grey[200]!;
  }

  static Color getInputBackgroundColor(BuildContext context) {
    return Theme.of(context).inputDecorationTheme.fillColor ??
           Theme.of(context).colorScheme.surface;
  }

  static Color getInputBorderColor(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  // Button Colors
  static Color getButtonColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getButtonTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  static Color getSecondaryButtonColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondaryContainer;
  }

  static Color getSecondaryButtonTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondaryContainer;
  }

  // Utility method for adaptive opacity
  static Color withAdaptiveOpacity(BuildContext context, Color color, double lightOpacity, double darkOpacity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return color.withOpacity(isDark ? darkOpacity : lightOpacity);
  }

  // Container decoration helper matching calendar card styling
  static BoxDecoration getCardDecoration(BuildContext context, {Color? color, double? elevation}) {
    return BoxDecoration(
      color: color ?? getCardColor(context),
      borderRadius: BorderRadius.circular(8), // Match calendar cards: 8px instead of 12px
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withOpacity(0.1),
          blurRadius: 4, // Match calendar cards
          offset: const Offset(0, 2), // Match calendar cards
          spreadRadius: 0, // Match calendar cards
        )
      ],
    );
  }
}
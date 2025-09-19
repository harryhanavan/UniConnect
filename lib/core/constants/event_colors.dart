import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Event color constants for consistent theming across the app
class EventColors {
  // Private constructor to prevent instantiation
  EventColors._();

  // Event Type Colors
  static const Color personal = Color(0xFF0D99FF);  // Blue
  static const Color society = Color(0xFF4CAF50);   // Green  
  static const Color social = Color(0xFF8BC34A);    // Lime Green
  static const Color academic = Color(0xFF2196F3);  // Academic Blue
  static const Color friends = Color(0xFFFF9800);   // Orange

  // Event Color Backgrounds (10% opacity)
  static const Color personalBackground = Color(0x190D99FF);
  static const Color societyBackground = Color(0x194CAF50);
  static const Color socialBackground = Color(0x198BC34A);
  static const Color academicBackground = Color(0x192196F3);
  static const Color friendsBackground = Color(0x19FF9800);

  // Text Colors - use theme-aware methods instead
  static Color getPrimaryTextColor(BuildContext context) => AppTheme.getTextColor(context);
  static Color getSecondaryTextColor(BuildContext context) => AppTheme.getSecondaryTextColor(context);
  static Color getTertiaryTextColor(BuildContext context) => AppTheme.getSecondaryTextColor(context);

  // Background Colors - use theme-aware methods instead
  static Color getCardBackgroundColor(BuildContext context) => AppTheme.getCardColor(context);
  static Color getSuggestionBackgroundColor(BuildContext context) => AppTheme.getInputBackgroundColor(context);

  // Shadow Color - use theme-aware method
  static Color getShadowColor(BuildContext context) => Theme.of(context).shadowColor.withOpacity(0.1);

  // Legacy constants for backward compatibility - deprecated
  @deprecated
  static const Color primaryText = Color(0xFF000000);
  @deprecated
  static const Color secondaryText = Color(0xFF9E9E9E);
  @deprecated
  static const Color tertiaryText = Color(0xFF795548);
  @deprecated
  static const Color cardBackground = Color(0xFFFFFFFF);
  @deprecated
  static const Color suggestionBackground = Color(0xFFFFF8E1);
  @deprecated
  static const Color shadowColor = Color(0x19000000);

  /// Get event color based on event source/type
  static Color getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'personal':
        return personal;
      case 'society':
      case 'societies':
        return society;
      case 'social':
      case 'friends':
        return social;
      case 'academic':
      case 'class':
      case 'classes':
        return academic;
      default:
        return personal;
    }
  }

  /// Get event background color based on event source/type
  static Color getEventBackgroundColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'personal':
        return personalBackground;
      case 'society':
      case 'societies':
        return societyBackground;
      case 'social':
      case 'friends':
        return socialBackground;
      case 'academic':
      case 'class':
      case 'classes':
        return academicBackground;
      default:
        return personalBackground;
    }
  }

  /// Get event type label for display
  static String getEventTypeLabel(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'personal':
        return 'PERSONAL';
      case 'society':
      case 'societies':
        return 'SOCIETY';
      case 'social':
      case 'friends':
        return 'SOCIAL';
      case 'academic':
      case 'class':
      case 'classes':
        return 'ACADEMIC';
      default:
        return 'PERSONAL';
    }
  }
}
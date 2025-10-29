import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors - Purple from Figma design
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF93BBFC);
  static const Color primaryDark = Color(0xFF1E40AF);
  
  // Secondary colors
  static const Color secondary = Color(0xFF6C757D);
  static const Color accent = Color(0xFF28A745);
  
  // UniConnect Five-Color System
  static const Color homeColor = Color(0xFF8B5CF6);       // Purple for home tab, primary actions
  static const Color personalColor = Color(0xFF0D99FF);   // Blue for personal events, timetables
  static const Color societyColor = Color(0xFF4CAF50);    // Green for society events, clubs
  static const Color socialColor = Color(0xFF31E615);     // Bright Green for social events, friends, campus map
  static const Color studyGroupColor = Color(0xFFFF7A00); // Orange for study groups, collaboration
  
  // UI colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF17A2B8);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFADB5BD);
  
  // Border colors
  static const Color border = Color(0xFFDEE2E6);
  static const Color borderLight = Color(0xFFF8F9FA);
  
  // Status colors
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF6C757D);
  static const Color away = Color(0xFFFFC107);
  static const Color busy = Color(0xFFEF4444);
  // Alias for study spots - use homeColor instead
  static const Color studyColor = homeColor; // Purple for study spots (same as home color)
  
  // Helper methods for temp style toggle support
  static Color getAdaptiveColor({
    required Color originalColor,
    required bool isTempStyleEnabled,
  }) {
    return isTempStyleEnabled ? primaryDark : originalColor;
  }

  static Color getAdaptiveHomeColor(bool isTempStyleEnabled) {
    return getAdaptiveColor(originalColor: homeColor, isTempStyleEnabled: isTempStyleEnabled);
  }

  static Color getAdaptiveSocietyColor(bool isTempStyleEnabled) {
    return getAdaptiveColor(originalColor: societyColor, isTempStyleEnabled: isTempStyleEnabled);
  }

  static Color getAdaptiveSocialColor(bool isTempStyleEnabled) {
    return getAdaptiveColor(originalColor: socialColor, isTempStyleEnabled: isTempStyleEnabled);
  }

  static Color getAdaptivePersonalColor(bool isTempStyleEnabled) {
    return getAdaptiveColor(originalColor: personalColor, isTempStyleEnabled: isTempStyleEnabled);
  }

  static Color getAdaptiveStudyGroupColor(bool isTempStyleEnabled) {
    return getAdaptiveColor(originalColor: studyGroupColor, isTempStyleEnabled: isTempStyleEnabled);
  }

  // Helper method to get color by event type
  static Color getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'personal':
      case 'timetable':
      case 'class_':
      case 'class':
        return personalColor;     // Personal palette - Blue
      case 'society':
        return societyColor;      // Societies palette - Green
      case 'social':
      case 'friend':
      case 'map':
        return socialColor;       // Social palette - Bright Green
      case 'study_group':
      case 'studygroup':
      case 'collaboration':
        return studyGroupColor;   // Study Groups palette - Orange
      case 'home':
      case 'main':
        return homeColor;         // Home palette - Purple
      default:
        return personalColor;     // Fallback - Blue
    }
  }
}
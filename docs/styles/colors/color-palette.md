# Color Palette

## Overview

This document defines the core color palette for UniConnect, establishing the primary, secondary, and accent colors used throughout the application.

## Primary Colors

### Main Brand Colors

| Color Name | Hex Code | Usage | Flutter Reference |
|------------|----------|-------|-------------------|
| Primary Blue | `#PLACEHOLDER` | Primary actions, headers | `AppColors.primary` |
| Primary Dark | `#PLACEHOLDER` | Dark theme primary | `AppColors.primaryDark` |
| Primary Light | `#PLACEHOLDER` | Light backgrounds, highlights | `AppColors.primaryLight` |

### Visual Reference
```
[PLACEHOLDER FOR COLOR SWATCHES]
```

## Secondary Colors

### Supporting Colors

| Color Name | Hex Code | Usage | Flutter Reference |
|------------|----------|-------|-------------------|
| Secondary Green | `#PLACEHOLDER` | Success states, confirmations | `AppColors.secondary` |
| Accent Orange | `#PLACEHOLDER` | Highlights, notifications | `AppColors.accent` |
| Tertiary Purple | `#PLACEHOLDER` | Special features, badges | `AppColors.tertiary` |

## Neutral Colors

### Text and Background Colors

| Color Name | Hex Code | Usage | Flutter Reference |
|------------|----------|-------|-------------------|
| Text Primary | `#PLACEHOLDER` | Main text content | `AppColors.textPrimary` |
| Text Secondary | `#PLACEHOLDER` | Secondary text, subtitles | `AppColors.textSecondary` |
| Text Light | `#PLACEHOLDER` | Light text on dark backgrounds | `AppColors.textLight` |
| Background | `#PLACEHOLDER` | Main background | `AppColors.background` |
| Surface | `#PLACEHOLDER` | Card backgrounds | `AppColors.surface` |
| Border | `#PLACEHOLDER` | Dividers, borders | `AppColors.border` |

## Color Implementation

### Flutter Constants
```dart
// lib/core/constants/app_colors.dart
class AppColors {
  // Primary Colors
  static const Color primary = Color(0x00000000); // PLACEHOLDER
  static const Color primaryDark = Color(0x00000000); // PLACEHOLDER
  static const Color primaryLight = Color(0x00000000); // PLACEHOLDER
  
  // Secondary Colors
  static const Color secondary = Color(0x00000000); // PLACEHOLDER
  static const Color accent = Color(0x00000000); // PLACEHOLDER
  static const Color tertiary = Color(0x00000000); // PLACEHOLDER
  
  // Neutral Colors
  static const Color textPrimary = Color(0x00000000); // PLACEHOLDER
  static const Color textSecondary = Color(0x00000000); // PLACEHOLDER
  static const Color textLight = Color(0x00000000); // PLACEHOLDER
  static const Color background = Color(0x00000000); // PLACEHOLDER
  static const Color surface = Color(0x00000000); // PLACEHOLDER
  static const Color border = Color(0x00000000); // PLACEHOLDER
}
```

### Theme Integration
```dart
// Usage in ThemeData
ThemeData(
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    background: AppColors.background,
  ),
)
```

## Accessibility Guidelines

### Contrast Ratios
- **Text on Background**: Minimum 4.5:1 ratio
- **Large Text**: Minimum 3:1 ratio
- **Interactive Elements**: Minimum 3:1 ratio

### Color Blindness Considerations
- Do not rely solely on color to convey information
- Use patterns, icons, or text alongside color coding
- Test with color blindness simulators

## Usage Examples

### Primary Color Usage
- App bars and headers
- Primary buttons and CTAs
- Active navigation indicators
- Progress bars and loading states

### Secondary Color Usage
- Success messages and confirmations
- Completed states
- Positive feedback indicators

### Accent Color Usage
- Notification badges
- Warning states
- Highlighting important information
- Interactive elements on hover/press

## Dark Theme Variations

| Light Theme Color | Dark Theme Equivalent | Notes |
|-------------------|----------------------|--------|
| `AppColors.primary` | `AppColors.primaryDark` | Adjusted for dark backgrounds |
| `AppColors.background` | `#PLACEHOLDER` | Dark background color |
| `AppColors.surface` | `#PLACEHOLDER` | Elevated surface color |
| `AppColors.textPrimary` | `AppColors.textLight` | Light text for dark backgrounds |

## Color Naming Convention

- Use descriptive names: `successGreen` not `green`
- Include context: `buttonPrimary` not just `primary`
- Indicate usage: `errorText` not `redText`
- Use semantic naming: `warningBackground` not `yellowLight`

## Testing and Validation

### Tools for Color Testing
- **WebAIM Contrast Checker** - Verify accessibility ratios
- **Stark (Figma Plugin)** - Check color blindness compatibility
- **Flutter Color Tool** - Generate Material color schemes

### Testing Checklist
- [ ] Colors work in both light and dark themes
- [ ] Sufficient contrast ratios maintained
- [ ] Colors are distinguishable for color blind users
- [ ] Brand consistency maintained
- [ ] Colors work across all platforms (iOS, Android, Web)

## Notes for Population

*When filling out this document:*
1. **Extract colors** from current `app_colors.dart` file
2. **Add visual swatches** using color preview tools
3. **Test contrast ratios** and document results
4. **Add screenshots** showing colors in context
5. **Verify dark theme** color mappings
6. **Update Flutter constants** if needed

---

*This template is ready to be populated with actual UniConnect color values.*
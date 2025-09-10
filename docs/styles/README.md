# Styles Documentation

## Overview

This section contains the visual design system and style guidelines for UniConnect. It serves as the single source of truth for all design decisions, color schemes, component styles, and visual patterns used throughout the application.

## Style Framework Structure

### 📊 [Colors](colors/)
- **[Color Palette](colors/color-palette.md)** - Primary, secondary, and accent colors
- **[Feature Colors](colors/feature-colors.md)** - Color schemes for specific features
- **[Semantic Colors](colors/semantic-colors.md)** - Status, success, error, warning colors
- **[Theme Colors](colors/theme-colors.md)** - Light and dark theme variations

### 🧩 [Components](components/)
- **[Buttons](components/buttons.md)** - Button styles and variations
- **[Cards](components/cards.md)** - Card layouts and styles
- **[Forms](components/forms.md)** - Input fields, forms, validation styles
- **[Navigation](components/navigation.md)** - Navigation patterns and styles
- **[Lists](components/lists.md)** - List items, tiles, and layouts
- **[Modals](components/modals.md)** - Dialog and modal styles

### 🎯 [Icons](icons/)
- **[Icon Library](icons/icon-library.md)** - Standard iconography
- **[Feature Icons](icons/feature-icons.md)** - Feature-specific icons
- **[Status Icons](icons/status-icons.md)** - Status and state indicators
- **[Custom Icons](icons/custom-icons.md)** - UniConnect custom icons

### 📱 [Layouts](layouts/)
- **[Screen Layouts](layouts/screen-layouts.md)** - Standard screen templates
- **[Grid System](layouts/grid-system.md)** - Spacing and grid guidelines
- **[Typography](layouts/typography.md)** - Font styles and hierarchy
- **[Responsive Design](layouts/responsive-design.md)** - Breakpoints and adaptations

## Feature-Specific Styles

### Academic Features
- **Calendar/Timetable** - Event styling, time blocks, calendar grid
- **Assignments** - Due date indicators, priority colors, status badges

### Social Features
- **Friends** - Online status indicators, profile layouts
- **Chat** - Message bubbles, typing indicators, timestamps
- **Societies** - Society cards, membership badges, category colors

### Location Features
- **Maps** - Markers, location pins, privacy indicators
- **Location Cards** - Building layouts, accessibility indicators

## Style Guidelines

### Design Principles
1. **Consistency** - Uniform patterns across features
2. **Accessibility** - WCAG compliant color contrasts and sizing
3. **Brand Alignment** - University/academic theme
4. **Responsive** - Works across all screen sizes
5. **Intuitive** - Clear visual hierarchy and affordances

### Documentation Format

Each style document should include:
- **Visual Examples** - Screenshots or mockups
- **Code Implementation** - Flutter/Dart code snippets
- **Usage Guidelines** - When and how to use
- **Variations** - Different states or contexts
- **Accessibility Notes** - Contrast ratios, touch targets
- **Related Styles** - Connected components or patterns

## Implementation Reference

### Flutter Theme Integration
```dart
// Reference to app theme structure
ThemeData(
  primarySwatch: // From color-palette.md
  colorScheme: // From theme-colors.md
  textTheme: // From typography.md
  // Component themes from components/
)
```

### Constants Location
- **App Colors**: `lib/core/constants/app_colors.dart`
- **App Theme**: `lib/core/constants/app_theme.dart`
- **Text Styles**: `lib/core/constants/text_styles.dart`

## Style Workflow

### Adding New Styles
1. **Document First** - Define styles in appropriate markdown file
2. **Implement** - Add to Flutter constants/theme
3. **Apply** - Use in components and screens
4. **Update Changes Stack** - Record style changes

### Updating Existing Styles
1. **Review Impact** - Check all usages
2. **Update Documentation** - Modify style guide
3. **Update Implementation** - Change Flutter code
4. **Test** - Verify across light/dark themes
5. **Record Changes** - Update changes stack

## Style Audit Checklist

When reviewing styles:
- [ ] Consistent with design system
- [ ] Accessible (contrast, sizing)
- [ ] Responsive across devices
- [ ] Works in light/dark themes
- [ ] Documented with examples
- [ ] Used consistently across app

## Tools and Resources

### Design Tools
- Figma (for mockups and design specs)
- Color contrast checkers
- Flutter Inspector (for implementation review)

### Reference Standards
- Material Design 3 Guidelines
- WCAG 2.1 Accessibility Guidelines
- University branding guidelines (if applicable)

## Maintenance

This style documentation should be:
- **Updated regularly** as styles evolve
- **Reviewed before releases** for consistency
- **Referenced during code reviews** for compliance
- **Used as onboarding material** for new developers

---

*This framework is ready to be populated with specific style definitions as the design system develops.*
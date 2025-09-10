# Typography

## Overview

This document defines the typography system for UniConnect, establishing consistent text styles, hierarchies, and formatting patterns across all features and platforms.

## Font Family

### Primary Font
**Google Fonts Integration**: Used throughout the application
```dart
// Current implementation
GoogleFonts.roboto() // PLACEHOLDER - Document actual font
```

### Font Stack Hierarchy
1. **Primary**: Custom Google Font (to be documented)
2. **Fallback 1**: System default (Roboto on Android, SF Pro on iOS)
3. **Fallback 2**: Sans-serif system font
4. **Monospace**: For code/technical content

## Text Style Hierarchy

### Headings

#### Display Styles (Hero Text)
| Style Name | Font Size | Weight | Line Height | Usage |
|------------|-----------|---------|-------------|-------|
| Display Large | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Welcome screens, hero sections |
| Display Medium | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Section titles, feature headers |
| Display Small | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Card titles, modal headers |

#### Headline Styles
| Style Name | Font Size | Weight | Line Height | Usage |
|------------|-----------|---------|-------------|-------|
| Headline Large | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Screen titles, page headers |
| Headline Medium | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Section headers, important content |
| Headline Small | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Subsection headers, card titles |

#### Title Styles
| Style Name | Font Size | Weight | Line Height | Usage |
|------------|-----------|---------|-------------|-------|
| Title Large | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | List headers, form sections |
| Title Medium | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Content titles, item names |
| Title Small | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Component titles, labels |

### Body Text

#### Body Styles
| Style Name | Font Size | Weight | Line Height | Usage |
|------------|-----------|---------|-------------|-------|
| Body Large | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Main content, descriptions |
| Body Medium | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Standard text, paragraphs |
| Body Small | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Captions, secondary info |

#### Label Styles
| Style Name | Font Size | Weight | Line Height | Usage |
|------------|-----------|---------|-------------|-------|
| Label Large | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Form labels, button text |
| Label Medium | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | UI labels, navigation |
| Label Small | `#PLACEHOLDER` | `#PLACEHOLDER` | `#PLACEHOLDER` | Tiny labels, badges |

## Feature-Specific Typography

### Calendar & Timetable
| Element | Text Style | Specs | Usage |
|---------|------------|-------|-------|
| Date Numbers | `#PLACEHOLDER` | Large, bold | Calendar grid dates |
| Day Names | `#PLACEHOLDER` | Small caps, medium | Weekday headers |
| Event Titles | `#PLACEHOLDER` | Medium, semibold | Event names |
| Event Times | `#PLACEHOLDER` | Small, regular | Time ranges |
| Event Details | `#PLACEHOLDER` | Small, light | Location, description |
| Current Day | `#PLACEHOLDER` | Bold, colored | Today's date |
| Month/Year | `#PLACEHOLDER` | Large, bold | Calendar header |

### Chat & Messages
| Element | Text Style | Specs | Usage |
|---------|------------|-------|-------|
| Message Text | `#PLACEHOLDER` | Medium, regular | Chat content |
| Sender Name | `#PLACEHOLDER` | Small, semibold | Message attribution |
| Timestamp | `#PLACEHOLDER` | Tiny, light | Message time |
| Status Text | `#PLACEHOLDER` | Tiny, italic | Delivered, read status |
| Chat Title | `#PLACEHOLDER` | Medium, semibold | Conversation header |
| Typing Indicator | `#PLACEHOLDER` | Small, italic | "User is typing..." |

### Friends & Profiles
| Element | Text Style | Specs | Usage |
|---------|------------|-------|-------|
| Name | `#PLACEHOLDER` | Medium, bold | User display names |
| Course/Year | `#PLACEHOLDER` | Small, regular | Academic info |
| Status Message | `#PLACEHOLDER` | Small, italic | Custom status |
| Last Seen | `#PLACEHOLDER` | Tiny, light | Activity timestamp |
| Mutual Friends | `#PLACEHOLDER` | Small, regular | Connection count |

### Societies & Clubs
| Element | Text Style | Specs | Usage |
|---------|------------|-------|-------|
| Society Name | `#PLACEHOLDER` | Medium, bold | Club names |
| Description | `#PLACEHOLDER` | Small, regular | Club descriptions |
| Member Count | `#PLACEHOLDER` | Tiny, medium | Membership info |
| Category Tags | `#PLACEHOLDER` | Tiny, bold | Club categories |
| Join Status | `#PLACEHOLDER` | Small, semibold | Membership status |

## Text Color Hierarchy

### Color Applications
| Text Type | Light Theme | Dark Theme | Usage |
|-----------|-------------|------------|-------|
| Primary Text | `#PLACEHOLDER` | `#PLACEHOLDER` | Main content, headers |
| Secondary Text | `#PLACEHOLDER` | `#PLACEHOLDER` | Supporting text, subtitles |
| Tertiary Text | `#PLACEHOLDER` | `#PLACEHOLDER` | Captions, metadata |
| Link Text | `#PLACEHOLDER` | `#PLACEHOLDER` | Interactive text, links |
| Error Text | `#PLACEHOLDER` | `#PLACEHOLDER` | Error messages, warnings |
| Success Text | `#PLACEHOLDER` | `#PLACEHOLDER` | Success messages, confirmations |
| Disabled Text | `#PLACEHOLDER` | `#PLACEHOLDER` | Inactive elements |

## Flutter Implementation

### Text Theme Integration
```dart
// Theme configuration
ThemeData(
  textTheme: TextTheme(
    // Display Styles
    displayLarge: GoogleFonts.roboto(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 1.12,
      letterSpacing: -0.25,
    ),
    
    // Headline Styles
    headlineLarge: GoogleFonts.roboto(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: 1.25,
    ),
    
    // Body Styles
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.15,
    ),
    
    // Label Styles
    labelLarge: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.1,
    ),
  ),
)
```

### Usage Examples
```dart
// Using theme text styles
Text(
  'Welcome to UniConnect',
  style: Theme.of(context).textTheme.headlineLarge,
)

// Custom styling with theme base
Text(
  'Event Title',
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    color: FeatureColors.calendarEvent,
    fontWeight: FontWeight.w600,
  ),
)

// Rich text with multiple styles
RichText(
  text: TextSpan(
    style: Theme.of(context).textTheme.bodyMedium,
    children: [
      TextSpan(text: 'Due: '),
      TextSpan(
        text: '2 hours',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
)
```

## Responsive Typography

### Scale Factors by Device
| Device Type | Scale Factor | Notes |
|-------------|--------------|-------|
| Phone | 1.0 | Base scale |
| Tablet | 1.1 | Slightly larger |
| Desktop | 1.2 | More readable on larger screens |
| Large Desktop | 1.3 | Comfortable viewing distance |

### Dynamic Type Support
```dart
// Responsive text sizing
double getScaleFactor(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth < 600) return 1.0;  // Phone
  if (screenWidth < 1024) return 1.1; // Tablet
  return 1.2; // Desktop
}

TextStyle responsiveStyle(BuildContext context, TextStyle base) {
  return base.copyWith(
    fontSize: base.fontSize! * getScaleFactor(context),
  );
}
```

## Accessibility Typography

### Readability Guidelines
- **Minimum font size**: 12dp for body text
- **Line height**: 1.4-1.6 for optimal readability
- **Contrast ratio**: Minimum 4.5:1 for normal text, 3:1 for large text
- **Line length**: 45-75 characters for optimal reading

### Accessibility Features
```dart
// Dynamic type support
Text(
  'Content',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: MediaQuery.of(context).textScaleFactor * 16,
  ),
)

// High contrast mode support
Text(
  'Important text',
  style: TextStyle(
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black,
    fontWeight: FontWeight.bold,
  ),
)
```

## Text Truncation & Overflow

### Overflow Handling
| Context | Strategy | Implementation |
|---------|----------|----------------|
| Single Line | Ellipsis | `overflow: TextOverflow.ellipsis` |
| Multiple Lines | Fade | `overflow: TextOverflow.fade` |
| Expandable | Show More | Custom expansion widget |
| Critical Info | Wrap | `softWrap: true` |

### Examples
```dart
// Single line with ellipsis
Text(
  'Very long title that might overflow',
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
)

// Multi-line with fade
Text(
  longDescription,
  overflow: TextOverflow.fade,
  maxLines: 3,
)

// Expandable text
ExpandableText(
  text: longContent,
  maxLines: 2,
  expandText: 'Read more',
  collapseText: 'Read less',
)
```

## Special Typography Cases

### Code and Technical Text
```dart
// Monospace font for technical content
Text(
  'user_id: 12345',
  style: TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    backgroundColor: Colors.grey[100],
  ),
)
```

### Internationalization Support
```dart
// Support for different languages
Text(
  localizedString,
  style: Theme.of(context).textTheme.bodyMedium,
  textDirection: Localizations.of(context).textDirection,
)
```

### Rich Text Formatting
```dart
// Formatted text with links and emphasis
RichText(
  text: TextSpan(
    style: Theme.of(context).textTheme.bodyMedium,
    children: [
      TextSpan(text: 'Join the '),
      TextSpan(
        text: 'Programming Society',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => navigateToSociety(),
      ),
      TextSpan(text: ' meeting today!'),
    ],
  ),
)
```

## Performance Considerations

### Font Loading
- Preload Google Fonts for better performance
- Fallback fonts for offline scenarios
- Font caching strategies

### Memory Optimization
- Reuse TextStyle objects
- Use theme styles instead of creating new styles
- Minimize rich text complexity

## Notes for Population

*When filling out this document:*
1. **Audit current text styles** across all screens
2. **Document Google Font usage** and configuration
3. **Measure font sizes** and spacing used in app
4. **Test text hierarchy** for visual clarity
5. **Verify accessibility compliance** with contrast tools
6. **Screenshot typography examples** from each feature
7. **Document theme integration** in Flutter code

---

*This framework provides comprehensive structure for documenting UniConnect's typography system.*
# Feature Colors

## Overview

This document defines color schemes and conventions for specific features within UniConnect. Each feature area has its own color language while maintaining consistency with the overall brand palette.

## Primary Color System

UniConnect uses a five-color system: one home/main color and four feature-specific palettes that are consistently applied throughout the app to maintain visual coherence and help users quickly identify content types.

### 🏠 Home/Main Palette (Purple)
| Element | Primary Color | Secondary Color | Usage | Implementation |
|---------|---------------|-----------------|-------|----------------|
| Home Tab | `#8B5CF6` (Purple) | `#8B5CF6` with opacity | Home navigation, primary actions | `AppColors.homeColor` |
| Main Actions | `#8B5CF6` | `#8B5CF6` with opacity | Primary buttons, key CTAs | `AppColors.homeColor` |
| App Branding | `#8B5CF6` | `#8B5CF6` with opacity | Logo, brand elements | `AppColors.homeColor` |
| Central Navigation | `#8B5CF6` | `#8B5CF6` with opacity | Main navigation highlights | `AppColors.homeColor` |

## Feature Color Palettes

### 📅 Personal Palette (Blue)
| Element | Primary Color | Secondary Color | Usage | Implementation |
|---------|---------------|-----------------|-------|----------------|
| Personal Events | `#0D99FF` (Blue) | `#0D99FF` with opacity | Personal appointments, timetables | `AppColors.personalColor` |
| Timetable Events | `#0D99FF` | `#0D99FF` with opacity | Personal schedule, calendar events | `AppColors.personalColor` |
| Personal Calendar | `#0D99FF` | `#0D99FF` with opacity | User's personal calendar entries | `AppColors.personalColor` |
| Profile Elements | `#0D99FF` | `#0D99FF` with opacity | User profiles, personal settings | `AppColors.personalColor` |

### 🏛️ Societies Palette (Green)
| Element | Primary Color | Secondary Color | Usage | Implementation |
|---------|---------------|-----------------|-------|----------------|
| Society Events | `#4CAF50` (Green) | `#4CAF50` with opacity | Club events in calendar | `AppColors.societyColor` |
| Society Cards | `#4CAF50` | `#4CAF50` with opacity | Society listings, details | `AppColors.societyColor` |
| Membership Status | `#4CAF50` | `#4CAF50` with opacity | Joined indicators, badges | `AppColors.societyColor` |
| Society Categories | `#4CAF50` | `#4CAF50` with opacity | Academic, Sports, Cultural tags | `AppColors.societyColor` |

### 👥 Social Palette (Bright Green)
| Element | Primary Color | Secondary Color | Usage | Implementation |
|---------|---------------|-----------------|-------|----------------|
| Social Events | `#R` (Bright Green) | `#31E615` with opacity | Friend meetups, social gatherings | `AppColors.socialColor` |
| Friend Activities | `#31E615` | `#31E615` with opacity | Friend status, activity feed | `AppColors.socialColor` |
| Chat Elements | `#31E615` | `#31E615` with opacity | Messages, conversations | `AppColors.socialColor` |
| Campus Map | `#31E615` | `#31E615` with opacity | Location features, map elements | `AppColors.socialColor` |
| Social Interactions | `#31E615` | `#31E615` with opacity | Friend connections, social features | `AppColors.socialColor` |

### 📚 Study Groups Palette (Orange)
| Element | Primary Color | Secondary Color | Usage | Implementation |
|---------|---------------|-----------------|-------|----------------|
| Study Groups | `#FF7A00` (Orange) | `#FF7A00` with opacity | Study group events, academic collaboration | `AppColors.studyGroupColor` |
| Academic Collaboration | `#FF7A00` | `#FF7A00` with opacity | Group study sessions, peer learning | `AppColors.studyGroupColor` |
| Study Group Cards | `#FF7A00` | `#FF7A00` with opacity | Study group listings, details | `AppColors.studyGroupColor` |
| Collaborative Learning | `#FF7A00` | `#FF7A00` with opacity | Group projects, study sessions | `AppColors.studyGroupColor` |

## Cross-Feature Color Application

### Calendar Event Colors
Events in the calendar use their respective feature palette:

| Event Type | Color Palette | Actual Color | Implementation |
|------------|---------------|---------------|----------------|
| Home Tab | Home Palette | `#8B5CF6` (Purple) | `AppColors.homeColor` |
| Primary Actions | Home Palette | `#8B5CF6` (Purple) | `AppColors.homeColor` |
| Personal Event | Personal Palette | `#0D99FF` (Blue) | `AppColors.personalColor` |
| Personal Timetable | Personal Palette | `#0D99FF` (Blue) | `AppColors.personalColor` |
| Society Event | Societies Palette | `#4CAF50` (Green) | `AppColors.societyColor` |
| Social/Friend Event | Social Palette | `#31E615` (Bright Green) | `AppColors.socialColor` |
| Campus Map Features | Social Palette | `#31E615` (Bright Green) | `AppColors.socialColor` |
| Study Group Event | Study Groups Palette | `#FF7A00` (Orange) | `AppColors.studyGroupColor` |
| Academic Collaboration | Study Groups Palette | `#FF7A00` (Orange) | `AppColors.studyGroupColor` |

### Navigation and UI Elements
Feature colors also extend to navigation and UI elements:

| UI Element | Home Color | Personal Color | Societies Color | Social Color | Study Groups Color | Usage Context |
|------------|-------------|----------------|-----------------|--------------|-------------------|---------------|
| Tab Indicators | `#8B5CF6` | `#0D99FF` | `#4CAF50` | `#31E615` | `#FF7A00` | Active tab highlighting |
| Progress Bars | `#8B5CF6` | `#0D99FF` | `#4CAF50` | `#31E615` | `#FF7A00` | Feature-specific progress |
| Badges | `#8B5CF6` | `#0D99FF` | `#4CAF50` | `#31E615` | `#FF7A00` | Notification counts, status |
| Icons | `#8B5CF6` | `#0D99FF` | `#4CAF50` | `#31E615` | `#FF7A00` | Feature-specific icons |

### 💬 Chat & Messages
| Element | Color | Usage | Implementation |
|---------|-------|-------|----------------|
| Sent Messages | `#PLACEHOLDER` | User's message bubbles | `FeatureColors.chatSent` |
| Received Messages | `#PLACEHOLDER` | Friend's message bubbles | `FeatureColors.chatReceived` |
| Unread Badge | `#PLACEHOLDER` | Unread message indicator | `FeatureColors.chatUnread` |
| Typing Indicator | `#PLACEHOLDER` | Someone is typing | `FeatureColors.chatTyping` |
| Online Status | `#PLACEHOLDER` | Friend is online | `FeatureColors.chatOnline` |
| Last Seen | `#PLACEHOLDER` | Last seen timestamp | `FeatureColors.chatLastSeen` |

### 👥 Friends & Social
| Element | Color | Usage | Implementation |
|---------|-------|-------|----------------|
| Online Status | `#PLACEHOLDER` | Friend is online | `FeatureColors.friendOnline` |
| Offline Status | `#PLACEHOLDER` | Friend is offline | `FeatureColors.friendOffline` |
| Busy Status | `#PLACEHOLDER` | Friend is busy | `FeatureColors.friendBusy` |
| In Class Status | `#PLACEHOLDER` | Friend is in class | `FeatureColors.friendInClass` |
| Friend Request | `#PLACEHOLDER` | Pending friend request | `FeatureColors.friendRequest` |
| Mutual Friends | `#PLACEHOLDER` | Mutual connection indicator | `FeatureColors.friendMutual` |

### 🏛️ Societies & Clubs
| Element | Color | Usage | Implementation |
|---------|-------|-------|----------------|
| Academic Societies | `#PLACEHOLDER` | Academic clubs | `FeatureColors.societyAcademic` |
| Sports Societies | `#PLACEHOLDER` | Sports clubs | `FeatureColors.societySports` |
| Cultural Societies | `#PLACEHOLDER` | Cultural groups | `FeatureColors.societyCultural` |
| Creative Societies | `#PLACEHOLDER` | Creative clubs | `FeatureColors.societyCreative` |
| Professional Societies | `#PLACEHOLDER` | Professional development | `FeatureColors.societyProfessional` |
| Joined Badge | `#PLACEHOLDER` | User is a member | `FeatureColors.societyJoined` |

### 📍 Location & Maps
| Element | Color | Usage | Implementation |
|---------|-------|-------|----------------|
| User Location | `#PLACEHOLDER` | Current user position | `FeatureColors.locationUser` |
| Friend Location | `#PLACEHOLDER` | Friend's position | `FeatureColors.locationFriend` |
| Building Marker | `#PLACEHOLDER` | University buildings | `FeatureColors.locationBuilding` |
| Study Space | `#PLACEHOLDER` | Available study areas | `FeatureColors.locationStudy` |
| Privacy Zone | `#PLACEHOLDER` | Hidden location areas | `FeatureColors.locationPrivate` |
| Navigation Path | `#PLACEHOLDER` | Route to destination | `FeatureColors.locationPath` |

## Status and State Colors

### User Status Colors
```dart
enum UserStatus {
  online,    // #PLACEHOLDER - Green
  offline,   // #PLACEHOLDER - Gray
  busy,      // #PLACEHOLDER - Red
  away,      // #PLACEHOLDER - Yellow
  inClass,   // #PLACEHOLDER - Blue
  studying   // #PLACEHOLDER - Purple
}
```

### Priority Colors
| Priority Level | Color | Usage |
|---------------|-------|-------|
| Critical | `#PLACEHOLDER` | Urgent assignments, important events |
| High | `#PLACEHOLDER` | Important but not urgent |
| Medium | `#PLACEHOLDER` | Standard priority |
| Low | `#PLACEHOLDER` | Optional or background tasks |

### Event Type Colors
| Event Type | Color | Description |
|------------|-------|-------------|
| Lecture | `#PLACEHOLDER` | Class lectures |
| Tutorial | `#PLACEHOLDER` | Tutorial sessions |
| Lab | `#PLACEHOLDER` | Laboratory sessions |
| Assignment | `#PLACEHOLDER` | Assignment due dates |
| Exam | `#PLACEHOLDER` | Examination periods |
| Society Meeting | `#PLACEHOLDER` | Club meetings |
| Social Event | `#PLACEHOLDER` | Social gatherings |
| Personal | `#PLACEHOLDER` | Personal appointments |

## Implementation Framework

### Updated Implementation (lib/core/constants/app_colors.dart)
```dart
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF3B82F6);        // App primary color
  static const Color primaryLight = Color(0xFF93BBFC);
  static const Color primaryDark = Color(0xFF1E40AF);
  
  // Home/Main color
  static const Color homeColor = Color(0xFF8B5CF6);       // Purple for home tab, primary actions
  
  // Feature-specific event colors (UPDATED COLORS)
  static const Color personalColor = Color(0xFF0D99FF);   // Blue for personal/timetable events
  static const Color societyColor = Color(0xFF4CAF50);    // Green for society events
  static const Color socialColor = Color(0xFF31E615);     // Bright Green for social/friend events & campus map
  static const Color studyGroupColor = Color(0xFFFF7A00); // Orange for study groups
  
  // Special use case aliases
  static const Color studyColor = homeColor;              // Purple for study spots (same as home)
  
  // Existing system colors remain
  // UI colors: background, surface, error, warning, success, danger, info
  // Text colors: textPrimary, textSecondary, textLight
  // Status colors: online, offline, away, busy
  // Border colors: border, borderLight
  
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
      default:
        return personalColor;     // Fallback - Blue
    }
  }
}
```

### Complete Color System
```dart
// UniConnect Five-Color System:
// 🏠 Home/Main: #8B5CF6 (Purple) - home tab, primary actions, app branding
// 📅 Personal: #0D99FF (Blue) - personal events, timetables, personal calendar
// 🏛️ Societies: #4CAF50 (Green) - society events, clubs, organizations  
// 👥 Social: #31E615 (Bright Green) - social events, friends, chat, campus map
// 📚 Study Groups: #FF7A00 (Orange) - study groups, academic collaboration
```
```

### Usage Examples
```dart
// Calendar event styling with feature colors
Container(
  decoration: BoxDecoration(
    color: FeatureColors.getFeatureColor(event.type),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(event.title),
)

// Feature-specific navigation indicator
Container(
  width: 4,
  height: 24,
  decoration: BoxDecoration(
    color: currentFeature == Feature.social 
        ? FeatureColors.socialPrimary
        : currentFeature == Feature.societies
        ? FeatureColors.societiesPrimary
        : FeatureColors.timePrimary,
    borderRadius: BorderRadius.circular(2),
  ),
)

// Feature badge with appropriate color
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: event.source == EventSource.societies 
        ? FeatureColors.societiesSecondary
        : event.source == EventSource.friends
        ? FeatureColors.socialSecondary
        : FeatureColors.timeSecondary,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    getEventTypeLabel(event.type),
    style: TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

## Color Psychology and Reasoning

### Academic Features (Blue Spectrum)
- **Blue**: Trust, reliability, academic focus
- **Light Blue**: Clarity, communication, accessibility
- **Navy**: Authority, professionalism, depth

### Social Features (Warm Spectrum)  
- **Green**: Online, available, positive interaction
- **Orange**: Notifications, attention, energy
- **Yellow**: Caution, away status, friendly warmth

### Location Features (Earth Tones)
- **Purple**: Privacy, security, special areas
- **Teal**: Navigation, movement, journey
- **Brown**: Buildings, physical spaces, stability

## Accessibility Considerations

### Color Coding Guidelines
- Never use color alone to convey information
- Always pair with icons, text, or patterns
- Maintain minimum contrast ratios
- Provide alternative indicators for color-blind users

### Testing Requirements
- [ ] Test with Protanopia (red-blind) simulation
- [ ] Test with Deuteranopia (green-blind) simulation  
- [ ] Test with Tritanopia (blue-blind) simulation
- [ ] Verify contrast ratios meet WCAG guidelines
- [ ] Test in different lighting conditions

## Future Color Extensions

### Planned Features
- **Study Groups**: Team collaboration colors
- **Achievements**: Gamification badge colors
- **Marketplace**: Buy/sell item categories
- **Events RSVP**: Response status indicators
- **Lost & Found**: Item category colors

### Color Scalability
- Reserve color families for future features
- Plan for seasonal or themed color variations
- Consider user customization options
- Maintain brand consistency as features grow

## Notes for Population

*When filling out this document:*
1. **Audit current feature implementations** for existing colors
2. **Screenshot feature areas** to identify color patterns  
3. **Map to Flutter constants** in the codebase
4. **Test color combinations** for accessibility
5. **Document the reasoning** behind color choices
6. **Plan for dark theme variations** of each color

---

*This framework provides structure for documenting feature-specific color schemes as they are defined.*
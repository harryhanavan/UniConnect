# Icon Library

## Overview

This document catalogs all icons used throughout UniConnect, establishing a consistent iconography system that enhances user experience and maintains visual coherence across all features.

## Icon Design Principles

### Consistency Guidelines
- **Style**: Maintain consistent stroke width and corner radius
- **Size**: Standard sizes for different contexts
- **Alignment**: Proper optical alignment in layouts
- **Recognition**: Use familiar, intuitive symbols
- **Accessibility**: Pair with text or labels when needed

### Icon Families

#### Primary Icon Set
**Source**: Material Design Icons (default Flutter icon set)
**Style**: Outlined (primary), Filled (emphasis), Rounded (friendly contexts)

#### Custom Icons
**Source**: Custom designed for UniConnect-specific features
**Style**: Matching Material Design principles
**Format**: SVG vector icons, Flutter IconData

## Core Navigation Icons

### Bottom Navigation
| Feature | Icon | Icon Name | Usage Context |
|---------|------|-----------|---------------|
| Home | 🏠 | `Icons.home` / `Icons.home_outlined` | Main dashboard, overview |
| Calendar | 📅 | `Icons.calendar_today` / `Icons.event` | Schedule, timetable, events |
| Chat | 💬 | `Icons.chat` / `Icons.chat_bubble_outline` | Messages, conversations |
| Societies | 🏛️ | `Icons.groups` / `Icons.school` | Clubs, organizations |
| Friends | 👥 | `Icons.people` / `Icons.person_add` | Social connections, profiles |

### Action Icons
| Action | Icon | Icon Name | Description |
|--------|------|-----------|-------------|
| Add | ➕ | `Icons.add` | Create new content |
| Search | 🔍 | `Icons.search` | Find, filter, discover |
| Settings | ⚙️ | `Icons.settings` | Preferences, configuration |
| Profile | 👤 | `Icons.account_circle` | User profile, avatar |
| Back | ⬅️ | `Icons.arrow_back` | Navigate backwards |
| More | ⋯ | `Icons.more_vert` / `Icons.more_horiz` | Additional options |
| Edit | ✏️ | `Icons.edit` | Modify, update content |
| Delete | 🗑️ | `Icons.delete` | Remove, discard |
| Share | 📤 | `Icons.share` | Share content externally |
| Save | 💾 | `Icons.bookmark` / `Icons.favorite` | Save for later |

## Feature-Specific Icons

### Calendar & Events
| Element | Icon | Icon Name | Context |
|---------|------|-----------|---------|
| Event | 📅 | `Icons.event` | Generic event marker |
| Class/Lecture | 📚 | `Icons.school` | Academic sessions |
| Assignment | 📝 | `Icons.assignment` | Homework, tasks |
| Exam | 📋 | `Icons.quiz` | Tests, assessments |
| Deadline | ⏰ | `Icons.schedule` | Time-sensitive items |
| All Day | 🌅 | `Icons.all_day` | Full day events |
| Recurring | 🔄 | `Icons.repeat` | Repeating events |
| Location | 📍 | `Icons.location_on` | Event location |
| Time | 🕒 | `Icons.access_time` | Event timing |
| Duration | ⏱️ | `Icons.timer` | Event length |

### Social & Communication
| Element | Icon | Icon Name | Context |
|---------|------|-----------|---------|
| Message | 💬 | `Icons.message` | Text conversations |
| Call | 📞 | `Icons.call` | Voice communication |
| Video Call | 📹 | `Icons.videocam` | Video communication |
| Friend Request | 👋 | `Icons.person_add` | Connection requests |
| Online Status | 🟢 | `Icons.circle` (green) | User availability |
| Offline Status | ⚪ | `Icons.circle` (gray) | User unavailable |
| Busy Status | 🔴 | `Icons.do_not_disturb` | User busy |
| Typing | ✍️ | `Icons.keyboard` | Someone typing |
| Read Receipt | ✓ | `Icons.done` | Message read |
| Unread | 📩 | `Icons.mark_unread_chat` | Unread messages |

### Location & Navigation
| Element | Icon | Icon Name | Context |
|---------|------|-----------|---------|
| My Location | 📍 | `Icons.my_location` | User's position |
| Building | 🏢 | `Icons.business` | Campus buildings |
| Room | 🚪 | `Icons.room` | Specific rooms |
| Library | 📚 | `Icons.local_library` | Study spaces |
| Cafeteria | 🍽️ | `Icons.restaurant` | Food areas |
| Lab | 🔬 | `Icons.science` | Laboratory spaces |
| Outdoor | 🌳 | `Icons.park` | Open areas |
| Accessible | ♿ | `Icons.accessible` | Accessibility features |
| WiFi | 📶 | `Icons.wifi` | Internet availability |
| Parking | 🅿️ | `Icons.local_parking` | Parking areas |

### Privacy & Security
| Element | Icon | Icon Name | Context |
|---------|------|-----------|---------|
| Privacy | 🔒 | `Icons.lock` | Privacy settings |
| Public | 🌐 | `Icons.public` | Public visibility |
| Friends Only | 👥 | `Icons.group` | Limited visibility |
| Hidden | 👁️ | `Icons.visibility_off` | Hidden content |
| Share Location | 📍 | `Icons.share_location` | Location sharing |
| Block | 🚫 | `Icons.block` | Blocked users |

## Status Indicators

### User Status Icons
| Status | Icon | Color | Animation |
|--------|------|-------|-----------|
| Online | 🟢 | Green | Solid circle |
| Away | 🟡 | Yellow | Solid circle |
| Busy | 🔴 | Red | Solid circle |
| Offline | ⚪ | Gray | Hollow circle |
| In Class | 📚 | Blue | Book icon |
| Studying | 📖 | Purple | Study icon |

### Notification Badges
| Type | Icon | Color | Usage |
|------|------|-------|-------|
| Unread Count | `●` | Red | Number overlay |
| New Content | `●` | Blue | Content indicator |
| Alert | `!` | Orange | Attention needed |
| Success | `✓` | Green | Completed action |
| Error | `✗` | Red | Failed action |

## Icon Sizing Standards

### Size Categories
| Context | Size (dp) | Usage |
|---------|-----------|-------|
| Large | 48 | Hero icons, empty states |
| Medium | 24 | Standard UI icons |
| Small | 16 | Inline icons, status |
| Tiny | 12 | Badges, micro-interactions |

### Platform Adjustments
| Platform | Adjustment | Notes |
|----------|------------|-------|
| iOS | +2dp | Slightly larger for iOS design |
| Android | Standard | Material Design sizes |
| Web | +1dp | Better visibility on screens |

## Icon Implementation

### Flutter Icon Usage
```dart
// Standard Material icon
Icon(
  Icons.home,
  size: 24,
  color: AppColors.primary,
)

// Icon with custom color and size
Icon(
  Icons.notification_important,
  size: 20,
  color: FeatureColors.notificationAlert,
)

// Icon button
IconButton(
  icon: Icon(Icons.search),
  onPressed: () => // Action
  iconSize: 24,
  color: Theme.of(context).iconTheme.color,
)
```

### Custom Icon Integration
```dart
// Custom SVG icon as IconData
class CustomIcons {
  static const IconData university = IconData(
    0xe900,
    fontFamily: 'UniConnect',
    fontPackage: null,
  );
}

// Usage
Icon(
  CustomIcons.university,
  size: 24,
  color: AppColors.primary,
)
```

## Icon Accessibility

### Screen Reader Support
```dart
// Icon with semantic label
Semantics(
  label: 'Add new event',
  child: IconButton(
    icon: Icon(Icons.add),
    onPressed: addEvent,
  ),
)

// Decorative icon (no semantic meaning)
ExcludeSemantics(
  child: Icon(Icons.star),
)
```

### High Contrast Mode
- Ensure icons remain visible in high contrast themes
- Use outlined versions for better visibility
- Maintain minimum contrast ratios

## Icon States

### Interactive States
| State | Visual Change | Implementation |
|-------|---------------|----------------|
| Default | Standard appearance | Base icon styling |
| Hover | Slight opacity change | `opacity: 0.8` |
| Pressed | Scale down slightly | `transform: scale(0.95)` |
| Disabled | Reduced opacity | `opacity: 0.4` |
| Selected | Different color/style | Active state color |

### Animation Guidelines
```dart
// Icon with scale animation on tap
AnimatedScale(
  scale: _isPressed ? 0.95 : 1.0,
  duration: Duration(milliseconds: 100),
  child: Icon(Icons.favorite),
)

// Rotating icon for loading states
RotationTransition(
  turns: _animationController,
  child: Icon(Icons.refresh),
)
```

## Icon Creation Guidelines

### Custom Icon Design
1. **Grid System**: Use 24x24dp grid
2. **Stroke Width**: 2dp for outlined icons
3. **Corner Radius**: 2dp for rounded corners
4. **Optical Balance**: Center icons visually, not mathematically
5. **Simplicity**: Keep designs simple and recognizable

### Icon Export
- **Format**: SVG (vector)
- **Size**: 24x24dp base size
- **Naming**: Descriptive, lowercase, underscores
- **Color**: Single color (usually black)
- **Optimization**: Remove unnecessary paths/groups

## Icon Audit Checklist

### Quality Check
- [ ] Icon is recognizable at all sizes
- [ ] Consistent style with icon family
- [ ] Accessible color contrast
- [ ] Proper semantic labeling
- [ ] Works in both light/dark themes
- [ ] Optimized file size
- [ ] Cross-platform compatibility

## Notes for Population

*When filling out this document:*
1. **Audit current icon usage** across all screens
2. **Screenshot icon collections** by feature area
3. **Document custom icons** and their creation process
4. **Test icon visibility** in different themes
5. **Verify accessibility** compliance
6. **Map to Flutter icon constants** in codebase

---

*This framework provides comprehensive structure for cataloging and maintaining the UniConnect icon system.*
# Timetable & Calendar Components

## Overview

This document defines the visual design and styling patterns for calendar and timetable components throughout UniConnect. These components are central to the academic experience and require clear, accessible, and intuitive design.

## Calendar Views

### Monthly Calendar View

#### Grid Structure
| Element | Style Properties | Description |
|---------|------------------|-------------|
| Calendar Grid | `#PLACEHOLDER` | Main calendar container styling |
| Day Headers | `#PLACEHOLDER` | Mon, Tue, Wed header styling |
| Date Cells | `#PLACEHOLDER` | Individual date cell styling |
| Today Highlight | `#PLACEHOLDER` | Current date emphasis |
| Other Month | `#PLACEHOLDER` | Previous/next month dates |
| Selected Date | `#PLACEHOLDER` | User-selected date styling |

#### Visual Examples
```
[PLACEHOLDER FOR CALENDAR GRID SCREENSHOT/MOCKUP]
```

#### Implementation Reference
```dart
// Calendar grid styling
Container(
  decoration: BoxDecoration(
    // Style properties to be documented
  ),
  child: GridView.count(
    crossAxisCount: 7,
    children: [
      // Date cells with styling
    ],
  ),
)
```

### Weekly Calendar View

#### Time Blocks
| Element | Style Properties | Description |
|---------|------------------|-------------|
| Time Column | `#PLACEHOLDER` | Left side time indicators |
| Day Columns | `#PLACEHOLDER` | Individual day columns |
| Hour Lines | `#PLACEHOLDER` | Horizontal hour dividers |
| Half-Hour Lines | `#PLACEHOLDER` | Subtle half-hour marks |
| Current Time | `#PLACEHOLDER` | Current time indicator line |
| Event Blocks | `#PLACEHOLDER` | Event representation styling |

### Daily Calendar View

#### Detailed Time Layout
| Element | Style Properties | Description |
|---------|------------------|-------------|
| Time Slots | `#PLACEHOLDER` | Granular time slot styling |
| All-Day Events | `#PLACEHOLDER` | Full-day event section |
| Event Details | `#PLACEHOLDER` | Expanded event information |
| Free Time | `#PLACEHOLDER` | Available time slot styling |

## Overlap Detection System

### Overview

UniConnect's timetable views implement intelligent overlap detection to handle simultaneous events with view-specific display strategies. The system automatically detects time conflicts and positions event chips for optimal visibility and usability.

### Overlap Detection Algorithm

The overlap detection system uses a comprehensive algorithm that:

1. **Time-based Detection**: Compares event start/end times to identify overlapping events
2. **Column Assignment**: Assigns overlapping events to display columns for side-by-side positioning
3. **View-specific Strategies**: Applies different display approaches based on calendar view constraints

#### Core Algorithm Implementation

```dart
/// Detects and calculates overlap information for events on the same day
Map<EventV2, Map<String, dynamic>> _calculateEventOverlaps(List<EventV2> dayEvents) {
  final Map<EventV2, Map<String, dynamic>> overlapInfo = {};
  
  // Initialize each event with no overlap
  for (final event in dayEvents) {
    overlapInfo[event] = {
      'columnIndex': 0,
      'totalColumns': 1,
      'overlappingEvents': <EventV2>[],
    };
  }
  
  // Sort events by start time for processing
  final sortedEvents = List<EventV2>.from(dayEvents);
  sortedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
  
  // Detect overlaps and assign columns
  for (int i = 0; i < sortedEvents.length; i++) {
    final eventA = sortedEvents[i];
    final overlappingEvents = <EventV2>[];
    
    for (int j = i + 1; j < sortedEvents.length; j++) {
      final eventB = sortedEvents[j];
      if (_eventsOverlap(eventA, eventB)) {
        overlappingEvents.add(eventB);
      }
    }
    
    if (overlappingEvents.isNotEmpty) {
      // Assign column positions for overlapping events
      final totalColumns = overlappingEvents.length + 1;
      overlapInfo[eventA]!['totalColumns'] = totalColumns;
      overlapInfo[eventA]!['overlappingEvents'] = overlappingEvents;
      
      for (int k = 0; k < overlappingEvents.length; k++) {
        overlapInfo[overlappingEvents[k]]!['columnIndex'] = k + 1;
        overlapInfo[overlappingEvents[k]]!['totalColumns'] = totalColumns;
      }
    }
  }
  
  return overlapInfo;
}

/// Check if two events overlap in time
bool _eventsOverlap(EventV2 eventA, EventV2 eventB) {
  return eventA.startTime.isBefore(eventB.endTime) && 
         eventB.startTime.isBefore(eventA.endTime);
}
```

### View-Specific Display Strategies

#### 3-Day View Overlap Handling

The 3-day view provides more horizontal space, enabling sophisticated overlap display:

**Two Overlapping Events**: Side-by-side positioning
```dart
// Side-by-side for 2 overlapping events using responsive width calculation
case CalendarView.threeDays:
  if (hasOverlap && totalColumns == 2) {
    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: height.clamp(40.0, double.infinity),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = (constraints.maxWidth / 2) - 1;
          final leftPosition = columnIndex * (columnWidth + 2);
          return Positioned(
            left: leftPosition,
            width: columnWidth,
            child: eventWidget,
          );
        },
      ),
    );
  }
```

**Three or More Events**: Cascade effect with transparency
```dart
// Cascade effect for 3+ overlapping events
else if (hasOverlap && totalColumns >= 3) {
  final opacity = 1.0 - (columnIndex * 0.15);
  final offset = columnIndex * 8.0;
  
  return Positioned(
    top: top + offset,
    left: 1 + offset,
    right: 1,
    height: height.clamp(40.0, double.infinity),
    child: Opacity(
      opacity: opacity.clamp(0.4, 1.0),
      child: eventWidget,
    ),
  );
}
```

#### Week View Overlap Handling

Week view has limited horizontal space, requiring a different approach:

**All Overlapping Events**: Full-width with transparency and offset
```dart
case CalendarView.week:
  if (hasOverlap) {
    final opacity = 1.0 - (columnIndex * 0.2);
    final offset = columnIndex * 4.0;
    
    return Positioned(
      top: top + offset,
      left: 1 + offset,
      right: 1,
      height: height.clamp(30.0, double.infinity),
      child: Opacity(
        opacity: opacity.clamp(0.3, 1.0),
        child: eventWidget,
      ),
    );
  }
```

### Responsive Width System

#### Previous Fixed Width Issues

The original system used fixed pixel widths that caused display problems:
- **3-Day View**: Fixed 61px width (appeared as ~50% of day width)  
- **Week View**: Fixed 43px width (appeared as ~75% of day width)
- **Type Tags**: Fixed 23px width caused text truncation

#### Current Responsive Solution

**Container Sizing**: Event chips now use responsive constraints
```dart
// Responsive width implementation
Container(
  // Height specified, width determined by parent constraints
  height: 123, // or 111 for week view
  // No width specified - allows responsive sizing
  child: Stack(
    children: [
      // Event content with flexible positioning
      Positioned(
        left: 6,
        top: 4,
        right: 6, // Right constraint enables responsive width
        child: SizedBox(
          height: 48,
          child: Text(event.title, /* styling */),
        ),
      ),
    ],
  ),
)
```

**Type Tag Improvements**: Content-based sizing with proper padding
```dart
// Responsive type tag implementation
Positioned(
  left: 6,
  top: 90,
  // No right constraint - sizes to content
  child: Container(
    height: 14,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: ShapeDecoration(
      color: eventBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Center(
      child: Text(
        eventLabel,
        style: TextStyle(
          fontSize: 7, // Improved from 6px
          fontWeight: FontWeight.w700,
          letterSpacing: 0.30, // Reduced from 0.50 for better fit
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
  ),
),
```

### Performance Considerations

#### Optimized Processing
- **Single Pass Algorithm**: Overlap detection processes each day's events once
- **Sorted Processing**: Events sorted by start time for efficient comparison
- **Column Reuse**: Column assignments reused across similar overlap patterns
- **Conditional Calculation**: Overlap detection only runs when multiple events exist

#### Memory Management
- **Temporary Maps**: Overlap information stored in temporary maps during processing
- **Garbage Collection**: Overlap data cleared after positioning calculations complete
- **Event Caching**: Processed events cached to avoid recalculation on minor updates

## Event Styling

### Event Colors by Feature Palette

UniConnect uses three main feature color palettes that are consistently applied to calendar events:

#### Personal Palette Events (Blue)
| Event Type | Background Color | Border Color | Text Color | Icon |
|------------|------------------|--------------|------------|------|
| Personal Event | `#0D99FF` (Blue) | `#0D99FF` (Blue) | White | 👤 |
| Timetable Entry | `#0D99FF` (Blue) | `#0D99FF` (Blue) | White | 📅 |
| Personal Calendar | `#0D99FF` (Blue) | `#0D99FF` (Blue) | White | 📋 |
| Class/Lecture | `#0D99FF` (Blue) | `#0D99FF` (Blue) | White | 📚 |
| Tutorial | `#0D99FF` (Blue) | `#0D99FF` (Blue) | White | 👥 |

#### Societies Palette Events (Green)
| Event Type | Background Color | Border Color | Text Color | Icon |
|------------|------------------|--------------|------------|------|
| Society Meeting | `#4CAF50` (Green) | `#4CAF50` (Green) | White | 🏛️ |
| Club Event | `#4CAF50` (Green) | `#4CAF50` (Green) | White | 🎭 |
| Society Social | `#4CAF50` (Green) | `#4CAF50` (Green) | White | 🎉 |
| Organization Activity | `#4CAF50` (Green) | `#4CAF50` (Green) | White | 🏢 |

#### Social Palette Events (Bright Green)
| Event Type | Background Color | Border Color | Text Color | Icon |
|------------|------------------|--------------|------------|------|
| Social Event | `#31E615` (Bright Green) | `#31E615` (Bright Green) | White | 🎉 |
| Friend Meetup | `#31E615` (Bright Green) | `#31E615` (Bright Green) | White | 👥 |
| Campus Map Event | `#31E615` (Bright Green) | `#31E615` (Bright Green) | White | 🗺️ |
| Social Gathering | `#31E615` (Bright Green) | `#31E615` (Bright Green) | White | 🤝 |

#### Study Groups Palette Events (Orange)
| Event Type | Background Color | Border Color | Text Color | Icon |
|------------|------------------|--------------|------------|------|
| Study Group | `#FF7A00` (Orange) | `#FF7A00` (Orange) | White | 📖 |
| Group Study Session | `#FF7A00` (Orange) | `#FF7A00` (Orange) | White | 📚 |
| Academic Collaboration | `#FF7A00` (Orange) | `#FF7A00` (Orange) | White | 🤝 |
| Peer Learning | `#FF7A00` (Orange) | `#FF7A00` (Orange) | White | 👥 |

### Event Block Structure

#### Standard Event Block
```dart
// Event block styling template with feature color system
Container(
  decoration: BoxDecoration(
    color: FeatureColors.getFeatureColor(event.type),
    borderRadius: BorderRadius.circular(8),
    border: Border.left(
      width: 4,
      color: _getFeatureAccentColor(event.type),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Event title
      Text(
        event.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white, // White text on colored background
        ),
      ),
      // Event details (time, location)
      Row(children: [
        Icon(Icons.access_time, size: 12, color: Colors.white70),
        Text(timeRange, style: TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(width: 8),
        Icon(Icons.location_on, size: 12, color: Colors.white70),
        Text(location, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    ],
  ),
)

// Helper method for accent colors
Color _getFeatureAccentColor(EventType eventType) {
  switch (eventType) {
    case EventType.personal:
    case EventType.friend:
      return FeatureColors.socialAccent;
    case EventType.society:
      return FeatureColors.societiesAccent;
    case EventType.class_:
    case EventType.assignment:
      return FeatureColors.timeAccent;
    default:
      return FeatureColors.socialAccent;
  }
}
```

#### Compact Event Block (for busy days)
```dart
// Condensed version for crowded schedules
Container(
  height: 24,
  decoration: BoxDecoration(
    color: // Subtle background
    borderRadius: BorderRadius.circular(4),
    border: Border.left(width: 3, color: // Category color),
  ),
  child: Row(
    children: [
      Text(event.title, overflow: TextOverflow.ellipsis),
      Spacer(),
      Text(duration, style: // Small text style),
    ],
  ),
)
```

## Time Display Patterns

### Time Formatting
| Context | Format | Example | Style |
|---------|--------|---------|-------|
| 24-hour | `HH:mm` | `14:30` | `#PLACEHOLDER` |
| 12-hour | `h:mm a` | `2:30 PM` | `#PLACEHOLDER` |
| Duration | `h'h' m'm'` | `1h 30m` | `#PLACEHOLDER` |
| Time Range | `HH:mm - HH:mm` | `14:30 - 16:00` | `#PLACEHOLDER` |

### Current Time Indicators
| Indicator Type | Style Properties | Usage |
|---------------|------------------|-------|
| Time Line | `#PLACEHOLDER` | Red line across weekly/daily view |
| Time Dot | `#PLACEHOLDER` | Circular indicator on time axis |
| Now Badge | `#PLACEHOLDER` | "Now" text label styling |

## Status Indicators

### Event Status
| Status | Visual Indicator | Description |
|--------|------------------|-------------|
| Confirmed | `#PLACEHOLDER` | Solid border, full opacity |
| Tentative | `#PLACEHOLDER` | Dashed border, reduced opacity |
| Cancelled | `#PLACEHOLDER` | Strikethrough text, gray overlay |
| Completed | `#PLACEHOLDER` | Checkmark icon, muted colors |
| In Progress | `#PLACEHOLDER` | Pulse animation, bright colors |

### Attendance Status
| Status | Icon | Color | Description |
|--------|------|-------|-------------|
| Attending | ✅ | `#PLACEHOLDER` | User confirmed attendance |
| Maybe | ❓ | `#PLACEHOLDER` | Uncertain attendance |
| Not Attending | ❌ | `#PLACEHOLDER` | User declined |
| Not Responded | ⭕ | `#PLACEHOLDER` | No response yet |

## Responsive Design

### Screen Size Adaptations

#### Mobile (< 600px)
- Single column layout
- Larger touch targets (minimum 44px)
- Simplified event display
- Swipe navigation between views

#### Tablet (600px - 1024px)
- Two column layout for weekly view
- Medium-sized event blocks
- Side panel for event details
- Touch-friendly navigation

#### Desktop (> 1024px)
- Full weekly/monthly grid view
- Detailed event information
- Hover states and tooltips
- Mouse-optimized interactions

## Accessibility Features

### Color and Contrast
- Minimum 4.5:1 contrast ratio for text
- Color coding paired with icons/patterns
- High contrast mode support
- Colorblind-friendly palette

### Navigation and Interaction
- Keyboard navigation support
- Screen reader compatible
- Focus indicators
- Voice-over descriptions

### Text and Typography
- Scalable font sizes
- Clear hierarchy
- Readable font choices
- RTL language support

## Animation and Transitions

### View Transitions
| Transition | Duration | Easing | Description |
|------------|----------|--------|-------------|
| Month Change | `300ms` | `ease-in-out` | Slide transition between months |
| View Switch | `250ms` | `ease-out` | Fade between calendar views |
| Event Expand | `200ms` | `ease-out` | Event detail expansion |
| Scroll | `150ms` | `linear` | Smooth scrolling in time views |

### Micro-interactions
- Event hover effects
- Button press feedback
- Loading state animations
- Success/error confirmations

## Empty States

### No Events
```dart
// Empty calendar day styling
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(
      Icons.event_available,
      size: 48,
      color: // Muted color
    ),
    SizedBox(height: 16),
    Text(
      'No events today',
      style: // Muted text style
    ),
    TextButton(
      onPressed: // Add event action
      child: Text('Add Event'),
    ),
  ],
)
```

### Loading States
- Skeleton screens for calendar grid
- Shimmer effects for event blocks
- Progress indicators for data loading

## Implementation Notes

### Performance Considerations
- Virtualized scrolling for large date ranges
- Lazy loading of event details
- Cached event data
- Optimized re-renders

### Platform Considerations
- iOS-style date pickers on iOS
- Material design on Android
- Web-optimized interactions
- Consistent cross-platform styling

## Notes for Population

*When filling out this document:*
1. **Screenshot current calendar views** to document existing styles
2. **Identify color values** used for different event types
3. **Document component hierarchy** and styling patterns
4. **Test accessibility features** and document compliance
5. **Capture animation details** and transition specifications
6. **Note platform differences** in calendar styling

---

*This framework provides comprehensive structure for documenting all timetable and calendar styling patterns.*
import 'package:flutter/material.dart';
import '../../shared/models/event.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';

/// Enhanced event display properties for Phase 2
/// Supports both legacy and v2 event models with rich display options
class EventDisplayProperties {
  final String primaryLabel;
  final String categoryLabel;
  final String? subTypeLabel;
  final String? relationshipBadge;
  final Color primaryColor;
  final Color backgroundColor;
  final IconData categoryIcon;
  final IconData? privacyIcon;
  final String colorKey;
  final int displayPriority;
  final List<BadgeInfo> badges;

  const EventDisplayProperties({
    required this.primaryLabel,
    required this.categoryLabel,
    this.subTypeLabel,
    this.relationshipBadge,
    required this.primaryColor,
    required this.backgroundColor,
    required this.categoryIcon,
    this.privacyIcon,
    required this.colorKey,
    required this.displayPriority,
    this.badges = const [],
  });

  /// Get display properties from EventV2 model
  static EventDisplayProperties fromEventV2(EventV2 event, String currentUserId) {
    final category = event.category;
    final subType = event.subType;
    final relationship = event.getUserRelationship(currentUserId);
    
    // Get category colors and icons
    final categoryProps = _getCategoryProperties(category);
    
    // Get relationship badge
    final relationshipBadge = _getRelationshipBadge(relationship);
    
    // Get privacy icon
    final privacyIcon = _getPrivacyIcon(event.privacyLevel);
    
    // Build badges list
    final badges = <BadgeInfo>[];
    
    if (event.isRecurring) {
      badges.add(BadgeInfo(
        icon: Icons.repeat,
        label: 'Recurring',
        color: Colors.orange,
      ));
    }
    
    if (event.origin == EventOrigin.aiSuggested) {
      badges.add(BadgeInfo(
        icon: Icons.auto_awesome,
        label: 'Suggested',
        color: Colors.purple,
      ));
    }
    
    if (event.attendeeIds.length > 5) {
      badges.add(BadgeInfo(
        icon: Icons.groups,
        label: '${event.attendeeIds.length}+',
        color: Colors.blue,
      ));
    }
    
    // Calculate display priority
    int priority = 0;
    if (relationship == EventRelationship.owner) priority += 10;
    if (relationship == EventRelationship.organizer) priority += 8;
    if (relationship == EventRelationship.attendee) priority += 5;
    if (category == EventCategory.academic) priority += 3;
    if (subType == EventSubType.exam) priority += 5;
    if (subType == EventSubType.assignment) priority += 4;
    
    return EventDisplayProperties(
      primaryLabel: EventTypeHelper.getSubTypeDisplayName(subType),
      categoryLabel: _getCategoryLabel(category),
      subTypeLabel: EventTypeHelper.getSubTypeDisplayName(subType),
      relationshipBadge: relationshipBadge,
      primaryColor: categoryProps.color,
      backgroundColor: categoryProps.backgroundColor,
      categoryIcon: categoryProps.icon,
      privacyIcon: privacyIcon,
      colorKey: category.toString().split('.').last,
      displayPriority: priority,
      badges: badges,
    );
  }
  
  /// Get display properties from legacy Event model (backward compatibility)
  static EventDisplayProperties fromLegacyEvent(Event event, String currentUserId) {
    final eventV2 = EventV2.fromLegacyEvent(event);
    return fromEventV2(eventV2, currentUserId);
  }
  
  /// Legacy method for Phase 1 compatibility - simplified display properties
  static EventDisplayProperties fromEvent(Event event) {
    switch (event.type) {
      case EventType.class_:
        return EventDisplayProperties(
          primaryLabel: 'Class',
          categoryLabel: 'ACADEMIC',
          primaryColor: const Color(0xFF2196F3),
          backgroundColor: const Color(0x192196F3),
          categoryIcon: Icons.school,
          colorKey: 'academic',
          displayPriority: 3,
        );
      
      case EventType.assignment:
        return EventDisplayProperties(
          primaryLabel: 'Assignment',
          categoryLabel: 'ACADEMIC',
          primaryColor: const Color(0xFF2196F3),
          backgroundColor: const Color(0x192196F3),
          categoryIcon: Icons.assignment,
          colorKey: 'academic',
          displayPriority: 4,
        );
      
      case EventType.society:
        return EventDisplayProperties(
          primaryLabel: 'Society',
          categoryLabel: 'SOCIETY',
          primaryColor: const Color(0xFF4CAF50),
          backgroundColor: const Color(0x194CAF50),
          categoryIcon: Icons.groups,
          colorKey: 'society',
          displayPriority: 2,
        );
      
      case EventType.personal:
        // Check if it's a social event based on attendees and source
        if (event.attendeeIds.isNotEmpty && event.source == EventSource.friends) {
          return EventDisplayProperties(
            primaryLabel: 'Social',
            categoryLabel: 'SOCIAL',
            primaryColor: const Color(0xFF8BC34A),
            backgroundColor: const Color(0x198BC34A),
            categoryIcon: Icons.people,
            colorKey: 'social',
            displayPriority: 2,
          );
        }
        return EventDisplayProperties(
          primaryLabel: 'Personal',
          categoryLabel: 'PERSONAL',
          primaryColor: const Color(0xFF0D99FF),
          backgroundColor: const Color(0x190D99FF),
          categoryIcon: Icons.person,
          colorKey: 'personal',
          displayPriority: 1,
        );
    }
  }

  /// Get relationship badge for additional context (backward compatibility)
  static String? getRelationshipBadge(Event event, String currentUserId) {
    if (event.creatorId == currentUserId) {
      return 'Organizer';
    } else if (event.attendeeIds.contains(currentUserId)) {
      return 'Attending';
    } else if (event.source == EventSource.shared) {
      return 'Invited';
    }
    return null;
  }

  /// Get source context for filtering (maintains backward compatibility)
  static EventSource getEventSource(Event event, String currentUserId) {
    return event.source;
  }

  /// Determine if event should show in specific view
  static bool shouldShowInView(Event event, EventSource filterSource) {
    if (filterSource == EventSource.shared) {
      return true;
    }
    return event.source == filterSource;
  }

  /// Get priority for display ordering (legacy version)
  static int getDisplayPriority(Event event, String currentUserId) {
    if (event.type == EventType.assignment) return 4;
    if (event.type == EventType.class_) return 3;
    if (event.creatorId == currentUserId) return 2;
    if (event.attendeeIds.contains(currentUserId)) return 1;
    return 0;
  }
  
  /// Get category display properties
  static _CategoryProperties _getCategoryProperties(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return _CategoryProperties(
          color: const Color(0xFF2196F3),
          backgroundColor: const Color(0x192196F3),
          icon: Icons.school,
        );
      case EventCategory.social:
        return _CategoryProperties(
          color: const Color(0xFF8BC34A),
          backgroundColor: const Color(0x198BC34A),
          icon: Icons.people,
        );
      case EventCategory.society:
        return _CategoryProperties(
          color: const Color(0xFF4CAF50),
          backgroundColor: const Color(0x194CAF50),
          icon: Icons.groups,
        );
      case EventCategory.personal:
        return _CategoryProperties(
          color: const Color(0xFF0D99FF),
          backgroundColor: const Color(0x190D99FF),
          icon: Icons.person,
        );
      case EventCategory.university:
        return _CategoryProperties(
          color: const Color(0xFF9C27B0),
          backgroundColor: const Color(0x199C27B0),
          icon: Icons.account_balance,
        );
    }
  }
  
  /// Get category label for display
  static String _getCategoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'ACADEMIC';
      case EventCategory.social:
        return 'SOCIAL';
      case EventCategory.society:
        return 'SOCIETY';
      case EventCategory.personal:
        return 'PERSONAL';
      case EventCategory.university:
        return 'UNIVERSITY';
    }
  }
  
  /// Get relationship badge text
  static String? _getRelationshipBadge(EventRelationship relationship) {
    switch (relationship) {
      case EventRelationship.owner:
        return 'Organizer';
      case EventRelationship.organizer:
        return 'Co-organizer';
      case EventRelationship.attendee:
        return 'Attending';
      case EventRelationship.invited:
        return 'Invited';
      case EventRelationship.interested:
        return 'Interested';
      case EventRelationship.observer:
      case EventRelationship.none:
        return null;
    }
  }
  
  /// Get privacy icon based on privacy level
  static IconData? _getPrivacyIcon(EventPrivacyLevel privacy) {
    switch (privacy) {
      case EventPrivacyLevel.public:
        return Icons.public;
      case EventPrivacyLevel.university:
        return Icons.school;
      case EventPrivacyLevel.faculty:
        return Icons.class_;
      case EventPrivacyLevel.societyOnly:
        return Icons.group_work;
      case EventPrivacyLevel.friendsOnly:
        return Icons.group;
      case EventPrivacyLevel.friendsOfFriends:
        return Icons.people_outline;
      case EventPrivacyLevel.inviteOnly:
        return Icons.lock_outline;
      case EventPrivacyLevel.private:
        return Icons.lock;
    }
  }
}

/// Helper class for category properties
class _CategoryProperties {
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  
  const _CategoryProperties({
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });
}

/// Badge information for event display
class BadgeInfo {
  final IconData icon;
  final String label;
  final Color color;
  
  const BadgeInfo({
    required this.icon,
    required this.label,
    required this.color,
  });
}
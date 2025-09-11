import 'package:flutter/material.dart';
import '../../shared/models/event.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';

/// Enhanced event display properties for Phase 2
/// Supports both legacy and v2 event models with rich display options
class EventDisplayPropertiesV2 {
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

  const EventDisplayPropertiesV2({
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
  static EventDisplayPropertiesV2 fromEventV2(EventV2 event, String currentUserId) {
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
    
    return EventDisplayPropertiesV2(
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
  static EventDisplayPropertiesV2 fromLegacyEvent(Event event, String currentUserId) {
    final eventV2 = EventV2.fromLegacyEvent(event);
    return fromEventV2(eventV2, currentUserId);
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
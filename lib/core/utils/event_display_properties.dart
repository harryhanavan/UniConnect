import 'package:flutter/material.dart';
import '../../shared/models/event.dart';
import '../constants/app_colors.dart';

/// Unified event display properties for consistent rendering across the app
class EventDisplayProperties {
  final String primaryLabel;
  final String categoryLabel;
  final Color primaryColor;
  final Color backgroundColor;
  final IconData icon;
  final String colorKey;

  const EventDisplayProperties({
    required this.primaryLabel,
    required this.categoryLabel,
    required this.primaryColor,
    required this.backgroundColor,
    required this.icon,
    required this.colorKey,
  });

  /// Get display properties based on event type (Phase 1 implementation)
  static EventDisplayProperties fromEvent(Event event) {
    switch (event.type) {
      case EventType.class_:
        return EventDisplayProperties(
          primaryLabel: 'Class',
          categoryLabel: 'ACADEMIC',
          primaryColor: const Color(0xFF2196F3),
          backgroundColor: const Color(0x192196F3),
          icon: Icons.school,
          colorKey: 'academic',
        );
      
      case EventType.assignment:
        return EventDisplayProperties(
          primaryLabel: 'Assignment',
          categoryLabel: 'ACADEMIC',
          primaryColor: const Color(0xFF2196F3),
          backgroundColor: const Color(0x192196F3),
          icon: Icons.assignment,
          colorKey: 'academic',
        );
      
      case EventType.society:
        return EventDisplayProperties(
          primaryLabel: 'Society',
          categoryLabel: 'SOCIETY',
          primaryColor: const Color(0xFF4CAF50),
          backgroundColor: const Color(0x194CAF50),
          icon: Icons.groups,
          colorKey: 'society',
        );
      
      case EventType.personal:
        // Check if it's a social event based on attendees and source
        if (event.attendeeIds.isNotEmpty && event.source == EventSource.friends) {
          return EventDisplayProperties(
            primaryLabel: 'Social',
            categoryLabel: 'SOCIAL',
            primaryColor: const Color(0xFF8BC34A),
            backgroundColor: const Color(0x198BC34A),
            icon: Icons.people,
            colorKey: 'social',
          );
        }
        return EventDisplayProperties(
          primaryLabel: 'Personal',
          categoryLabel: 'PERSONAL',
          primaryColor: const Color(0xFF0D99FF),
          backgroundColor: const Color(0x190D99FF),
          icon: Icons.person,
          colorKey: 'personal',
        );
    }
  }

  /// Get relationship badge for additional context (Phase 2 preparation)
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
    // Use the actual source from the event model
    return event.source;
  }

  /// Determine if event should show in specific view
  static bool shouldShowInView(Event event, EventSource filterSource) {
    if (filterSource == EventSource.shared) {
      // "All events" view shows everything
      return true;
    }
    return event.source == filterSource;
  }

  /// Get priority for display ordering
  static int getDisplayPriority(Event event, String currentUserId) {
    // Higher priority = shows first
    if (event.type == EventType.assignment) return 4;
    if (event.type == EventType.class_) return 3;
    if (event.creatorId == currentUserId) return 2;
    if (event.attendeeIds.contains(currentUserId)) return 1;
    return 0;
  }
}
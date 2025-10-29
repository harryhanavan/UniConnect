import 'package:flutter/foundation.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../demo_data/demo_data_manager.dart';

/// Service for managing user relationships with events
/// Handles attendance status, calendar integration, and event notifications
class EventRelationshipService {
  static final EventRelationshipService _instance = EventRelationshipService._internal();
  factory EventRelationshipService() => _instance;
  EventRelationshipService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  
  // Notifiers for real-time UI updates
  final ValueNotifier<int> _relationshipChangeNotifier = ValueNotifier<int>(0);
  ValueNotifier<int> get relationshipChangeNotifier => _relationshipChangeNotifier;

  bool _isInitialized = false;
  
  /// Ensure data is loaded before using any methods
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _demoData.enhancedEvents; // Trigger initialization
      _isInitialized = true;
    }
  }

  /// Get user's relationship to a specific event
  Future<EventRelationship> getUserEventRelationship(String userId, String eventId) async {
    await _ensureInitialized();
    final event = _demoData.getEventV2ById(eventId);
    return event?.getUserRelationship(userId) ?? EventRelationship.none;
  }

  /// Get user's relationship to a specific event (sync version)
  EventRelationship getUserEventRelationshipSync(String userId, String eventId) {
    if (!_isInitialized) {
      throw StateError('EventRelationshipService not initialized. Call async method first.');
    }
    final event = _demoData.getEventV2ById(eventId);
    return event?.getUserRelationship(userId) ?? EventRelationship.none;
  }

  /// Update user's relationship with an event
  Future<bool> updateEventRelationship(String userId, String eventId, EventRelationship newRelationship) async {
    await _ensureInitialized();
    
    final event = _demoData.getEventV2ById(eventId);
    if (event == null) return false;

    // Remove user from all relationship lists first
    final updatedEvent = event.copyWith(
      attendeeIds: List<String>.from(event.attendeeIds)..remove(userId),
      invitedIds: List<String>.from(event.invitedIds)..remove(userId),
      interestedIds: List<String>.from(event.interestedIds)..remove(userId),
    );

    // Add user to appropriate relationship list
    EventV2 finalEvent;
    switch (newRelationship) {
      case EventRelationship.attendee:
        finalEvent = updatedEvent.copyWith(
          attendeeIds: List<String>.from(updatedEvent.attendeeIds)..add(userId),
        );
        break;
      case EventRelationship.invited:
        finalEvent = updatedEvent.copyWith(
          invitedIds: List<String>.from(updatedEvent.invitedIds)..add(userId),
        );
        break;
      case EventRelationship.interested:
        finalEvent = updatedEvent.copyWith(
          interestedIds: List<String>.from(updatedEvent.interestedIds)..add(userId),
        );
        break;
      case EventRelationship.none:
      case EventRelationship.observer:
        finalEvent = updatedEvent; // User removed from all lists
        break;
      case EventRelationship.owner:
      case EventRelationship.organizer:
        // These relationships can't be changed via this method
        return false;
    }

    // Update the event in the data manager
    bool success = await _updateEventInDataManager(finalEvent);
    
    if (success) {
      _relationshipChangeNotifier.value++;
    }
    
    return success;
  }

  /// Get all events where user has a specific relationship
  Future<List<EventV2>> getEventsByRelationship(String userId, EventRelationship relationship) async {
    await _ensureInitialized();
    
    final allEvents = _demoData.enhancedEventsSync;
    
    return allEvents.where((event) => 
      event.getUserRelationship(userId) == relationship
    ).toList();
  }

  /// Get all events user is attending (for personal calendar)
  Future<List<EventV2>> getUserAttendingEvents(String userId, {DateTime? startDate, DateTime? endDate}) async {
    await _ensureInitialized();
    
    final start = startDate ?? DateTime.now();
    final end = endDate ?? start.add(const Duration(days: 30));
    
    final allEvents = _demoData.getEnhancedEventsByDateRange(start, end);
    
    return allEvents.where((event) => 
      event.getUserRelationship(userId) == EventRelationship.attendee
    ).toList();
  }

  /// Get society events with user's relationship status
  Future<List<Map<String, dynamic>>> getSocietyEventsWithStatus(
    String userId,
    String societyId,
    {EventTimeFilter timeFilter = EventTimeFilter.upcoming}
  ) async {
    await _ensureInitialized();

    final allEvents = _demoData.enhancedEventsSync;
    final now = DateTime.now();

    final societyEvents = allEvents.where((event) {
      if (event.societyId != societyId) return false;

      // Apply time filter
      switch (timeFilter) {
        case EventTimeFilter.upcoming:
          return event.startTime.isAfter(now);
        case EventTimeFilter.past:
          return event.startTime.isBefore(now);
        case EventTimeFilter.all:
          return true;
      }
    }).toList();

    // Sort events: upcoming events ascending, past events descending
    societyEvents.sort((a, b) {
      if (timeFilter == EventTimeFilter.past) {
        return b.startTime.compareTo(a.startTime); // Most recent first for past events
      } else {
        return a.startTime.compareTo(b.startTime); // Soonest first for upcoming/all
      }
    });

    return societyEvents.map((event) => {
      'event': event,
      'relationship': event.getUserRelationship(userId),
      'canView': event.canUserView(userId),
      'canEdit': event.canUserEdit(userId),
    }).toList();
  }

  /// Get discoverable society events (events user can see but may not be attending)
  Future<List<EventV2>> getDiscoverableSocietyEvents(String userId, {DateTime? startDate, DateTime? endDate}) async {
    await _ensureInitialized();
    
    final start = startDate ?? DateTime.now();
    final end = endDate ?? start.add(const Duration(days: 30));
    
    final userSocieties = _demoData.joinedSocieties.map((s) => s.id).toSet();
    final allEvents = _demoData.getEnhancedEventsByDateRange(start, end);
    
    return allEvents.where((event) => 
      event.societyId != null && 
      userSocieties.contains(event.societyId) &&
      event.canUserView(userId)
    ).toList();
  }

  /// Quick actions for common relationship changes
  Future<bool> markEventAsAttending(String userId, String eventId) async {
    return await updateEventRelationship(userId, eventId, EventRelationship.attendee);
  }

  Future<bool> markEventAsInterested(String userId, String eventId) async {
    return await updateEventRelationship(userId, eventId, EventRelationship.interested);
  }

  Future<bool> removeEventFromCalendar(String userId, String eventId) async {
    return await updateEventRelationship(userId, eventId, EventRelationship.none);
  }

  /// Check if user can perform actions on an event
  bool canUserManageAttendance(String userId, String eventId) {
    if (!_isInitialized) return false;
    
    final event = _demoData.getEventV2ById(eventId);
    if (event == null) return false;
    
    final relationship = event.getUserRelationship(userId);
    return relationship != EventRelationship.owner && 
           relationship != EventRelationship.organizer &&
           event.canUserView(userId);
  }

  /// Get attendance statistics for an event
  Map<String, int> getEventAttendanceStats(String eventId) {
    if (!_isInitialized) return {};
    
    final event = _demoData.getEventV2ById(eventId);
    if (event == null) return {};
    
    return {
      'attending': event.attendeeIds.length,
      'interested': event.interestedIds.length,
      'invited': event.invitedIds.length,
    };
  }

  /// Update event details (title, description, time, etc.)
  /// Used by the event editing interface
  Future<bool> updateEventDetails(EventV2 updatedEvent) async {
    await _ensureInitialized();
    
    bool success = await _updateEventInDataManager(updatedEvent);
    
    if (success) {
      _relationshipChangeNotifier.value++;
    }
    
    return success;
  }

  /// Private helper to update event in data manager
  /// Note: In a real app, this would make API calls to update the backend
  Future<bool> _updateEventInDataManager(EventV2 updatedEvent) async {
    try {
      // For demo purposes, we'll update the event in the in-memory data
      // In a real app, this would be an API call followed by local data refresh
      
      final events = _demoData.enhancedEventsSync;
      final eventIndex = events.indexWhere((e) => e.id == updatedEvent.id);
      
      if (eventIndex != -1) {
        // Replace the event in the list
        events[eventIndex] = updatedEvent;
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating event relationship: $e');
      return false;
    }
  }

  /// Get events for debugging/testing
  void debugPrintEventRelationships(String userId) {
    if (!_isInitialized) {
      print('EventRelationshipService not initialized');
      return;
    }
    
    final allEvents = _demoData.enhancedEventsSync;
    print('=== Event Relationships for User: $userId ===');
    
    for (final event in allEvents.take(5)) {
      final relationship = event.getUserRelationship(userId);
      print('Event: ${event.title} - Relationship: $relationship');
    }
  }
}
import '../../shared/models/event.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../demo_data/demo_data_manager.dart';

/// Service to handle migration between legacy and v2 event models
/// Provides seamless transition while maintaining backward compatibility
class EventMigrationService {
  static final EventMigrationService _instance = EventMigrationService._internal();
  factory EventMigrationService() => _instance;
  EventMigrationService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  
  // Cache for migrated events
  final Map<String, EventV2> _v2EventCache = {};
  bool _isMigrated = false;
  
  /// Check if migration has been performed
  bool get isMigrated => _isMigrated;
  
  /// Migrate all events to v2 format
  Future<List<EventV2>> migrateAllEvents() async {
    if (_isMigrated) {
      return _v2EventCache.values.toList();
    }
    
    final legacyEvents = await _demoData.events;
    final migratedEvents = <EventV2>[];
    
    for (final legacyEvent in legacyEvents) {
      final v2Event = _enhanceMigratedEvent(
        EventV2.fromLegacyEvent(legacyEvent)
      );
      _v2EventCache[v2Event.id] = v2Event;
      migratedEvents.add(v2Event);
    }
    
    _isMigrated = true;
    return migratedEvents;
  }
  
  /// Enhance migrated event with additional v2 features
  EventV2 _enhanceMigratedEvent(EventV2 event) {
    // Add smart enhancements based on event patterns
    var enhanced = event;
    
    // Enhance academic events
    if (event.category == EventCategory.academic) {
      enhanced = _enhanceAcademicEvent(enhanced);
    }
    
    // Enhance society events
    if (event.societyId != null) {
      enhanced = _enhanceSocietyEvent(enhanced);
    }
    
    // Enhance social events
    if (event.attendeeIds.length > 2) {
      enhanced = _enhanceSocialEvent(enhanced);
    }
    
    // Add recurring patterns for regular classes
    if (event.subType == EventSubType.lecture || 
        event.subType == EventSubType.tutorial) {
      enhanced = _addRecurringPattern(enhanced);
    }
    
    return enhanced;
  }
  
  /// Enhance academic events with course-specific metadata
  EventV2 _enhanceAcademicEvent(EventV2 event) {
    // Determine more specific subtype based on title
    EventSubType subType = event.subType;
    
    if (event.title.toLowerCase().contains('lab')) {
      subType = EventSubType.lab;
    } else if (event.title.toLowerCase().contains('tutorial')) {
      subType = EventSubType.tutorial;
    } else if (event.title.toLowerCase().contains('exam')) {
      subType = EventSubType.exam;
    } else if (event.title.toLowerCase().contains('presentation')) {
      subType = EventSubType.presentation;
    }
    
    // Add custom fields for academic events
    final customFields = <String, dynamic>{
      'mandatory': true,
      'credits': event.courseCode != null ? 3 : 0,
      'assessmentWeight': subType == EventSubType.exam ? 40 : 0,
    };
    
    return event.copyWith(
      subType: subType,
      privacyLevel: EventPrivacyLevel.faculty,
      sharingPermission: EventSharingPermission.canSuggest,
      discoverability: EventDiscoverability.searchable,
      customFields: customFields,
    );
  }
  
  /// Enhance society events with society-specific features
  EventV2 _enhanceSocietyEvent(EventV2 event) {
    // Determine society event subtype from title
    EventSubType subType = EventSubType.societyEvent;
    
    if (event.title.toLowerCase().contains('workshop')) {
      subType = EventSubType.societyWorkshop;
    } else if (event.title.toLowerCase().contains('meeting')) {
      subType = EventSubType.meeting;
    } else if (event.title.toLowerCase().contains('competition')) {
      subType = EventSubType.competition;
    }
    
    // Get society members as potential attendees
    final society = _demoData.getSocietyById(event.societyId!);
    final organizerIds = society != null && society.adminIds.isNotEmpty ? [society.adminIds.first] : <String>[];
    
    return event.copyWith(
      subType: subType,
      organizerIds: organizerIds,
      privacyLevel: EventPrivacyLevel.societyOnly,
      sharingPermission: EventSharingPermission.canShare,
      discoverability: EventDiscoverability.searchable,
      origin: EventOrigin.society,
    );
  }
  
  /// Enhance social events with social features
  EventV2 _enhanceSocialEvent(EventV2 event) {
    EventSubType subType = EventSubType.meetup;
    
    if (event.title.toLowerCase().contains('party')) {
      subType = EventSubType.party;
    } else if (event.title.toLowerCase().contains('study')) {
      subType = EventSubType.studySession;
    } else if (event.title.toLowerCase().contains('game')) {
      subType = EventSubType.gameNight;
    }
    
    return event.copyWith(
      category: subType == EventSubType.studySession 
          ? EventCategory.academic 
          : EventCategory.social,
      subType: subType,
      privacyLevel: EventPrivacyLevel.friendsOnly,
      sharingPermission: EventSharingPermission.canShare,
      discoverability: EventDiscoverability.feedVisible,
    );
  }
  
  /// Add recurring pattern to regular events
  EventV2 _addRecurringPattern(EventV2 event) {
    // Check if this looks like a weekly class
    if (event.category == EventCategory.academic && 
        (event.subType == EventSubType.lecture || 
         event.subType == EventSubType.tutorial)) {
      
      final dayOfWeek = _getDayOfWeek(event.startTime.weekday);
      final timeStr = '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}';
      
      return event.copyWith(
        isRecurring: true,
        recurringPattern: 'WEEKLY:$dayOfWeek:$timeStr',
      );
    }
    
    return event;
  }
  
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'MON';
      case DateTime.tuesday: return 'TUE';
      case DateTime.wednesday: return 'WED';
      case DateTime.thursday: return 'THU';
      case DateTime.friday: return 'FRI';
      case DateTime.saturday: return 'SAT';
      case DateTime.sunday: return 'SUN';
      default: return 'MON';
    }
  }
  
  /// Get a single event in v2 format
  EventV2? getEventV2(String eventId) {
    if (_v2EventCache.containsKey(eventId)) {
      return _v2EventCache[eventId];
    }
    
    // Try to find in legacy events and migrate
    final legacyEvents = _demoData.eventsSync;
    final legacyEvent = legacyEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found'),
    );
    
    final v2Event = _enhanceMigratedEvent(
      EventV2.fromLegacyEvent(legacyEvent)
    );
    _v2EventCache[eventId] = v2Event;
    
    return v2Event;
  }
  
  /// Get events for a date range in v2 format
  Future<List<EventV2>> getEventsV2ForDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    // Ensure all events are migrated
    await migrateAllEvents();
    
    return _v2EventCache.values
        .where((event) => 
            event.startTime.isAfter(startDate) && 
            event.startTime.isBefore(endDate))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  /// Filter events by category
  List<EventV2> filterByCategory(
    List<EventV2> events, 
    EventCategory category,
  ) {
    return events.where((e) => e.category == category).toList();
  }
  
  /// Filter events by relationship
  List<EventV2> filterByRelationship(
    List<EventV2> events,
    String userId,
    EventRelationship relationship,
  ) {
    return events.where((e) => 
      e.getUserRelationship(userId) == relationship
    ).toList();
  }
  
  /// Filter events by privacy level
  List<EventV2> filterByPrivacy(
    List<EventV2> events,
    EventPrivacyLevel minPrivacy,
  ) {
    final privacyOrder = [
      EventPrivacyLevel.public,
      EventPrivacyLevel.university,
      EventPrivacyLevel.faculty,
      EventPrivacyLevel.societyOnly,
      EventPrivacyLevel.friendsOfFriends,
      EventPrivacyLevel.friendsOnly,
      EventPrivacyLevel.inviteOnly,
      EventPrivacyLevel.private,
    ];
    
    final minIndex = privacyOrder.indexOf(minPrivacy);
    
    return events.where((e) {
      final eventIndex = privacyOrder.indexOf(e.privacyLevel);
      return eventIndex <= minIndex;
    }).toList();
  }
}
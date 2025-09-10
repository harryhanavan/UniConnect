import '../../shared/models/event.dart';
import '../../shared/models/user.dart';
import '../demo_data/demo_data_manager.dart';
import 'friendship_service.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  final FriendshipService _friendshipService = FriendshipService();
  
  bool _isInitialized = false;
  
  // Ensure data is loaded before using any methods
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _demoData.users; // This triggers async initialization
      _isInitialized = true;
    }
  }

  // Get unified calendar events for a user with all sources (async version)
  Future<List<Event>> getUnifiedCalendar(String userId, {DateTime? startDate, DateTime? endDate}) async {
    await _ensureInitialized();
    
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    final start = startDate ?? DateTime.now();
    final end = endDate ?? start.add(const Duration(days: 30));

    final allEvents = <Event>[];

    // 1. Personal events (classes, assignments, personal)
    allEvents.addAll(_getPersonalEvents(userId, start, end));

    // 2. Society events from joined societies
    allEvents.addAll(_getSocietyEvents(userId, start, end));

    // 3. Friend shared events (study sessions, meetups)
    allEvents.addAll(_getFriendSharedEvents(userId, start, end));

    // 4. Events where user is invited/attending
    allEvents.addAll(_getAttendingEvents(userId, start, end));

    // Remove duplicates and sort by start time
    final uniqueEvents = allEvents.toSet().toList();
    uniqueEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    return uniqueEvents;
  }
  
  // Sync version for backward compatibility (after async initialization)
  List<Event> getUnifiedCalendarSync(String userId, {DateTime? startDate, DateTime? endDate}) {
    if (!_isInitialized) {
      throw StateError('CalendarService not initialized. Call await getUnifiedCalendar first.');
    }
    
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    final start = startDate ?? DateTime.now();
    final end = endDate ?? start.add(const Duration(days: 30));

    final allEvents = <Event>[];

    // 1. Personal events (classes, assignments, personal)
    allEvents.addAll(_getPersonalEvents(userId, start, end));

    // 2. Society events from joined societies
    allEvents.addAll(_getSocietyEvents(userId, start, end));

    // 3. Friend shared events (study sessions, meetups)
    allEvents.addAll(_getFriendSharedEvents(userId, start, end));

    // 4. Events where user is invited/attending
    allEvents.addAll(_getAttendingEvents(userId, start, end));

    // Remove duplicates and sort by start time
    final uniqueEvents = allEvents.toSet().toList();
    uniqueEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    return uniqueEvents;
  }

  // Get events filtered by source type (async version)
  Future<List<Event>> getEventsBySource(String userId, EventSource source, {DateTime? startDate, DateTime? endDate}) async {
    await _ensureInitialized();
    
    final start = startDate ?? DateTime.now();
    final end = endDate ?? start.add(const Duration(days: 30));

    switch (source) {
      case EventSource.personal:
        return _getPersonalEvents(userId, start, end);
      case EventSource.friends:
        return _getFriendSharedEvents(userId, start, end);
      case EventSource.societies:
        return _getSocietyEvents(userId, start, end);
      case EventSource.shared:
        return _getAttendingEvents(userId, start, end);
    }
  }
  
  // Sync version for backward compatibility
  List<Event> getEventsBySourceSync(String userId, EventSource source, {DateTime? startDate, DateTime? endDate}) {
    if (!_isInitialized) {
      throw StateError('CalendarService not initialized. Call await getEventsBySource first.');
    }
    
    final start = startDate ?? DateTime.now();
    final end = endDate ?? start.add(const Duration(days: 30));

    switch (source) {
      case EventSource.personal:
        return _getPersonalEvents(userId, start, end);
      case EventSource.friends:
        return _getFriendSharedEvents(userId, start, end);
      case EventSource.societies:
        return _getSocietyEvents(userId, start, end);
      case EventSource.shared:
        return _getAttendingEvents(userId, start, end);
    }
  }

  // Get events for a user on a specific date (async version)
  Future<List<Event>> getUserEventsForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getUnifiedCalendar(userId, startDate: startOfDay, endDate: endOfDay);
  }
  
  // Sync version for backward compatibility
  List<Event> getUserEventsForDateSync(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getUnifiedCalendarSync(userId, startDate: startOfDay, endDate: endOfDay);
  }

  // Get friend schedule overlay data
  Future<Map<String, dynamic>> getFriendScheduleOverlay(String userId, DateTime date) async {
    return await getEventsWithFriendOverlay(userId, date);
  }

  // Get events for a specific date with friend overlay information
  Future<Map<String, dynamic>> getEventsWithFriendOverlay(String userId, DateTime date) async {
    final user = _demoData.getUserById(userId);
    if (user == null) return {};

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get user's events for the day
    final userEvents = await getUnifiedCalendar(userId, startDate: startOfDay, endDate: endOfDay);

    // Get friends' events that are visible
    final friendsSchedules = <String, List<Event>>{};
    final friends = _demoData.getFriendsForUser(userId);
    
    for (final friend in friends) {
      if (_friendshipService.canViewTimetable(userId, friend.id)) {
        final friendEvents = await getUnifiedCalendar(friend.id, startDate: startOfDay, endDate: endOfDay);
        friendsSchedules[friend.id] = friendEvents;
      }
    }

    // Find overlapping events and common free times
    final overlaps = _findEventOverlaps(userEvents, friendsSchedules);
    final commonFreeTimes = _findCommonFreeTimes(userId, friends, date);

    return {
      'userEvents': userEvents,
      'friendsSchedules': friendsSchedules,
      'overlaps': overlaps,
      'commonFreeTimes': commonFreeTimes,
    };
  }
  
  // Sync version for backward compatibility
  Map<String, dynamic> getEventsWithFriendOverlaySync(String userId, DateTime date) {
    if (!_isInitialized) {
      throw StateError('CalendarService not initialized. Call await getEventsWithFriendOverlay first.');
    }
    
    final user = _demoData.getUserById(userId);
    if (user == null) return {};

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get user's events for the day
    final userEvents = getUnifiedCalendarSync(userId, startDate: startOfDay, endDate: endOfDay);

    // Get friends' events that are visible
    final friendsSchedules = <String, List<Event>>{};
    final friends = _demoData.getFriendsForUser(userId);
    
    for (final friend in friends) {
      if (_friendshipService.canViewTimetable(userId, friend.id)) {
        final friendEvents = getUnifiedCalendarSync(friend.id, startDate: startOfDay, endDate: endOfDay);
        friendsSchedules[friend.id] = friendEvents;
      }
    }

    // Find overlapping events and common free times
    final overlaps = _findEventOverlaps(userEvents, friendsSchedules);
    final commonFreeTimes = _findCommonFreeTimes(userId, friends, date);

    return {
      'userEvents': userEvents,
      'friendsSchedules': friendsSchedules,
      'overlaps': overlaps,
      'commonFreeTimes': commonFreeTimes,
    };
  }

  // Create a shared event between friends
  Future<Event> createSharedEvent({
    required String creatorId,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required List<String> invitedFriendIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newEvent = Event(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      type: EventType.personal,
      source: EventSource.shared,
      creatorId: creatorId,
      attendeeIds: [creatorId, ...invitedFriendIds],
    );

    // Add to demo data (in real app, would save to database)
    // Note: In the JSON-based system, this would require updating the JSON file
    // For now, this is a limitation of the demo system
    // Note: Adding events at runtime not yet supported in JSON-based demo data

    // Send notifications to invited friends (simulate)
    await _notifyInvitedFriends(newEvent, invitedFriendIds);

    return newEvent;
  }

  // Join a society and automatically add its events to calendar
  Future<bool> joinSocietyWithCalendarIntegration(String userId, String societyId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Join the society
    _demoData.joinSociety(societyId);

    // Get society events and add to user's calendar view
    final society = _demoData.getSocietyById(societyId);
    if (society == null) return false;

    // In a real app, this would create calendar subscriptions
    // For demo, we simulate by marking user as interested in society events
    final societyEvents = _demoData.eventsSync
        .where((event) => event.societyId == societyId)
        .toList();

    // Note: Auto-RSVP functionality temporarily disabled in JSON-based demo data
    // In a real app, this would update the database
    // Society joined: ${society.name}. Event RSVP updates not yet supported in JSON-based demo data.

    // Trigger calendar refresh
    await _refreshCalendar(userId);

    return true;
  }

  // Leave society and remove its events
  Future<bool> leaveSocietyWithCalendarCleanup(String userId, String societyId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Leave the society
    _demoData.leaveSociety(societyId);

    // Remove user from society event attendee lists
    final societyEvents = _demoData.eventsSync
        .where((event) => event.societyId == societyId)
        .toList();

    // Note: Event attendee list updates temporarily disabled in JSON-based demo data
    // In a real app, this would update the database
    // Society left. Event attendee updates not yet supported in JSON-based demo data.

    await _refreshCalendar(userId);
    return true;
  }

  // Get upcoming events with smart suggestions
  Future<List<Map<String, dynamic>>> getUpcomingEventsWithSuggestions(String userId) async {
    final upcomingEvents = await getUnifiedCalendar(userId, 
        startDate: DateTime.now(), 
        endDate: DateTime.now().add(const Duration(days: 7)));

    return upcomingEvents.map((event) {
      final suggestions = <String>[];

      // Add friend suggestions based on event type and location
      if (event.type == EventType.class_) {
        final classmatesInSameEvent = _findClassmates(userId, event);
        if (classmatesInSameEvent.isNotEmpty) {
          suggestions.add('${classmatesInSameEvent.length} friends are also attending');
        }
      }

      // Add location-based suggestions
      if (event.location.isNotEmpty) {
        final nearbyFriends = _findNearbyFriends(userId, event.location);
        if (nearbyFriends.isNotEmpty) {
          suggestions.add('${nearbyFriends.length} friends will be nearby');
        }
      }

      // Add study group suggestions
      if (event.type == EventType.class_ || event.type == EventType.assignment) {
        final studyBuddies = _suggestStudyBuddies(userId, event);
        if (studyBuddies.isNotEmpty) {
          suggestions.add('Plan study session with ${studyBuddies.length} friends');
        }
      }

      return {
        'event': event,
        'suggestions': suggestions,
        'source': _determineEventSource(event, userId),
      };
    }).toList();
  }

  // Detect and resolve schedule conflicts (async version)
  Future<List<Map<String, dynamic>>> detectScheduleConflicts(String userId, {int daysAhead = 7}) async {
    final events = await getUnifiedCalendar(userId,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: daysAhead)));

    final conflicts = <Map<String, dynamic>>[];

    for (int i = 0; i < events.length - 1; i++) {
      for (int j = i + 1; j < events.length; j++) {
        if (_eventsOverlap(events[i], events[j])) {
          conflicts.add({
            'event1': events[i],
            'event2': events[j],
            'conflictType': _determineConflictType(events[i], events[j]),
            'suggestions': _getConflictResolutionSuggestions(events[i], events[j]),
          });
        }
      }
    }

    return conflicts;
  }
  
  // Sync version for backward compatibility
  List<Map<String, dynamic>> detectScheduleConflictsSync(String userId, {int daysAhead = 7}) {
    if (!_isInitialized) {
      throw StateError('CalendarService not initialized. Call await detectScheduleConflicts first.');
    }
    
    final events = getUnifiedCalendarSync(userId,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: daysAhead)));

    final conflicts = <Map<String, dynamic>>[];

    for (int i = 0; i < events.length - 1; i++) {
      for (int j = i + 1; j < events.length; j++) {
        if (_eventsOverlap(events[i], events[j])) {
          conflicts.add({
            'event1': events[i],
            'event2': events[j],
            'conflictType': _determineConflictType(events[i], events[j]),
            'suggestions': _getConflictResolutionSuggestions(events[i], events[j]),
          });
        }
      }
    }

    return conflicts;
  }

  // Private helper methods
  List<Event> _getPersonalEvents(String userId, DateTime start, DateTime end) {
    return _demoData.getEventsByDateRange(start, end)
        .where((event) => 
            (event.creatorId == userId || event.creatorId == 'system') && 
            (event.type == EventType.class_ || 
             event.type == EventType.assignment ||
             event.type == EventType.personal))
        .toList();
  }

  List<Event> _getSocietyEvents(String userId, DateTime start, DateTime end) {
    final joinedSocieties = _demoData.joinedSocieties;
    final societyIds = joinedSocieties.map((s) => s.id).toSet();

    return _demoData.getEventsByDateRange(start, end)
        .where((event) => 
            event.societyId != null && 
            societyIds.contains(event.societyId))
        .toList();
  }

  List<Event> _getFriendSharedEvents(String userId, DateTime start, DateTime end) {
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    return _demoData.getEventsByDateRange(start, end)
        .where((event) => 
            // Include events with EventSource.friends
            (event.source == EventSource.friends && 
             user.friendIds.contains(event.creatorId)) ||
            // Also include personal shared events (original logic)
            (event.type == EventType.personal &&
             event.creatorId != userId &&
             event.attendeeIds.contains(userId) &&
             user.friendIds.contains(event.creatorId)))
        .toList();
  }

  List<Event> _getAttendingEvents(String userId, DateTime start, DateTime end) {
    return _demoData.getEventsByDateRange(start, end)
        .where((event) => event.attendeeIds.contains(userId))
        .toList();
  }

  Map<String, List<Event>> _findEventOverlaps(List<Event> userEvents, Map<String, List<Event>> friendsSchedules) {
    final overlaps = <String, List<Event>>{};

    for (final userEvent in userEvents) {
      for (final friendId in friendsSchedules.keys) {
        final friendEvents = friendsSchedules[friendId]!;
        for (final friendEvent in friendEvents) {
          if (_eventsOverlap(userEvent, friendEvent)) {
            overlaps.putIfAbsent(friendId, () => []).add(friendEvent);
          }
        }
      }
    }

    return overlaps;
  }

  List<Map<String, dynamic>> _findCommonFreeTimes(String userId, List<User> friends, DateTime date) {
    final commonTimes = <Map<String, dynamic>>[];

    for (final friend in friends) {
      if (_friendshipService.canViewTimetable(userId, friend.id)) {
        final freeSlots = _friendshipService.findCommonFreeTime(userId, [friend.id], date: date);
        for (final slot in freeSlots) {
          commonTimes.add({
            'friend': friend,
            'timeSlot': slot,
          });
        }
      }
    }

    return commonTimes;
  }

  List<User> _findClassmates(String userId, Event classEvent) {
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    return user.friendIds
        .map((friendId) => _demoData.getUserById(friendId))
        .where((friend) => friend != null && classEvent.attendeeIds.contains(friend.id))
        .cast<User>()
        .toList();
  }

  List<User> _findNearbyFriends(String userId, String location) {
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    // Simple location matching - in real app would use proper geo-matching
    return user.friendIds
        .map((friendId) => _demoData.getUserById(friendId))
        .where((friend) => friend != null && 
            friend.currentBuilding != null &&
            location.contains(friend.currentBuilding!))
        .cast<User>()
        .toList();
  }

  List<User> _suggestStudyBuddies(String userId, Event studyEvent) {
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    // Suggest friends in same course for study sessions
    return user.friendIds
        .map((friendId) => _demoData.getUserById(friendId))
        .where((friend) => friend != null && friend.course == user.course)
        .cast<User>()
        .toList();
  }

  bool _eventsOverlap(Event event1, Event event2) {
    return event1.startTime.isBefore(event2.endTime) && 
           event2.startTime.isBefore(event1.endTime);
  }

  String _determineConflictType(Event event1, Event event2) {
    if (event1.type == EventType.class_ && event2.type == EventType.class_) {
      return 'Class Conflict';
    } else if (event1.type == EventType.assignment || event2.type == EventType.assignment) {
      return 'Assignment Deadline Conflict';
    } else {
      return 'Schedule Conflict';
    }
  }

  List<String> _getConflictResolutionSuggestions(Event event1, Event event2) {
    final suggestions = <String>[];
    
    if (event1.type == EventType.personal || event2.type == EventType.personal) {
      suggestions.add('Reschedule personal event');
    }
    
    if (event1.type == EventType.society || event2.type == EventType.society) {
      suggestions.add('Check if society event can be moved');
    }
    
    suggestions.add('Find alternative time slot');
    
    return suggestions;
  }

  EventSource _determineEventSource(Event event, String userId) {
    if (event.creatorId == userId) return EventSource.personal;
    if (event.societyId != null) return EventSource.societies;
    if (event.attendeeIds.contains(userId)) return EventSource.shared;
    return EventSource.friends;
  }

  Future<void> _notifyInvitedFriends(Event event, List<String> friendIds) async {
    // Simulate sending notifications
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _refreshCalendar(String userId) async {
    // Simulate calendar refresh
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
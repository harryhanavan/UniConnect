import 'dart:convert';
import 'package:flutter/services.dart';
import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../../shared/models/location.dart';
import '../../shared/models/privacy_settings.dart';
import '../../shared/models/friend_request.dart';

/// Enhanced demo data loader for Phase 2/3 implementation
/// Handles both legacy and v2 event formats
class DemoDataLoader {
  static const String _basePath = 'assets/demo_data';

  /// Load events from enhanced events.json file
  static Future<List<EventV2>> loadEnhancedEvents() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/events.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> eventsList = jsonData['events'];
      
      return _parseV2Events(eventsList);
    } catch (e) {
      print('Error loading enhanced events: $e');
      return [];
    }
  }
  
  /// Backward compatibility method
  @Deprecated('Use loadEnhancedEvents instead')
  static Future<List<EventV2>> loadEventsV2() async {
    return loadEnhancedEvents();
  }

  /// Parse enhanced events from JSON with advanced properties
  static List<EventV2> _parseV2Events(List<dynamic> eventsList) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return eventsList.map((json) {
      DateTime startTime;
      DateTime endTime;
      
      // Check if this event uses absolute date or enhanced academic scheduling
      final useAbsoluteDate = json['useAbsoluteDate'] ?? false;
      final category = _parseEventCategory(json['category']);
      final isAllDay = json['isAllDay'] ?? false;
      final duration = json['duration'] ?? 1;
      
      if (useAbsoluteDate && json['exactDate'] != null) {
        // Use exact date with time
        final exactDate = DateTime.parse(json['exactDate']);
        final timeOfDay = json['timeOfDay'] ?? '09:00';
        final timeParts = timeOfDay.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
        
        startTime = DateTime(exactDate.year, exactDate.month, exactDate.day, hour, minute);
        
        // Apply drift adjustment for society events if needed
        if (json['driftAdjustment'] == true) {
          startTime = _applyDriftAdjustment(startTime);
        }
        
        if (isAllDay) {
          endTime = startTime;
        } else {
          endTime = startTime.add(Duration(
            hours: duration.toInt(),
            minutes: ((duration % 1) * 60).toInt(),
          ));
        }
      } else if (category == EventCategory.academic && json['dayOfWeek'] != null) {
        // Use academic semester calendar for classes
        final result = _calculateAcademicEventTime(json);
        startTime = result['startTime'] as DateTime;
        endTime = result['endTime'] as DateTime;
      } else {
        // Fall back to original daysFromNow system
        final daysFromNow = json['daysFromNow'] ?? 0;
        final hoursFromStart = json['hoursFromStart'] ?? 0;
        
        if (isAllDay) {
          startTime = today.add(Duration(days: daysFromNow));
          endTime = startTime;
        } else {
          startTime = today.add(Duration(
            days: daysFromNow,
            hours: hoursFromStart.toInt(),
            minutes: ((hoursFromStart % 1) * 60).toInt(),
          ));
          endTime = startTime.add(Duration(
            hours: duration.toInt(),
            minutes: ((duration % 1) * 60).toInt(),
          ));
        }
      }

      // Parse enhanced enums  
      final subType = _parseEventSubType(json['subType'], json['type']);
      final origin = _parseEventOrigin(json['origin'], json['source']);
      final privacyLevel = _parseEventPrivacyLevel(json['privacyLevel']);
      final sharingPermission = _parseEventSharingPermission(json['sharingPermission']);
      final discoverability = _parseEventDiscoverability(json['discoverability']);

      return EventV2(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        startTime: startTime,
        endTime: endTime,
        location: json['location'],
        category: category,
        subType: subType,
        origin: origin,
        creatorId: json['creatorId'] ?? 'system',
        organizerIds: (json['organizerIds'] as List<dynamic>?)?.cast<String>() ?? [],
        attendeeIds: (json['attendeeIds'] as List<dynamic>?)?.cast<String>() ?? [],
        invitedIds: (json['invitedIds'] as List<dynamic>?)?.cast<String>() ?? [],
        interestedIds: (json['interestedIds'] as List<dynamic>?)?.cast<String>() ?? [],
        privacyLevel: privacyLevel,
        sharingPermission: sharingPermission,
        discoverability: discoverability,
        courseCode: json['courseCode'],
        societyId: json['societyId'],
        isAllDay: isAllDay,
        isRecurring: json['isRecurring'] ?? false,
        recurringPattern: json['recurringPattern'],
        customFields: json['customFields'] != null 
            ? Map<String, dynamic>.from(json['customFields'])
            : null,
        semesterType: json['semesterType'],
        semesterYear: json['semesterYear'],
        semesterStartDate: json['semesterStartDate'] != null 
            ? DateTime.parse(json['semesterStartDate']) 
            : null,
        semesterEndDate: json['semesterEndDate'] != null 
            ? DateTime.parse(json['semesterEndDate']) 
            : null,
        academicWeek: json['academicWeek'],
        useAbsoluteDate: json['useAbsoluteDate'] ?? false,
        exactDate: json['exactDate'] != null 
            ? DateTime.parse(json['exactDate']) 
            : null,
        dayOfWeek: json['dayOfWeek'],
        timeOfDay: json['timeOfDay'],
        driftAdjustment: json['driftAdjustment'] ?? false,
        importPeriod: json['importPeriod'] != null 
            ? Map<String, dynamic>.from(json['importPeriod'])
            : null,
      );
    }).toList();
  }

  /// Parse event category from string
  static EventCategory _parseEventCategory(String? categoryStr) {
    if (categoryStr == null) {
      return EventCategory.personal;
    }
    
    switch (categoryStr.toLowerCase()) {
      case 'academic':
        return EventCategory.academic;
      case 'social':
        return EventCategory.social;
      case 'society':
        return EventCategory.society;
      case 'personal':
        return EventCategory.personal;
      case 'university':
        return EventCategory.university;
      default:
        return EventCategory.personal;
    }
  }

  /// Parse event sub-type from string, with fallback to legacy type
  static EventSubType _parseEventSubType(String? subTypeStr, String? legacyType) {
    if (subTypeStr != null) {
      switch (subTypeStr.toLowerCase()) {
        case 'lecture':
          return EventSubType.lecture;
        case 'tutorial':
          return EventSubType.tutorial;
        case 'lab':
          return EventSubType.lab;
        case 'exam':
          return EventSubType.exam;
        case 'assignment':
          return EventSubType.assignment;
        case 'presentation':
          return EventSubType.presentation;
        case 'workshop':
          return EventSubType.workshop;
        case 'party':
          return EventSubType.party;
        case 'meetup':
          return EventSubType.meetup;
        case 'networking':
          return EventSubType.networking;
        case 'gamenight':
          return EventSubType.gameNight;
        case 'casualhangout':
          return EventSubType.casualHangout;
        case 'meeting':
          return EventSubType.meeting;
        case 'societyworkshop':
          return EventSubType.societyWorkshop;
        case 'competition':
          return EventSubType.competition;
        case 'fundraiser':
          return EventSubType.fundraiser;
        case 'societyevent':
          return EventSubType.societyEvent;
        case 'studysession':
          return EventSubType.studySession;
        case 'appointment':
          return EventSubType.appointment;
        case 'task':
          return EventSubType.task;
        case 'break_':
          return EventSubType.break_;
        case 'personalgoal':
          return EventSubType.personalGoal;
        case 'orientation':
          return EventSubType.orientation;
        case 'careerfair':
          return EventSubType.careerFair;
        case 'guestlecture':
          return EventSubType.guestLecture;
        case 'administrative':
          return EventSubType.administrative;
        case 'ceremony':
          return EventSubType.ceremony;
      }
    }

    // Fallback to legacy type mapping
    return EventTypeHelper.fromLegacyType(legacyType ?? 'personal');
  }

  /// Parse event origin from string
  static EventOrigin _parseEventOrigin(String? originStr, String? legacySource) {
    if (originStr != null) {
      switch (originStr.toLowerCase()) {
        case 'system':
          return EventOrigin.system;
        case 'user':
          return EventOrigin.user;
        case 'society':
          return EventOrigin.society;
        case 'university':
          return EventOrigin.university;
        case 'friend':
          return EventOrigin.friend;
        case 'import':
          return EventOrigin.import;
        case 'aisuggested':
          return EventOrigin.aiSuggested;
      }
    }

    // Fallback to legacy source mapping
    switch (legacySource?.toLowerCase()) {
      case 'societies':
        return EventOrigin.society;
      case 'friends':
        return EventOrigin.friend;
      case 'shared':
        return EventOrigin.user;
      case 'personal':
      default:
        return EventOrigin.user;
    }
  }

  /// Parse event privacy level
  static EventPrivacyLevel _parseEventPrivacyLevel(String? privacyStr) {
    if (privacyStr == null) return EventPrivacyLevel.friendsOnly;
    
    switch (privacyStr.toLowerCase()) {
      case 'public':
        return EventPrivacyLevel.public;
      case 'university':
        return EventPrivacyLevel.university;
      case 'faculty':
        return EventPrivacyLevel.faculty;
      case 'societyonly':
        return EventPrivacyLevel.societyOnly;
      case 'friendsonly':
        return EventPrivacyLevel.friendsOnly;
      case 'friendsoffriends':
        return EventPrivacyLevel.friendsOfFriends;
      case 'inviteonly':
        return EventPrivacyLevel.inviteOnly;
      case 'private':
        return EventPrivacyLevel.private;
      default:
        return EventPrivacyLevel.friendsOnly;
    }
  }

  /// Parse event sharing permission
  static EventSharingPermission _parseEventSharingPermission(String? sharingStr) {
    if (sharingStr == null) return EventSharingPermission.canSuggest;
    
    switch (sharingStr.toLowerCase()) {
      case 'canshare':
        return EventSharingPermission.canShare;
      case 'cansuggest':
        return EventSharingPermission.canSuggest;
      case 'noshare':
        return EventSharingPermission.noShare;
      case 'hidden':
        return EventSharingPermission.hidden;
      default:
        return EventSharingPermission.canSuggest;
    }
  }

  /// Parse event discoverability
  static EventDiscoverability _parseEventDiscoverability(String? discoverStr) {
    if (discoverStr == null) return EventDiscoverability.feedVisible;
    
    switch (discoverStr.toLowerCase()) {
      case 'searchable':
        return EventDiscoverability.searchable;
      case 'recommended':
        return EventDiscoverability.recommended;
      case 'feedvisible':
        return EventDiscoverability.feedVisible;
      case 'calendaronly':
        return EventDiscoverability.calendarOnly;
      default:
        return EventDiscoverability.feedVisible;
    }
  }

  /// Load legacy events (backward compatibility)
  static Future<List<Event>> _loadLegacyEvents() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/events.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> eventsList = jsonData['events'];
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      return eventsList.map((json) {
        // Convert relative dates to actual DateTime
        final daysFromNow = json['daysFromNow'] ?? 0;
        final hoursFromStart = json['hoursFromStart'] ?? 0;
        final duration = json['duration'] ?? 1;
        final isAllDay = json['isAllDay'] ?? false;
        
        DateTime startTime;
        DateTime endTime;
        
        if (isAllDay) {
          startTime = today.add(Duration(days: daysFromNow));
          endTime = startTime;
        } else {
          startTime = today.add(Duration(
            days: daysFromNow,
            hours: hoursFromStart.toInt(),
            minutes: ((hoursFromStart % 1) * 60).toInt(),
          ));
          endTime = startTime.add(Duration(
            hours: duration.toInt(),
            minutes: ((duration % 1) * 60).toInt(),
          ));
        }
        
        // Convert type string to EventType enum
        EventType eventType;
        switch (json['type']) {
          case 'class':
            eventType = EventType.class_;
          case 'assignment':
            eventType = EventType.assignment;
          case 'society':
            eventType = EventType.society;
          case 'personal':
            eventType = EventType.personal;
          default:
            eventType = EventType.personal;
        }
        
        // Convert source string to EventSource enum
        EventSource eventSource;
        switch (json['source']) {
          case 'personal':
            eventSource = EventSource.personal;
          case 'friends':
            eventSource = EventSource.friends;
          case 'societies':
            eventSource = EventSource.societies;
          case 'shared':
            eventSource = EventSource.shared;
          default:
            eventSource = EventSource.personal;
        }
        
        return Event(
          id: json['id'],
          title: json['title'],
          description: json['description'],
          startTime: startTime,
          endTime: endTime,
          location: json['location'],
          type: eventType,
          source: eventSource,
          courseCode: json['courseCode'],
          societyId: json['societyId'],
          creatorId: json['creatorId'] ?? 'system',
          attendeeIds: (json['attendeeIds'] as List<dynamic>?)?.cast<String>() ?? [],
          isAllDay: isAllDay,
        );
      }).toList();
    } catch (e) {
      print('Error loading legacy events: $e');
      return [];
    }
  }

  // Re-export existing loader methods for compatibility
  static Future<List<User>> loadUsers() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/users.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      final now = DateTime.now();
      
      return jsonList.map((jsonMap) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(jsonMap);
        
        // Set lastSeen based on status
        if (json['status'] == 'online') {
          json.remove('lastSeen');
        } else if (json['status'] == 'studying') {
          json['lastSeen'] = now.subtract(const Duration(minutes: 5)).toIso8601String();
        } else if (json['status'] == 'offline') {
          json['lastSeen'] = now.subtract(const Duration(hours: 2)).toIso8601String();
        } else if (json['status'] == 'away') {
          json['lastSeen'] = now.subtract(const Duration(minutes: 30)).toIso8601String();
        }
        
        // Set locationUpdatedAt if location is present
        if (json['currentLocationId'] != null) {
          if (json['status'] == 'online') {
            json['locationUpdatedAt'] = now.subtract(const Duration(minutes: 10)).toIso8601String();
          } else if (json['status'] == 'studying') {
            json['locationUpdatedAt'] = now.subtract(const Duration(minutes: 20)).toIso8601String();
          } else {
            json['locationUpdatedAt'] = now.subtract(const Duration(minutes: 35)).toIso8601String();
          }
        }
        
        return User.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error loading users: $e');
      return [];
    }
  }

  static Future<List<Society>> loadSocieties() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/societies.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Society.fromJson(json)).toList();
    } catch (e) {
      print('Error loading societies: $e');
      return [];
    }
  }

  static Future<List<Location>> loadLocations() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/locations.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      return jsonList.map((json) {
        LocationType locationType;
        switch (json['type']) {
          case 'classroom':
            locationType = LocationType.classroom;
          case 'lab':
            locationType = LocationType.lab;
          case 'common':
            locationType = LocationType.common;
          case 'study':
            locationType = LocationType.study;
          default:
            locationType = LocationType.common;
        }
        
        return Location(
          id: json['id'],
          name: json['name'],
          building: json['building'],
          room: json['room'],
          floor: json['floor'],
          type: locationType,
          latitude: json['latitude'],
          longitude: json['longitude'],
          description: json['description'],
          isAccessible: json['isAccessible'] ?? true,
          capacity: json['capacity'],
          amenities: (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [],
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error loading locations: $e');
      return [];
    }
  }

  static Future<List<PrivacySettings>> loadPrivacySettings() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/privacy_settings.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      final now = DateTime.now();
      
      return jsonList.map((jsonItem) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(jsonItem);
        
        // Add missing required fields with defaults
        json['createdAt'] = json['createdAt'] ?? now.toIso8601String();
        json['defaultPrivacy'] = json['defaultPrivacy'] ?? 'friends';
        json['allowFriendRequests'] = json['allowFriendRequests'] ?? true;
        json['allowSocietyInvites'] = json['allowSocietyInvites'] ?? true;
        json['locationExceptions'] = json['locationExceptions'] ?? [];
        json['showActivity'] = json['showActivity'] ?? true;
        json['allowActivityNotifications'] = json['allowActivityNotifications'] ?? true;
        json['showSocietyMemberships'] = json['showSocietyMemberships'] ?? true;
        json['allowEventInvites'] = json['allowEventInvites'] ?? true;
        json['shareEventAttendance'] = json['shareEventAttendance'] ?? true;
        json['societyEventDefaultPrivacy'] = json['societyEventDefaultPrivacy'] ?? 'friends';
        json['discoverableByEmail'] = json['discoverableByEmail'] ?? true;
        json['discoverableByPhone'] = json['discoverableByPhone'] ?? false;
        json['showInSuggestions'] = json['showInSuggestions'] ?? true;
        json['allowAnalytics'] = json['allowAnalytics'] ?? true;
        
        return PrivacySettings.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error loading privacy settings: $e');
      return [];
    }
  }

  static Future<List<FriendRequest>> loadFriendRequests() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/friend_requests.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> jsonList = jsonData['requests'];
      
      final now = DateTime.now();
      
      return jsonList.map((json) {
        // Convert relative dates to actual DateTime
        final daysAgo = json['daysAgo'] ?? 0;
        final respondedDaysAgo = json['respondedDaysAgo'];
        
        final Map<String, dynamic> requestJson = Map<String, dynamic>.from(json);
        requestJson['createdAt'] = now.subtract(Duration(days: daysAgo)).toIso8601String();
        
        if (respondedDaysAgo != null) {
          requestJson['respondedAt'] = now.subtract(Duration(days: respondedDaysAgo)).toIso8601String();
        }
        
        return FriendRequest.fromJson(requestJson);
      }).toList();
    } catch (e) {
      print('Error loading friend requests: $e');
      return [];
    }
  }

  /// Validation method for data integrity
  static Future<List<String>> validateDataIntegrity({
    required List<User> users,
    required List<PrivacySettings> privacySettings,
    required List<FriendRequest> friendRequests,
    required List<Event> events,
    required List<Society> societies,
    required List<Location> locations,
  }) async {
    final warnings = <String>[];
    
    // User validation
    for (final user in users) {
      final privacy = privacySettings.firstWhere(
        (p) => p.userId == user.id,
        orElse: () => throw Exception('Missing privacy settings for user ${user.id}'),
      );
      if (privacy.userId != user.id) {
        warnings.add('User ${user.id} missing privacy settings');
      }
    }
    
    // Event validation
    for (final event in events) {
      if (event.societyId != null) {
        final society = societies.firstWhere(
          (s) => s.id == event.societyId,
          orElse: () => throw Exception('Invalid society reference in event ${event.id}'),
        );
        if (society.id != event.societyId) {
          warnings.add('Event ${event.id} references non-existent society ${event.societyId}');
        }
      }
    }
    
    return warnings;
  }

  /// Calculate academic event time based on semester calendar and day of week
  /// TODO: TEMPORARY DEMO CALCULATION - Replace with proper semester system
  static Map<String, DateTime> _calculateAcademicEventTime(Map<String, dynamic> json) {
    print('⚠️ DEMO: Using simplified academic calendar calculation');
    
    // UTS Spring 2025 semester dates (simplified for demo)
    final semesterStart = DateTime(2025, 2, 24); // Feb 24, 2025
    final semesterEnd = DateTime(2025, 6, 27);   // Jun 27, 2025
    
    final dayOfWeek = json['dayOfWeek'] ?? 'Monday';
    final timeOfDay = json['timeOfDay'] ?? '10:00';
    final duration = json['duration'] ?? 1;
    final academicWeek = json['academicWeek'] ?? 6; // Default to week 6
    
    // Convert day of week to DateTime weekday (1=Monday, 7=Sunday)
    final dayMap = {
      'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
      'Friday': 5, 'Saturday': 6, 'Sunday': 7
    };
    final targetWeekday = dayMap[dayOfWeek] ?? 1;
    
    // Calculate the date for the specific academic week
    final weekStart = semesterStart.add(Duration(days: (academicWeek - 1) * 7));
    final daysToAdd = (targetWeekday - weekStart.weekday + 7) % 7;
    final eventDate = weekStart.add(Duration(days: daysToAdd));
    
    // Parse time
    final timeParts = timeOfDay.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    
    final startTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour, minute);
    final endTime = startTime.add(Duration(
      hours: duration.toInt(),
      minutes: ((duration % 1) * 60).toInt(),
    ));
    
    return {'startTime': startTime, 'endTime': endTime};
  }

  /// Apply drift adjustment for society events to keep them relevant
  /// TODO: TEMPORARY DEMO ADJUSTMENT - Replace with proper event scheduling
  static DateTime _applyDriftAdjustment(DateTime originalDate) {
    print('⚠️ DEMO: Applying drift adjustment for society event');
    
    // Demo base date: September 13, 2025
    final baseDemoDate = DateTime(2025, 9, 13);
    final today = DateTime.now();
    
    // If current date is after base demo date, shift the event forward
    if (today.isAfter(baseDemoDate)) {
      final daysDrift = today.difference(baseDemoDate).inDays;
      return originalDate.add(Duration(days: daysDrift));
    }
    
    return originalDate;
  }
}
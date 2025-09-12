import 'package:flutter/material.dart';
import '../demo_data/demo_data_manager.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../../shared/models/user.dart';

/// Service for managing user timetables including import, manual entry, and sync
class TimetableService extends ChangeNotifier {
  static final TimetableService _instance = TimetableService._internal();
  static TimetableService get instance => _instance;
  
  TimetableService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  
  // Connection status for external systems
  final Map<String, bool> _connectionStatus = {};
  final Map<String, DateTime> _lastSyncTimes = {};
  
  // Supported external systems
  static const Map<String, Map<String, dynamic>> supportedSystems = {
    'uts_msa': {
      'name': 'UTS MyStudentAdmin',
      'description': 'University of Technology Sydney Student Portal',
      'icon': 'school',
      'requiresAuth': true,
    },
    'canvas': {
      'name': 'Canvas LMS',
      'description': 'Learning Management System Integration',
      'icon': 'book',
      'requiresAuth': true,
    },
    'external_calendar': {
      'name': 'External Calendar',
      'description': 'Import from Google Calendar, Outlook, etc.',
      'icon': 'calendar_today',
      'requiresAuth': true,
    },
  };

  /// Get all academic events for the current user
  Future<List<EventV2>> getAcademicEvents() async {
    final events = await _demoData.enhancedEvents;
    return events.where((event) => 
      event.category == EventCategory.academic && 
      event.attendeeIds.contains(_demoData.currentUser.id)
    ).toList();
  }

  /// Get timetable events for a specific date range
  Future<List<EventV2>> getTimetableEvents(DateTime startDate, DateTime endDate) async {
    final academicEvents = await getAcademicEvents();
    return academicEvents.where((event) {
      return event.startTime.isAfter(startDate) && 
             event.startTime.isBefore(endDate);
    }).toList();
  }

  /// Check if a system is connected
  bool isSystemConnected(String systemId) {
    return _connectionStatus[systemId] ?? false;
  }

  /// Get last sync time for a system
  DateTime? getLastSyncTime(String systemId) {
    return _lastSyncTimes[systemId];
  }

  /// Connect to an external system (simulated)
  Future<bool> connectToSystem(String systemId, {Map<String, String>? credentials}) async {
    if (!supportedSystems.containsKey(systemId)) {
      throw ArgumentError('Unsupported system: $systemId');
    }

    // Simulate connection process
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real implementation, this would involve OAuth or API authentication
    _connectionStatus[systemId] = true;
    _lastSyncTimes[systemId] = DateTime.now();
    
    notifyListeners();
    return true;
  }

  /// Disconnect from an external system
  Future<void> disconnectFromSystem(String systemId) async {
    _connectionStatus[systemId] = false;
    _lastSyncTimes.remove(systemId);
    
    // In a real implementation, this would revoke tokens and remove imported events
    notifyListeners();
  }

  /// Import timetable from connected system (simulated)
  Future<List<EventV2>> importFromSystem(String systemId) async {
    if (!isSystemConnected(systemId)) {
      throw StateError('System $systemId is not connected');
    }

    // Simulate import process
    await Future.delayed(const Duration(seconds: 3));
    
    // Generate sample imported events
    final importedEvents = _generateSampleImportedEvents(systemId);
    
    // Update last sync time
    _lastSyncTimes[systemId] = DateTime.now();
    
    notifyListeners();
    return importedEvents;
  }

  /// Add a class manually to the timetable
  Future<EventV2> addManualClass({
    required String title,
    required EventSubType subType,
    required String location,
    String? instructor,
    required List<int> weekdays, // 1-7, Monday = 1
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) async {
    final currentUser = _demoData.currentUser;
    
    // Create recurring events for each weekday in the date range
    final events = <EventV2>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (weekdays.contains(current.weekday)) {
        final eventStartTime = DateTime(
          current.year,
          current.month,
          current.day,
          startTime.hour,
          startTime.minute,
        );
        
        final eventEndTime = DateTime(
          current.year,
          current.month,
          current.day,
          endTime.hour,
          endTime.minute,
        );

        final event = EventV2(
          id: 'manual_${DateTime.now().millisecondsSinceEpoch}_${events.length}',
          title: title,
          description: description ?? (instructor != null ? 'Instructor: $instructor' : ''),
          startTime: eventStartTime,
          endTime: eventEndTime,
          location: location,
          category: EventCategory.academic,
          subType: subType,
          origin: EventOrigin.user,
          creatorId: currentUser.id,
          attendeeIds: [currentUser.id],
          organizerIds: [currentUser.id],
          privacyLevel: EventPrivacyLevel.private,
          sharingPermission: EventSharingPermission.noShare,
          discoverability: EventDiscoverability.calendarOnly,
          isRecurring: true,
        );
        
        events.add(event);
      }
      
      current = current.add(const Duration(days: 1));
    }

    // In a real implementation, this would persist the events
    notifyListeners();
    
    return events.first; // Return the first event as a reference
  }

  /// Remove a class from the timetable
  Future<void> removeClass(String eventId) async {
    // In a real implementation, this would remove the event from storage
    notifyListeners();
  }

  /// Update an existing class
  Future<EventV2> updateClass(String eventId, Map<String, dynamic> updates) async {
    // In a real implementation, this would update the event in storage
    notifyListeners();
    
    // For now, return a mock updated event
    final events = await getAcademicEvents();
    return events.firstWhere((e) => e.id == eventId);
  }

  /// Get class statistics
  Future<Map<String, dynamic>> getClassStatistics() async {
    final academicEvents = await getAcademicEvents();
    
    final typeCount = <EventSubType, int>{};
    var totalHours = 0.0;
    
    for (final event in academicEvents) {
      typeCount[event.subType] = (typeCount[event.subType] ?? 0) + 1;
      
      final duration = event.endTime.difference(event.startTime);
      totalHours += duration.inMinutes / 60.0;
    }

    return {
      'totalClasses': academicEvents.length,
      'totalHours': totalHours,
      'typeBreakdown': typeCount,
      'averageHoursPerWeek': totalHours / 15, // Assuming 15-week semester
    };
  }

  /// Sync all connected systems
  Future<void> syncAllSystems() async {
    for (final systemId in _connectionStatus.keys) {
      if (_connectionStatus[systemId] == true) {
        try {
          await importFromSystem(systemId);
        } catch (e) {
          print('Failed to sync $systemId: $e');
        }
      }
    }
  }

  /// Generate sample imported events for demo purposes
  List<EventV2> _generateSampleImportedEvents(String systemId) {
    final currentUser = _demoData.currentUser;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    final sampleEvents = <EventV2>[];
    
    // Sample classes based on system type
    final classData = systemId == 'uts_msa' ? [
      {
        'title': 'Software Engineering Principles',
        'subType': EventSubType.lecture,
        'location': 'CB02.06.15',
        'day': 1, // Monday
        'startHour': 10,
        'endHour': 12,
      },
      {
        'title': 'Database Systems Tutorial',
        'subType': EventSubType.tutorial,
        'location': 'CB02.07.20',
        'day': 3, // Wednesday
        'startHour': 14,
        'endHour': 16,
      },
      {
        'title': 'Programming Lab',
        'subType': EventSubType.lab,
        'location': 'CB02.05.10',
        'day': 5, // Friday
        'startHour': 9,
        'endHour': 12,
      },
    ] : [
      {
        'title': 'Imported Assignment Due',
        'subType': EventSubType.assignment,
        'location': 'Online',
        'day': 7, // Sunday
        'startHour': 23,
        'endHour': 23,
      },
    ];

    for (int week = 0; week < 15; week++) {
      for (final classInfo in classData) {
        final classDate = startOfWeek.add(Duration(days: (classInfo['day'] as int) - 1 + (week * 7)));
        
        final event = EventV2(
          id: 'imported_${systemId}_${week}_${classInfo['title']}',
          title: classInfo['title'] as String,
          description: 'Imported from ${supportedSystems[systemId]!['name']}',
          startTime: DateTime(
            classDate.year,
            classDate.month,
            classDate.day,
            classInfo['startHour'] as int,
            0,
          ),
          endTime: DateTime(
            classDate.year,
            classDate.month,
            classDate.day,
            classInfo['endHour'] as int,
            0,
          ),
          location: classInfo['location'] as String,
          category: EventCategory.academic,
          subType: classInfo['subType'] as EventSubType,
          origin: systemId == 'uts_msa' ? EventOrigin.system : EventOrigin.import,
          creatorId: currentUser.id,
          attendeeIds: [currentUser.id],
          organizerIds: [currentUser.id],
          privacyLevel: EventPrivacyLevel.private,
          sharingPermission: EventSharingPermission.noShare,
          discoverability: EventDiscoverability.calendarOnly,
          isRecurring: false,
        );
        
        sampleEvents.add(event);
      }
    }
    
    return sampleEvents;
  }

  /// Get available time slots based on current timetable
  Future<List<Map<String, dynamic>>> getAvailableTimeSlots(DateTime date) async {
    final academicEvents = await getTimetableEvents(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59),
    );
    
    // Sort events by start time
    academicEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    final availableSlots = <Map<String, dynamic>>[];
    var currentTime = DateTime(date.year, date.month, date.day, 8, 0); // Start at 8 AM
    
    for (final event in academicEvents) {
      // Add slot before this event if there's a gap
      if (currentTime.isBefore(event.startTime)) {
        availableSlots.add({
          'start': currentTime,
          'end': event.startTime,
          'duration': event.startTime.difference(currentTime),
        });
      }
      
      currentTime = event.endTime;
    }
    
    // Add slot after last event until 10 PM
    final endOfDay = DateTime(date.year, date.month, date.day, 22, 0);
    if (currentTime.isBefore(endOfDay)) {
      availableSlots.add({
        'start': currentTime,
        'end': endOfDay,
        'duration': endOfDay.difference(currentTime),
      });
    }
    
    return availableSlots;
  }

  /// Check for timetable conflicts
  Future<List<EventV2>> checkForConflicts(DateTime startTime, DateTime endTime) async {
    final academicEvents = await getTimetableEvents(
      DateTime(startTime.year, startTime.month, startTime.day),
      DateTime(endTime.year, endTime.month, endTime.day, 23, 59),
    );
    
    return academicEvents.where((event) {
      return (startTime.isBefore(event.endTime) && endTime.isAfter(event.startTime));
    }).toList();
  }
}
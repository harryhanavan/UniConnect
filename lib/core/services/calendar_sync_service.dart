import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/event.dart';
import '../demo_data/demo_data_manager.dart';
import 'event_reminder_service.dart';
import 'notification_service.dart';

enum CalendarSyncProvider {
  uts,
  google,
  outlook,
  apple,
  canvas,
  blackboard,
}

enum SyncStatus {
  notConfigured,
  syncing,
  synced,
  error,
  paused,
}

class CalendarSyncConfig {
  final CalendarSyncProvider provider;
  final String name;
  final String? url;
  final Map<String, String> credentials;
  final bool autoSync;
  final Duration syncInterval;
  final DateTime? lastSyncTime;
  final SyncStatus status;
  final String? errorMessage;

  const CalendarSyncConfig({
    required this.provider,
    required this.name,
    this.url,
    this.credentials = const {},
    this.autoSync = true,
    this.syncInterval = const Duration(hours: 4),
    this.lastSyncTime,
    this.status = SyncStatus.notConfigured,
    this.errorMessage,
  });

  CalendarSyncConfig copyWith({
    CalendarSyncProvider? provider,
    String? name,
    String? url,
    Map<String, String>? credentials,
    bool? autoSync,
    Duration? syncInterval,
    DateTime? lastSyncTime,
    SyncStatus? status,
    String? errorMessage,
  }) {
    return CalendarSyncConfig(
      provider: provider ?? this.provider,
      name: name ?? this.name,
      url: url ?? this.url,
      credentials: credentials ?? this.credentials,
      autoSync: autoSync ?? this.autoSync,
      syncInterval: syncInterval ?? this.syncInterval,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.toString(),
      'name': name,
      'url': url,
      'credentials': credentials,
      'autoSync': autoSync,
      'syncInterval': syncInterval.inMilliseconds,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'status': status.toString(),
      'errorMessage': errorMessage,
    };
  }

  static CalendarSyncConfig fromJson(Map<String, dynamic> json) {
    return CalendarSyncConfig(
      provider: CalendarSyncProvider.values.firstWhere(
        (e) => e.toString() == json['provider'],
        orElse: () => CalendarSyncProvider.uts,
      ),
      name: json['name'],
      url: json['url'],
      credentials: Map<String, String>.from(json['credentials'] ?? {}),
      autoSync: json['autoSync'] ?? true,
      syncInterval: Duration(milliseconds: json['syncInterval'] ?? 14400000),
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'])
          : null,
      status: SyncStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => SyncStatus.notConfigured,
      ),
      errorMessage: json['errorMessage'],
    );
  }
}

class ImportedEvent {
  final String id;
  final String sourceCalendarId;
  final EventV2 event;
  final DateTime importedAt;
  final Map<String, dynamic> originalData;

  const ImportedEvent({
    required this.id,
    required this.sourceCalendarId,
    required this.event,
    required this.importedAt,
    this.originalData = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceCalendarId': sourceCalendarId,
      'event': event.toJson(),
      'importedAt': importedAt.toIso8601String(),
      'originalData': originalData,
    };
  }

  static ImportedEvent fromJson(Map<String, dynamic> json) {
    return ImportedEvent(
      id: json['id'],
      sourceCalendarId: json['sourceCalendarId'],
      event: EventV2.fromJson(json['event']),
      importedAt: DateTime.parse(json['importedAt']),
      originalData: Map<String, dynamic>.from(json['originalData'] ?? {}),
    );
  }
}

class CalendarSyncService {
  static final CalendarSyncService _instance = CalendarSyncService._internal();
  factory CalendarSyncService() => _instance;
  CalendarSyncService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  final EventReminderService _reminderService = EventReminderService();
  final NotificationService _notificationService = NotificationService();

  final StreamController<List<CalendarSyncConfig>> _configsController =
      StreamController<List<CalendarSyncConfig>>.broadcast();
  final StreamController<List<ImportedEvent>> _eventsController =
      StreamController<List<ImportedEvent>>.broadcast();

  final List<CalendarSyncConfig> _syncConfigs = [];
  final List<ImportedEvent> _importedEvents = [];
  Timer? _autoSyncTimer;

  Stream<List<CalendarSyncConfig>> get configsStream => _configsController.stream;
  Stream<List<ImportedEvent>> get eventsStream => _eventsController.stream;

  List<CalendarSyncConfig> get syncConfigs => List.from(_syncConfigs);
  List<ImportedEvent> get importedEvents => List.from(_importedEvents);

  Future<void> initialize() async {
    await _loadSyncConfigs();
    await _loadImportedEvents();
    _startAutoSyncTimer();
  }

  /// Add a new calendar sync configuration
  Future<void> addCalendarSync({
    required CalendarSyncProvider provider,
    required String name,
    String? url,
    Map<String, String>? credentials,
    bool autoSync = true,
    Duration syncInterval = const Duration(hours: 4),
  }) async {
    final config = CalendarSyncConfig(
      provider: provider,
      name: name,
      url: url,
      credentials: credentials ?? {},
      autoSync: autoSync,
      syncInterval: syncInterval,
      status: SyncStatus.notConfigured,
    );

    _syncConfigs.add(config);
    await _saveSyncConfigs();
    _configsController.add(List.from(_syncConfigs));

    // Test connection and perform initial sync
    await testConnection(config);
  }

  /// Test connection to external calendar
  Future<bool> testConnection(CalendarSyncConfig config) async {
    try {
      final index = _syncConfigs.indexWhere((c) => c.name == config.name);
      if (index == -1) return false;

      _syncConfigs[index] = config.copyWith(status: SyncStatus.syncing);
      _configsController.add(List.from(_syncConfigs));

      bool success = false;

      switch (config.provider) {
        case CalendarSyncProvider.uts:
          success = await _testUTSConnection(config);
          break;
        case CalendarSyncProvider.google:
          success = await _testGoogleConnection(config);
          break;
        case CalendarSyncProvider.outlook:
          success = await _testOutlookConnection(config);
          break;
        case CalendarSyncProvider.canvas:
          success = await _testCanvasConnection(config);
          break;
        case CalendarSyncProvider.blackboard:
          success = await _testBlackboardConnection(config);
          break;
        case CalendarSyncProvider.apple:
          success = await _testAppleConnection(config);
          break;
      }

      final newStatus = success ? SyncStatus.synced : SyncStatus.error;
      _syncConfigs[index] = config.copyWith(
        status: newStatus,
        lastSyncTime: success ? DateTime.now() : null,
        errorMessage: success ? null : 'Connection failed',
      );

      await _saveSyncConfigs();
      _configsController.add(List.from(_syncConfigs));

      if (success) {
        await _notificationService.sendNotification(
          userId: 'current_user',
          title: 'Calendar Connected',
          body: '${config.name} calendar sync is now active',
          type: NotificationType.eventReminder,
        );
      }

      return success;
    } catch (e) {
      print('Calendar sync test failed: $e');
      return false;
    }
  }

  /// Sync all configured calendars
  Future<void> syncAllCalendars(String userId) async {
    for (final config in _syncConfigs) {
      if (config.status == SyncStatus.synced || config.status == SyncStatus.error) {
        await syncCalendar(config, userId);
      }
    }
  }

  /// Sync a specific calendar
  Future<void> syncCalendar(CalendarSyncConfig config, String userId) async {
    try {
      final index = _syncConfigs.indexWhere((c) => c.name == config.name);
      if (index == -1) return;

      _syncConfigs[index] = config.copyWith(status: SyncStatus.syncing);
      _configsController.add(List.from(_syncConfigs));

      List<EventV2> newEvents = [];

      switch (config.provider) {
        case CalendarSyncProvider.uts:
          newEvents = await _syncUTSCalendar(config, userId);
          break;
        case CalendarSyncProvider.google:
          newEvents = await _syncGoogleCalendar(config, userId);
          break;
        case CalendarSyncProvider.outlook:
          newEvents = await _syncOutlookCalendar(config, userId);
          break;
        case CalendarSyncProvider.canvas:
          newEvents = await _syncCanvasCalendar(config, userId);
          break;
        case CalendarSyncProvider.blackboard:
          newEvents = await _syncBlackboardCalendar(config, userId);
          break;
        case CalendarSyncProvider.apple:
          newEvents = await _syncAppleCalendar(config, userId);
          break;
      }

      // Process imported events
      for (final event in newEvents) {
        final importedEvent = ImportedEvent(
          id: 'imported_${event.id}_${DateTime.now().millisecondsSinceEpoch}',
          sourceCalendarId: config.name,
          event: event,
          importedAt: DateTime.now(),
        );

        _importedEvents.add(importedEvent);

        // Schedule reminders for imported events
        await _reminderService.scheduleEventReminders(userId, event);
      }

      _syncConfigs[index] = config.copyWith(
        status: SyncStatus.synced,
        lastSyncTime: DateTime.now(),
        errorMessage: null,
      );

      await _saveSyncConfigs();
      await _saveImportedEvents();
      _configsController.add(List.from(_syncConfigs));
      _eventsController.add(List.from(_importedEvents));

      if (newEvents.isNotEmpty) {
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Calendar Updated',
          body: 'Added ${newEvents.length} events from ${config.name}',
          type: NotificationType.eventReminder,
        );
      }
    } catch (e) {
      final index = _syncConfigs.indexWhere((c) => c.name == config.name);
      if (index != -1) {
        _syncConfigs[index] = config.copyWith(
          status: SyncStatus.error,
          errorMessage: 'Sync failed: $e',
        );
        await _saveSyncConfigs();
        _configsController.add(List.from(_syncConfigs));
      }
      print('Calendar sync failed: $e');
    }
  }

  /// Export user schedule to various formats
  Future<String> exportSchedule({
    required String userId,
    required String format, // 'ics', 'json', 'csv'
    DateTime? startDate,
    DateTime? endDate,
    List<EventCategory>? categories,
  }) async {
    final start = startDate ?? DateTime.now();
    final end = endDate ?? start.add(const Duration(days: 30));

    // Get user events
    final events = await _demoData.enhancedEvents;
    final userEvents = events.where((event) {
      final relationship = event.getUserRelationship(userId);
      final inDateRange = event.startTime.isAfter(start) && event.startTime.isBefore(end);
      final hasRelationship = relationship != EventRelationship.none;
      final categoryMatch = categories?.contains(event.category) ?? true;

      return inDateRange && hasRelationship && categoryMatch;
    }).toList();

    switch (format.toLowerCase()) {
      case 'ics':
        return _exportToICS(userEvents);
      case 'json':
        return _exportToJSON(userEvents);
      case 'csv':
        return _exportToCSV(userEvents);
      default:
        throw ArgumentError('Unsupported format: $format');
    }
  }

  /// Import calendar from file
  Future<List<EventV2>> importFromFile(String filePath, String userId) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError('File not found: $filePath');
    }

    final content = await file.readAsString();
    final extension = filePath.split('.').last.toLowerCase();

    List<EventV2> events = [];

    switch (extension) {
      case 'ics':
        events = _parseICS(content, userId);
        break;
      case 'json':
        events = _parseJSON(content, userId);
        break;
      case 'csv':
        events = _parseCSV(content, userId);
        break;
      default:
        throw ArgumentError('Unsupported file format: $extension');
    }

    // Add imported events
    for (final event in events) {
      final importedEvent = ImportedEvent(
        id: 'import_${event.id}_${DateTime.now().millisecondsSinceEpoch}',
        sourceCalendarId: 'file_import',
        event: event,
        importedAt: DateTime.now(),
      );

      _importedEvents.add(importedEvent);
      await _reminderService.scheduleEventReminders(userId, event);
    }

    await _saveImportedEvents();
    _eventsController.add(List.from(_importedEvents));

    return events;
  }

  /// Remove a calendar sync configuration
  Future<void> removeCalendarSync(String configName) async {
    // Remove config
    _syncConfigs.removeWhere((config) => config.name == configName);

    // Remove associated imported events
    _importedEvents.removeWhere((event) => event.sourceCalendarId == configName);

    await _saveSyncConfigs();
    await _saveImportedEvents();
    _configsController.add(List.from(_syncConfigs));
    _eventsController.add(List.from(_importedEvents));
  }

  /// Update sync configuration
  Future<void> updateSyncConfig(CalendarSyncConfig updatedConfig) async {
    final index = _syncConfigs.indexWhere((c) => c.name == updatedConfig.name);
    if (index != -1) {
      _syncConfigs[index] = updatedConfig;
      await _saveSyncConfigs();
      _configsController.add(List.from(_syncConfigs));
    }
  }

  // Private methods for specific calendar providers

  Future<bool> _testUTSConnection(CalendarSyncConfig config) async {
    // Simulate UTS timetable API connection
    await Future.delayed(const Duration(seconds: 2));
    return config.credentials.containsKey('studentId') &&
           config.credentials.containsKey('password');
  }

  Future<List<EventV2>> _syncUTSCalendar(CalendarSyncConfig config, String userId) async {
    // Simulate UTS timetable sync
    await Future.delayed(const Duration(seconds: 3));

    // In a real implementation, this would fetch from UTS API
    // For demo, we'll create some sample academic events
    final events = <EventV2>[];
    final now = DateTime.now();

    for (int i = 0; i < 5; i++) {
      events.add(EventV2(
        id: 'uts_import_${now.millisecondsSinceEpoch}_$i',
        title: 'Lecture ${i + 1}',
        description: 'Imported from UTS timetable',
        startTime: now.add(Duration(days: i)),
        endTime: now.add(Duration(days: i, hours: 2)),
        location: 'Building 11.${i + 1}',
        category: EventCategory.academic,
        subType: EventSubType.lecture,
        origin: EventOrigin.import,
        creatorId: userId,
        attendeeIds: [userId],
        importSource: 'UTS',
        lastSyncTime: DateTime.now(),
      ));
    }

    return events;
  }

  Future<bool> _testGoogleConnection(CalendarSyncConfig config) async {
    await Future.delayed(const Duration(seconds: 2));
    return config.credentials.containsKey('accessToken');
  }

  Future<List<EventV2>> _syncGoogleCalendar(CalendarSyncConfig config, String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    // Google Calendar API implementation would go here
    return [];
  }

  Future<bool> _testOutlookConnection(CalendarSyncConfig config) async {
    await Future.delayed(const Duration(seconds: 2));
    return config.credentials.containsKey('accessToken');
  }

  Future<List<EventV2>> _syncOutlookCalendar(CalendarSyncConfig config, String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    // Outlook Calendar API implementation would go here
    return [];
  }

  Future<bool> _testCanvasConnection(CalendarSyncConfig config) async {
    await Future.delayed(const Duration(seconds: 2));
    return config.url != null && config.credentials.containsKey('apiKey');
  }

  Future<List<EventV2>> _syncCanvasCalendar(CalendarSyncConfig config, String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    // Canvas API implementation would go here
    return [];
  }

  Future<bool> _testBlackboardConnection(CalendarSyncConfig config) async {
    await Future.delayed(const Duration(seconds: 2));
    return config.url != null && config.credentials.containsKey('username');
  }

  Future<List<EventV2>> _syncBlackboardCalendar(CalendarSyncConfig config, String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    // Blackboard API implementation would go here
    return [];
  }

  Future<bool> _testAppleConnection(CalendarSyncConfig config) async {
    await Future.delayed(const Duration(seconds: 2));
    return config.credentials.containsKey('username') &&
           config.credentials.containsKey('password');
  }

  Future<List<EventV2>> _syncAppleCalendar(CalendarSyncConfig config, String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    // Apple Calendar implementation would go here
    return [];
  }

  // Export format implementations

  String _exportToICS(List<EventV2> events) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:UniConnect');
    buffer.writeln('CALSCALE:GREGORIAN');

    for (final event in events) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${event.id}@uniconnect.app');
      buffer.writeln('DTSTART:${_formatICSDateTime(event.startTime)}');
      buffer.writeln('DTEND:${_formatICSDateTime(event.endTime)}');
      buffer.writeln('SUMMARY:${event.title}');
      buffer.writeln('DESCRIPTION:${event.description}');
      buffer.writeln('LOCATION:${event.location}');
      buffer.writeln('CATEGORIES:${event.category.toString().split('.').last.toUpperCase()}');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  String _exportToJSON(List<EventV2> events) {
    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'source': 'UniConnect',
      'events': events.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  String _exportToCSV(List<EventV2> events) {
    final buffer = StringBuffer();
    buffer.writeln('Title,Description,Start Time,End Time,Location,Category,Type');

    for (final event in events) {
      buffer.writeln([
        '"${event.title}"',
        '"${event.description}"',
        '"${event.startTime.toIso8601String()}"',
        '"${event.endTime.toIso8601String()}"',
        '"${event.location}"',
        '"${event.category.toString().split('.').last}"',
        '"${event.subType.toString().split('.').last}"',
      ].join(','));
    }

    return buffer.toString();
  }

  // Import format parsers

  List<EventV2> _parseICS(String content, String userId) {
    final events = <EventV2>[];
    final lines = content.split('\n');

    EventV2? currentEvent;
    Map<String, String> eventData = {};

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed == 'BEGIN:VEVENT') {
        eventData = {};
      } else if (trimmed == 'END:VEVENT') {
        if (eventData.isNotEmpty) {
          currentEvent = _createEventFromICSData(eventData, userId);
          if (currentEvent != null) {
            events.add(currentEvent);
          }
        }
      } else if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          final key = parts[0];
          final value = parts.sublist(1).join(':');
          eventData[key] = value;
        }
      }
    }

    return events;
  }

  List<EventV2> _parseJSON(String content, String userId) {
    final data = jsonDecode(content);
    final eventsData = data['events'] as List? ?? [];

    return eventsData.map((eventData) {
      return EventV2.fromJson(eventData);
    }).toList();
  }

  List<EventV2> _parseCSV(String content, String userId) {
    final events = <EventV2>[];
    final lines = content.split('\n');

    if (lines.isEmpty) return events;

    // Skip header
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = _parseCSVLine(line);
      if (fields.length >= 6) {
        try {
          final event = EventV2(
            id: 'csv_import_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: fields[0],
            description: fields[1],
            startTime: DateTime.parse(fields[2]),
            endTime: DateTime.parse(fields[3]),
            location: fields[4],
            category: _parseEventCategory(fields[5]),
            subType: fields.length > 6 ? _parseEventSubType(fields[6]) : EventSubType.personalGoal,
            origin: EventOrigin.import,
            creatorId: userId,
            attendeeIds: [userId],
          );
          events.add(event);
        } catch (e) {
          print('Error parsing CSV line $i: $e');
        }
      }
    }

    return events;
  }

  EventV2? _createEventFromICSData(Map<String, String> data, String userId) {
    try {
      return EventV2(
        id: 'ics_import_${DateTime.now().millisecondsSinceEpoch}',
        title: data['SUMMARY'] ?? 'Imported Event',
        description: data['DESCRIPTION'] ?? '',
        startTime: _parseICSDateTime(data['DTSTART'] ?? ''),
        endTime: _parseICSDateTime(data['DTEND'] ?? ''),
        location: data['LOCATION'] ?? '',
        category: _parseEventCategory(data['CATEGORIES'] ?? 'PERSONAL'),
        subType: EventSubType.personalGoal,
        origin: EventOrigin.import,
        creatorId: userId,
        attendeeIds: [userId],
      );
    } catch (e) {
      print('Error creating event from ICS data: $e');
      return null;
    }
  }

  // Helper methods

  String _formatICSDateTime(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0] + 'Z';
  }

  DateTime _parseICSDateTime(String icsDateTime) {
    if (icsDateTime.endsWith('Z')) {
      icsDateTime = icsDateTime.substring(0, icsDateTime.length - 1);
    }

    final formatted = '${icsDateTime.substring(0, 4)}-${icsDateTime.substring(4, 6)}-${icsDateTime.substring(6, 8)}T${icsDateTime.substring(9, 11)}:${icsDateTime.substring(11, 13)}:${icsDateTime.substring(13, 15)}Z';
    return DateTime.parse(formatted);
  }

  List<String> _parseCSVLine(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    String currentField = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField);
        currentField = '';
      } else {
        currentField += char;
      }
    }

    fields.add(currentField);
    return fields;
  }

  EventCategory _parseEventCategory(String category) {
    final normalized = category.toLowerCase();

    if (normalized.contains('academic') || normalized.contains('class') || normalized.contains('lecture')) {
      return EventCategory.academic;
    } else if (normalized.contains('society') || normalized.contains('club')) {
      return EventCategory.society;
    } else if (normalized.contains('social') || normalized.contains('party')) {
      return EventCategory.social;
    } else if (normalized.contains('university') || normalized.contains('uni')) {
      return EventCategory.university;
    } else {
      return EventCategory.personal;
    }
  }

  EventSubType _parseEventSubType(String subType) {
    final normalized = subType.toLowerCase();

    // Academic types
    if (normalized.contains('lecture')) return EventSubType.lecture;
    if (normalized.contains('tutorial')) return EventSubType.tutorial;
    if (normalized.contains('lab')) return EventSubType.lab;
    if (normalized.contains('exam')) return EventSubType.exam;
    if (normalized.contains('assignment')) return EventSubType.assignment;

    // Social types
    if (normalized.contains('party')) return EventSubType.party;
    if (normalized.contains('hangout')) return EventSubType.hangout;
    if (normalized.contains('meetup')) return EventSubType.meetup;

    // Society types
    if (normalized.contains('meeting')) return EventSubType.meeting;
    if (normalized.contains('workshop')) return EventSubType.societyWorkshop;

    return EventSubType.personalGoal;
  }

  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _performAutoSync();
    });
  }

  Future<void> _performAutoSync() async {
    final now = DateTime.now();

    for (final config in _syncConfigs) {
      if (config.autoSync &&
          config.status == SyncStatus.synced &&
          config.lastSyncTime != null) {

        final timeSinceLastSync = now.difference(config.lastSyncTime!);
        if (timeSinceLastSync >= config.syncInterval) {
          await syncCalendar(config, 'current_user');
        }
      }
    }
  }

  // Persistence methods

  Future<void> _loadSyncConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString('calendar_sync_configs');
    if (configsJson != null) {
      try {
        final data = jsonDecode(configsJson) as List;
        _syncConfigs.clear();
        _syncConfigs.addAll(
          data.map((item) => CalendarSyncConfig.fromJson(item)).toList(),
        );
      } catch (e) {
        print('Error loading sync configs: $e');
      }
    }
  }

  Future<void> _saveSyncConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _syncConfigs.map((config) => config.toJson()).toList();
    await prefs.setString('calendar_sync_configs', jsonEncode(data));
  }

  Future<void> _loadImportedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('imported_events');
    if (eventsJson != null) {
      try {
        final data = jsonDecode(eventsJson) as List;
        _importedEvents.clear();
        _importedEvents.addAll(
          data.map((item) => ImportedEvent.fromJson(item)).toList(),
        );
      } catch (e) {
        print('Error loading imported events: $e');
      }
    }
  }

  Future<void> _saveImportedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _importedEvents.map((event) => event.toJson()).toList();
    await prefs.setString('imported_events', jsonEncode(data));
  }

  void dispose() {
    _autoSyncTimer?.cancel();
    _configsController.close();
    _eventsController.close();
  }
}
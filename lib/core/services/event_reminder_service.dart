import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/event.dart';
import '../demo_data/demo_data_manager.dart';
import 'notification_service.dart';
import 'calendar_service.dart';

enum ReminderType {
  oneWeek,
  oneDay,
  fourHours,
  oneHour,
  fifteenMinutes,
  fiveMinutes,
}

enum ReminderPriority {
  low,
  normal,
  high,
  critical,
}

class ReminderSettings {
  final Map<EventCategory, List<ReminderType>> categoryReminders;
  final Map<EventSubType, List<ReminderType>> customReminders;
  final bool enablePushNotifications;
  final bool enableInAppNotifications;
  final bool enableSoundForCritical;
  final bool enableVibrationForCritical;

  const ReminderSettings({
    required this.categoryReminders,
    this.customReminders = const {},
    this.enablePushNotifications = true,
    this.enableInAppNotifications = true,
    this.enableSoundForCritical = true,
    this.enableVibrationForCritical = true,
  });

  static ReminderSettings getDefault() {
    return ReminderSettings(
      categoryReminders: {
        EventCategory.academic: [
          ReminderType.oneDay,
          ReminderType.oneHour,
          ReminderType.fifteenMinutes,
        ],
        EventCategory.society: [
          ReminderType.oneDay,
          ReminderType.oneHour,
        ],
        EventCategory.social: [
          ReminderType.fourHours,
          ReminderType.fifteenMinutes,
        ],
        EventCategory.personal: [
          ReminderType.oneHour,
          ReminderType.fifteenMinutes,
        ],
        EventCategory.university: [
          ReminderType.oneDay,
          ReminderType.oneHour,
        ],
      },
      customReminders: {
        EventSubType.exam: [
          ReminderType.oneWeek,
          ReminderType.oneDay,
          ReminderType.fourHours,
          ReminderType.oneHour,
        ],
        EventSubType.assignment: [
          ReminderType.oneDay,
          ReminderType.fourHours,
          ReminderType.oneHour,
        ],
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryReminders': categoryReminders.map(
        (key, value) => MapEntry(
          key.toString(),
          value.map((r) => r.toString()).toList(),
        ),
      ),
      'customReminders': customReminders.map(
        (key, value) => MapEntry(
          key.toString(),
          value.map((r) => r.toString()).toList(),
        ),
      ),
      'enablePushNotifications': enablePushNotifications,
      'enableInAppNotifications': enableInAppNotifications,
      'enableSoundForCritical': enableSoundForCritical,
      'enableVibrationForCritical': enableVibrationForCritical,
    };
  }

  static ReminderSettings fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      categoryReminders: (json['categoryReminders'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                    EventCategory.values.firstWhere(
                      (e) => e.toString() == key,
                      orElse: () => EventCategory.personal,
                    ),
                    (value as List)
                        .map((r) => ReminderType.values.firstWhere(
                              (e) => e.toString() == r,
                              orElse: () => ReminderType.fifteenMinutes,
                            ))
                        .toList(),
                  )) ??
          ReminderSettings.getDefault().categoryReminders,
      customReminders: (json['customReminders'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                    EventSubType.values.firstWhere(
                      (e) => e.toString() == key,
                      orElse: () => EventSubType.personalGoal,
                    ),
                    (value as List)
                        .map((r) => ReminderType.values.firstWhere(
                              (e) => e.toString() == r,
                              orElse: () => ReminderType.fifteenMinutes,
                            ))
                        .toList(),
                  )) ??
          {},
      enablePushNotifications: json['enablePushNotifications'] ?? true,
      enableInAppNotifications: json['enableInAppNotifications'] ?? true,
      enableSoundForCritical: json['enableSoundForCritical'] ?? true,
      enableVibrationForCritical: json['enableVibrationForCritical'] ?? true,
    );
  }
}

class ScheduledReminder {
  final String id;
  final String eventId;
  final String userId;
  final ReminderType type;
  final DateTime scheduledTime;
  final ReminderPriority priority;
  final String title;
  final String body;
  final bool isCompleted;
  final bool isPushNotification;

  const ScheduledReminder({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.type,
    required this.scheduledTime,
    required this.priority,
    required this.title,
    required this.body,
    this.isCompleted = false,
    this.isPushNotification = false,
  });

  ScheduledReminder copyWith({
    String? id,
    String? eventId,
    String? userId,
    ReminderType? type,
    DateTime? scheduledTime,
    ReminderPriority? priority,
    String? title,
    String? body,
    bool? isCompleted,
    bool? isPushNotification,
  }) {
    return ScheduledReminder(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      body: body ?? this.body,
      isCompleted: isCompleted ?? this.isCompleted,
      isPushNotification: isPushNotification ?? this.isPushNotification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'type': type.toString(),
      'scheduledTime': scheduledTime.toIso8601String(),
      'priority': priority.toString(),
      'title': title,
      'body': body,
      'isCompleted': isCompleted,
      'isPushNotification': isPushNotification,
    };
  }

  static ScheduledReminder fromJson(Map<String, dynamic> json) {
    return ScheduledReminder(
      id: json['id'],
      eventId: json['eventId'],
      userId: json['userId'],
      type: ReminderType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ReminderType.fifteenMinutes,
      ),
      scheduledTime: DateTime.parse(json['scheduledTime']),
      priority: ReminderPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => ReminderPriority.normal,
      ),
      title: json['title'],
      body: json['body'],
      isCompleted: json['isCompleted'] ?? false,
      isPushNotification: json['isPushNotification'] ?? false,
    );
  }
}

class EventReminderService {
  static final EventReminderService _instance = EventReminderService._internal();
  factory EventReminderService() => _instance;
  EventReminderService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DemoDataManager _demoData = DemoDataManager.instance;
  final NotificationService _notificationService = NotificationService();
  final CalendarService _calendarService = CalendarService();

  final StreamController<List<ScheduledReminder>> _remindersController =
      StreamController<List<ScheduledReminder>>.broadcast();

  bool _isInitialized = false;
  ReminderSettings _settings = ReminderSettings.getDefault();
  final List<ScheduledReminder> _scheduledReminders = [];
  Timer? _reminderCheckTimer;

  Stream<List<ScheduledReminder>> get remindersStream => _remindersController.stream;
  ReminderSettings get settings => _settings;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Load settings and scheduled reminders
    await _loadSettings();
    await _loadScheduledReminders();

    // Start background reminder checking
    _startReminderTimer();

    _isInitialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        final eventId = data['eventId'] as String?;
        final action = data['action'] as String?;

        if (eventId != null) {
          _handleNotificationAction(eventId, action);
        }
      } catch (e) {
        print('Error handling notification response: $e');
      }
    }
  }

  void _handleNotificationAction(String eventId, String? action) {
    switch (action) {
      case 'mark_done':
        markEventCompleted(eventId);
        break;
      case 'snooze':
        snoozeReminder(eventId, const Duration(minutes: 10));
        break;
      case 'view_event':
        // This would typically navigate to event details
        // In a real app, you'd use a navigation service
        break;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('reminder_settings');
    if (settingsJson != null) {
      try {
        final data = jsonDecode(settingsJson);
        _settings = ReminderSettings.fromJson(data);
      } catch (e) {
        print('Error loading reminder settings: $e');
        _settings = ReminderSettings.getDefault();
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_settings', jsonEncode(_settings.toJson()));
  }

  Future<void> _loadScheduledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString('scheduled_reminders');
    if (remindersJson != null) {
      try {
        final data = jsonDecode(remindersJson) as List;
        _scheduledReminders.clear();
        _scheduledReminders.addAll(
          data.map((item) => ScheduledReminder.fromJson(item)).toList(),
        );
      } catch (e) {
        print('Error loading scheduled reminders: $e');
      }
    }
  }

  Future<void> _saveScheduledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _scheduledReminders.map((r) => r.toJson()).toList();
    await prefs.setString('scheduled_reminders', jsonEncode(data));
  }

  void _startReminderTimer() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndTriggerReminders();
    });
  }

  Future<void> _checkAndTriggerReminders() async {
    final now = DateTime.now();
    final dueReminders = _scheduledReminders
        .where((reminder) =>
            !reminder.isCompleted &&
            reminder.scheduledTime.isBefore(now.add(const Duration(minutes: 1))))
        .toList();

    for (final reminder in dueReminders) {
      await _triggerReminder(reminder);

      // Mark as completed
      final index = _scheduledReminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _scheduledReminders[index] = reminder.copyWith(isCompleted: true);
      }
    }

    if (dueReminders.isNotEmpty) {
      await _saveScheduledReminders();
      _remindersController.add(List.from(_scheduledReminders));
    }
  }

  Future<void> _triggerReminder(ScheduledReminder reminder) async {
    // Send in-app notification if enabled
    if (_settings.enableInAppNotifications) {
      await _notificationService.sendNotification(
        userId: reminder.userId,
        title: reminder.title,
        body: reminder.body,
        type: NotificationType.eventReminder,
        data: {
          'eventId': reminder.eventId,
          'reminderType': reminder.type.toString(),
          'priority': reminder.priority.toString(),
        },
        actionUrl: '/calendar/event/${reminder.eventId}',
      );
    }

    // Show push notification if enabled and app is backgrounded
    if (_settings.enablePushNotifications && reminder.isPushNotification) {
      await _showPushNotification(reminder);
    }
  }

  Future<void> _showPushNotification(ScheduledReminder reminder) async {
    final androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Event Reminders',
      channelDescription: 'Notifications for upcoming events and assignments',
      importance: _getAndroidImportance(reminder.priority),
      priority: _getAndroidPriority(reminder.priority),
      enableVibration: _settings.enableVibrationForCritical &&
          reminder.priority == ReminderPriority.critical,
      playSound: _settings.enableSoundForCritical &&
          reminder.priority == ReminderPriority.critical,
      actions: _getNotificationActions(reminder),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      reminder.id.hashCode,
      reminder.title,
      reminder.body,
      details,
      payload: jsonEncode({
        'eventId': reminder.eventId,
        'reminderType': reminder.type.toString(),
      }),
    );
  }

  Importance _getAndroidImportance(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.critical:
        return Importance.max;
      case ReminderPriority.high:
        return Importance.high;
      case ReminderPriority.normal:
        return Importance.defaultImportance;
      case ReminderPriority.low:
        return Importance.low;
    }
  }

  Priority _getAndroidPriority(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.critical:
        return Priority.max;
      case ReminderPriority.high:
        return Priority.high;
      case ReminderPriority.normal:
        return Priority.defaultPriority;
      case ReminderPriority.low:
        return Priority.low;
    }
  }

  List<AndroidNotificationAction> _getNotificationActions(ScheduledReminder reminder) {
    final actions = <AndroidNotificationAction>[];

    // Add "Mark Done" action for assignments and personal tasks
    if (reminder.type == ReminderType.oneHour ||
        reminder.type == ReminderType.fifteenMinutes) {
      actions.add(const AndroidNotificationAction(
        'mark_done',
        'Mark Done',
        showsUserInterface: false,
      ));
    }

    // Add "Snooze" action
    actions.add(const AndroidNotificationAction(
      'snooze',
      'Snooze 10min',
      showsUserInterface: false,
    ));

    // Add "View" action
    actions.add(const AndroidNotificationAction(
      'view_event',
      'View Event',
      showsUserInterface: true,
    ));

    return actions;
  }

  /// Schedule reminders for a specific event
  Future<void> scheduleEventReminders(String userId, EventV2 event) async {
    if (!_isInitialized) await initialize();

    // Get reminder types for this event
    final reminderTypes = _getReminderTypesForEvent(event);

    // Clear existing reminders for this event
    await cancelEventReminders(event.id);

    final now = DateTime.now();
    final scheduledReminders = <ScheduledReminder>[];

    for (final reminderType in reminderTypes) {
      final reminderTime = _calculateReminderTime(event.startTime, reminderType);

      // Only schedule future reminders
      if (reminderTime.isAfter(now)) {
        final reminder = ScheduledReminder(
          id: 'reminder_${event.id}_${reminderType.toString()}_${DateTime.now().millisecondsSinceEpoch}',
          eventId: event.id,
          userId: userId,
          type: reminderType,
          scheduledTime: reminderTime,
          priority: _getPriorityForEvent(event, reminderType),
          title: _getReminderTitle(event, reminderType),
          body: _getReminderBody(event, reminderType),
          isPushNotification: _settings.enablePushNotifications,
        );

        scheduledReminders.add(reminder);
      }
    }

    _scheduledReminders.addAll(scheduledReminders);
    await _saveScheduledReminders();
    _remindersController.add(List.from(_scheduledReminders));
  }

  /// Schedule reminders for all user events
  Future<void> scheduleAllEventReminders(String userId) async {
    if (!_isInitialized) await initialize();

    final events = await _calendarService.getEnhancedUnifiedCalendar(
      userId,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    for (final event in events) {
      await scheduleEventReminders(userId, event);
    }
  }

  /// Cancel reminders for a specific event
  Future<void> cancelEventReminders(String eventId) async {
    _scheduledReminders.removeWhere((reminder) => reminder.eventId == eventId);
    await _saveScheduledReminders();
    _remindersController.add(List.from(_scheduledReminders));

    // Cancel push notifications
    final notificationIds = _scheduledReminders
        .where((r) => r.eventId == eventId)
        .map((r) => r.id.hashCode)
        .toList();

    for (final id in notificationIds) {
      await _localNotifications.cancel(id);
    }
  }

  /// Mark an event as completed (cancels remaining reminders)
  Future<void> markEventCompleted(String eventId) async {
    final reminders = _scheduledReminders
        .where((r) => r.eventId == eventId && !r.isCompleted)
        .toList();

    for (final reminder in reminders) {
      final index = _scheduledReminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _scheduledReminders[index] = reminder.copyWith(isCompleted: true);
      }

      // Cancel push notification
      await _localNotifications.cancel(reminder.id.hashCode);
    }

    await _saveScheduledReminders();
    _remindersController.add(List.from(_scheduledReminders));
  }

  /// Snooze a reminder
  Future<void> snoozeReminder(String eventId, Duration snoozeFor) async {
    final activeReminders = _scheduledReminders
        .where((r) => r.eventId == eventId && !r.isCompleted)
        .toList();

    for (final reminder in activeReminders) {
      final newTime = reminder.scheduledTime.add(snoozeFor);
      final index = _scheduledReminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _scheduledReminders[index] = reminder.copyWith(scheduledTime: newTime);
      }
    }

    await _saveScheduledReminders();
    _remindersController.add(List.from(_scheduledReminders));
  }

  /// Get upcoming reminders for a user
  List<ScheduledReminder> getUpcomingReminders(String userId, {int? limit}) {
    final now = DateTime.now();
    final upcoming = _scheduledReminders
        .where((r) => r.userId == userId && !r.isCompleted && r.scheduledTime.isAfter(now))
        .toList();

    upcoming.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return limit != null ? upcoming.take(limit).toList() : upcoming;
  }

  /// Update reminder settings
  Future<void> updateSettings(ReminderSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
  }

  /// Get reminder types for an event based on category and subtype
  List<ReminderType> _getReminderTypesForEvent(EventV2 event) {
    // Check for custom reminders first
    if (_settings.customReminders.containsKey(event.subType)) {
      return _settings.customReminders[event.subType]!;
    }

    // Fall back to category reminders
    return _settings.categoryReminders[event.category] ??
           [ReminderType.fifteenMinutes];
  }

  /// Calculate reminder time based on event start and reminder type
  DateTime _calculateReminderTime(DateTime eventStart, ReminderType type) {
    switch (type) {
      case ReminderType.oneWeek:
        return eventStart.subtract(const Duration(days: 7));
      case ReminderType.oneDay:
        return eventStart.subtract(const Duration(days: 1));
      case ReminderType.fourHours:
        return eventStart.subtract(const Duration(hours: 4));
      case ReminderType.oneHour:
        return eventStart.subtract(const Duration(hours: 1));
      case ReminderType.fifteenMinutes:
        return eventStart.subtract(const Duration(minutes: 15));
      case ReminderType.fiveMinutes:
        return eventStart.subtract(const Duration(minutes: 5));
    }
  }

  /// Get priority for an event and reminder type
  ReminderPriority _getPriorityForEvent(EventV2 event, ReminderType reminderType) {
    // Critical events: exams, important assignments
    if (event.subType == EventSubType.exam) {
      return ReminderPriority.critical;
    }

    // High priority: assignments, meetings close to deadline
    if (event.subType == EventSubType.assignment ||
        event.subType == EventSubType.meeting) {
      if (reminderType == ReminderType.oneHour ||
          reminderType == ReminderType.fifteenMinutes) {
        return ReminderPriority.high;
      }
    }

    // Normal priority for most events
    if (event.category == EventCategory.academic ||
        event.category == EventCategory.university) {
      return ReminderPriority.normal;
    }

    // Low priority for social events
    return ReminderPriority.low;
  }

  /// Generate reminder title
  String _getReminderTitle(EventV2 event, ReminderType reminderType) {
    final timeString = _getReminderTimeString(reminderType);

    switch (event.subType) {
      case EventSubType.exam:
        return 'Exam in $timeString';
      case EventSubType.assignment:
        return 'Assignment due in $timeString';
      case EventSubType.lecture:
      case EventSubType.tutorial:
      case EventSubType.lab:
        return 'Class in $timeString';
      case EventSubType.meeting:
        return 'Meeting in $timeString';
      default:
        return '${event.title} in $timeString';
    }
  }

  /// Generate reminder body
  String _getReminderBody(EventV2 event, ReminderType reminderType) {
    final location = event.location.isNotEmpty ? ' at ${event.location}' : '';
    return '${event.title}$location';
  }

  /// Get human-readable time string for reminder type
  String _getReminderTimeString(ReminderType type) {
    switch (type) {
      case ReminderType.oneWeek:
        return '1 week';
      case ReminderType.oneDay:
        return '1 day';
      case ReminderType.fourHours:
        return '4 hours';
      case ReminderType.oneHour:
        return '1 hour';
      case ReminderType.fifteenMinutes:
        return '15 minutes';
      case ReminderType.fiveMinutes:
        return '5 minutes';
    }
  }

  void dispose() {
    _reminderCheckTimer?.cancel();
    _remindersController.close();
  }
}
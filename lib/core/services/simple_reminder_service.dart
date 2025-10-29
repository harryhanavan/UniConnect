import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/event.dart';
import '../demo_data/demo_data_manager.dart';
import 'notification_service.dart';

class SimpleReminderService {
  static final SimpleReminderService _instance = SimpleReminderService._internal();
  factory SimpleReminderService() => _instance;
  SimpleReminderService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;
  Timer? _reminderCheckTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Start background reminder checking every 5 minutes
    _startReminderTimer();
    _isInitialized = true;
  }

  void _startReminderTimer() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkAndTriggerReminders();
    });
  }

  Future<void> _checkAndTriggerReminders() async {
    try {
      final now = DateTime.now();
      final nextHour = now.add(const Duration(hours: 1));

      // Get events in the next hour that need reminders
      final upcomingEvents = _demoData.getEventsByDateRange(now, nextHour);

      for (final event in upcomingEvents) {
        final timeUntilEvent = event.startTime.difference(now);
        final reminderTimes = [15]; // Default to 15 minutes for legacy events

        // Check if we should send reminders based on event's specific settings
        for (final reminderMinutes in reminderTimes) {
          final shouldSend = timeUntilEvent.inMinutes <= reminderMinutes &&
                           timeUntilEvent.inMinutes > (reminderMinutes - 5);

          if (shouldSend) {
            await _sendEventReminder(event, _formatReminderTime(reminderMinutes));
          }
        }
      }

      // Check for upcoming deadlines (1 day before)
      final tomorrow = now.add(const Duration(days: 1));
      final dayAfterTomorrow = now.add(const Duration(days: 2));
      final tomorrowEvents = _demoData.getEventsByDateRange(tomorrow, dayAfterTomorrow);

      for (final event in tomorrowEvents) {
        // Only send deadline reminders for assignments and exams with reminders enabled
        if (event.type == EventType.assignment) {
          await _sendDeadlineReminder(event);
        }
      }

    } catch (e) {
      print('Error checking reminders: $e');
    }
  }

  Future<void> _sendEventReminder(Event event, String timeString) async {
    final reminderKey = 'reminder_sent_${event.id}_$timeString';
    final prefs = await SharedPreferences.getInstance();

    // Check if we already sent this reminder
    if (prefs.getBool(reminderKey) == true) {
      return;
    }

    // Get current user ID from demo data
    final currentUser = await _demoData.currentUserAsync;

    await _notificationService.sendNotification(
      userId: currentUser.id,
      title: _getReminderTitle(event, timeString),
      body: _getReminderBody(event),
      type: NotificationType.eventReminder,
      data: {
        'eventId': event.id,
        'reminderType': timeString,
        'eventType': event.type.toString(),
        'isReminder': true,
      },
      actionUrl: '/calendar/event/${event.id}',
    );

    // Mark reminder as sent
    await prefs.setBool(reminderKey, true);
  }

  Future<void> _sendDeadlineReminder(Event event) async {
    final reminderKey = 'deadline_reminder_sent_${event.id}';
    final prefs = await SharedPreferences.getInstance();

    // Check if we already sent this reminder
    if (prefs.getBool(reminderKey) == true) {
      return;
    }

    // Get current user ID from demo data
    final currentUser = await _demoData.currentUserAsync;

    await _notificationService.sendNotification(
      userId: currentUser.id,
      title: _getDeadlineTitle(event),
      body: _getDeadlineBody(event),
      type: NotificationType.eventReminder,
      data: {
        'eventId': event.id,
        'reminderType': 'deadline',
        'eventType': event.type.toString(),
        'isReminder': true,
        'isDeadline': true,
      },
      actionUrl: '/calendar/event/${event.id}',
    );

    // Mark reminder as sent
    await prefs.setBool(reminderKey, true);
  }

  String _getReminderTitle(Event event, String timeString) {
    switch (event.type) {
      case EventType.class_:
        return 'Class starting in $timeString';
      case EventType.assignment:
        return 'Assignment deadline in $timeString';
      case EventType.society:
        return 'Society event starting in $timeString';
      case EventType.personal:
        return 'Event starting in $timeString';
      default:
        return '${event.title} starting in $timeString';
    }
  }

  String _getReminderBody(Event event) {
    final location = event.location.isNotEmpty ? ' at ${event.location}' : '';
    String body = '${event.title}$location';
    return body;
  }

  String _getDeadlineTitle(Event event) {
    switch (event.type) {
      case EventType.assignment:
        return 'Assignment due tomorrow';
      case EventType.class_:
        return 'Class tomorrow';
      default:
        return 'Important event tomorrow';
    }
  }

  String _getDeadlineBody(Event event) {
    return '${event.title} - Make sure you\'re prepared!';
  }

  /// Get upcoming events that need reminders
  Future<List<Event>> getUpcomingEventsWithReminders(String userId) async {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    final events = _demoData.getEventsByDateRange(now, nextWeek);

    return events
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get upcoming deadlines
  Future<List<Event>> getUpcomingDeadlines(String userId) async {
    final now = DateTime.now();
    final twoWeeksFromNow = now.add(const Duration(days: 14));

    final events = _demoData.getEventsByDateRange(now, twoWeeksFromNow);

    return events
        .where((event) => event.type == EventType.assignment)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Mark an event as completed (prevents further reminders)
  Future<void> markEventCompleted(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('event_completed_$eventId', true);
  }

  /// Check if an event is completed
  Future<bool> isEventCompleted(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('event_completed_$eventId') ?? false;
  }

  /// Format reminder time in minutes to a readable string
  String _formatReminderTime(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hour' : '$hours hours';
    } else {
      final days = minutes ~/ 1440;
      return days == 1 ? '1 day' : '$days days';
    }
  }

  void dispose() {
    _reminderCheckTimer?.cancel();
  }
}
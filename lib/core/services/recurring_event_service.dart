import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';

/// Service for generating recurring event instances based on RRULE patterns
class RecurringEventService {
  static final RecurringEventService _instance = RecurringEventService._internal();
  factory RecurringEventService() => _instance;
  RecurringEventService._internal();

  /// Generate recurring event instances for a given date range
  List<EventV2> generateRecurringInstances(
    EventV2 parentEvent,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (!parentEvent.isRecurring || parentEvent.recurringRule == null) {
      return [];
    }

    final instances = <EventV2>[];
    final rule = _parseRRule(parentEvent.recurringRule!);

    if (rule['FREQ'] == 'WEEKLY') {
      instances.addAll(_generateWeeklyInstances(parentEvent, rule, startDate, endDate));
    }
    // Future: Add support for DAILY, MONTHLY, etc.

    return instances;
  }

  /// Parse RRULE string into a map of components
  Map<String, dynamic> _parseRRule(String rrule) {
    final components = <String, dynamic>{};

    // Split by semicolon and parse each component
    for (final part in rrule.split(';')) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = keyValue[1].trim();

        switch (key) {
          case 'FREQ':
            components[key] = value;
            break;
          case 'BYDAY':
            components[key] = _parseDays(value);
            break;
          case 'BYHOUR':
            components[key] = int.tryParse(value) ?? 0;
            break;
          case 'BYMINUTE':
            components[key] = int.tryParse(value) ?? 0;
            break;
          case 'UNTIL':
            components[key] = DateTime.tryParse(value);
            break;
          case 'COUNT':
            components[key] = int.tryParse(value);
            break;
          case 'INTERVAL':
            components[key] = int.tryParse(value) ?? 1;
            break;
        }
      }
    }

    return components;
  }

  /// Parse BYDAY values (MO, TU, WE, TH, FR, SA, SU) to weekday numbers
  List<int> _parseDays(String dayString) {
    final dayMap = {
      'MO': DateTime.monday,
      'TU': DateTime.tuesday,
      'WE': DateTime.wednesday,
      'TH': DateTime.thursday,
      'FR': DateTime.friday,
      'SA': DateTime.saturday,
      'SU': DateTime.sunday,
    };

    final days = <int>[];
    for (final dayCode in dayString.split(',')) {
      final weekday = dayMap[dayCode.trim()];
      if (weekday != null) {
        days.add(weekday);
      }
    }

    return days;
  }

  /// Generate weekly recurring instances
  List<EventV2> _generateWeeklyInstances(
    EventV2 parentEvent,
    Map<String, dynamic> rule,
    DateTime startDate,
    DateTime endDate,
  ) {
    final instances = <EventV2>[];
    final weekdays = rule['BYDAY'] as List<int>? ?? [parentEvent.startTime.weekday];
    final interval = rule['INTERVAL'] as int? ?? 1;
    final until = rule['UNTIL'] as DateTime?;
    final count = rule['COUNT'] as int?;

    // Start from the parent event's first occurrence
    var current = DateTime(
      parentEvent.startTime.year,
      parentEvent.startTime.month,
      parentEvent.startTime.day,
    );

    // Find the first occurrence within our date range
    while (current.isBefore(startDate)) {
      current = current.add(Duration(days: 7 * interval));
    }

    // Generate instances
    var instanceCount = 0;
    final maxInstances = count ?? 1000; // Reasonable limit if no count specified

    while (current.isBefore(endDate) && instanceCount < maxInstances) {
      // Check if we've exceeded the UNTIL date
      if (until != null && current.isAfter(until)) {
        break;
      }

      // Generate instances for each specified weekday in this week
      for (final weekday in weekdays) {
        final instanceDate = _getDateForWeekday(current, weekday);

        // Only include if within our requested range
        if (instanceDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            instanceDate.isBefore(endDate)) {

          // Skip if this would be the original parent event
          final parentDate = DateTime(
            parentEvent.startTime.year,
            parentEvent.startTime.month,
            parentEvent.startTime.day,
          );

          if (!_isSameDay(instanceDate, parentDate)) {
            final instance = _createRecurringInstance(parentEvent, instanceDate);
            instances.add(instance);
            instanceCount++;
          }
        }
      }

      // Move to next week(s)
      current = current.add(Duration(days: 7 * interval));
    }

    return instances;
  }

  /// Get the date for a specific weekday in a given week
  DateTime _getDateForWeekday(DateTime weekStart, int targetWeekday) {
    final currentWeekday = weekStart.weekday;
    final daysToAdd = (targetWeekday - currentWeekday) % 7;
    return weekStart.add(Duration(days: daysToAdd));
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Create a recurring instance from a parent event
  EventV2 _createRecurringInstance(EventV2 parentEvent, DateTime instanceDate) {
    // Calculate the time offset from the parent event
    final duration = parentEvent.endTime.difference(parentEvent.startTime);

    // Create start and end times for this instance
    final instanceStartTime = DateTime(
      instanceDate.year,
      instanceDate.month,
      instanceDate.day,
      parentEvent.startTime.hour,
      parentEvent.startTime.minute,
      parentEvent.startTime.second,
    );

    final instanceEndTime = instanceStartTime.add(duration);

    // Generate unique ID for this instance
    final instanceId = '${parentEvent.id}_${instanceDate.year}${instanceDate.month.toString().padLeft(2, '0')}${instanceDate.day.toString().padLeft(2, '0')}';

    return parentEvent.copyWith(
      id: instanceId,
      startTime: instanceStartTime,
      endTime: instanceEndTime,
      scheduledDate: instanceStartTime,
      endDate: instanceEndTime,
      isRecurringInstance: true,
      parentEventId: parentEvent.id,
      isRecurring: false, // Instances are not recurring themselves
      recurringRule: null, // Instances don't have their own rules
      nextOccurrence: null, // Only parent events track next occurrence
    );
  }

  /// Get all recurring events that could have instances in the date range
  List<EventV2> getRecurringEventsForRange(
    List<EventV2> allEvents,
    DateTime startDate,
    DateTime endDate,
  ) {
    return allEvents.where((event) {
      if (!event.isRecurring || event.recurringRule == null) {
        return false;
      }

      // Include if the parent event is before our end date
      // (it could have instances in our range)
      return event.startTime.isBefore(endDate);
    }).toList();
  }

  /// Generate all recurring instances for multiple parent events
  List<EventV2> generateAllRecurringInstances(
    List<EventV2> parentEvents,
    DateTime startDate,
    DateTime endDate,
  ) {
    final allInstances = <EventV2>[];

    for (final parentEvent in parentEvents) {
      if (parentEvent.isRecurring && parentEvent.recurringRule != null) {
        final instances = generateRecurringInstances(parentEvent, startDate, endDate);
        allInstances.addAll(instances);
      }
    }

    return allInstances;
  }

  /// Helper method to get the next occurrence of a recurring event
  DateTime? getNextOccurrence(EventV2 recurringEvent, {DateTime? afterDate}) {
    if (!recurringEvent.isRecurring || recurringEvent.recurringRule == null) {
      return null;
    }

    final after = afterDate ?? DateTime.now();
    final futureInstances = generateRecurringInstances(
      recurringEvent,
      after,
      after.add(const Duration(days: 365)), // Look ahead 1 year
    );

    if (futureInstances.isNotEmpty) {
      futureInstances.sort((a, b) => a.startTime.compareTo(b.startTime));
      return futureInstances.first.startTime;
    }

    return null;
  }

  /// Validate an RRULE string
  bool isValidRRule(String rrule) {
    try {
      final rule = _parseRRule(rrule);
      return rule.containsKey('FREQ') &&
             ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'].contains(rule['FREQ']);
    } catch (e) {
      return false;
    }
  }

  /// Get human-readable description of a recurring pattern
  String getRecurrenceDescription(String rrule) {
    try {
      final rule = _parseRRule(rrule);
      final freq = rule['FREQ'] as String;
      final interval = rule['INTERVAL'] as int? ?? 1;
      final weekdays = rule['BYDAY'] as List<int>?;

      switch (freq) {
        case 'WEEKLY':
          if (weekdays != null && weekdays.isNotEmpty) {
            final dayNames = weekdays.map(_weekdayToName).join(', ');
            if (interval == 1) {
              return 'Weekly on $dayNames';
            } else {
              return 'Every $interval weeks on $dayNames';
            }
          } else {
            return interval == 1 ? 'Weekly' : 'Every $interval weeks';
          }
        case 'DAILY':
          return interval == 1 ? 'Daily' : 'Every $interval days';
        case 'MONTHLY':
          return interval == 1 ? 'Monthly' : 'Every $interval months';
        case 'YEARLY':
          return interval == 1 ? 'Yearly' : 'Every $interval years';
        default:
          return 'Recurring';
      }
    } catch (e) {
      return 'Recurring';
    }
  }

  /// Convert weekday number to name
  String _weekdayToName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return 'Unknown';
    }
  }
}
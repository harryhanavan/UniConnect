import 'package:flutter/material.dart';
import '../../core/constants/event_colors.dart';
import '../models/event.dart';

/// Event card widgets based on Figma designs
class EventCards {
  EventCards._();

  /// 1 Day View - Full detailed card
  static Widget buildDayViewCard({
    required Event event,
    required String eventType,
    required int attendeeCount,
    List<String> suggestions = const [],
    VoidCallback? onTap,
  }) {
    final eventColor = EventColors.getEventColor(eventType);
    final eventBgColor = EventColors.getEventBackgroundColor(eventType);
    final eventLabel = EventColors.getEventTypeLabel(eventType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 148,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: EventColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: const [
            BoxShadow(
              color: EventColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // Left color bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 4,
                height: 147.58,
                decoration: ShapeDecoration(
                  color: eventColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Event title
            Positioned(
              left: 20,
              top: 16,
              child: SizedBox(
                width: 200,
                height: 19,
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: EventColors.primaryText,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    height: 1.20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Course code
            if (event.courseCode != null)
              Positioned(
                left: 20,
                top: 37.19,
                child: Text(
                  event.courseCode!,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    height: 1.20,
                  ),
                ),
              ),

            // Time
            Positioned(
              left: 20,
              top: 55.58,
              child: Text(
                '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: EventColors.secondaryText,
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Event type badge
            Positioned(
              right: 20,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: eventBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  eventLabel,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 10,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.50,
                  ),
                ),
              ),
            ),

            // Attendee count
            Positioned(
              right: 20,
              top: 39,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 12, color: EventColors.secondaryText),
                  const SizedBox(width: 2),
                  Text(
                    attendeeCount.toString(),
                    style: const TextStyle(
                      color: EventColors.secondaryText,
                      fontSize: 10,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Location
            Positioned(
              left: 20,
              top: 83.58,
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: EventColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    event.location,
                    style: const TextStyle(
                      color: EventColors.secondaryText,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Suggestions
            if (suggestions.isNotEmpty)
              Positioned(
                left: 20,
                top: 109.58,
                child: Row(
                  children: suggestions.take(2).map((suggestion) => 
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: ShapeDecoration(
                        color: EventColors.suggestionBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            suggestion.startsWith('📚') ? '📚' : '👥',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            suggestion.replaceFirst(RegExp(r'^[📚👥]\s*'), ''),
                            style: const TextStyle(
                              color: EventColors.tertiaryText,
                              fontSize: 11,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  ).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 1 Day Timetable Chip - Simplified version for timetable view
  static Widget buildDayTimetableChip({
    required Event event,
    required String eventType,
    required int attendeeCount,
    VoidCallback? onTap,
  }) {
    final eventColor = EventColors.getEventColor(eventType);
    final eventBgColor = EventColors.getEventBackgroundColor(eventType);
    final eventLabel = EventColors.getEventTypeLabel(eventType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 128,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: EventColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: const [
            BoxShadow(
              color: EventColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // Left color bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 4,
                height: 127.58,
                decoration: ShapeDecoration(
                  color: eventColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Event title
            Positioned(
              left: 20,
              top: 16,
              child: SizedBox(
                width: 180,
                height: 19,
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: EventColors.primaryText,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    height: 1.20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Course code
            if (event.courseCode != null)
              Positioned(
                left: 20,
                top: 37.19,
                child: Text(
                  event.courseCode!,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    height: 1.20,
                  ),
                ),
              ),

            // Event type badge
            Positioned(
              right: 20,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: eventBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  eventLabel,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 10,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.50,
                  ),
                ),
              ),
            ),

            // Attendee count
            Positioned(
              right: 20,
              top: 39,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 12, color: EventColors.secondaryText),
                  const SizedBox(width: 2),
                  Text(
                    attendeeCount.toString(),
                    style: const TextStyle(
                      color: EventColors.secondaryText,
                      fontSize: 10,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Location
            Positioned(
              left: 20,
              top: 51,
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: EventColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    event.location,
                    style: const TextStyle(
                      color: EventColors.secondaryText,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 7 Day Week Card - Compact card for week view
  static Widget buildWeekViewCard({
    required Event event,
    required String eventType,
    required int attendeeCount,
    VoidCallback? onTap,
  }) {
    final eventColor = EventColors.getEventColor(eventType);
    final eventBgColor = EventColors.getEventBackgroundColor(eventType);
    final eventLabel = EventColors.getEventTypeLabel(eventType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 61,
        height: 123,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: EventColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: const [
            BoxShadow(
              color: EventColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // Left color bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 4,
                height: 122.58,
                decoration: ShapeDecoration(
                  color: eventColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Event title
            Positioned(
              left: 6,
              top: 4,
              child: SizedBox(
                width: 49,
                height: 48,
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: EventColors.primaryText,
                    fontSize: 10,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Course code
            if (event.courseCode != null)
              Positioned(
                left: 6,
                top: 58,
                child: Text(
                  event.courseCode!,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    height: 1.20,
                  ),
                ),
              ),

            // Time
            Positioned(
              left: 6,
              top: 72,
              child: Text(
                '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: EventColors.secondaryText,
                  fontSize: 8,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Event type badge
            Positioned(
              left: 7,
              top: 90,
              child: Container(
                width: 23,
                height: 12,
                decoration: ShapeDecoration(
                  color: eventBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Center(
                  child: Text(
                    eventLabel,
                    style: TextStyle(
                      color: eventColor,
                      fontSize: 3,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.50,
                    ),
                  ),
                ),
              ),
            ),

            // Attendee count
            Positioned(
              left: 31,
              top: 90,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 12, color: EventColors.secondaryText),
                  const SizedBox(width: 2),
                  Text(
                    attendeeCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: EventColors.secondaryText,
                      fontSize: 5,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Location
            Positioned(
              left: 6,
              top: 112,
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 8, color: EventColors.secondaryText),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 43,
                    child: Text(
                      event.location,
                      style: const TextStyle(
                        color: EventColors.secondaryText,
                        fontSize: 3,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 7 Day Week Timetable Chip - Ultra compact for week timetable
  static Widget buildWeekTimetableChip({
    required Event event,
    required String eventType,
    required int attendeeCount,
    VoidCallback? onTap,
  }) {
    final eventColor = EventColors.getEventColor(eventType);
    final eventBgColor = EventColors.getEventBackgroundColor(eventType);
    final eventLabel = EventColors.getEventTypeLabel(eventType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 43,
        height: 111,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: EventColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: const [
            BoxShadow(
              color: EventColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // Left color bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 4,
                height: 110.58,
                decoration: ShapeDecoration(
                  color: eventColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Event title
            Positioned(
              left: 6,
              top: 4,
              child: SizedBox(
                width: 33,
                height: 32,
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: EventColors.primaryText,
                    fontSize: 7,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    height: 1.43,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Course code
            if (event.courseCode != null)
              Positioned(
                left: 6,
                top: 52,
                child: Text(
                  event.courseCode!,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 8,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    height: 1.80,
                  ),
                ),
              ),

            // Event type badge
            Positioned(
              left: 6,
              top: 64,
              child: Container(
                width: 23,
                height: 12,
                decoration: ShapeDecoration(
                  color: eventBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Center(
                  child: Text(
                    eventLabel,
                    style: TextStyle(
                      color: eventColor,
                      fontSize: 3,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.50,
                    ),
                  ),
                ),
              ),
            ),

            // Attendee count
            Positioned(
              left: 6,
              top: 76,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 12, color: EventColors.secondaryText),
                  const SizedBox(width: 2),
                  Text(
                    attendeeCount.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: EventColors.secondaryText,
                      fontSize: 5,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/constants/event_colors.dart';
import '../../core/constants/app_theme.dart';
import '../models/event.dart';

/// Event card widgets based on Figma designs
class EventCards {
  EventCards._();

  /// 1 Day View - Full detailed card
  static Widget buildDayViewCard({
    required BuildContext context,
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
          color: EventColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: [
            BoxShadow(
              color: EventColors.getShadowColor(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                  style: TextStyle(
                    color: EventColors.getPrimaryTextColor(context),
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
                style: TextStyle(
                  color: EventColors.getSecondaryTextColor(context),
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
                  Icon(Icons.people, size: 12, color: EventColors.getSecondaryTextColor(context)),
                  const SizedBox(width: 2),
                  Text(
                    attendeeCount.toString(),
                    style: TextStyle(
                      color: EventColors.getSecondaryTextColor(context),
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
                  Icon(Icons.location_on, size: 14, color: EventColors.getSecondaryTextColor(context)),
                  const SizedBox(width: 4),
                  Text(
                    event.location,
                    style: TextStyle(
                      color: EventColors.getSecondaryTextColor(context),
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
                        color: EventColors.getSuggestionBackgroundColor(context),
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
                            style: TextStyle(
                              color: EventColors.getTertiaryTextColor(context),
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
    required BuildContext context,
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
          color: EventColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: [
            BoxShadow(
              color: EventColors.getShadowColor(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                  style: TextStyle(
                    color: EventColors.getPrimaryTextColor(context),
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
                  Icon(Icons.people, size: 12, color: EventColors.getSecondaryTextColor(context)),
                  const SizedBox(width: 2),
                  Text(
                    attendeeCount.toString(),
                    style: TextStyle(
                      color: EventColors.getSecondaryTextColor(context),
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
                  Icon(Icons.location_on, size: 14, color: EventColors.getSecondaryTextColor(context)),
                  const SizedBox(width: 4),
                  Text(
                    event.location,
                    style: TextStyle(
                      color: EventColors.getSecondaryTextColor(context),
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
    required BuildContext context,
    required Event event,
    required String eventType,
    required int attendeeCount,
    VoidCallback? onTap,
  }) {
    final eventColor = EventColors.getEventColor(eventType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 61,
        height: 123,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: EventColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: [
            BoxShadow(
              color: EventColors.getShadowColor(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
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

            // Event title - increased to 5 lines
            Positioned(
              left: 6,
              top: 4,
              child: SizedBox(
                width: 49,
                height: 60,
                child: Text(
                  event.title,
                  style: TextStyle(
                    color: EventColors.getPrimaryTextColor(context),
                    fontSize: 10,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Course code - shifted down
            if (event.courseCode != null)
              Positioned(
                left: 6,
                top: 68,
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

            // Time - shifted down
            Positioned(
              left: 6,
              top: 84,
              child: Text(
                '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: EventColors.getSecondaryTextColor(context),
                  fontSize: 8,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Attendee count - shifted down
            Positioned(
              left: 6,
              top: 102,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people, size: 12, color: EventColors.getSecondaryTextColor(context)),
                  const SizedBox(width: 2),
                  Text(
                    attendeeCount.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EventColors.getSecondaryTextColor(context),
                      fontSize: 8,
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

  /// 7 Day Week Timetable Chip - Ultra compact for week timetable
  static Widget buildWeekTimetableChip({
    required BuildContext context,
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
          color: EventColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: [
            BoxShadow(
              color: EventColors.getShadowColor(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                  style: TextStyle(
                    color: EventColors.getPrimaryTextColor(context),
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
                  Icon(Icons.people, size: 12, color: EventColors.getSecondaryTextColor(context)),
                  const SizedBox(width: 2),
                  Text(
                    attendeeCount.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EventColors.getSecondaryTextColor(context),
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
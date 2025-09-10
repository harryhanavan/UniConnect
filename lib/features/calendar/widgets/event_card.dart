import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/event.dart';
import '../../../core/constants/app_colors.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Event type indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _getEventColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              // Event content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          event.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    // Course code or society info
                    if (event.courseCode != null || event.societyId != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getEventColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.courseCode ?? _getEventTypeLabel(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getEventColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventColor() {
    switch (event.type) {
      case EventType.class_:
        return AppColors.personalColor;  // Classes are part of personal schedule
      case EventType.society:
        return AppColors.societyColor;
      case EventType.personal:
        return AppColors.personalColor;
      case EventType.assignment:
        return AppColors.personalColor;  // Assignments are part of personal academic schedule
    }
  }

  String _getEventTypeLabel() {
    switch (event.type) {
      case EventType.class_:
        return 'Class';
      case EventType.society:
        return 'Society';
      case EventType.personal:
        return 'Personal';
      case EventType.assignment:
        return 'Assignment';
    }
  }

  String _formatTime() {
    if (event.isAllDay) {
      return 'All day';
    }
    
    final start = DateFormat('HH:mm').format(event.startTime);
    final end = DateFormat('HH:mm').format(event.endTime);
    return '$start - $end';
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/simple_reminder_service.dart';
import '../../core/services/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../shared/models/event.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/utils/navigation_helper.dart';

class HomeReminderSection extends StatefulWidget {
  const HomeReminderSection({super.key});

  @override
  State<HomeReminderSection> createState() => _HomeReminderSectionState();
}

class _HomeReminderSectionState extends State<HomeReminderSection> {
  final SimpleReminderService _reminderService = SimpleReminderService();
  final DemoDataManager _demoData = DemoDataManager.instance;

  @override
  void initState() {
    super.initState();
    _initializeReminderService();
  }

  Future<void> _initializeReminderService() async {
    try {
      await _reminderService.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing reminder service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upcoming Deadlines
            _buildUpcomingDeadlinesCard(appState.currentUser.id),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingDeadlinesCard(String userId) {
    return FutureBuilder<List<Event>>(
      future: _getUpcomingDeadlines(userId),
      builder: (context, snapshot) {
        return Container(
          width: double.infinity,
          decoration: AppTheme.getCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_late,
                          color: AppColors.personalColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upcoming Deadlines',
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        NavigationHelper.navigateToCalendarWithParams(
                          context,
                          // initialFilter: CalendarFilter.academic,
                          // initialView: CalendarView.week,
                        );
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.personalColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Show deadlines if available, otherwise show placeholder
                if (snapshot.hasData && snapshot.data!.isNotEmpty)
                  ...snapshot.data!.take(3).map((deadline) => _buildDeadlineItem(deadline))
                else
                  _buildNoDeadlinesPlaceholder(),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildNoDeadlinesPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      width: double.infinity,
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 40,
            color: AppTheme.getIconColor(context, opacity: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming deadlines',
            style: TextStyle(
              color: AppTheme.getTextColor(context, opacity: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add deadlines to stay organized',
            style: TextStyle(
              color: AppTheme.getTextColor(context, opacity: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem(Event deadline) {
    final now = DateTime.now();
    final timeUntil = deadline.startTime.difference(now);
    final isUrgent = timeUntil.inDays <= 1;
    final color = isUrgent ? Colors.red : AppColors.personalColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Priority indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                Text(
                  _formatTimeUntil(timeUntil),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Quick action button
          IconButton(
            icon: Icon(
              deadline.type == EventType.assignment
                  ? Icons.assignment_turned_in
                  : Icons.event_available,
              color: color,
              size: 20,
            ),
            onPressed: () => _markEventCompleted(deadline.id),
          ),
        ],
      ),
    );
  }


  Future<List<Event>> _getUpcomingDeadlines(String userId) async {
    final events = await _demoData.events;
    final now = DateTime.now();
    final twoWeeksFromNow = now.add(const Duration(days: 14));

    return events
        .where((event) =>
            event.type == EventType.assignment &&
            event.startTime.isAfter(now) &&
            event.startTime.isBefore(twoWeeksFromNow))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }


  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.assignment:
        return AppColors.studyGroupColor;
      case EventType.class_:
        return AppColors.personalColor;
      case EventType.society:
        return AppColors.societyColor;
      case EventType.personal:
        return AppColors.socialColor;
      default:
        return AppColors.personalColor;
    }
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.class_:
        return Icons.school;
      case EventType.assignment:
        return Icons.assignment;
      case EventType.society:
        return Icons.groups;
      case EventType.personal:
        return Icons.celebration;
      default:
        return Icons.event;
    }
  }

  String _formatTimeUntil(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min';
    } else {
      return 'Now';
    }
  }

  void _markEventCompleted(String eventId) async {
    await _reminderService.markEventCompleted(eventId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event marked as completed'),
          backgroundColor: AppColors.socialColor,
          duration: const Duration(seconds: 2),
        ),
      );
      // Refresh the UI
      setState(() {});
    }
  }
}
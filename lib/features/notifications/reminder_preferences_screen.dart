import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../shared/models/event_enums.dart';

class ReminderPreferencesScreen extends StatefulWidget {
  const ReminderPreferencesScreen({super.key});

  @override
  State<ReminderPreferencesScreen> createState() => _ReminderPreferencesScreenState();
}

class _ReminderPreferencesScreenState extends State<ReminderPreferencesScreen> {
  // Reminder settings for different event categories
  Map<EventCategory, Map<String, bool>> _categorySettings = {
    EventCategory.academic: {
      '1 week before': false,
      '1 day before': true,
      '4 hours before': false,
      '1 hour before': true,
      '15 minutes before': true,
      '5 minutes before': false,
    },
    EventCategory.social: {
      '1 week before': false,
      '1 day before': false,
      '4 hours before': true,
      '1 hour before': false,
      '15 minutes before': true,
      '5 minutes before': false,
    },
    EventCategory.society: {
      '1 week before': false,
      '1 day before': true,
      '4 hours before': false,
      '1 hour before': true,
      '15 minutes before': false,
      '5 minutes before': false,
    },
    EventCategory.personal: {
      '1 week before': false,
      '1 day before': false,
      '4 hours before': false,
      '1 hour before': true,
      '15 minutes before': true,
      '5 minutes before': false,
    },
  };

  // Special settings for specific event types
  Map<String, Map<String, bool>> _specialSettings = {
    'Exams': {
      '1 week before': true,
      '1 day before': true,
      '4 hours before': true,
      '1 hour before': true,
      '15 minutes before': false,
      '5 minutes before': false,
    },
    'Assignments': {
      '1 week before': false,
      '1 day before': true,
      '4 hours before': true,
      '1 hour before': true,
      '15 minutes before': false,
      '5 minutes before': false,
    },
  };

  // General notification settings
  bool _enablePushNotifications = true;
  bool _enableInAppNotifications = true;
  bool _enableSoundForCritical = true;
  bool _enableVibrationForCritical = true;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _enableQuietHours = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _enablePushNotifications = prefs.getBool('enable_push_notifications') ?? true;
      _enableInAppNotifications = prefs.getBool('enable_in_app_notifications') ?? true;
      _enableSoundForCritical = prefs.getBool('enable_sound_for_critical') ?? true;
      _enableVibrationForCritical = prefs.getBool('enable_vibration_for_critical') ?? true;
      _enableQuietHours = prefs.getBool('enable_quiet_hours') ?? false;

      // Load quiet hours
      final quietStartHour = prefs.getInt('quiet_hours_start_hour') ?? 22;
      final quietStartMinute = prefs.getInt('quiet_hours_start_minute') ?? 0;
      final quietEndHour = prefs.getInt('quiet_hours_end_hour') ?? 7;
      final quietEndMinute = prefs.getInt('quiet_hours_end_minute') ?? 0;

      _quietHoursStart = TimeOfDay(hour: quietStartHour, minute: quietStartMinute);
      _quietHoursEnd = TimeOfDay(hour: quietEndHour, minute: quietEndMinute);
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('enable_push_notifications', _enablePushNotifications);
    await prefs.setBool('enable_in_app_notifications', _enableInAppNotifications);
    await prefs.setBool('enable_sound_for_critical', _enableSoundForCritical);
    await prefs.setBool('enable_vibration_for_critical', _enableVibrationForCritical);
    await prefs.setBool('enable_quiet_hours', _enableQuietHours);

    await prefs.setInt('quiet_hours_start_hour', _quietHoursStart.hour);
    await prefs.setInt('quiet_hours_start_minute', _quietHoursStart.minute);
    await prefs.setInt('quiet_hours_end_hour', _quietHoursEnd.hour);
    await prefs.setInt('quiet_hours_end_minute', _quietHoursEnd.minute);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reminder preferences saved'),
          backgroundColor: AppColors.socialColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Reminder Preferences'),
        backgroundColor: AppColors.homeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _savePreferences,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            _buildSectionCard(
              'General Settings',
              Icons.settings,
              [
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive notifications when app is closed',
                  _enablePushNotifications,
                  (value) => setState(() => _enablePushNotifications = value),
                ),
                _buildSwitchTile(
                  'In-App Notifications',
                  'Show notifications when app is open',
                  _enableInAppNotifications,
                  (value) => setState(() => _enableInAppNotifications = value),
                ),
                _buildSwitchTile(
                  'Sound for Critical Events',
                  'Play sound for exams and urgent deadlines',
                  _enableSoundForCritical,
                  (value) => setState(() => _enableSoundForCritical = value),
                ),
                _buildSwitchTile(
                  'Vibration for Critical Events',
                  'Vibrate for exams and urgent deadlines',
                  _enableVibrationForCritical,
                  (value) => setState(() => _enableVibrationForCritical = value),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quiet Hours
            _buildSectionCard(
              'Quiet Hours',
              Icons.bedtime,
              [
                _buildSwitchTile(
                  'Enable Quiet Hours',
                  'Suppress non-critical notifications during quiet hours',
                  _enableQuietHours,
                  (value) => setState(() => _enableQuietHours = value),
                ),
                if (_enableQuietHours) ...[
                  _buildTimeTile(
                    'Start Time',
                    _quietHoursStart,
                    (time) => setState(() => _quietHoursStart = time),
                  ),
                  _buildTimeTile(
                    'End Time',
                    _quietHoursEnd,
                    (time) => setState(() => _quietHoursEnd = time),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Event Category Settings
            ...EventCategory.values.map((category) => Column(
              children: [
                _buildCategoryCard(category),
                const SizedBox(height: 16),
              ],
            )),

            // Special Event Types
            _buildSpecialEventCard('Exams', 'Special reminder settings for exams', Icons.quiz),
            const SizedBox(height: 16),
            _buildSpecialEventCard('Assignments', 'Special reminder settings for assignments', Icons.assignment),

            const SizedBox(height: 20),

            // Reset to Defaults
            _buildResetCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: AppTheme.getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.homeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(EventCategory category) {
    final categoryName = _getCategoryDisplayName(category);
    final categoryColor = _getCategoryColor(category);
    final categoryIcon = _getCategoryIcon(category);

    return Container(
      decoration: AppTheme.getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(categoryIcon, color: categoryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$categoryName Events',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getCategoryDescription(category),
              style: TextStyle(
                color: AppTheme.getTextColor(context, opacity: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ..._categorySettings[category]!.entries.map((entry) =>
              _buildCheckboxTile(
                entry.key,
                entry.value,
                (value) => setState(() {
                  _categorySettings[category]![entry.key] = value ?? false;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialEventCard(String title, String description, IconData icon) {
    return Container(
      decoration: AppTheme.getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.studyGroupColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: AppTheme.getTextColor(context, opacity: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ..._specialSettings[title]!.entries.map((entry) =>
              _buildCheckboxTile(
                entry.key,
                entry.value,
                (value) => setState(() {
                  _specialSettings[title]![entry.key] = value ?? false;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetCard() {
    return Container(
      decoration: AppTheme.getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restore, color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reset Settings',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reset all reminder preferences to default values',
              style: TextStyle(
                color: AppTheme.getTextColor(context, opacity: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resetToDefaults,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.danger),
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('Reset to Defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.getTextColor(context, opacity: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.homeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(String title, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontSize: 16,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.homeColor,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildTimeTile(String title, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (newTime != null) {
                onChanged(newTime);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.homeColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  color: AppColors.homeColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.social:
        return 'Social';
      case EventCategory.society:
        return 'Society';
      case EventCategory.personal:
        return 'Personal';
      case EventCategory.university:
        return 'University';
    }
  }

  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return AppColors.personalColor;
      case EventCategory.social:
        return AppColors.socialColor;
      case EventCategory.society:
        return AppColors.societyColor;
      case EventCategory.personal:
        return AppColors.homeColor;
      case EventCategory.university:
        return AppColors.studyGroupColor;
    }
  }

  IconData _getCategoryIcon(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return Icons.school;
      case EventCategory.social:
        return Icons.celebration;
      case EventCategory.society:
        return Icons.groups;
      case EventCategory.personal:
        return Icons.person;
      case EventCategory.university:
        return Icons.account_balance;
    }
  }

  String _getCategoryDescription(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'Classes, lectures, tutorials, labs, and study sessions';
      case EventCategory.social:
        return 'Parties, hangouts, meetups, and social gatherings';
      case EventCategory.society:
        return 'Club meetings, events, workshops, and activities';
      case EventCategory.personal:
        return 'Personal tasks, appointments, and private events';
      case EventCategory.university:
        return 'Official university events, ceremonies, and announcements';
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all reminder preferences to their default values? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Reset to default values from initState
                _enablePushNotifications = true;
                _enableInAppNotifications = true;
                _enableSoundForCritical = true;
                _enableVibrationForCritical = true;
                _enableQuietHours = false;
                _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
                _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

                // Reset category settings
                _categorySettings = {
                  EventCategory.academic: {
                    '1 week before': false,
                    '1 day before': true,
                    '4 hours before': false,
                    '1 hour before': true,
                    '15 minutes before': true,
                    '5 minutes before': false,
                  },
                  EventCategory.social: {
                    '1 week before': false,
                    '1 day before': false,
                    '4 hours before': true,
                    '1 hour before': false,
                    '15 minutes before': true,
                    '5 minutes before': false,
                  },
                  EventCategory.society: {
                    '1 week before': false,
                    '1 day before': true,
                    '4 hours before': false,
                    '1 hour before': true,
                    '15 minutes before': false,
                    '5 minutes before': false,
                  },
                  EventCategory.personal: {
                    '1 week before': false,
                    '1 day before': false,
                    '4 hours before': false,
                    '1 hour before': true,
                    '15 minutes before': true,
                    '5 minutes before': false,
                  },
                };
              });
              Navigator.pop(context);
              _savePreferences();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
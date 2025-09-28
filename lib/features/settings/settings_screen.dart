import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/app_state.dart';
import '../testing/phase1_test_screen.dart';
import '../testing/phase2_test_screen.dart';
import '../testing/phase3_test_screen.dart';
import '../friends/enhanced_friends_screen.dart';
import '../calendar/enhanced_calendar_screen.dart';
import '../societies/enhanced_societies_screen.dart';
import '../friends/enhanced_map_screen.dart';
import '../timetable/smart_timetable_overlay.dart';
import '../timetable/timetable_management_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../privacy/privacy_settings_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool locationVisible = true;
  bool notificationsEnabled = true;
  String selectedLanguage = 'English';
  String selectedTimeZone = 'AEST (UTC+10)';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final user = appState.currentUser;
        return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.getTextColor(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    backgroundColor: AppColors.primary,
                    child: user.profileImageUrl == null
                        ? Text(
                            user.name[0],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getButtonTextColor(context),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.course} • ${user.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Privacy Settings
            _buildSettingsSection(
              'Privacy Settings',
              [
                _buildTile(
                  'Privacy Settings',
                  'Manage location, timetable, and online status privacy',
                  Icons.privacy_tip,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
                    );
                  },
                ),
              ],
            ),

            // Academic & Timetable
            _buildSettingsSection(
              'Academic & Timetable',
              [
                _buildTile(
                  'Manage Timetable',
                  'Import classes from university or add manually',
                  Icons.edit_calendar,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TimetableManagementScreen()),
                    );
                  },
                ),
                _buildTile(
                  'Timetable Privacy',
                  'Control who can see your class schedule',
                  Icons.schedule,
                  () {},
                  trailing: Text('Friends Only', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
                ),
                _buildTile(
                  'Academic Notifications',
                  'Alerts for classes, assignments, and deadlines',
                  Icons.school,
                  () {},
                  trailing: Switch(
                    value: notificationsEnabled,
                    onChanged: (value) => setState(() => notificationsEnabled = value),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
              ],
            ),

            // Preferences
            _buildSettingsSection(
              'Preferences',
              [
                _buildSwitchTile(
                  'Dark Mode',
                  'Use dark theme throughout the app',
                  appState.isDarkMode,
                  (value) => appState.toggleTheme(),
                  Icons.dark_mode,
                ),
                _buildSwitchTile(
                  'Temp Style',
                  'Enable blue navigation and alternative design elements',
                  appState.isTempStyleEnabled,
                  (value) => appState.toggleTempStyle(),
                  Icons.palette,
                ),
                _buildTile(
                  'Language',
                  'App language preference',
                  Icons.language,
                  () {},
                  trailing: Text(selectedLanguage, style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
                ),
                _buildTile(
                  'Time Zone',
                  'Your local time zone',
                  Icons.access_time,
                  () {},
                  trailing: Text(selectedTimeZone, style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
                ),
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive notifications for events and messages',
                  notificationsEnabled,
                  (value) => setState(() => notificationsEnabled = value),
                  Icons.notifications,
                ),
              ],
            ),

            // Account
            _buildSettingsSection(
              'Account',
              [
                _buildTile(
                  'Connected Accounts',
                  'Manage linked university accounts',
                  Icons.link,
                  () {},
                ),
                _buildTile(
                  'Data Export',
                  'Download your data',
                  Icons.download,
                  () {},
                ),
                _buildTile(
                  'Delete Account',
                  'Permanently delete your account',
                  Icons.delete_forever,
                  () {},
                  textColor: AppColors.danger,
                ),
              ],
            ),

            // Support
            _buildSettingsSection(
              'Support',
              [
                _buildTile(
                  'Help Center',
                  'Get help and support',
                  Icons.help,
                  () {},
                ),
                _buildTile(
                  'Privacy Policy',
                  'Read our privacy policy',
                  Icons.privacy_tip,
                  () {},
                ),
                _buildTile(
                  'Terms of Service',
                  'Read terms and conditions',
                  Icons.description,
                  () {},
                ),
              ],
            ),

            // Enhanced Features
            _buildSettingsSection(
              'Enhanced Features',
              [
                _buildTile(
                  'Smart Timetable',
                  'Interactive timetable with friend availability matrix',
                  Icons.schedule,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SmartTimetableOverlay()),
                    );
                  },
                ),
                _buildTile(
                  'Notification Center',
                  'Cross-feature notification system with real-time updates',
                  Icons.notifications,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getButtonTextColor(context),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}
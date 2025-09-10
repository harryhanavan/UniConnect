import 'package:flutter/material.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';
import '../testing/phase1_test_screen.dart';
import '../testing/phase2_test_screen.dart';
import '../testing/phase3_test_screen.dart';
import '../friends/enhanced_friends_screen.dart';
import '../calendar/enhanced_calendar_screen.dart';
import '../societies/enhanced_societies_screen.dart';
import '../friends/enhanced_map_screen.dart';
import '../timetable/smart_timetable_overlay.dart';
import '../notifications/notification_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool locationVisible = true;
  bool darkMode = false;
  bool notificationsEnabled = true;
  String selectedLanguage = 'English';
  String selectedTimeZone = 'AEST (UTC+10)';

  @override
  Widget build(BuildContext context) {
    final user = DemoDataManager.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
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
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.name[0],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.course} • ${user.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Privacy Settings
            _buildSettingsSection(
              'Privacy Settings',
              [
                _buildSwitchTile(
                  'Location visible to friends',
                  'Allow friends to see your current campus location',
                  locationVisible,
                  (value) => setState(() => locationVisible = value),
                  Icons.location_on,
                ),
                _buildTile(
                  'Timetable Privacy',
                  'Manage who can see your class schedule',
                  Icons.schedule,
                  () {},
                  trailing: const Text('Friends Only', style: TextStyle(color: Colors.grey)),
                ),
                _buildTile(
                  'Profile Visibility',
                  'Control who can find you',
                  Icons.visibility,
                  () {},
                  trailing: const Text('Public', style: TextStyle(color: Colors.grey)),
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
                  darkMode,
                  (value) => setState(() => darkMode = value),
                  Icons.dark_mode,
                ),
                _buildTile(
                  'Language',
                  'App language preference',
                  Icons.language,
                  () {},
                  trailing: Text(selectedLanguage, style: const TextStyle(color: Colors.grey)),
                ),
                _buildTile(
                  'Time Zone',
                  'Your local time zone',
                  Icons.access_time,
                  () {},
                  trailing: Text(selectedTimeZone, style: const TextStyle(color: Colors.grey)),
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

            // Enhanced Features Access
            _buildSettingsSection(
              'Enhanced Features (Phase 3)',
              [
                _buildTile(
                  'Enhanced Calendar',
                  'Unified calendar with friend overlays and multi-source events',
                  Icons.calendar_today,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EnhancedCalendarScreen()),
                    );
                  },
                ),
                _buildTile(
                  'Enhanced Societies',
                  'Society integration with auto-calendar updates',
                  Icons.groups,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EnhancedSocietiesScreen()),
                    );
                  },
                ),
                _buildTile(
                  'Enhanced Map',
                  'Real-time friend tracking with UTS campus integration',
                  Icons.map,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EnhancedMapScreen()),
                    );
                  },
                ),
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

            // Debug & Development (for testing)
            _buildSettingsSection(
              'Development & Testing',
              [
                _buildTile(
                  'Phase 1: Data Architecture Test',
                  'Test interconnected data models',
                  Icons.storage,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Phase1TestScreen()),
                    );
                  },
                ),
                _buildTile(
                  'Phase 2: Feature Interconnection Test',
                  'Test cross-feature integrations',
                  Icons.hub,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Phase2TestScreen()),
                    );
                  },
                ),
                _buildTile(
                  'Phase 3: Enhanced UI Test',
                  'Test all enhanced screens and cross-feature integration',
                  Icons.science,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Phase3TestScreen()),
                    );
                  },
                ),
                _buildTile(
                  'Enhanced Friends Screen',
                  'View the new interconnected friends interface',
                  Icons.people,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EnhancedFriendsScreen()),
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
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
              color: Colors.grey[50],
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
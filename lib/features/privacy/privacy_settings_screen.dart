import 'package:flutter/material.dart';
import '../../shared/models/privacy_settings.dart';
import '../../core/services/privacy_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../shared/widgets/app_colors.dart';
import 'friend_privacy_overrides_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final PrivacyService _privacyService = PrivacyService();
  
  PrivacySettings? _currentSettings;
  Map<String, dynamic>? _privacySummary;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyData();
  }

  Future<void> _loadPrivacyData() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _currentSettings = _privacyService.getCurrentUserPrivacySettings();
      _privacySummary = _privacyService.getPrivacySummary();
      _recommendations = _privacyService.getPrivacyRecommendations();
      _isLoading = false;
    });
  }

  Future<void> _updateLocationSharing(LocationSharingLevel level) async {
    if (_currentSettings == null) return;

    final updatedSettings = _currentSettings!.copyWith(locationSharing: level);
    final success = await _privacyService.updatePrivacySettings(updatedSettings);
    
    if (success) {
      await _loadPrivacyData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location sharing updated')),
        );
      }
    }
  }

  Future<void> _updateTimetableSharing(TimetableSharingLevel level) async {
    if (_currentSettings == null) return;

    final updatedSettings = _currentSettings!.copyWith(timetableSharing: level);
    final success = await _privacyService.updatePrivacySettings(updatedSettings);
    
    if (success) {
      await _loadPrivacyData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable sharing updated')),
        );
      }
    }
  }

  Future<void> _updateOnlineStatusVisibility(OnlineStatusVisibility visibility) async {
    if (_currentSettings == null) return;

    final updatedSettings = _currentSettings!.copyWith(onlineStatusVisibility: visibility);
    final success = await _privacyService.updatePrivacySettings(updatedSettings);
    
    if (success) {
      await _loadPrivacyData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Online status visibility updated')),
        );
      }
    }
  }

  Future<void> _toggleLocationDetail(bool shareExact) async {
    if (_currentSettings == null) return;

    final updatedSettings = _currentSettings!.copyWith(
      shareExactLocation: shareExact,
      shareBuildingOnly: !shareExact,
    );
    final success = await _privacyService.updatePrivacySettings(updatedSettings);
    
    if (success) {
      await _loadPrivacyData();
    }
  }

  Future<void> _toggleTimetableDetail(String detailType, bool value) async {
    if (_currentSettings == null) return;

    PrivacySettings updatedSettings;
    
    switch (detailType) {
      case 'freeTimes':
        updatedSettings = _currentSettings!.copyWith(shareFreeTimes: value);
        break;
      case 'classDetails':
        updatedSettings = _currentSettings!.copyWith(shareClassDetails: value);
        break;
      case 'lastSeen':
        updatedSettings = _currentSettings!.copyWith(showLastSeen: value);
        break;
      default:
        return;
    }
    
    final success = await _privacyService.updatePrivacySettings(updatedSettings);
    if (success) {
      await _loadPrivacyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPrivacyData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_recommendations.isNotEmpty) ...[
                      _buildRecommendationsSection(),
                      const SizedBox(height: 24),
                    ],
                    _buildLocationSharingSection(),
                    const SizedBox(height: 24),
                    _buildTimetableSharingSection(),
                    const SizedBox(height: 24),
                    _buildOnlineStatusSection(),
                    const SizedBox(height: 24),
                    _buildAdvancedControlsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.warning),
                SizedBox(width: 8),
                Text(
                  'Privacy Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  rec['type'] == 'warning' ? Icons.warning_amber
                    : rec['type'] == 'info' ? Icons.info_outline
                    : Icons.tips_and_updates,
                  color: rec['type'] == 'warning' ? AppColors.warning
                       : rec['type'] == 'info' ? AppColors.primary
                       : AppColors.success,
                ),
                title: Text(rec['title'] ?? ''),
                subtitle: Text(rec['description'] ?? ''),
                trailing: TextButton(
                  onPressed: () {
                    // Action would scroll to relevant section
                  },
                  child: Text(rec['action'] ?? 'Review'),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSharingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Location Sharing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Who can see your location on campus?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...LocationSharingLevel.values.map((level) {
              return RadioListTile<LocationSharingLevel>(
                value: level,
                groupValue: _currentSettings?.locationSharing,
                onChanged: (value) => value != null ? _updateLocationSharing(value) : null,
                title: Text(_getLocationSharingTitle(level)),
                subtitle: Text(_getLocationSharingDescription(level)),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              );
            }),
            if (_currentSettings?.locationSharing != LocationSharingLevel.nobody) ...[
              const Divider(),
              const Text(
                'Location Detail Level',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Share exact location'),
                subtitle: const Text('Share precise coordinates and room details'),
                value: _currentSettings?.shareExactLocation ?? false,
                onChanged: _toggleLocationDetail,
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Share building only'),
                subtitle: const Text('Only show which building you\'re in'),
                value: _currentSettings?.shareBuildingOnly ?? false,
                onChanged: (value) => _toggleLocationDetail(!value),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableSharingSection() {
    final friendsCount = _privacySummary?['friendsCount'] ?? 0;
    final overridesCount = _privacySummary?['individualOverridesCount'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Timetable Sharing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Who can see your class schedule and free times?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...TimetableSharingLevel.values.map((level) {
              return RadioListTile<TimetableSharingLevel>(
                value: level,
                groupValue: _currentSettings?.timetableSharing,
                onChanged: (value) => value != null ? _updateTimetableSharing(value) : null,
                title: Text(_getTimetableSharingTitle(level)),
                subtitle: Text(_getTimetableSharingDescription(level)),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              );
            }),
            if (_currentSettings?.timetableSharing != TimetableSharingLevel.nobody) ...[
              const Divider(),
              const Text(
                'Timetable Details',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Share free times'),
                subtitle: const Text('Help friends find when you\'re available'),
                value: _currentSettings?.shareFreeTimes ?? false,
                onChanged: (value) => _toggleTimetableDetail('freeTimes', value),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Share class details'),
                subtitle: const Text('Show specific class names and locations'),
                value: _currentSettings?.shareClassDetails ?? false,
                onChanged: (value) => _toggleTimetableDetail('classDetails', value),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Individual Friend Controls'),
                subtitle: Text('$overridesCount custom overrides for $friendsCount friends'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FriendPrivacyOverridesScreen(),
                    ),
                  );
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.online_prediction, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Online Status & Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Who can see when you\'re online and your activity?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...OnlineStatusVisibility.values.map((visibility) {
              return RadioListTile<OnlineStatusVisibility>(
                value: visibility,
                groupValue: _currentSettings?.onlineStatusVisibility,
                onChanged: (value) => value != null ? _updateOnlineStatusVisibility(value) : null,
                title: Text(_getOnlineStatusTitle(visibility)),
                subtitle: Text(_getOnlineStatusDescription(visibility)),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              );
            }),
            if (_currentSettings?.onlineStatusVisibility != OnlineStatusVisibility.nobody) ...[
              const Divider(),
              SwitchListTile(
                title: const Text('Show "last seen" times'),
                subtitle: const Text('Let others see when you were last active'),
                value: _currentSettings?.showLastSeen ?? false,
                onChanged: (value) => _toggleTimetableDetail('lastSeen', value),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedControlsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Advanced Privacy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Privacy Activity Log'),
              subtitle: const Text('View your recent privacy-related actions'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/privacy-activity');
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download My Data'),
              subtitle: const Text('Get a copy of all your privacy settings and data'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data export initiated. You\'ll receive an email when ready.'),
                  ),
                );
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Privacy Data', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently remove all privacy settings'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Privacy Data?'),
                    content: const Text(
                      'This will reset all your privacy settings to defaults. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Privacy data reset to defaults')),
                          );
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  String _getLocationSharingTitle(LocationSharingLevel level) {
    switch (level) {
      case LocationSharingLevel.nobody:
        return 'Nobody';
      case LocationSharingLevel.friends:
        return 'Friends Only';
      case LocationSharingLevel.everyone:
        return 'Everyone';
    }
  }

  String _getLocationSharingDescription(LocationSharingLevel level) {
    switch (level) {
      case LocationSharingLevel.nobody:
        return 'Keep your location completely private';
      case LocationSharingLevel.friends:
        return 'Share location only with accepted friends';
      case LocationSharingLevel.everyone:
        return 'Anyone can see where you are on campus';
    }
  }

  String _getTimetableSharingTitle(TimetableSharingLevel level) {
    switch (level) {
      case TimetableSharingLevel.nobody:
        return 'Private';
      case TimetableSharingLevel.friends:
        return 'Friends Only';
      case TimetableSharingLevel.everyone:
        return 'Everyone';
    }
  }

  String _getTimetableSharingDescription(TimetableSharingLevel level) {
    switch (level) {
      case TimetableSharingLevel.nobody:
        return 'Keep your schedule completely private';
      case TimetableSharingLevel.friends:
        return 'Share timetable only with accepted friends';
      case TimetableSharingLevel.everyone:
        return 'Anyone can see your class schedule';
    }
  }

  String _getOnlineStatusTitle(OnlineStatusVisibility visibility) {
    switch (visibility) {
      case OnlineStatusVisibility.nobody:
        return 'Invisible';
      case OnlineStatusVisibility.friends:
        return 'Friends Only';
      case OnlineStatusVisibility.everyone:
        return 'Everyone';
    }
  }

  String _getOnlineStatusDescription(OnlineStatusVisibility visibility) {
    switch (visibility) {
      case OnlineStatusVisibility.nobody:
        return 'Always appear offline to everyone';
      case OnlineStatusVisibility.friends:
        return 'Show online status only to friends';
      case OnlineStatusVisibility.everyone:
        return 'Everyone can see when you\'re online';
    }
  }
}
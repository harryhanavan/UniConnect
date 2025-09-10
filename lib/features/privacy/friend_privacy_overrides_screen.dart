import 'package:flutter/material.dart';
import '../../shared/models/privacy_settings.dart';
import '../../shared/models/user.dart';
import '../../core/services/privacy_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';

class FriendPrivacyOverridesScreen extends StatefulWidget {
  const FriendPrivacyOverridesScreen({super.key});

  @override
  State<FriendPrivacyOverridesScreen> createState() => _FriendPrivacyOverridesScreenState();
}

class _FriendPrivacyOverridesScreenState extends State<FriendPrivacyOverridesScreen> {
  final PrivacyService _privacyService = PrivacyService();
  final DemoDataManager _demoData = DemoDataManager.instance;
  
  PrivacySettings? _currentSettings;
  List<User> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      _currentSettings = _privacyService.getCurrentUserPrivacySettings();
      _friends = _demoData.getFriendsForUser(_demoData.currentUser.id);
      _isLoading = false;
    });
  }

  Future<void> _updateFriendOverride(String friendId, TimetableSharingLevel? level) async {
    if (level == null) return;
    
    final success = await _privacyService.updatePerFriendTimetableSharing(friendId, level);
    
    if (success) {
      await _loadData();
      if (mounted) {
        final friend = _friends.firstWhere((f) => f.id == friendId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated timetable sharing for ${friend.name}'),
          ),
        );
      }
    }
  }

  TimetableSharingLevel _getEffectiveLevel(String friendId) {
    final perFriendOverride = _currentSettings?.perFriendTimetableSharing[friendId];
    return perFriendOverride ?? _currentSettings?.timetableSharing ?? TimetableSharingLevel.nobody;
  }

  bool _hasOverride(String friendId) {
    return _currentSettings?.perFriendTimetableSharing.containsKey(friendId) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Friend Controls'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Timetable Sharing Overrides',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set individual sharing levels for specific friends. '
                        'Global setting: ${_getTimetableSharingTitle(_currentSettings?.timetableSharing ?? TimetableSharingLevel.nobody)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _friends.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No Friends Yet',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Add friends to set individual privacy controls',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _friends.length,
                          itemBuilder: (context, index) {
                            final friend = _friends[index];
                            return _buildFriendCard(friend);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFriendCard(User friend) {
    final effectiveLevel = _getEffectiveLevel(friend.id);
    final hasOverride = _hasOverride(friend.id);
    final globalLevel = _currentSettings?.timetableSharing ?? TimetableSharingLevel.nobody;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(friend.profileImageUrl ?? ''),
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${friend.course} • ${friend.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasOverride)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Custom',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Timetable Sharing Level:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: TimetableSharingLevel.values.map((level) {
                final isSelected = effectiveLevel == level;
                final isGlobalDefault = level == globalLevel;
                
                return RadioListTile<TimetableSharingLevel>(
                  value: level,
                  groupValue: effectiveLevel,
                  onChanged: (value) => _updateFriendOverride(friend.id, value),
                  title: Row(
                    children: [
                      Text(_getTimetableSharingTitle(level)),
                      if (isGlobalDefault && !hasOverride)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(_getTimetableSharingDescription(level)),
                  activeColor: AppColors.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                );
              }).toList(),
            ),
            if (hasOverride) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'This friend has a custom override (global default: ${_getTimetableSharingTitle(globalLevel)})',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _updateFriendOverride(friend.id, globalLevel),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Reset to Default',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
        return 'This friend cannot see your schedule';
      case TimetableSharingLevel.friends:
        return 'Share your timetable with this friend';
      case TimetableSharingLevel.everyone:
        return 'Full timetable access (same as public)';
    }
  }
}
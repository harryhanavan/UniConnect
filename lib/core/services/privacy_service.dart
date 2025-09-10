import '../../shared/models/privacy_settings.dart';
import '../demo_data/demo_data_manager.dart';

class PrivacyService {
  static final PrivacyService _instance = PrivacyService._internal();
  factory PrivacyService() => _instance;
  PrivacyService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;

  // Get current user's privacy settings
  PrivacySettings? getCurrentUserPrivacySettings() {
    return _demoData.getPrivacySettingsForUser(_demoData.currentUser.id);
  }

  // Update privacy settings for current user
  Future<bool> updatePrivacySettings(PrivacySettings newSettings) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final privacyList = _demoData.privacySettingsSync;
    final index = privacyList.indexWhere((p) => p.userId == newSettings.userId);
    
    if (index != -1) {
      privacyList[index] = newSettings.copyWith(updatedAt: DateTime.now());
      return true;
    }
    
    return false;
  }

  // Update per-friend timetable sharing
  Future<bool> updatePerFriendTimetableSharing(String friendId, TimetableSharingLevel level) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final currentSettings = getCurrentUserPrivacySettings();
    if (currentSettings == null) return false;

    final updatedPerFriendSharing = Map<String, TimetableSharingLevel>.from(
      currentSettings.perFriendTimetableSharing ?? {}
    );
    
    if (level == currentSettings.timetableSharing) {
      // Remove individual override if it matches global setting
      updatedPerFriendSharing.remove(friendId);
    } else {
      // Set individual override
      updatedPerFriendSharing[friendId] = level;
    }

    final updatedSettings = currentSettings.copyWith(
      perFriendTimetableSharing: updatedPerFriendSharing,
      updatedAt: DateTime.now(),
    );

    return await updatePrivacySettings(updatedSettings);
  }

  // Check if user can view another user's location
  bool canViewLocation(String viewerId, String targetUserId) {
    if (viewerId == targetUserId) return true;

    final targetSettings = _demoData.getPrivacySettingsForUser(targetUserId);
    if (targetSettings == null) return false;

    final targetUser = _demoData.getUserById(targetUserId);
    final viewerUser = _demoData.getUserById(viewerId);
    
    if (targetUser == null || viewerUser == null) return false;

    switch (targetSettings.locationSharing) {
      case LocationSharingLevel.nobody:
        return false;
      case LocationSharingLevel.friends:
        return targetUser.friendIds.contains(viewerId);
      case LocationSharingLevel.everyone:
        return true;
    }
  }

  // Check if user can view another user's timetable
  bool canViewTimetable(String viewerId, String targetUserId) {
    if (viewerId == targetUserId) return true;

    final targetSettings = _demoData.getPrivacySettingsForUser(targetUserId);
    if (targetSettings == null) return false;

    final targetUser = _demoData.getUserById(targetUserId);
    final viewerUser = _demoData.getUserById(viewerId);
    
    if (targetUser == null || viewerUser == null) return false;

    // Check per-friend override first
    final perFriendSetting = targetSettings.perFriendTimetableSharing[viewerId];
    if (perFriendSetting != null) {
      switch (perFriendSetting) {
        case TimetableSharingLevel.nobody:
          return false;
        case TimetableSharingLevel.friends:
          return targetUser.friendIds.contains(viewerId);
        case TimetableSharingLevel.everyone:
          return true;
      }
    }

    // Fall back to global setting
    switch (targetSettings.timetableSharing) {
      case TimetableSharingLevel.nobody:
        return false;
      case TimetableSharingLevel.friends:
        return targetUser.friendIds.contains(viewerId);
      case TimetableSharingLevel.everyone:
        return true;
    }
  }

  // Check if user can view another user's online status
  bool canViewOnlineStatus(String viewerId, String targetUserId) {
    if (viewerId == targetUserId) return true;

    final targetSettings = _demoData.getPrivacySettingsForUser(targetUserId);
    if (targetSettings == null) return false;

    final targetUser = _demoData.getUserById(targetUserId);
    final viewerUser = _demoData.getUserById(viewerId);
    
    if (targetUser == null || viewerUser == null) return false;

    switch (targetSettings.onlineStatusVisibility) {
      case OnlineStatusVisibility.nobody:
        return false;
      case OnlineStatusVisibility.friends:
        return targetUser.friendIds.contains(viewerId);
      case OnlineStatusVisibility.everyone:
        return true;
    }
  }

  // Get filtered location data based on privacy settings
  Map<String, dynamic> getFilteredLocationData(String viewerId, String targetUserId) {
    final targetUser = _demoData.getUserById(targetUserId);
    final targetSettings = _demoData.getPrivacySettingsForUser(targetUserId);
    
    if (targetUser == null || targetSettings == null) return {};
    
    if (!canViewLocation(viewerId, targetUserId)) {
      return {'canView': false};
    }

    final result = <String, dynamic>{
      'canView': true,
      'userId': targetUserId,
      'locationUpdatedAt': targetUser.locationUpdatedAt,
    };

    if (targetSettings.shareExactLocation == true) {
      result.addAll({
        'latitude': targetUser.latitude,
        'longitude': targetUser.longitude,
        'currentRoom': targetUser.currentRoom,
        'currentBuilding': targetUser.currentBuilding,
        'currentLocationId': targetUser.currentLocationId,
      });
    } else if (targetSettings.shareBuildingOnly == true) {
      result.addAll({
        'currentBuilding': targetUser.currentBuilding,
      });
    }

    return result;
  }

  // Get privacy-aware timetable data
  Map<String, dynamic> getFilteredTimetableData(String viewerId, String targetUserId, DateTime date) {
    final targetSettings = _demoData.getPrivacySettingsForUser(targetUserId);
    
    if (targetSettings == null || !canViewTimetable(viewerId, targetUserId)) {
      return {'canView': false};
    }

    final result = <String, dynamic>{
      'canView': true,
      'userId': targetUserId,
      'shareFreeTimes': targetSettings.shareFreeTimes ?? false,
      'shareClassDetails': targetSettings.shareClassDetails ?? false,
    };

    // Add actual timetable data based on sharing level
    // This would integrate with CalendarService to get filtered events
    
    return result;
  }

  // Get privacy summary for settings UI
  Map<String, dynamic> getPrivacySummary() {
    final settings = getCurrentUserPrivacySettings();
    if (settings == null) return {};

    final friends = _demoData.getFriendsForUser(_demoData.currentUser.id);
    final overridesCount = settings.perFriendTimetableSharing.length ?? 0;

    return {
      'locationSharing': settings.locationSharing,
      'shareExactLocation': settings.shareExactLocation,
      'shareBuildingOnly': settings.shareBuildingOnly,
      'timetableSharing': settings.timetableSharing,
      'shareFreeTimes': settings.shareFreeTimes,
      'shareClassDetails': settings.shareClassDetails,
      'onlineStatusVisibility': settings.onlineStatusVisibility,
      'showLastSeen': settings.showLastSeen,
      'friendsCount': friends.length,
      'individualOverridesCount': overridesCount,
    };
  }

  // Create privacy audit log entry (for demonstrating privacy awareness)
  Map<String, dynamic> createPrivacyAuditEntry(String action, Map<String, dynamic> details) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'userId': _demoData.currentUser.id,
      'action': action,
      'details': details,
      'ipAddress': '192.168.1.100', // Simulated
    };
  }

  // Get recent privacy actions (demo data)
  List<Map<String, dynamic>> getRecentPrivacyActions() {
    final now = DateTime.now();
    return [
      {
        'action': 'Updated location sharing',
        'timestamp': now.subtract(const Duration(days: 2)),
        'details': 'Changed from "Everyone" to "Friends only"',
      },
      {
        'action': 'Individual timetable override',
        'timestamp': now.subtract(const Duration(days: 5)),
        'details': 'Set Marcus Rodriguez to "No sharing"',
      },
      {
        'action': 'Privacy settings reviewed',
        'timestamp': now.subtract(const Duration(days: 7)),
        'details': 'Reviewed all privacy settings',
      },
    ];
  }

  // Generate privacy recommendations
  List<Map<String, dynamic>> getPrivacyRecommendations() {
    final settings = getCurrentUserPrivacySettings();
    final recommendations = <Map<String, dynamic>>[];

    if (settings == null) return recommendations;

    if (settings.shareExactLocation == true) {
      recommendations.add({
        'type': 'warning',
        'title': 'Exact Location Sharing',
        'description': 'You\'re sharing your exact location. Consider sharing building-only for better privacy.',
        'action': 'Review Location Settings',
      });
    }

    if (settings.timetableSharing == TimetableSharingLevel.everyone) {
      recommendations.add({
        'type': 'info',
        'title': 'Public Timetable',
        'description': 'Your timetable is visible to everyone. This helps with spontaneous meetups but reduces privacy.',
        'action': 'Review Timetable Settings',
      });
    }

    if (settings.showLastSeen == true && settings.onlineStatusVisibility != OnlineStatusVisibility.nobody) {
      recommendations.add({
        'type': 'tip',
        'title': 'Last Seen Status',
        'description': 'Consider hiding "last seen" times if you value privacy about your activity patterns.',
        'action': 'Review Status Settings',
      });
    }

    return recommendations;
  }
}
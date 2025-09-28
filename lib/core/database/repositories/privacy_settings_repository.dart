import '../../../shared/models/privacy_settings.dart';
import '../base_repository.dart';
import '../database_helper.dart';

class PrivacySettingsRepository extends BaseRepository<PrivacySettings> {
  @override
  String get tableName => 'privacy_settings';

  @override
  PrivacySettings fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      defaultPrivacy: PrivacyLevel.friends, // Default privacy level
      allowFriendRequests: (map['allow_friend_requests'] as int) == 1,
      allowSocietyInvites: (map['allow_event_invitations'] as int) == 1,
      locationSharing: LocationSharingLevel.friends, // Default location sharing
      shareExactLocation: (map['show_location'] as int) == 1,
      shareBuildingOnly: true, // Default
      locationExceptions: [], // Default empty
      timetableSharing: TimetableSharingLevel.friends, // Default timetable sharing
      shareFreeTimes: (map['show_calendar'] as int) == 1,
      shareClassDetails: false, // Default
      perFriendTimetableSharing: {}, // Default empty
      onlineStatusVisibility: OnlineStatusVisibility.friends, // Default
      showLastSeen: (map['show_online_status'] as int) == 1,
      showActivity: true, // Default
      allowActivityNotifications: true, // Default
      showSocietyMemberships: (map['show_societies'] as int) == 1,
      allowEventInvites: (map['allow_event_invitations'] as int) == 1,
      shareEventAttendance: true, // Default
      societyEventDefaultPrivacy: PrivacyLevel.friends, // Default
      discoverableByEmail: false, // Default
      discoverableByPhone: false, // Default
      showInSuggestions: (map['show_friends'] as int) == 1,
      allowAnalytics: false, // Default
      createdAt: DateTime.now(), // Default creation time
    );
  }

  @override
  Map<String, dynamic> toMap(PrivacySettings settings) {
    return {
      'id': settings.id,
      'user_id': settings.userId,
      'show_online_status': settings.showLastSeen ? 1 : 0,
      'show_location': settings.shareExactLocation ? 1 : 0,
      'show_calendar': settings.shareFreeTimes ? 1 : 0,
      'show_friends': settings.showInSuggestions ? 1 : 0,
      'show_societies': settings.showSocietyMemberships ? 1 : 0,
      'allow_friend_requests': settings.allowFriendRequests ? 1 : 0,
      'allow_event_invitations': settings.allowEventInvites ? 1 : 0,
      'allow_study_group_invitations': settings.allowSocietyInvites ? 1 : 0,
      'allow_location_sharing': settings.shareExactLocation ? 1 : 0,
    };
  }

  Future<PrivacySettings?> getByUserId(String userId) async {
    final results = await query(
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<List<PrivacySettings>> getPrivateUsers() async {
    return await query(
      where: 'show_online_status = ? OR allow_friend_requests = ?',
      whereArgs: [0, 0],
      orderBy: 'user_id ASC',
    );
  }

  Future<List<PrivacySettings>> getLocationSharingUsers() async {
    return await query(
      where: 'allow_location_sharing = ? AND show_location = ?',
      whereArgs: [1, 1],
      orderBy: 'user_id ASC',
    );
  }

  Future<int> updateUserPrivacySettings(String userId, Map<String, bool> updates) async {
    final settings = await getByUserId(userId);
    if (settings == null) return 0;

    // Create updated settings using copyWith-like approach
    final updatedSettings = PrivacySettings(
      id: settings.id,
      userId: settings.userId,
      defaultPrivacy: settings.defaultPrivacy,
      allowFriendRequests: updates['allowFriendRequests'] ?? settings.allowFriendRequests,
      allowSocietyInvites: updates['allowSocietyInvites'] ?? settings.allowSocietyInvites,
      locationSharing: settings.locationSharing,
      shareExactLocation: updates['shareExactLocation'] ?? settings.shareExactLocation,
      shareBuildingOnly: settings.shareBuildingOnly,
      locationExceptions: settings.locationExceptions,
      timetableSharing: settings.timetableSharing,
      shareFreeTimes: updates['shareFreeTimes'] ?? settings.shareFreeTimes,
      shareClassDetails: settings.shareClassDetails,
      perFriendTimetableSharing: settings.perFriendTimetableSharing,
      onlineStatusVisibility: settings.onlineStatusVisibility,
      showLastSeen: updates['showLastSeen'] ?? settings.showLastSeen,
      showActivity: settings.showActivity,
      allowActivityNotifications: settings.allowActivityNotifications,
      showSocietyMemberships: updates['showSocietyMemberships'] ?? settings.showSocietyMemberships,
      allowEventInvites: updates['allowEventInvites'] ?? settings.allowEventInvites,
      shareEventAttendance: settings.shareEventAttendance,
      societyEventDefaultPrivacy: settings.societyEventDefaultPrivacy,
      discoverableByEmail: settings.discoverableByEmail,
      discoverableByPhone: settings.discoverableByPhone,
      showInSuggestions: updates['showInSuggestions'] ?? settings.showInSuggestions,
      allowAnalytics: settings.allowAnalytics,
      createdAt: settings.createdAt,
      updatedAt: DateTime.now(),
    );

    return await update(updatedSettings);
  }

  Future<Map<String, int>> getPrivacyStatistics() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        SUM(show_online_status) as show_online_count,
        SUM(show_location) as show_location_count,
        SUM(show_calendar) as show_calendar_count,
        SUM(show_friends) as show_friends_count,
        SUM(show_societies) as show_societies_count,
        SUM(allow_friend_requests) as allow_friend_requests_count,
        SUM(allow_event_invitations) as allow_event_invitations_count,
        SUM(allow_study_group_invitations) as allow_study_group_invitations_count,
        SUM(allow_location_sharing) as allow_location_sharing_count,
        COUNT(*) as total_users
      FROM privacy_settings
    ''');

    if (maps.isNotEmpty) {
      final result = maps.first;
      return {
        'show_online_status': result['show_online_count'] as int,
        'show_location': result['show_location_count'] as int,
        'show_calendar': result['show_calendar_count'] as int,
        'show_friends': result['show_friends_count'] as int,
        'show_societies': result['show_societies_count'] as int,
        'allow_friend_requests': result['allow_friend_requests_count'] as int,
        'allow_event_invitations': result['allow_event_invitations_count'] as int,
        'allow_study_group_invitations': result['allow_study_group_invitations_count'] as int,
        'allow_location_sharing': result['allow_location_sharing_count'] as int,
        'total_users': result['total_users'] as int,
      };
    }

    return {};
  }

  Future<bool> canUserReceiveFriendRequests(String userId) async {
    final settings = await getByUserId(userId);
    return settings?.allowFriendRequests ?? false;
  }

  Future<bool> canUserReceiveEventInvitations(String userId) async {
    final settings = await getByUserId(userId);
    return settings?.allowEventInvites ?? false;
  }

  Future<bool> isUserLocationVisible(String userId) async {
    final settings = await getByUserId(userId);
    return settings?.shareExactLocation ?? false;
  }

  Future<bool> isUserOnlineStatusVisible(String userId) async {
    final settings = await getByUserId(userId);
    return settings?.showLastSeen ?? false;
  }
}
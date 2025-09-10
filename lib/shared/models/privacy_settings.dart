enum PrivacyLevel { public, friends, private }
enum LocationSharingLevel { nobody, friends, everyone }
enum TimetableSharingLevel { nobody, friends, everyone }
enum OnlineStatusVisibility { nobody, friends, everyone }

class PrivacySettings {
  final String id;
  final String userId;
  
  // General privacy settings
  final PrivacyLevel defaultPrivacy;
  final bool allowFriendRequests;
  final bool allowSocietyInvites;
  
  // Location sharing settings
  final LocationSharingLevel locationSharing;
  final bool shareExactLocation;
  final bool shareBuildingOnly;
  final List<String> locationExceptions; // User IDs with different permissions
  
  // Timetable sharing settings
  final TimetableSharingLevel timetableSharing;
  final bool shareFreeTimes;
  final bool shareClassDetails;
  final Map<String, TimetableSharingLevel> perFriendTimetableSharing; // Friend ID -> sharing level
  
  // Online status and activity
  final OnlineStatusVisibility onlineStatusVisibility;
  final bool showLastSeen;
  final bool showActivity;
  final bool allowActivityNotifications;
  
  // Society and event privacy
  final bool showSocietyMemberships;
  final bool allowEventInvites;
  final bool shareEventAttendance;
  final PrivacyLevel societyEventDefaultPrivacy;
  
  // Contact and discovery settings
  final bool discoverableByEmail;
  final bool discoverableByPhone;
  final bool showInSuggestions;
  final bool allowAnalytics;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PrivacySettings({
    required this.id,
    required this.userId,
    required this.createdAt,
    
    // Sensible defaults for university social app
    this.defaultPrivacy = PrivacyLevel.friends,
    this.allowFriendRequests = true,
    this.allowSocietyInvites = true,
    
    this.locationSharing = LocationSharingLevel.friends,
    this.shareExactLocation = false,
    this.shareBuildingOnly = true,
    this.locationExceptions = const [],
    
    this.timetableSharing = TimetableSharingLevel.friends,
    this.shareFreeTimes = true,
    this.shareClassDetails = false,
    this.perFriendTimetableSharing = const {},
    
    this.onlineStatusVisibility = OnlineStatusVisibility.friends,
    this.showLastSeen = true,
    this.showActivity = true,
    this.allowActivityNotifications = true,
    
    this.showSocietyMemberships = true,
    this.allowEventInvites = true,
    this.shareEventAttendance = true,
    this.societyEventDefaultPrivacy = PrivacyLevel.friends,
    
    this.discoverableByEmail = true,
    this.discoverableByPhone = false,
    this.showInSuggestions = true,
    this.allowAnalytics = true,
    
    this.updatedAt,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      
      defaultPrivacy: PrivacyLevel.values.firstWhere(
        (e) => e.toString() == 'PrivacyLevel.${json['defaultPrivacy']}',
        orElse: () => PrivacyLevel.friends,
      ),
      allowFriendRequests: json['allowFriendRequests'] as bool? ?? true,
      allowSocietyInvites: json['allowSocietyInvites'] as bool? ?? true,
      
      locationSharing: LocationSharingLevel.values.firstWhere(
        (e) => e.toString() == 'LocationSharingLevel.${json['locationSharing']}',
        orElse: () => LocationSharingLevel.friends,
      ),
      shareExactLocation: json['shareExactLocation'] as bool? ?? false,
      shareBuildingOnly: json['shareBuildingOnly'] as bool? ?? true,
      locationExceptions: (json['locationExceptions'] as List<dynamic>?)?.cast<String>() ?? [],
      
      timetableSharing: TimetableSharingLevel.values.firstWhere(
        (e) => e.toString() == 'TimetableSharingLevel.${json['timetableSharing']}',
        orElse: () => TimetableSharingLevel.friends,
      ),
      shareFreeTimes: json['shareFreeTimes'] as bool? ?? true,
      shareClassDetails: json['shareClassDetails'] as bool? ?? false,
      perFriendTimetableSharing: (json['perFriendTimetableSharing'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                key, 
                TimetableSharingLevel.values.firstWhere(
                  (e) => e.toString() == 'TimetableSharingLevel.$value',
                  orElse: () => TimetableSharingLevel.friends,
                )
              )) ?? {},
      
      onlineStatusVisibility: OnlineStatusVisibility.values.firstWhere(
        (e) => e.toString() == 'OnlineStatusVisibility.${json['onlineStatusVisibility']}',
        orElse: () => OnlineStatusVisibility.friends,
      ),
      showLastSeen: json['showLastSeen'] as bool? ?? true,
      showActivity: json['showActivity'] as bool? ?? true,
      allowActivityNotifications: json['allowActivityNotifications'] as bool? ?? true,
      
      showSocietyMemberships: json['showSocietyMemberships'] as bool? ?? true,
      allowEventInvites: json['allowEventInvites'] as bool? ?? true,
      shareEventAttendance: json['shareEventAttendance'] as bool? ?? true,
      societyEventDefaultPrivacy: PrivacyLevel.values.firstWhere(
        (e) => e.toString() == 'PrivacyLevel.${json['societyEventDefaultPrivacy']}',
        orElse: () => PrivacyLevel.friends,
      ),
      
      discoverableByEmail: json['discoverableByEmail'] as bool? ?? true,
      discoverableByPhone: json['discoverableByPhone'] as bool? ?? false,
      showInSuggestions: json['showInSuggestions'] as bool? ?? true,
      allowAnalytics: json['allowAnalytics'] as bool? ?? true,
      
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      
      'defaultPrivacy': defaultPrivacy.toString().split('.').last,
      'allowFriendRequests': allowFriendRequests,
      'allowSocietyInvites': allowSocietyInvites,
      
      'locationSharing': locationSharing.toString().split('.').last,
      'shareExactLocation': shareExactLocation,
      'shareBuildingOnly': shareBuildingOnly,
      'locationExceptions': locationExceptions,
      
      'timetableSharing': timetableSharing.toString().split('.').last,
      'shareFreeTimes': shareFreeTimes,
      'shareClassDetails': shareClassDetails,
      'perFriendTimetableSharing': perFriendTimetableSharing.map(
        (key, value) => MapEntry(key, value.toString().split('.').last)
      ),
      
      'onlineStatusVisibility': onlineStatusVisibility.toString().split('.').last,
      'showLastSeen': showLastSeen,
      'showActivity': showActivity,
      'allowActivityNotifications': allowActivityNotifications,
      
      'showSocietyMemberships': showSocietyMemberships,
      'allowEventInvites': allowEventInvites,
      'shareEventAttendance': shareEventAttendance,
      'societyEventDefaultPrivacy': societyEventDefaultPrivacy.toString().split('.').last,
      
      'discoverableByEmail': discoverableByEmail,
      'discoverableByPhone': discoverableByPhone,
      'showInSuggestions': showInSuggestions,
      'allowAnalytics': allowAnalytics,
      
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PrivacySettings copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    
    PrivacyLevel? defaultPrivacy,
    bool? allowFriendRequests,
    bool? allowSocietyInvites,
    
    LocationSharingLevel? locationSharing,
    bool? shareExactLocation,
    bool? shareBuildingOnly,
    List<String>? locationExceptions,
    
    TimetableSharingLevel? timetableSharing,
    bool? shareFreeTimes,
    bool? shareClassDetails,
    Map<String, TimetableSharingLevel>? perFriendTimetableSharing,
    
    OnlineStatusVisibility? onlineStatusVisibility,
    bool? showLastSeen,
    bool? showActivity,
    bool? allowActivityNotifications,
    
    bool? showSocietyMemberships,
    bool? allowEventInvites,
    bool? shareEventAttendance,
    PrivacyLevel? societyEventDefaultPrivacy,
    
    bool? discoverableByEmail,
    bool? discoverableByPhone,
    bool? showInSuggestions,
    bool? allowAnalytics,
    
    DateTime? updatedAt,
  }) {
    return PrivacySettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      
      defaultPrivacy: defaultPrivacy ?? this.defaultPrivacy,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      allowSocietyInvites: allowSocietyInvites ?? this.allowSocietyInvites,
      
      locationSharing: locationSharing ?? this.locationSharing,
      shareExactLocation: shareExactLocation ?? this.shareExactLocation,
      shareBuildingOnly: shareBuildingOnly ?? this.shareBuildingOnly,
      locationExceptions: locationExceptions ?? this.locationExceptions,
      
      timetableSharing: timetableSharing ?? this.timetableSharing,
      shareFreeTimes: shareFreeTimes ?? this.shareFreeTimes,
      shareClassDetails: shareClassDetails ?? this.shareClassDetails,
      perFriendTimetableSharing: perFriendTimetableSharing ?? this.perFriendTimetableSharing,
      
      onlineStatusVisibility: onlineStatusVisibility ?? this.onlineStatusVisibility,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showActivity: showActivity ?? this.showActivity,
      allowActivityNotifications: allowActivityNotifications ?? this.allowActivityNotifications,
      
      showSocietyMemberships: showSocietyMemberships ?? this.showSocietyMemberships,
      allowEventInvites: allowEventInvites ?? this.allowEventInvites,
      shareEventAttendance: shareEventAttendance ?? this.shareEventAttendance,
      societyEventDefaultPrivacy: societyEventDefaultPrivacy ?? this.societyEventDefaultPrivacy,
      
      discoverableByEmail: discoverableByEmail ?? this.discoverableByEmail,
      discoverableByPhone: discoverableByPhone ?? this.discoverableByPhone,
      showInSuggestions: showInSuggestions ?? this.showInSuggestions,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrivacySettings && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PrivacySettings(id: $id, userId: $userId)';
  }

  // Helper methods for checking permissions
  bool canShareLocationWith(String friendId) {
    // Check location exceptions first
    if (locationExceptions.contains(friendId)) {
      return true;
    }
    
    switch (locationSharing) {
      case LocationSharingLevel.nobody:
        return false;
      case LocationSharingLevel.friends:
        return true; // Assuming friendId is already a friend
      case LocationSharingLevel.everyone:
        return true;
    }
  }

  bool canShareTimetableWith(String friendId) {
    // Check per-friend settings first
    if (perFriendTimetableSharing.containsKey(friendId)) {
      final level = perFriendTimetableSharing[friendId]!;
      return level != TimetableSharingLevel.nobody;
    }
    
    switch (timetableSharing) {
      case TimetableSharingLevel.nobody:
        return false;
      case TimetableSharingLevel.friends:
        return true; // Assuming friendId is already a friend
      case TimetableSharingLevel.everyone:
        return true;
    }
  }

  bool canShareOnlineStatusWith(String friendId) {
    switch (onlineStatusVisibility) {
      case OnlineStatusVisibility.nobody:
        return false;
      case OnlineStatusVisibility.friends:
        return true; // Assuming friendId is already a friend
      case OnlineStatusVisibility.everyone:
        return true;
    }
  }

  // Update per-friend timetable sharing
  PrivacySettings setFriendTimetableSharing(String friendId, TimetableSharingLevel level) {
    final updated = Map<String, TimetableSharingLevel>.from(perFriendTimetableSharing);
    updated[friendId] = level;
    return copyWith(perFriendTimetableSharing: updated);
  }

  // Remove friend-specific settings (when unfriending)
  PrivacySettings removeFriendSettings(String friendId) {
    final updatedTimetable = Map<String, TimetableSharingLevel>.from(perFriendTimetableSharing);
    updatedTimetable.remove(friendId);
    
    final updatedExceptions = List<String>.from(locationExceptions);
    updatedExceptions.remove(friendId);
    
    return copyWith(
      perFriendTimetableSharing: updatedTimetable,
      locationExceptions: updatedExceptions,
    );
  }
}
enum UserStatus { online, offline, busy, away, inClass, studying }

class User {
  final String id;
  final String name;
  final String email;
  final String course;
  final String year;
  final String? profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  
  // Enhanced status and location fields
  final UserStatus status;
  final String? currentLocationId;
  final String? currentBuilding;
  final String? currentRoom;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;
  final String? statusMessage;
  
  // Friend relationships
  final List<String> friendIds;
  final List<String> pendingFriendRequests;
  final List<String> sentFriendRequests;
  
  // Society relationships
  final List<String> societyIds;
  
  // Privacy settings IDs (references to PrivacySettings)
  final String privacySettingsId;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.course,
    required this.year,
    required this.privacySettingsId,
    this.profileImageUrl,
    this.isOnline = false,
    this.lastSeen,
    this.status = UserStatus.offline,
    this.currentLocationId,
    this.currentBuilding,
    this.currentRoom,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.statusMessage,
    this.friendIds = const [],
    this.pendingFriendRequests = const [],
    this.sentFriendRequests = const [],
    this.societyIds = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      course: json['course'] as String,
      year: json['year'] as String,
      privacySettingsId: json['privacySettingsId'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'] as String) 
          : null,
      status: UserStatus.values.firstWhere(
        (e) => e.toString() == 'UserStatus.${json['status']}',
        orElse: () => UserStatus.offline,
      ),
      currentLocationId: json['currentLocationId'] as String?,
      currentBuilding: json['currentBuilding'] as String?,
      currentRoom: json['currentRoom'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      locationUpdatedAt: json['locationUpdatedAt'] != null 
          ? DateTime.parse(json['locationUpdatedAt'] as String) 
          : null,
      statusMessage: json['statusMessage'] as String?,
      friendIds: (json['friendIds'] as List<dynamic>?)?.cast<String>() ?? [],
      pendingFriendRequests: (json['pendingFriendRequests'] as List<dynamic>?)?.cast<String>() ?? [],
      sentFriendRequests: (json['sentFriendRequests'] as List<dynamic>?)?.cast<String>() ?? [],
      societyIds: (json['societyIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'course': course,
      'year': year,
      'privacySettingsId': privacySettingsId,
      'profileImageUrl': profileImageUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'status': status.toString().split('.').last,
      'currentLocationId': currentLocationId,
      'currentBuilding': currentBuilding,
      'currentRoom': currentRoom,
      'latitude': latitude,
      'longitude': longitude,
      'locationUpdatedAt': locationUpdatedAt?.toIso8601String(),
      'statusMessage': statusMessage,
      'friendIds': friendIds,
      'pendingFriendRequests': pendingFriendRequests,
      'sentFriendRequests': sentFriendRequests,
      'societyIds': societyIds,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? course,
    String? year,
    String? privacySettingsId,
    String? profileImageUrl,
    bool? isOnline,
    DateTime? lastSeen,
    UserStatus? status,
    String? currentLocationId,
    String? currentBuilding,
    String? currentRoom,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    String? statusMessage,
    List<String>? friendIds,
    List<String>? pendingFriendRequests,
    List<String>? sentFriendRequests,
    List<String>? societyIds,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      course: course ?? this.course,
      year: year ?? this.year,
      privacySettingsId: privacySettingsId ?? this.privacySettingsId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      currentBuilding: currentBuilding ?? this.currentBuilding,
      currentRoom: currentRoom ?? this.currentRoom,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      statusMessage: statusMessage ?? this.statusMessage,
      friendIds: friendIds ?? this.friendIds,
      pendingFriendRequests: pendingFriendRequests ?? this.pendingFriendRequests,
      sentFriendRequests: sentFriendRequests ?? this.sentFriendRequests,
      societyIds: societyIds ?? this.societyIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, course: $course, year: $year)';
  }
}
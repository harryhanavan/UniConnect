import 'dart:convert';
import 'package:flutter/services.dart';
import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/location.dart';
import '../../shared/models/privacy_settings.dart';
import '../../shared/models/friend_request.dart';

/// Loads demo data from JSON files in the assets folder
class DemoDataLoader {
  static const String _basePath = 'assets/demo_data';

  /// Load users from JSON file
  static Future<List<User>> loadUsers() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/users.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      final now = DateTime.now();
      
      return jsonList.map((jsonMap) {
        // Add dynamic date fields based on status
        final Map<String, dynamic> json = Map<String, dynamic>.from(jsonMap);
        
        // Set lastSeen based on status
        if (json['status'] == 'online') {
          // Online users don't need lastSeen
          json.remove('lastSeen');
        } else if (json['status'] == 'studying') {
          json['lastSeen'] = now.subtract(const Duration(minutes: 5)).toIso8601String();
        } else if (json['status'] == 'offline') {
          json['lastSeen'] = now.subtract(const Duration(hours: 2)).toIso8601String();
        } else if (json['status'] == 'away') {
          json['lastSeen'] = now.subtract(const Duration(minutes: 30)).toIso8601String();
        }
        
        // Set locationUpdatedAt if location is present
        if (json['currentLocationId'] != null) {
          if (json['status'] == 'online') {
            json['locationUpdatedAt'] = now.subtract(const Duration(minutes: 10)).toIso8601String();
          } else if (json['status'] == 'studying') {
            json['locationUpdatedAt'] = now.subtract(const Duration(minutes: 20)).toIso8601String();
          } else {
            json['locationUpdatedAt'] = now.subtract(const Duration(minutes: 35)).toIso8601String();
          }
        }
        
        return User.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error loading users: $e');
      return [];
    }
  }

  /// Load societies from JSON file
  static Future<List<Society>> loadSocieties() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/societies.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Society.fromJson(json)).toList();
    } catch (e) {
      print('Error loading societies: $e');
      return [];
    }
  }

  /// Load events from JSON file with relative date conversion
  static Future<List<Event>> loadEvents() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/events.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> eventsList = jsonData['events'];
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      return eventsList.map((json) {
        // Convert relative dates to actual DateTime
        final daysFromNow = json['daysFromNow'] ?? 0;
        final hoursFromStart = json['hoursFromStart'] ?? 0;
        final duration = json['duration'] ?? 1;
        final isAllDay = json['isAllDay'] ?? false;
        
        DateTime startTime;
        DateTime endTime;
        
        if (isAllDay) {
          startTime = today.add(Duration(days: daysFromNow));
          endTime = startTime;
        } else {
          startTime = today.add(Duration(
            days: daysFromNow,
            hours: hoursFromStart.toInt(),
            minutes: ((hoursFromStart % 1) * 60).toInt(),
          ));
          endTime = startTime.add(Duration(
            hours: duration.toInt(),
            minutes: ((duration % 1) * 60).toInt(),
          ));
        }
        
        // Convert type string to EventType enum
        EventType eventType;
        switch (json['type']) {
          case 'class':
            eventType = EventType.class_;
          case 'assignment':
            eventType = EventType.assignment;
          case 'society':
            eventType = EventType.society;
          case 'personal':
            eventType = EventType.personal;
          default:
            eventType = EventType.personal;
        }
        
        // Convert source string to EventSource enum
        EventSource eventSource;
        switch (json['source']) {
          case 'personal':
            eventSource = EventSource.personal;
          case 'friends':
            eventSource = EventSource.friends;
          case 'societies':
            eventSource = EventSource.societies;
          case 'shared':
            eventSource = EventSource.shared;
          default:
            eventSource = EventSource.personal;
        }
        
        return Event(
          id: json['id'],
          title: json['title'],
          description: json['description'],
          startTime: startTime,
          endTime: endTime,
          location: json['location'],
          type: eventType,
          source: eventSource,
          courseCode: json['courseCode'],
          societyId: json['societyId'],
          creatorId: json['creatorId'] ?? 'system',
          attendeeIds: (json['attendeeIds'] as List<dynamic>?)?.cast<String>() ?? [],
          isAllDay: isAllDay,
        );
      }).toList();
    } catch (e) {
      print('Error loading events: $e');
      return [];
    }
  }

  /// Load locations from JSON file
  static Future<List<Location>> loadLocations() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/locations.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      return jsonList.map((json) {
        // Convert type string to LocationType enum
        LocationType locationType;
        switch (json['type']) {
          case 'classroom':
            locationType = LocationType.classroom;
          case 'lab':
            locationType = LocationType.lab;
          case 'common':
            locationType = LocationType.common;
          case 'study':
            locationType = LocationType.study;
          default:
            locationType = LocationType.common;
        }
        
        return Location(
          id: json['id'],
          name: json['name'],
          building: json['building'],
          room: json['room'],
          floor: json['floor'],
          type: locationType,
          latitude: json['latitude'],
          longitude: json['longitude'],
          description: json['description'],
          isAccessible: json['isAccessible'] ?? true,
          capacity: json['capacity'],
          amenities: (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [],
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error loading locations: $e');
      return [];
    }
  }

  /// Load privacy settings from JSON file
  static Future<List<PrivacySettings>> loadPrivacySettings() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/privacy_settings.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      return jsonList.map((json) {
        // Convert sharing level strings to enums
        LocationSharingLevel locationSharing;
        switch (json['locationSharing']) {
          case 'nobody':
            locationSharing = LocationSharingLevel.nobody;
          case 'friends':
            locationSharing = LocationSharingLevel.friends;
          case 'everyone':
            locationSharing = LocationSharingLevel.everyone;
          default:
            locationSharing = LocationSharingLevel.friends;
        }
        
        TimetableSharingLevel timetableSharing;
        switch (json['timetableSharing']) {
          case 'nobody':
            timetableSharing = TimetableSharingLevel.nobody;
          case 'friends':
            timetableSharing = TimetableSharingLevel.friends;
          case 'everyone':
            timetableSharing = TimetableSharingLevel.everyone;
          default:
            timetableSharing = TimetableSharingLevel.friends;
        }
        
        OnlineStatusVisibility onlineStatus;
        switch (json['onlineStatusVisibility']) {
          case 'nobody':
            onlineStatus = OnlineStatusVisibility.nobody;
          case 'friends':
            onlineStatus = OnlineStatusVisibility.friends;
          case 'everyone':
            onlineStatus = OnlineStatusVisibility.everyone;
          default:
            onlineStatus = OnlineStatusVisibility.friends;
        }
        
        // Convert per-friend timetable sharing
        final perFriendSharing = <String, TimetableSharingLevel>{};
        if (json['perFriendTimetableSharing'] != null) {
          (json['perFriendTimetableSharing'] as Map<String, dynamic>).forEach((key, value) {
            TimetableSharingLevel level;
            switch (value) {
              case 'nobody':
                level = TimetableSharingLevel.nobody;
              case 'friends':
                level = TimetableSharingLevel.friends;
              case 'everyone':
                level = TimetableSharingLevel.everyone;
              default:
                level = TimetableSharingLevel.friends;
            }
            perFriendSharing[key] = level;
          });
        }
        
        return PrivacySettings(
          id: json['id'],
          userId: json['userId'],
          createdAt: DateTime.now(),
          locationSharing: locationSharing,
          shareExactLocation: json['shareExactLocation'] ?? false,
          shareBuildingOnly: json['shareBuildingOnly'] ?? true,
          timetableSharing: timetableSharing,
          shareFreeTimes: json['shareFreeTimes'] ?? true,
          shareClassDetails: json['shareClassDetails'] ?? false,
          onlineStatusVisibility: onlineStatus,
          showLastSeen: json['showLastSeen'] ?? true,
          perFriendTimetableSharing: perFriendSharing,
        );
      }).toList();
    } catch (e) {
      print('Error loading privacy settings: $e');
      return [];
    }
  }

  /// Load friend requests from JSON file with relative date conversion
  static Future<List<FriendRequest>> loadFriendRequests() async {
    try {
      final jsonString = await rootBundle.loadString('$_basePath/friend_requests.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> requestsList = jsonData['requests'];
      
      final now = DateTime.now();
      
      return requestsList.map((json) {
        // Convert relative dates to actual DateTime
        final daysAgo = json['daysAgo'] ?? 0;
        final respondedDaysAgo = json['respondedDaysAgo'];
        
        final createdAt = now.subtract(Duration(days: daysAgo));
        final respondedAt = respondedDaysAgo != null 
            ? now.subtract(Duration(days: respondedDaysAgo))
            : null;
        
        // Convert status string to enum
        FriendRequestStatus status;
        switch (json['status']) {
          case 'pending':
            status = FriendRequestStatus.pending;
          case 'accepted':
            status = FriendRequestStatus.accepted;
          case 'declined':
            status = FriendRequestStatus.declined;
          case 'cancelled':
            status = FriendRequestStatus.cancelled;
          default:
            status = FriendRequestStatus.pending;
        }
        
        return FriendRequest(
          id: json['id'],
          senderId: json['senderId'],
          receiverId: json['receiverId'],
          status: status,
          createdAt: createdAt,
          respondedAt: respondedAt,
          message: json['message'],
        );
      }).toList();
    } catch (e) {
      print('Error loading friend requests: $e');
      return [];
    }
  }

  /// Validate data relationships
  static Future<List<String>> validateDataIntegrity({
    required List<User> users,
    required List<PrivacySettings> privacySettings,
    required List<FriendRequest> friendRequests,
    required List<Event> events,
    required List<Society> societies,
    required List<Location> locations,
  }) async {
    final warnings = <String>[];
    
    // Check bidirectional friend relationships
    for (final user in users) {
      for (final friendId in user.friendIds) {
        final friend = users.firstWhere(
          (u) => u.id == friendId,
          orElse: () => User(
            id: '', name: '', email: '', course: '', year: '', 
            privacySettingsId: '',
          ),
        );
        if (friend.id.isEmpty) {
          warnings.add('User ${user.id} has friend $friendId who doesn\'t exist');
        } else if (!friend.friendIds.contains(user.id)) {
          warnings.add('Friend relationship not bidirectional: ${user.id} -> $friendId');
        }
      }
      
      // Check privacy settings exist
      final hasPrivacy = privacySettings.any((p) => p.userId == user.id);
      if (!hasPrivacy) {
        warnings.add('User ${user.id} has no privacy settings');
      }
    }
    
    // Check event references
    for (final event in events) {
      if (event.societyId != null) {
        final societyExists = societies.any((s) => s.id == event.societyId);
        if (!societyExists) {
          warnings.add('Event ${event.id} references non-existent society ${event.societyId}');
        }
      }
      
      for (final attendeeId in event.attendeeIds) {
        final userExists = users.any((u) => u.id == attendeeId);
        if (!userExists) {
          warnings.add('Event ${event.id} has non-existent attendee $attendeeId');
        }
      }
    }
    
    // Check society admin references
    for (final society in societies) {
      for (final adminId in society.adminIds) {
        final userExists = users.any((u) => u.id == adminId);
        if (!userExists) {
          warnings.add('Society ${society.id} has non-existent admin $adminId');
        }
      }
    }
    
    return warnings;
  }
}
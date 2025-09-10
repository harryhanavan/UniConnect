import 'dart:math';
import '../../shared/models/user.dart';
import '../../shared/models/location.dart';
import '../demo_data/demo_data_manager.dart';
import 'friendship_service.dart';
import 'loading_state_manager.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  final FriendshipService _friendshipService = FriendshipService();
  final LoadingStateManager _loadingManager = LoadingStateManager();
  bool _isInitialized = false;
  
  // Ensure data is loaded before using any methods
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _demoData.users; // This triggers async initialization
      _isInitialized = true;
    }
  }

  // Update user's current location with automatic status detection
  Future<bool> updateUserLocation({
    required String userId,
    required String locationId,
    String? building,
    String? room,
    double? latitude,
    double? longitude,
    String? statusMessage,
  }) async {
    return await _loadingManager.withLoading(LoadingOperations.updatingLocation, () async {
      await _ensureInitialized();
      await Future.delayed(const Duration(milliseconds: 300));

    // Note: Location updates temporarily disabled in JSON-based demo data
    // In a real app, this would update the database
    print('Location update for $userId to $locationId. Data updates not yet supported in JSON-based demo data.');
    
    final location = _demoData.getLocationById(locationId);
    final now = DateTime.now();

    // Auto-detect status based on location type
    UserStatus detectedStatus = UserStatus.online;
    String? autoStatusMessage = statusMessage;

    if (location != null) {
      switch (location.type) {
        case LocationType.classroom:
        case LocationType.lab:
          detectedStatus = UserStatus.inClass;
          autoStatusMessage ??= 'In ${location.name}';
          break;
        case LocationType.library:
        case LocationType.study:
          detectedStatus = UserStatus.studying;
          autoStatusMessage ??= 'Studying at ${location.name}';
          break;
        case LocationType.cafeteria:
        case LocationType.common:
          detectedStatus = UserStatus.online;
          autoStatusMessage ??= 'At ${location.name}';
          break;
        default:
          detectedStatus = UserStatus.online;
      }
    }

    // Note: User location updates temporarily disabled in JSON-based demo data
    // In a real app, this would update the user's location in the database
    print('Location update processed: User $userId would be updated with status $detectedStatus at ${location?.name}');

    // Notify nearby friends if location sharing is enabled
    await _notifyNearbyFriends(userId, locationId);

    // Trigger proximity suggestions
    await _updateProximitySuggestions(userId);

      return true;
    });
  }

  // Get visible friends on campus with their locations
  Map<String, dynamic> getFriendsOnCampusMap(String userId) {
    final user = _demoData.getUserById(userId);
    if (user == null) return {};

    final visibleFriends = <User>[];
    final friendLocations = <String, Location>{};
    final friendDistances = <String, double>{};

    for (final friendId in user.friendIds) {
      final friend = _demoData.getUserById(friendId);
      if (friend == null || !friend.isOnline || friend.currentLocationId == null) continue;

      // Check if user can see this friend's location
      if (!_friendshipService.canViewLocation(userId, friendId)) continue;

      // Check if location was updated recently (within last 2 hours)
      if (friend.locationUpdatedAt != null &&
          DateTime.now().difference(friend.locationUpdatedAt!).inHours > 2) {
        continue;
      }

      visibleFriends.add(friend);

      // Get friend's location details
      final location = _demoData.getLocationById(friend.currentLocationId!);
      if (location != null) {
        friendLocations[friendId] = location;

        // Calculate distance if user also has location
        if (user.latitude != null && user.longitude != null &&
            friend.latitude != null && friend.longitude != null) {
          final distance = calculateDistance(
            user.latitude!, user.longitude!,
            friend.latitude!, friend.longitude!,
          );
          friendDistances[friendId] = distance;
        }
      }
    }

    // Sort friends by distance (closest first)
    visibleFriends.sort((a, b) {
      final distanceA = friendDistances[a.id] ?? double.infinity;
      final distanceB = friendDistances[b.id] ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });

    return {
      'friends': visibleFriends,
      'locations': friendLocations,
      'distances': friendDistances,
      'userLocation': user.currentLocationId != null 
          ? _demoData.getLocationById(user.currentLocationId!) 
          : null,
    };
  }

  // Find friends within walking distance
  List<Map<String, dynamic>> findNearbyFriends(String userId, {double maxDistance = 500}) {
    final user = _demoData.getUserById(userId);
    if (user == null || user.latitude == null || user.longitude == null) return [];

    final nearbyFriends = <Map<String, dynamic>>[];

    for (final friendId in user.friendIds) {
      final friend = _demoData.getUserById(friendId);
      if (friend == null || !friend.isOnline || 
          friend.latitude == null || friend.longitude == null) {
        continue;
      }

      if (!_friendshipService.canViewLocation(userId, friendId)) continue;

      final distance = calculateDistance(
        user.latitude!, user.longitude!,
        friend.latitude!, friend.longitude!,
      );

      if (distance <= maxDistance) {
        final location = friend.currentLocationId != null 
            ? _demoData.getLocationById(friend.currentLocationId!) 
            : null;

        nearbyFriends.add({
          'friend': friend,
          'distance': distance,
          'location': location,
          'walkingTime': _calculateWalkingTime(distance),
        });
      }
    }

    // Sort by distance
    nearbyFriends.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return nearbyFriends;
  }

  // Get meetup suggestions based on friend locations and free time
  List<Map<String, dynamic>> getMeetupSuggestions(String userId) {
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    final suggestions = <Map<String, dynamic>>[];
    final nearbyFriends = findNearbyFriends(userId, maxDistance: 1000); // 1km radius

    for (final nearbyFriend in nearbyFriends.take(3)) { // Top 3 closest friends
      final friend = nearbyFriend['friend'] as User;
      final distance = nearbyFriend['distance'] as double;
      final friendLocation = nearbyFriend['location'] as Location?;

      // Find common free time slots
      final commonTimes = _friendshipService.findCommonFreeTime(userId, [friend.id]);
      
      if (commonTimes.isNotEmpty) {
        // Suggest meeting points between user and friend locations
        final meetingSpots = _suggestMeetingSpots(user, friend);

        suggestions.add({
          'friend': friend,
          'distance': distance,
          'commonTimes': commonTimes,
          'meetingSpots': meetingSpots,
          'friendLocation': friendLocation,
          'suggestion': _generateMeetupSuggestion(friend, distance, commonTimes.first),
        });
      }
    }

    return suggestions;
  }

  // Track user movement and update status automatically
  Future<void> startLocationTracking(String userId) async {
    // Simulate location tracking - in real app would use GPS/WiFi positioning
    final user = _demoData.getUserById(userId);
    if (user == null) return;

    // Simulate movement between locations based on schedule
    final currentEvents = _demoData.getEventsByDateRange(
      DateTime.now(),
      DateTime.now().add(const Duration(hours: 2)),
    ).where((event) => 
        event.creatorId == userId || event.attendeeIds.contains(userId)
    ).toList();

    if (currentEvents.isNotEmpty) {
      final nextEvent = currentEvents.first;
      
      // Try to find matching location for the event
      final eventLocation = _findLocationByName(nextEvent.location);
      if (eventLocation != null) {
        await updateUserLocation(
          userId: userId,
          locationId: eventLocation.id,
          statusMessage: 'Heading to ${nextEvent.title}',
        );
      }
    }
  }

  // Get location-based study group suggestions
  List<Map<String, dynamic>> getStudyGroupSuggestions(String userId) {
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    final suggestions = <Map<String, dynamic>>[];
    final studyLocations = _demoData.locationsSync
        .where((loc) => loc.type == LocationType.library || loc.type == LocationType.study)
        .toList();

    for (final location in studyLocations) {
      final friendsAtLocation = <User>[];
      
      for (final friendId in user.friendIds) {
        final friend = _demoData.getUserById(friendId);
        if (friend == null || !friend.isOnline) continue;

        if (_friendshipService.canViewLocation(userId, friendId) &&
            friend.currentLocationId == location.id &&
            friend.status == UserStatus.studying) {
          friendsAtLocation.add(friend);
        }
      }

      if (friendsAtLocation.isNotEmpty) {
        suggestions.add({
          'location': location,
          'friends': friendsAtLocation,
          'suggestion': 'Join ${friendsAtLocation.length} friends studying at ${location.name}',
        });
      }
    }

    return suggestions;
  }

  // Get campus activity heatmap
  Map<String, int> getCampusActivityHeatmap(String userId) {
    final user = _demoData.getUserById(userId);
    if (user == null) return {};

    final activityMap = <String, int>{};

    // Count friends at each location
    for (final friendId in user.friendIds) {
      final friend = _demoData.getUserById(friendId);
      if (friend == null || !friend.isOnline || friend.currentLocationId == null) continue;

      if (_friendshipService.canViewLocation(userId, friendId)) {
        final locationId = friend.currentLocationId!;
        activityMap[locationId] = (activityMap[locationId] ?? 0) + 1;
      }
    }

    return activityMap;
  }

  // Public distance calculation method
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters

    final lat1Rad = lat1 * (pi / 180);
    final lat2Rad = lat2 * (pi / 180);
    final deltaLat = (lat2 - lat1) * (pi / 180);
    final deltaLng = (lon2 - lon1) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  int _calculateWalkingTime(double distanceInMeters) {
    // Assume average walking speed of 5 km/h = 1.39 m/s
    return (distanceInMeters / 1.39).round();
  }

  List<Location> _suggestMeetingSpots(User user1, User user2) {
    final user1Location = user1.currentLocationId != null 
        ? _demoData.getLocationById(user1.currentLocationId!) 
        : null;
    final user2Location = user2.currentLocationId != null 
        ? _demoData.getLocationById(user2.currentLocationId!) 
        : null;

    if (user1Location == null || user2Location == null) {
      // Default meeting spots
      return _demoData.locationsSync
          .where((loc) => loc.type == LocationType.cafeteria || loc.type == LocationType.common)
          .take(3)
          .toList();
    }

    // Find locations between the two users
    final midpointLat = (user1Location.latitude + user2Location.latitude) / 2;
    final midpointLon = (user1Location.longitude + user2Location.longitude) / 2;

    final meetingSpots = _demoData.locationsSync
        .where((loc) => loc.type == LocationType.cafeteria || 
                       loc.type == LocationType.common ||
                       loc.type == LocationType.library)
        .toList();

    // Sort by proximity to midpoint
    meetingSpots.sort((a, b) {
      final distanceA = calculateDistance(midpointLat, midpointLon, a.latitude, a.longitude);
      final distanceB = calculateDistance(midpointLat, midpointLon, b.latitude, b.longitude);
      return distanceA.compareTo(distanceB);
    });

    return meetingSpots.take(3).toList();
  }

  String _generateMeetupSuggestion(User friend, double distance, Map<String, dynamic> commonTime) {
    final walkingTime = _calculateWalkingTime(distance);
    final timeSlot = commonTime['suggestion'] as String;
    
    if (distance < 100) {
      return 'Meet ${friend.name} for $timeSlot - they\'re very close!';
    } else if (distance < 500) {
      return 'Meet ${friend.name} for $timeSlot - ${walkingTime}s walk';
    } else {
      return 'Meet ${friend.name} for $timeSlot - ${(distance/1000).toStringAsFixed(1)}km away';
    }
  }

  Location? _findLocationByName(String locationName) {
    // Simple location matching - in real app would use fuzzy matching
    return _demoData.locationsSync.firstWhere(
      (location) => locationName.contains(location.building) || locationName.contains(location.name),
      orElse: () => _demoData.locationsSync.first, // fallback
    );
  }

  Future<void> _notifyNearbyFriends(String userId, String locationId) async {
    // Find friends within 200m and notify them
    final nearbyFriends = findNearbyFriends(userId, maxDistance: 200);
    
    for (final nearby in nearbyFriends) {
      // In real app, would send push notification
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _updateProximitySuggestions(String userId) async {
    // Update proximity-based suggestions
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
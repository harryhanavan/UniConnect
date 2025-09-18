import '../../shared/models/user.dart';
import '../../shared/models/friend_request.dart';
import '../../shared/models/privacy_settings.dart';
import '../demo_data/demo_data_manager.dart';

class FriendshipService {
  static final FriendshipService _instance = FriendshipService._internal();
  factory FriendshipService() => _instance;
  FriendshipService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  bool _isInitialized = false;
  
  // Ensure data is loaded before using any methods
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _demoData.users; // This triggers async initialization
      _isInitialized = true;
    }
  }

  // Send friend request with automatic timetable sharing setup
  Future<FriendRequest> sendFriendRequest(String senderId, String receiverId, {String? message}) async {
    await _ensureInitialized();
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final newRequest = FriendRequest(
      id: 'freq_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      receiverId: receiverId,
      createdAt: DateTime.now(),
      message: message,
    );

    // Add the request to demo data
    final success = _demoData.addFriendRequest(newRequest);
    if (!success) {
      throw Exception('Failed to send friend request - request already exists or users are already friends');
    }

    return newRequest;
  }

  // Accept friend request with immediate cross-feature updates
  Future<bool> acceptFriendRequest(String requestId) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 500));

    // Get the request before accepting to get user IDs
    final friendRequests = _demoData.friendRequestsSync;
    final request = friendRequests.firstWhere((r) => r.id == requestId, orElse: () => throw Exception('Request not found'));

    // Accept the friend request and update friend lists
    final success = _demoData.acceptFriendRequest(requestId);
    if (!success) {
      throw Exception('Failed to accept friend request');
    }

    // Auto-setup default timetable sharing
    await _setupDefaultTimetableSharing(request.senderId, request.receiverId);

    // Trigger calendar refresh for both users (simulate cross-feature update)
    await _refreshUserCalendars([request.senderId, request.receiverId]);

    return true;
  }

  // Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 300));

    // Decline the friend request
    final success = _demoData.declineFriendRequest(requestId);
    if (!success) {
      throw Exception('Failed to decline friend request');
    }

    return true;
  }

  // Cancel friend request (by sender)
  Future<bool> cancelFriendRequest(String requestId) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 300));

    // Cancel the friend request
    final success = _demoData.cancelFriendRequest(requestId);
    if (!success) {
      throw Exception('Failed to cancel friend request');
    }

    return true;
  }

  // Remove friend (affects all features)
  Future<bool> removeFriend(String userId1, String userId2) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 500));

    // Remove the friend relationship
    final success = _demoData.removeFriend(userId1, userId2);
    if (!success) {
      throw Exception('Failed to remove friend - users are not friends');
    }

    return true;
  }

  // Get mutual friends between two users (async version)
  Future<List<User>> getMutualFriends(String userId1, String userId2) async {
    await _ensureInitialized();
    
    final user1 = _demoData.getUserById(userId1);
    final user2 = _demoData.getUserById(userId2);
    
    if (user1 == null || user2 == null) return [];

    final mutualFriendIds = user1.friendIds
        .where((friendId) => user2.friendIds.contains(friendId))
        .toList();

    return mutualFriendIds
        .map((id) => _demoData.getUserById(id))
        .where((user) => user != null)
        .cast<User>()
        .toList();
  }
  
  // Sync version for backward compatibility
  List<User> getMutualFriendsSync(String userId1, String userId2) {
    if (!_isInitialized) {
      throw StateError('FriendshipService not initialized. Call await getMutualFriends first.');
    }
    
    final user1 = _demoData.getUserById(userId1);
    final user2 = _demoData.getUserById(userId2);
    
    if (user1 == null || user2 == null) return [];

    final mutualFriendIds = user1.friendIds
        .where((friendId) => user2.friendIds.contains(friendId))
        .toList();

    return mutualFriendIds
        .map((id) => _demoData.getUserById(id))
        .where((user) => user != null)
        .cast<User>()
        .toList();
  }

  // Get friend suggestions based on mutual connections and shared societies
  Future<List<User>> getFriendSuggestions(String userId) async {
    await _ensureInitialized();
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    final currentFriends = user.friendIds.toSet();
    final pendingRequestIds = user.pendingFriendRequests.toSet();
    final sentRequestIds = user.sentFriendRequests.toSet();

    // Get users from joined societies
    final joinedSocieties = _demoData.joinedSocieties;
    final societyMembers = <String>{};
    final users = _demoData.usersSync;
    
    for (final _ in joinedSocieties) {
      // In a real app, society would have a members list
      // For demo, we'll use a simple heuristic based on course similarity
      for (final otherUser in users) {
        if (otherUser.id != userId && 
            otherUser.course.contains(user.course.split(' ').last)) {
          societyMembers.add(otherUser.id);
        }
      }
    }

    // Get mutual friend connections
    final mutualConnections = <String>{};
    for (final friendId in currentFriends) {
      final friend = _demoData.getUserById(friendId);
      if (friend != null) {
        mutualConnections.addAll(friend.friendIds);
      }
    }

    // Combine suggestions and filter out existing relationships
    final suggestions = <String>{};
    suggestions.addAll(societyMembers);
    suggestions.addAll(mutualConnections);
    
    suggestions.removeWhere((id) => 
      id == userId ||
      currentFriends.contains(id) ||
      pendingRequestIds.contains(id) ||
      sentRequestIds.contains(id)
    );

    return suggestions
        .map((id) => _demoData.getUserById(id))
        .where((user) => user != null)
        .cast<User>()
        .take(5) // Limit to top 5 suggestions
        .toList();
  }
  
  // Sync version for backward compatibility
  List<User> getFriendSuggestionsSync(String userId) {
    if (!_isInitialized) {
      throw StateError('FriendshipService not initialized. Call await getFriendSuggestions first.');
    }
    
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    final currentFriends = user.friendIds.toSet();
    final pendingRequestIds = user.pendingFriendRequests.toSet();
    final sentRequestIds = user.sentFriendRequests.toSet();

    // Get users from joined societies
    final joinedSocieties = _demoData.joinedSocieties;
    final societyMembers = <String>{};
    final users = _demoData.usersSync;
    
    for (final _ in joinedSocieties) {
      // In a real app, society would have a members list
      // For demo, we'll use a simple heuristic based on course similarity
      for (final otherUser in users) {
        if (otherUser.id != userId && 
            otherUser.course.contains(user.course.split(' ').last)) {
          societyMembers.add(otherUser.id);
        }
      }
    }

    // Get mutual friend connections
    final mutualConnections = <String>{};
    for (final friendId in currentFriends) {
      final friend = _demoData.getUserById(friendId);
      if (friend != null) {
        mutualConnections.addAll(friend.friendIds);
      }
    }

    // Combine suggestions and filter out existing relationships
    final suggestions = <String>{};
    suggestions.addAll(societyMembers);
    suggestions.addAll(mutualConnections);
    
    suggestions.removeWhere((id) => 
      id == userId ||
      currentFriends.contains(id) ||
      pendingRequestIds.contains(id) ||
      sentRequestIds.contains(id)
    );

    return suggestions
        .map((id) => _demoData.getUserById(id))
        .where((user) => user != null)
        .cast<User>()
        .take(5) // Limit to top 5 suggestions
        .toList();
  }

  // Check if two users can see each other's timetable
  bool canViewTimetable(String viewerId, String targetUserId) {
    if (!_demoData.areFriends(viewerId, targetUserId)) return false;

    final targetPrivacy = _demoData.getPrivacySettingsForUser(targetUserId);
    return targetPrivacy?.canShareTimetableWith(viewerId) ?? false;
  }

  // Check if two users can see each other's location
  bool canViewLocation(String viewerId, String targetUserId) {
    if (!_demoData.areFriends(viewerId, targetUserId)) return false;

    final targetPrivacy = _demoData.getPrivacySettingsForUser(targetUserId);
    return targetPrivacy?.canShareLocationWith(viewerId) ?? false;
  }

  // Get all friends for a user
  List<User> getUserFriends(String userId) {
    return _demoData.getFriendsForUser(userId);
  }

  // Get friends currently on campus
  List<User> getFriendsOnCampus(String userId) {
    final user = _demoData.getUserById(userId);
    if (user == null) return [];

    final friends = _demoData.getFriendsForUser(userId);
    final now = DateTime.now();
    
    return friends.where((friend) {
      // Check if friend is online and has recent location
      if (!friend.isOnline || friend.currentLocationId == null) return false;
      
      // Check if location was updated recently (within last 2 hours)
      if (friend.locationUpdatedAt != null && 
          now.difference(friend.locationUpdatedAt!).inHours > 2) {
        return false;
      }

      // Check if user can see this friend's location
      return canViewLocation(userId, friend.id);
    }).toList();
  }

  // Find common free time between friends (supports multiple users)
  List<Map<String, dynamic>> findCommonFreeTime(String userId, List<String> friendIds, {DateTime? date}) {
    // Check if we can view all friends' timetables
    for (final friendId in friendIds) {
      if (!canViewTimetable(userId, friendId)) {
        return [];
      }
    }

    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    // Get all user IDs (including the main user)
    final allUserIds = [userId, ...friendIds];
    final allEvents = <String, List<dynamic>>{};
    
    // Get events for all users
    for (final id in allUserIds) {
      final userEvents = _demoData.getEventsByDateRange(startOfDay, startOfDay.add(const Duration(days: 1)))
          .where((event) => event.creatorId == id || event.attendeeIds.contains(id))
          .toList();
      allEvents[id] = userEvents;
    }

    return _findCommonFreeSlotsForUsers(allEvents, startOfDay);
  }

  // Legacy method for backward compatibility
  List<Map<String, dynamic>> findCommonFreeTimeBetweenTwo(String userId1, String userId2, {DateTime? date}) {
    if (!canViewTimetable(userId1, userId2) || !canViewTimetable(userId2, userId1)) {
      return [];
    }

    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get events for both users for the target date
    final user1Events = _demoData.getEventsByDateRange(startOfDay, endOfDay)
        .where((event) => event.creatorId == userId1 || 
                        event.attendeeIds.contains(userId1))
        .toList();

    final user2Events = _demoData.getEventsByDateRange(startOfDay, endOfDay)
        .where((event) => event.creatorId == userId2 || 
                        event.attendeeIds.contains(userId2))
        .toList();

    // Find gaps in schedules (simplified algorithm)
    final commonFreeSlots = <Map<String, dynamic>>[];
    
    // Check common lunch time (12:00-13:00)
    final lunchTime = startOfDay.add(const Duration(hours: 12));
    final hasUser1LunchConflict = user1Events.any((event) => 
        event.startTime.isBefore(lunchTime.add(const Duration(hours: 1))) &&
        event.endTime.isAfter(lunchTime));
    final hasUser2LunchConflict = user2Events.any((event) => 
        event.startTime.isBefore(lunchTime.add(const Duration(hours: 1))) &&
        event.endTime.isAfter(lunchTime));

    if (!hasUser1LunchConflict && !hasUser2LunchConflict) {
      commonFreeSlots.add({
        'startTime': lunchTime,
        'endTime': lunchTime.add(const Duration(hours: 1)),
        'suggestion': 'Lunch break',
      });
    }

    // Check common study time (15:00-17:00)
    final studyTime = startOfDay.add(const Duration(hours: 15));
    final hasUser1StudyConflict = user1Events.any((event) => 
        event.startTime.isBefore(studyTime.add(const Duration(hours: 2))) &&
        event.endTime.isAfter(studyTime));
    final hasUser2StudyConflict = user2Events.any((event) => 
        event.startTime.isBefore(studyTime.add(const Duration(hours: 2))) &&
        event.endTime.isAfter(studyTime));

    if (!hasUser1StudyConflict && !hasUser2StudyConflict) {
      commonFreeSlots.add({
        'startTime': studyTime,
        'endTime': studyTime.add(const Duration(hours: 2)),
        'suggestion': 'Study session',
      });
    }

    return commonFreeSlots;
  }

  // Helper method to find common free slots for multiple users
  List<Map<String, dynamic>> _findCommonFreeSlotsForUsers(Map<String, List<dynamic>> allEvents, DateTime startOfDay) {
    final commonFreeSlots = <Map<String, dynamic>>[];
    
    // Check common lunch time (12:00-13:00)
    final lunchTime = startOfDay.add(const Duration(hours: 12));
    bool hasLunchConflict = false;
    
    for (final events in allEvents.values) {
      if (events.any((event) => 
          event.startTime.isBefore(lunchTime.add(const Duration(hours: 1))) &&
          event.endTime.isAfter(lunchTime))) {
        hasLunchConflict = true;
        break;
      }
    }
    
    if (!hasLunchConflict) {
      commonFreeSlots.add({
        'startTime': lunchTime,
        'endTime': lunchTime.add(const Duration(hours: 1)),
        'suggestion': 'Lunch break',
      });
    }

    // Check common study time (15:00-17:00)
    final studyTime = startOfDay.add(const Duration(hours: 15));
    bool hasStudyConflict = false;
    
    for (final events in allEvents.values) {
      if (events.any((event) => 
          event.startTime.isBefore(studyTime.add(const Duration(hours: 2))) &&
          event.endTime.isAfter(studyTime))) {
        hasStudyConflict = true;
        break;
      }
    }
    
    if (!hasStudyConflict) {
      commonFreeSlots.add({
        'startTime': studyTime,
        'endTime': studyTime.add(const Duration(hours: 2)),
        'suggestion': 'Study session',
      });
    }

    return commonFreeSlots;
  }

  // Private helper methods
  void _addFriendRelationship(String userId1, String userId2) {
    // Note: Friend relationship updates temporarily disabled in JSON-based demo data
    // In a real app, this would update the database with bidirectional friend relationships
    // Friend relationship would be added: $userId1 <-> $userId2
  }

  void _removeFriendRelationship(String userId1, String userId2) {
    // Note: Friend relationship removal temporarily disabled in JSON-based demo data
    // In a real app, this would update the database with bidirectional friend relationship removal
    // Friend relationship would be removed: $userId1 <-> $userId2
  }

  void _removePendingRequests(String senderId, String receiverId) {
    // Note: Pending request removal temporarily disabled in JSON-based demo data
    // In a real app, this would update the database to remove request tracking
    // Pending requests would be removed between: $senderId <-> $receiverId
  }

  Future<void> _setupDefaultTimetableSharing(String userId1, String userId2) async {
    // Note: Privacy settings updates temporarily disabled in JSON-based demo data
    // In a real app, this would update the database with default timetable sharing between friends
    // Default timetable sharing would be enabled between: $userId1 <-> $userId2
  }

  void _removePrivacyExceptions(String userId1, String userId2) {
    // Remove friend-specific privacy settings
    final privacy1Index = _demoData.privacySettingsSync.indexWhere((p) => p.userId == userId1);
    if (privacy1Index != -1) {
      final updatedPrivacy1 = _demoData.privacySettingsSync[privacy1Index].removeFriendSettings(userId2);
      _demoData.privacySettingsSync[privacy1Index] = updatedPrivacy1;
    }

    final privacy2Index = _demoData.privacySettingsSync.indexWhere((p) => p.userId == userId2);
    if (privacy2Index != -1) {
      final updatedPrivacy2 = _demoData.privacySettingsSync[privacy2Index].removeFriendSettings(userId1);
      _demoData.privacySettingsSync[privacy2Index] = updatedPrivacy2;
    }
  }

  Future<void> _refreshUserCalendars(List<String> userIds) async {
    // Simulate calendar service refresh
    // In a real app, this would trigger calendar updates for affected users
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _refreshUserMaps(List<String> userIds) async {
    // Simulate map service refresh
    // In a real app, this would update friend visibility on maps
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _removeSharedCalendarEvents(String userId1, String userId2) async {
    // In a real app, this would remove shared calendar events between unfriended users
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
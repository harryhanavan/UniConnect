import 'package:flutter/foundation.dart';
import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/friend_request.dart';
import '../../shared/models/location.dart';
import '../../shared/models/privacy_settings.dart';
import 'demo_data_loader.dart';

/// Enhanced DemoDataManager supporting both legacy and v2 events
/// Provides backward compatibility while enabling new Phase 2/3 features
class DemoDataManager {
  static DemoDataManager? _instance;
  static DemoDataManager get instance => _instance ??= DemoDataManager._();
  DemoDataManager._();

  // Enhanced notifier for society membership changes with more granular information
  final ValueNotifier<Map<String, dynamic>> _societyMembershipNotifier = ValueNotifier<Map<String, dynamic>>({});
  ValueNotifier<Map<String, dynamic>> get societyMembershipNotifier => _societyMembershipNotifier;

  // Legacy support - simple counter for backwards compatibility
  final ValueNotifier<int> _societyMembershipCounter = ValueNotifier<int>(0);
  ValueNotifier<int> get societyMembershipCounter => _societyMembershipCounter;

  // Current logged in user - cached for performance
  User? _currentUser;
  User get currentUser {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }
    // Always return the updated cached user if available
    // Otherwise get from users list (first user is current user)
    if (_currentUser != null) {
      return _currentUser!;
    }
    _currentUser = usersSync.first;
    return _currentUser!;
  }
  
  Future<User> get currentUserAsync async {
    await _initializeData();
    return _currentUser ??= usersSync.first;
  }
  
  // Lazy-loaded data collections
  List<PrivacySettings>? _privacySettings;
  List<Location>? _locations;
  List<FriendRequest>? _friendRequests;
  List<User>? _users;
  List<Event>? _events; // Legacy events
  List<EventV2>? _eventsV2; // Enhanced events
  List<Society>? _societies;
  
  // Flag to track if data is loaded from JSON
  bool _isInitialized = false;
  bool _useV2Events = true; // Prefer v2 events when available

  // Initialize all data from JSON files
  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    _users = await DemoDataLoader.loadUsers();
    _societies = await DemoDataLoader.loadSocieties();
    _locations = await DemoDataLoader.loadLocations();
    _privacySettings = await DemoDataLoader.loadPrivacySettings();
    _friendRequests = await DemoDataLoader.loadFriendRequests();
    
    // Load enhanced events from single events.json file
    _eventsV2 = await DemoDataLoader.loadEnhancedEvents();
    _events = _eventsV2!.map((e) => e.toLegacyEvent()).toList();
    print('Loaded ${_eventsV2!.length} enhanced events successfully');
    
    // Validate data integrity
    final warnings = await DemoDataLoader.validateDataIntegrity(
      users: _users!,
      privacySettings: _privacySettings!,
      friendRequests: _friendRequests!,
      events: _events!,
      societies: _societies!,
      locations: _locations!,
    );
    
    if (warnings.isNotEmpty) {
      print('Demo data integrity warnings:');
      for (final warning in warnings) {
        print('  - $warning');
      }
    }

    _isInitialized = true;

    // Restore runtime membership changes after loading from JSON
    _restoreRuntimeMemberships();
  }

  // Restore runtime membership changes after data reload
  void _restoreRuntimeMemberships() {
    if (_users == null || _societies == null) return;

    // Process each user's runtime changes
    for (final userId in {..._runtimeJoinedSocieties.keys, ..._runtimeLeftSocieties.keys}) {
      final userIndex = _users!.indexWhere((u) => u.id == userId);
      if (userIndex == -1) continue;

      final user = _users![userIndex];
      final currentSocieties = Set<String>.from(user.societyIds);

      // Add joined societies
      if (_runtimeJoinedSocieties.containsKey(userId)) {
        currentSocieties.addAll(_runtimeJoinedSocieties[userId]!);
      }

      // Remove left societies
      if (_runtimeLeftSocieties.containsKey(userId)) {
        currentSocieties.removeAll(_runtimeLeftSocieties[userId]!);
      }

      // Update user with new society list
      _users![userIndex] = user.copyWith(societyIds: currentSocieties.toList());

      // Update current user reference if needed
      if (userId == _currentUser?.id || userId == _users!.first.id) {
        _currentUser = _users![userIndex];
      }
    }

    // Update society member lists based on runtime changes
    for (final societyId in _societies!.map((s) => s.id)) {
      final societyIndex = _societies!.indexWhere((s) => s.id == societyId);
      if (societyIndex == -1) continue;

      final society = _societies![societyIndex];
      final currentMembers = Set<String>.from(society.memberIds);

      // Add users who joined this society
      for (final entry in _runtimeJoinedSocieties.entries) {
        if (entry.value.contains(societyId)) {
          currentMembers.add(entry.key);
        }
      }

      // Remove users who left this society
      for (final entry in _runtimeLeftSocieties.entries) {
        if (entry.value.contains(societyId)) {
          currentMembers.remove(entry.key);
        }
      }

      // Update society with new member list
      _societies![societyIndex] = society.copyWith(
        memberIds: currentMembers.toList(),
        memberCount: currentMembers.length,
      );
    }
  }

  // Enhanced Events API (primary)
  Future<List<EventV2>> get enhancedEvents async {
    await _initializeData();
    return _eventsV2!;
  }
  
  List<EventV2> get enhancedEventsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.enhancedEvents first.');
    }
    return _eventsV2!;
  }
  
  // Enhanced Events API (Backward compatibility)
  @Deprecated('Use enhancedEvents instead')
  Future<List<EventV2>> get eventsV2 async {
    return enhancedEvents;
  }
  
  @Deprecated('Use enhancedEventsSync instead')
  List<EventV2> get eventsV2Sync {
    return enhancedEventsSync;
  }

  // Legacy Events API (for backward compatibility)
  Future<List<Event>> get events async {
    await _initializeData();
    return _events!;
  }
  
  List<Event> get eventsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.events first.');
    }
    return _events!;
  }

  // Other data collections (unchanged)
  Future<List<User>> get users async {
    await _initializeData();
    return _users!;
  }
  
  List<User> get usersSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }
    return _users!;
  }

  Future<List<Society>> get societies async {
    await _initializeData();
    return List.unmodifiable(_societies!);
  }
  
  List<Society> get societiesSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.societies first.');
    }
    return List.unmodifiable(_societies!);
  }

  Future<List<PrivacySettings>> get privacySettings async {
    await _initializeData();
    return _privacySettings!;
  }
  
  List<PrivacySettings> get privacySettingsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.privacySettings first.');
    }
    return _privacySettings!;
  }
  
  Future<List<Location>> get locations async {
    await _initializeData();
    return List.unmodifiable(_locations!);
  }
  
  List<Location> get locationsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.locations first.');
    }
    return List.unmodifiable(_locations!);
  }
  
  Future<List<FriendRequest>> get friendRequests async {
    await _initializeData();
    return _friendRequests!;
  }
  
  List<FriendRequest> get friendRequestsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.friendRequests first.');
    }
    return _friendRequests!;
  }

  // Helper methods for common queries
  List<User> get friends {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }
    return usersSync.where((user) => currentUser.friendIds.contains(user.id)).toList();
  }
  
  List<Society> get joinedSocieties {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.societies first.');
    }
    return societiesSync.where((society) => currentUser.societyIds.contains(society.id)).toList();
  }
  
  List<Event> get todayEvents {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.events first.');
    }
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return eventsSync.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList();
  }

  // Enhanced Events helper methods
  List<EventV2> get todayEventsV2 {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.eventsV2 first.');
    }
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return enhancedEventsSync.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList();
  }
  
  // Async versions for initial loading
  Future<List<User>> get friendsAsync async {
    await _initializeData();
    return usersSync.where((user) => currentUser.friendIds.contains(user.id)).toList();
  }
  
  Future<List<Society>> get joinedSocietiesAsync async {
    await _initializeData();
    return societiesSync.where((society) => currentUser.societyIds.contains(society.id)).toList();
  }
  
  Future<List<Event>> get todayEventsAsync async {
    await _initializeData();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return eventsSync.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList();
  }

  Future<List<EventV2>> get todayEventsV2Async async {
    await _initializeData();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return enhancedEventsSync.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList();
  }

  // Method to get events within a date range
  List<Event> getEventsByDateRange(DateTime startDate, DateTime endDate) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.events first.');
    }
    return eventsSync.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<EventV2> getEnhancedEventsByDateRange(DateTime startDate, DateTime endDate) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.enhancedEvents first.');
    }
    return enhancedEventsSync.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  Future<List<Event>> getEventsByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    await _initializeData();
    return eventsSync.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<List<EventV2>> getEnhancedEventsByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    await _initializeData();
    return enhancedEventsSync.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  // Backward compatibility methods
  @Deprecated('Use getEnhancedEventsByDateRange instead')
  List<EventV2> getEventsV2ByDateRange(DateTime startDate, DateTime endDate) {
    return getEnhancedEventsByDateRange(startDate, endDate);
  }
  
  @Deprecated('Use getEnhancedEventsByDateRangeAsync instead')
  Future<List<EventV2>> getEventsV2ByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    return getEnhancedEventsByDateRangeAsync(startDate, endDate);
  }

  // Track runtime membership changes to preserve across cache clears
  final Map<String, Set<String>> _runtimeJoinedSocieties = {}; // User -> Societies joined at runtime
  final Map<String, Set<String>> _runtimeLeftSocieties = {}; // User -> Societies left at runtime

  // Society methods
  void joinSociety(String societyId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.societies first.');
    }

    // Track runtime change - add to joined list and remove from left list
    _runtimeJoinedSocieties.putIfAbsent(currentUser.id, () => {}).add(societyId);
    _runtimeLeftSocieties[currentUser.id]?.remove(societyId);

    // Update society to add current user to memberIds
    final societyIndex = _societies!.indexWhere((s) => s.id == societyId);
    if (societyIndex != -1) {
      final society = _societies![societyIndex];
      if (!society.memberIds.contains(currentUser.id)) {
        final updatedMemberIds = List<String>.from(society.memberIds)..add(currentUser.id);
        _societies![societyIndex] = society.copyWith(
          memberIds: updatedMemberIds,
          memberCount: updatedMemberIds.length,
        );
      }
    }

    // Update current user to add society to societyIds
    final userIndex = _users!.indexWhere((u) => u.id == currentUser.id);
    if (userIndex != -1) {
      final user = _users![userIndex];
      if (!user.societyIds.contains(societyId)) {
        final updatedSocietyIds = List<String>.from(user.societyIds)..add(societyId);
        _users![userIndex] = user.copyWith(societyIds: updatedSocietyIds);
        _currentUser = _users![userIndex]; // Update current user reference

        // Notify listeners of membership change with detailed information
        _societyMembershipNotifier.value = {
          'action': 'joined',
          'societyId': societyId,
          'userId': currentUser.id,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        _societyMembershipCounter.value++;
      }
    }
  }

  void leaveSociety(String societyId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.societies first.');
    }

    // Track runtime change - add to left list and remove from joined list
    _runtimeLeftSocieties.putIfAbsent(currentUser.id, () => {}).add(societyId);
    _runtimeJoinedSocieties[currentUser.id]?.remove(societyId);

    // Update society to remove current user from memberIds
    final societyIndex = _societies!.indexWhere((s) => s.id == societyId);
    if (societyIndex != -1) {
      final society = _societies![societyIndex];
      if (society.memberIds.contains(currentUser.id)) {
        final updatedMemberIds = List<String>.from(society.memberIds)..remove(currentUser.id);
        _societies![societyIndex] = society.copyWith(
          memberIds: updatedMemberIds,
          memberCount: updatedMemberIds.length,
        );
      }
    }

    // Update current user to remove society from societyIds
    final userIndex = _users!.indexWhere((u) => u.id == currentUser.id);
    if (userIndex != -1) {
      final user = _users![userIndex];
      if (user.societyIds.contains(societyId)) {
        final updatedSocietyIds = List<String>.from(user.societyIds)..remove(societyId);
        _users![userIndex] = user.copyWith(societyIds: updatedSocietyIds);
        _currentUser = _users![userIndex]; // Update current user reference

        // Notify listeners of membership change with detailed information
        _societyMembershipNotifier.value = {
          'action': 'left',
          'societyId': societyId,
          'userId': currentUser.id,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        _societyMembershipCounter.value++;
      }
    }
  }

  void updateUser(User updatedUser) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }

    // Find and update the user in the users list
    final userIndex = _users!.indexWhere((u) => u.id == updatedUser.id);
    if (userIndex != -1) {
      _users![userIndex] = updatedUser;

      // Update current user cache if this is the current user
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
      }
    }
  }

  // User lookup methods
  User? getUserById(String id) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }
    try {
      return usersSync.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Society? getSocietyById(String id) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.societies first.');
    }
    try {
      return societiesSync.firstWhere((society) => society.id == id);
    } catch (e) {
      return null;
    }
  }

  EventV2? getEventV2ById(String id) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.eventsV2 first.');
    }
    try {
      return eventsV2Sync.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<User?> getUserByIdAsync(String id) async {
    await _initializeData();
    try {
      return usersSync.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Society?> getSocietyByIdAsync(String id) async {
    await _initializeData();
    try {
      return societiesSync.firstWhere((society) => society.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<EventV2?> getEventV2ByIdAsync(String id) async {
    await _initializeData();
    try {
      return eventsV2Sync.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  // Helper methods for new interconnected data
  PrivacySettings? getPrivacySettingsForUser(String userId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.privacySettings first.');
    }
    try {
      return privacySettingsSync.firstWhere((settings) => settings.userId == userId);
    } catch (e) {
      return null;
    }
  }

  Location? getLocationById(String id) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.locations first.');
    }
    try {
      return locationsSync.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }

  List<FriendRequest> getPendingFriendRequests(String userId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.friendRequests first.');
    }
    return friendRequestsSync.where((request) => 
      request.receiverId == userId && request.isPending
    ).toList();
  }

  List<FriendRequest> getSentFriendRequests(String userId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.friendRequests first.');
    }
    return friendRequestsSync.where((request) => 
      request.senderId == userId && request.isPending
    ).toList();
  }

  // Friend management methods
  bool areFriends(String userId1, String userId2) {
    final user1 = getUserById(userId1);
    final user2 = getUserById(userId2);
    return user1?.friendIds.contains(userId2) == true && 
           user2?.friendIds.contains(userId1) == true;
  }

  List<User> getFriendsForUser(String userId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }
    final user = getUserById(userId);
    if (user == null) return [];

    return user.friendIds.map((friendId) => getUserById(friendId))
        .where((friend) => friend != null)
        .cast<User>()
        .toList();
  }

  Future<List<User>> getFriendsForUserAsync(String userId) async {
    await _initializeData();
    final user = getUserById(userId);
    if (user == null) return [];

    return user.friendIds.map((friendId) => getUserById(friendId))
        .where((friend) => friend != null)
        .cast<User>()
        .toList();
  }

  // Friend management methods - add/remove friends and handle requests
  bool acceptFriendRequest(String requestId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.friendRequests first.');
    }

    final requestIndex = _friendRequests!.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return false;

    final request = _friendRequests![requestIndex];
    if (!request.isPending) return false;

    // Update the friend request status
    _friendRequests![requestIndex] = request.accept();

    // Add bidirectional friend relationship
    _addFriendRelationship(request.senderId, request.receiverId);

    return true;
  }

  bool declineFriendRequest(String requestId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.friendRequests first.');
    }

    final requestIndex = _friendRequests!.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return false;

    final request = _friendRequests![requestIndex];
    if (!request.isPending) return false;

    // Update the friend request status
    _friendRequests![requestIndex] = request.decline();

    return true;
  }

  bool cancelFriendRequest(String requestId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.friendRequests first.');
    }

    final requestIndex = _friendRequests!.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return false;

    final request = _friendRequests![requestIndex];
    if (!request.isPending) return false;

    // Update the friend request status to cancelled
    _friendRequests![requestIndex] = request.cancel();

    return true;
  }

  bool addFriendRequest(FriendRequest request) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.friendRequests first.');
    }

    // Check if request already exists
    final existingRequest = _friendRequests!.any((r) =>
      (r.senderId == request.senderId && r.receiverId == request.receiverId && r.isPending) ||
      (r.senderId == request.receiverId && r.receiverId == request.senderId && r.isPending)
    );

    if (existingRequest) return false;

    // Check if they're already friends
    if (areFriends(request.senderId, request.receiverId)) return false;

    _friendRequests!.add(request);
    return true;
  }

  bool removeFriend(String userId1, String userId2) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }

    if (!areFriends(userId1, userId2)) return false;

    _removeFriendRelationship(userId1, userId2);
    return true;
  }

  void _addFriendRelationship(String userId1, String userId2) {
    // Update first user
    final user1Index = _users!.indexWhere((u) => u.id == userId1);
    if (user1Index != -1) {
      final user1 = _users![user1Index];
      if (!user1.friendIds.contains(userId2)) {
        final updatedFriendIds = List<String>.from(user1.friendIds)..add(userId2);
        _users![user1Index] = user1.copyWith(friendIds: updatedFriendIds);

        // Update current user reference if applicable
        if (userId1 == currentUser.id) {
          _currentUser = _users![user1Index];
        }
      }
    }

    // Update second user
    final user2Index = _users!.indexWhere((u) => u.id == userId2);
    if (user2Index != -1) {
      final user2 = _users![user2Index];
      if (!user2.friendIds.contains(userId1)) {
        final updatedFriendIds = List<String>.from(user2.friendIds)..add(userId1);
        _users![user2Index] = user2.copyWith(friendIds: updatedFriendIds);

        // Update current user reference if applicable
        if (userId2 == currentUser.id) {
          _currentUser = _users![user2Index];
        }
      }
    }
  }

  void _removeFriendRelationship(String userId1, String userId2) {
    // Update first user
    final user1Index = _users!.indexWhere((u) => u.id == userId1);
    if (user1Index != -1) {
      final user1 = _users![user1Index];
      if (user1.friendIds.contains(userId2)) {
        final updatedFriendIds = List<String>.from(user1.friendIds)..remove(userId2);
        _users![user1Index] = user1.copyWith(friendIds: updatedFriendIds);

        // Update current user reference if applicable
        if (userId1 == currentUser.id) {
          _currentUser = _users![user1Index];
        }
      }
    }

    // Update second user
    final user2Index = _users!.indexWhere((u) => u.id == userId2);
    if (user2Index != -1) {
      final user2 = _users![user2Index];
      if (user2.friendIds.contains(userId1)) {
        final updatedFriendIds = List<String>.from(user2.friendIds)..remove(userId1);
        _users![user2Index] = user2.copyWith(friendIds: updatedFriendIds);

        // Update current user reference if applicable
        if (userId2 == currentUser.id) {
          _currentUser = _users![user2Index];
        }
      }
    }
  }

  // Check if using v2 events
  bool get isUsingV2Events => _useV2Events;

  // Clear all cached data and force reload from JSON
  Future<void> clearCache() async {
    _isInitialized = false;
    _currentUser = null;
    _users = null;
    _events = null;
    _eventsV2 = null;
    _societies = null;
    _locations = null;
    _friendRequests = null;
    _privacySettings = null;
    // Force reload from JSON files
    await _initializeData();
  }
}
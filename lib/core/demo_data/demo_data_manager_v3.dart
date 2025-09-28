import 'package:flutter/foundation.dart';
import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/friend_request.dart';
import '../../shared/models/location.dart';
import '../../shared/models/privacy_settings.dart';
import '../database/database_helper.dart';
import '../database/data_seeder.dart';
import '../database/repositories/user_repository.dart';
import '../database/repositories/society_repository.dart';
import '../database/repositories/event_repository.dart';
import '../database/repositories/location_repository.dart';
import '../database/repositories/privacy_settings_repository.dart';
import '../database/repositories/friend_request_repository.dart';

/// Database-backed DemoDataManager (v3) with full backward compatibility
/// Maintains the same API as v2 while using SQLite for scalable data management
class DemoDataManagerV3 {
  static DemoDataManagerV3? _instance;
  static DemoDataManagerV3 get instance => _instance ??= DemoDataManagerV3._();
  DemoDataManagerV3._();

  // Repositories
  final UserRepository _userRepository = UserRepository();
  final SocietyRepository _societyRepository = SocietyRepository();
  final EventRepository _eventRepository = EventRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final PrivacySettingsRepository _privacySettingsRepository = PrivacySettingsRepository();
  final FriendRequestRepository _friendRequestRepository = FriendRequestRepository();
  final DataSeeder _dataSeeder = DataSeeder();

  // Society membership notifiers (preserved for backward compatibility)
  final ValueNotifier<Map<String, dynamic>> _societyMembershipNotifier = ValueNotifier<Map<String, dynamic>>({});
  ValueNotifier<Map<String, dynamic>> get societyMembershipNotifier => _societyMembershipNotifier;

  final ValueNotifier<int> _societyMembershipCounter = ValueNotifier<int>(0);
  ValueNotifier<int> get societyMembershipCounter => _societyMembershipCounter;

  // Current user cache
  User? _currentUser;
  bool _isInitialized = false;

  // Initialize database and seed data if needed
  Future<void> _initializeData() async {
    if (_isInitialized) return;

    try {
      // Seed database if needed
      await _dataSeeder.seedDatabase();
      _isInitialized = true;

      if (kDebugMode) {
        print('DemoDataManagerV3 initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing DemoDataManagerV3: $e');
      }
      rethrow;
    }
  }

  // Current user management
  User get currentUser {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }
    if (_currentUser != null) {
      return _currentUser!;
    }
    throw StateError('Current user not loaded. Call await demoDataManager.currentUserAsync first.');
  }

  Future<User> get currentUserAsync async {
    await _initializeData();
    if (_currentUser == null) {
      final users = await _userRepository.getAllWithRelationships();
      if (users.isNotEmpty) {
        _currentUser = users.first; // First user is the current user by convention
      } else {
        throw StateError('No users found in database');
      }
    }
    return _currentUser!;
  }

  // Enhanced Events API (primary)
  Future<List<EventV2>> get enhancedEvents async {
    await _initializeData();
    return await _eventRepository.getAll();
  }

  List<EventV2> get enhancedEventsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.enhancedEvents first.');
    }
    throw StateError('Synchronous access not available with database backend. Use enhancedEvents instead.');
  }

  // Backward compatibility aliases
  @Deprecated('Use enhancedEvents instead')
  Future<List<EventV2>> get eventsV2 async => enhancedEvents;

  @Deprecated('Use enhancedEventsSync instead')
  List<EventV2> get eventsV2Sync => enhancedEventsSync;

  // Legacy Events API (for backward compatibility)
  Future<List<Event>> get events async {
    await _initializeData();
    final eventsV2 = await _eventRepository.getAll();
    return eventsV2.map((e) => e.toLegacyEvent()).toList();
  }

  List<Event> get eventsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.events first.');
    }
    throw StateError('Synchronous access not available with database backend. Use events instead.');
  }

  // Users API
  Future<List<User>> get users async {
    await _initializeData();
    return await _userRepository.getAllWithRelationships();
  }

  List<User> get usersSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }
    throw StateError('Synchronous access not available with database backend. Use users instead.');
  }

  // Societies API
  Future<List<Society>> get societies async {
    await _initializeData();
    return await _societyRepository.getAll();
  }

  List<Society> get societiesSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.societies first.');
    }
    throw StateError('Synchronous access not available with database backend. Use societies instead.');
  }

  // Other data collections
  Future<List<PrivacySettings>> get privacySettings async {
    await _initializeData();
    return await _privacySettingsRepository.getAll();
  }

  List<PrivacySettings> get privacySettingsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.privacySettings first.');
    }
    throw StateError('Synchronous access not available with database backend. Use privacySettings instead.');
  }

  Future<List<Location>> get locations async {
    await _initializeData();
    return await _locationRepository.getAll();
  }

  List<Location> get locationsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.locations first.');
    }
    throw StateError('Synchronous access not available with database backend. Use locations instead.');
  }

  Future<List<FriendRequest>> get friendRequests async {
    await _initializeData();
    return await _friendRequestRepository.getAll();
  }

  List<FriendRequest> get friendRequestsSync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.friendRequests first.');
    }
    throw StateError('Synchronous access not available with database backend. Use friendRequests instead.');
  }

  // Helper methods for common queries
  Future<List<User>> get friendsAsync async {
    await _initializeData();
    final currentUser = await currentUserAsync;
    return await _userRepository.getFriends(currentUser.id);
  }

  List<User> get friends {
    throw StateError('Synchronous access not available with database backend. Use friendsAsync instead.');
  }

  Future<List<Society>> get joinedSocietiesAsync async {
    await _initializeData();
    final currentUser = await currentUserAsync;
    final allSocieties = await _societyRepository.getAll();
    return allSocieties.where((society) => currentUser.societyIds.contains(society.id)).toList();
  }

  List<Society> get joinedSocieties {
    throw StateError('Synchronous access not available with database backend. Use joinedSocietiesAsync instead.');
  }

  Future<List<EventV2>> get todayEventsV2Async async {
    await _initializeData();
    return await _eventRepository.getTodayEvents();
  }

  List<EventV2> get todayEventsV2 {
    throw StateError('Synchronous access not available with database backend. Use todayEventsV2Async instead.');
  }

  Future<List<Event>> get todayEventsAsync async {
    await _initializeData();
    final eventsV2 = await _eventRepository.getTodayEvents();
    return eventsV2.map((e) => e.toLegacyEvent()).toList();
  }

  List<Event> get todayEvents {
    throw StateError('Synchronous access not available with database backend. Use todayEventsAsync instead.');
  }

  // Date range queries
  Future<List<Event>> getEventsByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    await _initializeData();
    final eventsV2 = await _eventRepository.getEventsByDateRange(startDate, endDate);
    return eventsV2.map((e) => e.toLegacyEvent()).toList();
  }

  List<Event> getEventsByDateRange(DateTime startDate, DateTime endDate) {
    throw StateError('Synchronous access not available with database backend. Use getEventsByDateRangeAsync instead.');
  }

  Future<List<EventV2>> getEnhancedEventsByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    await _initializeData();
    return await _eventRepository.getEventsByDateRange(startDate, endDate);
  }

  List<EventV2> getEnhancedEventsByDateRange(DateTime startDate, DateTime endDate) {
    throw StateError('Synchronous access not available with database backend. Use getEnhancedEventsByDateRangeAsync instead.');
  }

  // Backward compatibility methods
  @Deprecated('Use getEnhancedEventsByDateRangeAsync instead')
  Future<List<EventV2>> getEventsV2ByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    return getEnhancedEventsByDateRangeAsync(startDate, endDate);
  }

  @Deprecated('Use getEnhancedEventsByDateRange instead')
  List<EventV2> getEventsV2ByDateRange(DateTime startDate, DateTime endDate) {
    return getEnhancedEventsByDateRange(startDate, endDate);
  }

  // Society membership management
  Future<void> joinSociety(String societyId) async {
    await _initializeData();
    final currentUser = await currentUserAsync;

    await _userRepository.addSocietyMembership(currentUser.id, societyId);
    await _societyRepository.incrementMemberCount(societyId);

    // Update cached current user
    _currentUser = await _userRepository.getByIdWithRelationships(currentUser.id);

    // Notify listeners
    _societyMembershipNotifier.value = {
      'action': 'joined',
      'societyId': societyId,
      'userId': currentUser.id,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _societyMembershipCounter.value++;
  }

  Future<void> leaveSociety(String societyId) async {
    await _initializeData();
    final currentUser = await currentUserAsync;

    await _userRepository.removeSocietyMembership(currentUser.id, societyId);
    await _societyRepository.decrementMemberCount(societyId);

    // Update cached current user
    _currentUser = await _userRepository.getByIdWithRelationships(currentUser.id);

    // Notify listeners
    _societyMembershipNotifier.value = {
      'action': 'left',
      'societyId': societyId,
      'userId': currentUser.id,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _societyMembershipCounter.value++;
  }

  // Lookup methods
  Future<User?> getUserByIdAsync(String id) async {
    await _initializeData();
    return await _userRepository.getByIdWithRelationships(id);
  }

  User? getUserById(String id) {
    throw StateError('Synchronous access not available with database backend. Use getUserByIdAsync instead.');
  }

  Future<Society?> getSocietyByIdAsync(String id) async {
    await _initializeData();
    return await _societyRepository.getById(id);
  }

  Society? getSocietyById(String id) {
    throw StateError('Synchronous access not available with database backend. Use getSocietyByIdAsync instead.');
  }

  Future<EventV2?> getEventV2ByIdAsync(String id) async {
    await _initializeData();
    return await _eventRepository.getById(id);
  }

  EventV2? getEventV2ById(String id) {
    throw StateError('Synchronous access not available with database backend. Use getEventV2ByIdAsync instead.');
  }

  // Privacy and location helpers
  Future<PrivacySettings?> getPrivacySettingsForUserAsync(String userId) async {
    await _initializeData();
    return await _privacySettingsRepository.getByUserId(userId);
  }

  PrivacySettings? getPrivacySettingsForUser(String userId) {
    throw StateError('Synchronous access not available with database backend. Use getPrivacySettingsForUserAsync instead.');
  }

  Future<Location?> getLocationByIdAsync(String id) async {
    await _initializeData();
    return await _locationRepository.getById(id);
  }

  Location? getLocationById(String id) {
    throw StateError('Synchronous access not available with database backend. Use getLocationByIdAsync instead.');
  }

  // Friend request management
  Future<List<FriendRequest>> getPendingFriendRequestsAsync(String userId) async {
    await _initializeData();
    return await _friendRequestRepository.getPendingRequestsForUser(userId);
  }

  List<FriendRequest> getPendingFriendRequests(String userId) {
    throw StateError('Synchronous access not available with database backend. Use getPendingFriendRequestsAsync instead.');
  }

  Future<List<FriendRequest>> getSentFriendRequestsAsync(String userId) async {
    await _initializeData();
    return await _friendRequestRepository.getSentRequestsByUser(userId);
  }

  List<FriendRequest> getSentFriendRequests(String userId) {
    throw StateError('Synchronous access not available with database backend. Use getSentFriendRequestsAsync instead.');
  }

  // Friend management
  Future<bool> areFriendsAsync(String userId1, String userId2) async {
    await _initializeData();
    return await _userRepository.areFriends(userId1, userId2);
  }

  bool areFriends(String userId1, String userId2) {
    throw StateError('Synchronous access not available with database backend. Use areFriendsAsync instead.');
  }

  Future<List<User>> getFriendsForUserAsync(String userId) async {
    await _initializeData();
    return await _userRepository.getFriends(userId);
  }

  List<User> getFriendsForUser(String userId) {
    throw StateError('Synchronous access not available with database backend. Use getFriendsForUserAsync instead.');
  }

  Future<bool> acceptFriendRequestAsync(String requestId) async {
    await _initializeData();
    final request = await _friendRequestRepository.getById(requestId);
    if (request == null) return false;

    final updateCount = await _friendRequestRepository.acceptRequest(requestId);
    if (updateCount > 0) {
      // Add bidirectional friendship
      await _userRepository.addFriend(request.senderId, request.receiverId);
      return true;
    }
    return false;
  }

  bool acceptFriendRequest(String requestId) {
    throw StateError('Synchronous access not available with database backend. Use acceptFriendRequestAsync instead.');
  }

  Future<bool> declineFriendRequestAsync(String requestId) async {
    await _initializeData();
    final updateCount = await _friendRequestRepository.declineRequest(requestId);
    return updateCount > 0;
  }

  bool declineFriendRequest(String requestId) {
    throw StateError('Synchronous access not available with database backend. Use declineFriendRequestAsync instead.');
  }

  Future<bool> cancelFriendRequestAsync(String requestId) async {
    await _initializeData();
    final updateCount = await _friendRequestRepository.cancelRequest(requestId);
    return updateCount > 0;
  }

  bool cancelFriendRequest(String requestId) {
    throw StateError('Synchronous access not available with database backend. Use cancelFriendRequestAsync instead.');
  }

  Future<bool> addFriendRequestAsync(FriendRequest request) async {
    await _initializeData();
    final canSend = await _friendRequestRepository.canSendRequestToUser(request.senderId, request.receiverId);
    if (!canSend) return false;

    await _friendRequestRepository.insert(request);
    return true;
  }

  bool addFriendRequest(FriendRequest request) {
    throw StateError('Synchronous access not available with database backend. Use addFriendRequestAsync instead.');
  }

  Future<bool> removeFriendAsync(String userId1, String userId2) async {
    await _initializeData();
    final areFriends = await _userRepository.areFriends(userId1, userId2);
    if (!areFriends) return false;

    await _userRepository.removeFriend(userId1, userId2);
    return true;
  }

  bool removeFriend(String userId1, String userId2) {
    throw StateError('Synchronous access not available with database backend. Use removeFriendAsync instead.');
  }

  // Utility methods
  bool get isUsingV2Events => true; // Always true for v3

  Future<void> clearCache() async {
    await DatabaseHelper.instance.clearAllTables();
    await _dataSeeder.seedDatabase(forceReseed: true);
    _currentUser = null;
    _isInitialized = false;
  }

  // Database-specific methods
  Future<Map<String, dynamic>> getDatabaseStatus() async {
    return await _dataSeeder.getSeedStatus();
  }

  Future<void> reseedDatabase() async {
    await _dataSeeder.clearAndReseed();
    _currentUser = null;
    _isInitialized = false;
  }

  Future<bool> isDatabaseHealthy() async {
    return await DatabaseHelper.instance.isDatabaseHealthy();
  }

  Future<Map<String, int>> getDatabaseStats() async {
    return await DatabaseHelper.instance.getDatabaseStats();
  }
}
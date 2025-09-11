import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/friend_request.dart';
import '../../shared/models/location.dart';
import '../../shared/models/privacy_settings.dart';
import 'demo_data_loader.dart';
import 'demo_data_loader_v2.dart';

/// Enhanced DemoDataManager supporting both legacy and v2 events
/// Provides backward compatibility while enabling new Phase 2/3 features
class DemoDataManagerV2 {
  static DemoDataManagerV2? _instance;
  static DemoDataManagerV2 get instance => _instance ??= DemoDataManagerV2._();
  DemoDataManagerV2._();

  // Current logged in user - cached for performance
  User? _currentUser;
  User get currentUser {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.users first.');
    }
    return _currentUser ??= usersSync.first;
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
    
    _users = await DemoDataLoaderV2.loadUsers();
    _societies = await DemoDataLoaderV2.loadSocieties();
    _locations = await DemoDataLoaderV2.loadLocations();
    _privacySettings = await DemoDataLoaderV2.loadPrivacySettings();
    _friendRequests = await DemoDataLoaderV2.loadFriendRequests();
    
    // Load enhanced events from single events.json file
    _eventsV2 = await DemoDataLoaderV2.loadEventsV2();
    _events = _eventsV2!.map((e) => e.toLegacyEvent()).toList();
    print('Loaded ${_eventsV2!.length} enhanced events successfully');
    
    // Validate data integrity
    final warnings = await DemoDataLoaderV2.validateDataIntegrity(
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
  }

  // V2 Events API
  Future<List<EventV2>> get eventsV2 async {
    await _initializeData();
    return _eventsV2!;
  }
  
  List<EventV2> get eventsV2Sync {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.eventsV2 first.');
    }
    return _eventsV2!;
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
    return usersSync.where((user) => user.id != currentUser.id).toList();
  }
  
  List<Society> get joinedSocieties {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.societies first.');
    }
    return societiesSync.where((society) => society.isJoined).toList();
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

  // V2 Events helper methods
  List<EventV2> get todayEventsV2 {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.eventsV2 first.');
    }
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return eventsV2Sync.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList();
  }
  
  // Async versions for initial loading
  Future<List<User>> get friendsAsync async {
    await _initializeData();
    return usersSync.where((user) => user.id != currentUser.id).toList();
  }
  
  Future<List<Society>> get joinedSocietiesAsync async {
    await _initializeData();
    return societiesSync.where((society) => society.isJoined).toList();
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
    
    return eventsV2Sync.where((event) {
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

  List<EventV2> getEventsV2ByDateRange(DateTime startDate, DateTime endDate) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.eventsV2 first.');
    }
    return eventsV2Sync.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  Future<List<Event>> getEventsByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    await _initializeData();
    return eventsSync.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<List<EventV2>> getEventsV2ByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    await _initializeData();
    return eventsV2Sync.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Society methods
  void joinSociety(String societyId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.societies first.');
    }
    final index = _societies!.indexWhere((s) => s.id == societyId);
    if (index != -1) {
      _societies![index] = _societies![index].copyWith(
        isJoined: true,
        memberCount: _societies![index].memberCount + 1,
      );
    }
  }

  void leaveSociety(String societyId) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.societies first.');
    }
    final index = _societies!.indexWhere((s) => s.id == societyId);
    if (index != -1) {
      _societies![index] = _societies![index].copyWith(
        isJoined: false,
        memberCount: _societies![index].memberCount - 1,
      );
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

  // Check if using v2 events
  bool get isUsingV2Events => _useV2Events;
}
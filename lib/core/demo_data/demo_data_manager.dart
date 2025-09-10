import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/friend_request.dart';
import '../../shared/models/location.dart';
import '../../shared/models/privacy_settings.dart';
import 'demo_data_loader.dart';

class DemoDataManager {
  static DemoDataManager? _instance;
  static DemoDataManager get instance => _instance ??= DemoDataManager._();
  DemoDataManager._();

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
  List<Event>? _events;
  List<Society>? _societies;
  
  // Flag to track if data is loaded from JSON
  bool _isInitialized = false;

  // Initialize all data from JSON files
  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    _users = await DemoDataLoader.loadUsers();
    _societies = await DemoDataLoader.loadSocieties();
    _events = await DemoDataLoader.loadEvents();
    _locations = await DemoDataLoader.loadLocations();
    _privacySettings = await DemoDataLoader.loadPrivacySettings();
    _friendRequests = await DemoDataLoader.loadFriendRequests();
    
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
  }

  // Async getters for accessing demo data
  Future<List<User>> get users async {
    await _initializeData();
    return _users!;
  }
  
  // Synchronous getter for users (for backward compatibility)
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

  // Helper methods for common queries (cached for performance)
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

  // Method to get events within a date range
  List<Event> getEventsByDateRange(DateTime startDate, DateTime endDate) {
    if (!_isInitialized) {
      throw StateError('Demo data not initialized. Call await demoDataManager.events first.');
    }
    return eventsSync.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  Future<List<Event>> getEventsByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    await _initializeData();
    return eventsSync.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Methods to modify data (for demo purposes)
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
  
  // Async versions for initial loading
  Future<PrivacySettings?> getPrivacySettingsForUserAsync(String userId) async {
    await _initializeData();
    try {
      return privacySettingsSync.firstWhere((settings) => settings.userId == userId);
    } catch (e) {
      return null;
    }
  }

  Future<Location?> getLocationByIdAsync(String id) async {
    await _initializeData();
    try {
      return locationsSync.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<FriendRequest>> getPendingFriendRequestsAsync(String userId) async {
    await _initializeData();
    return friendRequestsSync.where((request) => 
      request.receiverId == userId && request.isPending
    ).toList();
  }

  Future<List<FriendRequest>> getSentFriendRequestsAsync(String userId) async {
    await _initializeData();
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
}
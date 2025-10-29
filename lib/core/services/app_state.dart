import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../demo_data/demo_data_manager.dart';
import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/event_enums.dart';
import '../../features/calendar/enhanced_calendar_screen.dart';
import '../../shared/widgets/main_navigation.dart';
import 'calendar_service.dart';
import 'friendship_service.dart';
import 'chat_service.dart';
import 'location_service.dart';

// Tab initialization parameters for smart navigation
class CalendarTabParams {
  final CalendarFilter? initialFilter;
  final CalendarView? initialView;
  final bool? initialUseTimetableView;

  CalendarTabParams({
    this.initialFilter,
    this.initialView,
    this.initialUseTimetableView,
  });
}

class FriendsTabParams {
  final int? initialTabIndex;

  FriendsTabParams({this.initialTabIndex});
}

class SocietiesTabParams {
  final int? initialTabIndex;

  SocietiesTabParams({this.initialTabIndex});
}

class AppState extends ChangeNotifier {
  final DemoDataManager _demoData = DemoDataManager.instance;
  bool _isDarkMode = false;
  bool _isTempStyleEnabled = true; // Temp style toggle for navigation and design changes

  // Development toggles
  static const bool _forceShowOnboardingInDev = true; // DEV TOGGLE: Set to false to skip onboarding in development
  static const bool _isProduction = false; // Set to true for production builds

  bool _isAuthenticated = _isProduction ? false : !_forceShowOnboardingInDev; // Skip auth if not showing onboarding in dev
  bool _hasCompletedOnboarding = false; // Tracks if user completed onboarding
  String? _activeUserId; // Track which user is currently active
  bool _isNewUser = false; // Track if user went through onboarding
  bool _hasExplicitlyEnteredDemo = false; // Track if user explicitly chose demo mode
  int _currentNavIndex = 0; // Start on Home
  bool _isInitialized = false;
  bool _isManuallyNavigating = false; // Prevent MaterialApp auto-routing during manual navigation

  // Tab initialization parameters for smart navigation
  CalendarTabParams? _pendingCalendarParams;
  FriendsTabParams? _pendingFriendsParams;
  SocietiesTabParams? _pendingSocietiesParams;

  AppState() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load onboarding completion status from persistent storage
      await _loadOnboardingStatus();

      // Initialize all demo data
      await _demoData.users;

      // Initialize all services by calling an async method on each
      // This ensures their internal _isInitialized flags are set
      final currentUserId = _demoData.currentUser.id;

      // Import and initialize services
      final calendarService = CalendarService();
      final friendshipService = FriendshipService();
      final chatService = ChatService();
      final locationService = LocationService();

      // Call async methods to trigger initialization
      await calendarService.getUnifiedCalendar(currentUserId);
      await friendshipService.getMutualFriends(currentUserId, currentUserId);
      await chatService.getUserChats(currentUserId);

      // Initialize LocationService with a minimal location update
      final currentUser = _demoData.currentUser;
      if (currentUser.currentLocationId != null) {
        await locationService.updateUserLocation(
          userId: currentUserId,
          locationId: currentUser.currentLocationId!,
        );
      }


      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing app: $e');
    }
  }

  Future<void> _loadOnboardingStatus() async {
    // In development, check the force toggle
    if (!_isProduction && _forceShowOnboardingInDev) {
      _hasCompletedOnboarding = false;
      return;
    }

    // In production or when dev toggle is off, check persistent storage
    try {
      // Using SharedPreferences would be ideal here, but for demo we'll use a simple approach
      // In a real app: final prefs = await SharedPreferences.getInstance();
      // _hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

      // For demo purposes, assume onboarding is not completed unless explicitly set
      _hasCompletedOnboarding = false;
    } catch (e) {
      print('Error loading onboarding status: $e');
      _hasCompletedOnboarding = false;
    }
  }

  Future<void> _saveOnboardingStatus() async {
    try {
      // In a real app: final prefs = await SharedPreferences.getInstance();
      // await prefs.setBool('has_completed_onboarding', true);
      print('Onboarding completion saved'); // Demo placeholder
    } catch (e) {
      print('Error saving onboarding status: $e');
    }
  }

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isTempStyleEnabled => _isTempStyleEnabled;
  bool get isAuthenticated => _isAuthenticated && _isInitialized && !_isManuallyNavigating;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get shouldShowOnboarding => _isInitialized && (!_hasCompletedOnboarding || (!_isProduction && _forceShowOnboardingInDev)) && !_hasExplicitlyEnteredDemo && !_isManuallyNavigating;
  bool get isNewUser => _isNewUser;
  String? get activeUserId => _activeUserId;
  int get currentNavIndex => _currentNavIndex;
  bool get isInitialized => _isInitialized;
  bool get isManuallyNavigating => _isManuallyNavigating;

  // Development getters
  bool get isForceShowOnboardingEnabled => _forceShowOnboardingInDev;
  bool get isProductionMode => _isProduction;

  // Tab parameter getters
  CalendarTabParams? get pendingCalendarParams => _pendingCalendarParams;
  FriendsTabParams? get pendingFriendsParams => _pendingFriendsParams;
  SocietiesTabParams? get pendingSocietiesParams => _pendingSocietiesParams;
  
  User get currentUser {
    // Debug logging to track which path is taken
    print('AppState.currentUser: _isNewUser=$_isNewUser, _newUserObject!=null=${_newUserObject != null}, _activeUserId=$_activeUserId');

    // If user is new and we have created a User object from onboarding data, return that
    if (_isNewUser && _newUserObject != null) {
      print('AppState.currentUser: Returning new user: ${_newUserObject!.name} (${_newUserObject!.id})');
      return _newUserObject!;
    }

    // Safety check: if _isNewUser is true but _newUserObject is null, this is an error state
    if (_isNewUser && _newUserObject == null) {
      print('AppState.currentUser: ERROR - _isNewUser is true but _newUserObject is null! Falling back to demo user.');
    }

    // Otherwise return the demo user (Andrea)
    print('AppState.currentUser: Returning demo user: ${_demoData.currentUser.name}');
    return _demoData.currentUser;
  }
  List<User> get friends {
    // New users start with no friends
    if (_isNewUser) return [];

    // Add try-catch to handle uninitialized data gracefully
    try {
      return _demoData.friends;
    } catch (e) {
      print('AppState.friends: Error getting friends: $e');
      return []; // Return empty list on error to prevent crash
    }
  }

  List<Society> get societies => _demoData.societiesSync; // All societies are always available

  List<Society> get joinedSocieties {
    // New users start with no joined societies
    if (_isNewUser) return [];

    // Add try-catch to handle uninitialized data gracefully
    try {
      return _demoData.joinedSocieties;
    } catch (e) {
      print('AppState.joinedSocieties: Error getting joined societies: $e');
      return []; // Return empty list on error to prevent crash
    }
  }

  List<Event> get events {
    // New users start with no events (or could show public events only)
    if (_isNewUser) return [];
    return _demoData.eventsSync;
  }

  List<Event> get todayEvents {
    // New users start with no events for today
    if (_isNewUser) return [];
    return _demoData.todayEvents;
  }

  // Actions
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleTempStyle() {
    _isTempStyleEnabled = !_isTempStyleEnabled;
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // Manual navigation control methods
  void startManualNavigation() {
    _isManuallyNavigating = true;
    notifyListeners();
  }

  void endManualNavigation() {
    _isManuallyNavigating = false;
    notifyListeners();
  }

  // Smart navigation methods
  void setNavIndexWithCalendarParams(int index, CalendarTabParams params) {
    _pendingCalendarParams = params;
    _currentNavIndex = index;
    notifyListeners();
  }

  void setNavIndexWithFriendsParams(int index, FriendsTabParams params) {
    _pendingFriendsParams = params;
    _currentNavIndex = index;
    notifyListeners();
  }

  void setNavIndexWithSocietiesParams(int index, SocietiesTabParams params) {
    _pendingSocietiesParams = params;
    _currentNavIndex = index;
    notifyListeners();
  }

  // Consume pending parameters (called by screens when they load)
  CalendarTabParams? consumeCalendarParams() {
    final params = _pendingCalendarParams;
    _pendingCalendarParams = null;
    return params;
  }

  FriendsTabParams? consumeFriendsParams() {
    final params = _pendingFriendsParams;
    _pendingFriendsParams = null;
    return params;
  }

  SocietiesTabParams? consumeSocietiesParams() {
    final params = _pendingSocietiesParams;
    _pendingSocietiesParams = null;
    return params;
  }

  void login() {
    _isAuthenticated = true;
    notifyListeners();
  }

  void enterDemoMode() {
    print('AppState.enterDemoMode: Clearing new user data and switching to Andrea');
    // Clear any new user data and switch to Andrea's demo profile
    _tempNewUserData = null;
    _newUserObject = null;
    _activeUserId = 'user_001'; // Andrea's ID
    _isNewUser = false;
    _isAuthenticated = true;
    _hasCompletedOnboarding = true;
    _hasExplicitlyEnteredDemo = true; // Override dev toggle
    print('AppState.enterDemoMode: Final state: _isNewUser=$_isNewUser, _activeUserId=$_activeUserId');
    notifyListeners();
  }

  // Navigation-aware version for use from UI components
  void enterDemoModeWithNavigation(BuildContext context) {
    print('AppState.enterDemoModeWithNavigation: Starting demo mode with navigation');

    enterDemoMode();

    // Set navigation index to home
    setNavIndex(0);

    // CRITICAL: Prevent MaterialApp from auto-routing during manual navigation
    // This prevents duplicate MainNavigation instances that cause GlobalKey conflicts
    startManualNavigation();

    print('AppState.enterDemoModeWithNavigation: Manually navigating to MainNavigation (MaterialApp auto-routing disabled)');

    // Navigate to main app - clear entire navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigation(),
      ),
      (route) => false, // Remove all previous routes
    ).then((_) {
      // Re-enable MaterialApp auto-routing after navigation completes
      endManualNavigation();
      print('AppState.enterDemoModeWithNavigation: Navigation complete, MaterialApp auto-routing re-enabled');
    });
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void completeOnboarding({String? newUserId}) {
    print('AppState.completeOnboarding: Called with newUserId: $newUserId');
    print('AppState.completeOnboarding: Current state before completion: _isNewUser=$_isNewUser, _newUserObject!=null=${_newUserObject != null}, _activeUserId=$_activeUserId');

    _hasCompletedOnboarding = true;
    _isAuthenticated = true;

    // IMPORTANT: If we already have new user data, preserve it
    if (_isNewUser && _newUserObject != null && newUserId != null) {
      print('AppState.completeOnboarding: Preserving existing new user state');
      // Ensure the active user ID matches the new user object
      if (_activeUserId != _newUserObject!.id) {
        print('AppState.completeOnboarding: WARNING: activeUserId mismatch, correcting it');
        _activeUserId = _newUserObject!.id;
      }
      // Keep existing new user state - _isNewUser stays true
    } else if (newUserId != null) {
      // New user but no object created yet (shouldn't happen in normal flow)
      print('AppState.completeOnboarding: New user without existing object - setting up new user state');
      _isNewUser = true;
      _activeUserId = newUserId;
    } else {
      // Standard completion logic for demo user
      print('AppState.completeOnboarding: Setting up demo user state');
      _isNewUser = false;
      _activeUserId = 'user_001'; // Andrea's ID
    }

    print('AppState.completeOnboarding: Final state: _isNewUser=$_isNewUser, _activeUserId=$_activeUserId, _newUserObject!=null=${_newUserObject != null}');
    _saveOnboardingStatus();
    notifyListeners();
  }

  void resetOnboardingForDev() {
    _hasCompletedOnboarding = false;
    _isAuthenticated = false;
    _isNewUser = false;
    _activeUserId = null;
    _hasExplicitlyEnteredDemo = false; // Reset demo override
    _tempNewUserData = null; // Clear new user data
    _newUserObject = null; // Clear new user object
    notifyListeners();
  }

  void switchUser(String userId) {
    _activeUserId = userId;
    _isNewUser = false; // Switching to existing user
    _tempNewUserData = null; // Clear new user data when switching
    _newUserObject = null; // Clear new user object when switching
    notifyListeners();
  }

  void createNewUserFromOnboarding(Map<String, dynamic> userData) {
    // In a real app, this would create a new user in the database
    // For demo purposes, we'll generate a new user ID
    final newUserId = 'user_new_${DateTime.now().millisecondsSinceEpoch}';
    print('AppState.createNewUserFromOnboarding: Setting new user ID: $newUserId');
    print('AppState.createNewUserFromOnboarding: User data: $userData');

    _activeUserId = newUserId;
    _isNewUser = true;

    // Store the new user data temporarily
    // In a real app, this would be saved to persistent storage
    _tempNewUserData = userData;

    // Convert the onboarding data to a proper User object
    _newUserObject = _createUserFromOnboardingData(userData, newUserId);
    print('AppState.createNewUserFromOnboarding: Created new user object: ${_newUserObject!.name}');
    print('AppState.createNewUserFromOnboarding: State after creation: _isNewUser=$_isNewUser');

    notifyListeners();
  }

  // Convert onboarding data to User object
  User _createUserFromOnboardingData(Map<String, dynamic> data, String userId) {
    print('AppState._createUserFromOnboardingData: Converting data for user $userId');
    print('AppState._createUserFromOnboardingData: Raw data: $data');

    final newUser = User(
      id: userId,
      name: data['name'] ?? 'New User',
      email: data['email'] ?? '',
      course: data['course'] ?? '',
      year: data['year'] ?? '1st Year',
      profileImageUrl: data['avatar'],
      privacySettingsId: 'privacy_new_user', // Default privacy settings
      isOnline: true,
      status: UserStatus.online,
      statusMessage: 'New UniConnect user!',
      currentBuilding: 'Building 1', // Default UTS building
      friendIds: [], // New user starts with no friends
      pendingFriendRequests: [],
      sentFriendRequests: [],
      societyIds: [], // New user starts with no societies
    );

    print('AppState._createUserFromOnboardingData: Created user: ${newUser.name} (${newUser.email})');
    return newUser;
  }

  Map<String, dynamic>? _tempNewUserData; // Temporary storage for new user data
  Map<String, dynamic>? get newUserData => _tempNewUserData;
  User? _newUserObject; // Converted User object for new users

  void joinSociety(String societyId) {
    _demoData.joinSociety(societyId);
    notifyListeners();
  }

  void leaveSociety(String societyId) {
    _demoData.leaveSociety(societyId);
    notifyListeners();
  }

  // Helper methods
  User? getUserById(String id) => _demoData.getUserById(id);
  Society? getSocietyById(String id) => _demoData.getSocietyById(id);
  
  List<Event> getEventsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return events.where((event) {
      return event.startTime.isAfter(startOfDay) &&
             event.startTime.isBefore(endOfDay);
    }).toList();
  }

  // Profile update functionality
  void updateCurrentUser({
    String? name,
    String? email,
    String? course,
    String? year,
    String? profileImageUrl,
    String? statusMessage,
    UserStatus? status,
  }) {
    if (_isNewUser && _newUserObject != null) {
      // Update new user object
      _newUserObject = _newUserObject!.copyWith(
        name: name,
        email: email,
        course: course,
        year: year,
        profileImageUrl: profileImageUrl,
        statusMessage: statusMessage,
        status: status,
      );

      // Also update the temp data for consistency
      if (_tempNewUserData != null) {
        _tempNewUserData = Map<String, dynamic>.from(_tempNewUserData!)
          ..addAll({
            if (name != null) 'name': name,
            if (email != null) 'email': email,
            if (course != null) 'course': course,
            if (year != null) 'year': year,
            if (profileImageUrl != null) 'avatar': profileImageUrl,
            if (statusMessage != null) 'statusMessage': statusMessage,
            if (status != null) 'status': status.toString().split('.').last,
          });
      }
    } else {
      // Update demo user through DemoDataManager
      final currentUser = _demoData.currentUser;
      final updatedUser = currentUser.copyWith(
        name: name,
        email: email,
        course: course,
        year: year,
        profileImageUrl: profileImageUrl,
        statusMessage: statusMessage,
        status: status,
      );

      // Update the user in demo data manager
      _demoData.updateUser(updatedUser);
    }

    notifyListeners();
  }

  // Separate method for quick status updates
  void updateUserStatus({
    UserStatus? status,
    String? statusMessage,
  }) {
    if (_isNewUser && _newUserObject != null) {
      // Update new user object
      _newUserObject = _newUserObject!.copyWith(
        status: status,
        statusMessage: statusMessage,
      );

      // Also update the temp data for consistency
      if (_tempNewUserData != null) {
        _tempNewUserData = Map<String, dynamic>.from(_tempNewUserData!)
          ..addAll({
            if (status != null) 'status': status.toString().split('.').last,
            if (statusMessage != null) 'statusMessage': statusMessage,
          });
      }
    } else {
      // Update demo user through DemoDataManager
      final currentUser = _demoData.currentUser;
      final updatedUser = currentUser.copyWith(
        status: status,
        statusMessage: statusMessage,
      );

      // Update the user in demo data manager
      _demoData.updateUser(updatedUser);
    }

    notifyListeners();
  }
}
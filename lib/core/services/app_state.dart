import 'package:flutter/foundation.dart';
import '../demo_data/demo_data_manager.dart';
import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import 'calendar_service.dart';
import 'friendship_service.dart';
import 'chat_service.dart';
import 'location_service.dart';

class AppState extends ChangeNotifier {
  final DemoDataManager _demoData = DemoDataManager.instance;
  bool _isDarkMode = false;
  bool _isTempStyleEnabled = false; // Temp style toggle for navigation and design changes
  bool _isAuthenticated = true; // Set to true for demo purposes
  int _currentNavIndex = 0; // Start on Home
  bool _isInitialized = false;

  AppState() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
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

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isTempStyleEnabled => _isTempStyleEnabled;
  bool get isAuthenticated => _isAuthenticated && _isInitialized;
  int get currentNavIndex => _currentNavIndex;
  bool get isInitialized => _isInitialized;
  
  User get currentUser => _demoData.currentUser;
  List<User> get friends => _demoData.friends;
  List<Society> get societies => _demoData.societiesSync;
  List<Society> get joinedSocieties => _demoData.joinedSocieties;
  List<Event> get events => _demoData.eventsSync;
  List<Event> get todayEvents => _demoData.todayEvents;

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

  void login() {
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

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
}
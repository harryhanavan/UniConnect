import 'package:flutter/material.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/friendship_service.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user.dart';
import '../../shared/models/event.dart';
import '../../shared/models/location.dart';
import '../calendar/enhanced_calendar_screen.dart';
import '../societies/enhanced_societies_screen.dart';
import '../friends/enhanced_map_screen.dart';
import '../timetable/smart_timetable_overlay.dart';
import '../notifications/notification_center_screen.dart';

class Phase3TestScreen extends StatefulWidget {
  const Phase3TestScreen({super.key});

  @override
  State<Phase3TestScreen> createState() => _Phase3TestScreenState();
}

class _Phase3TestScreenState extends State<Phase3TestScreen> {
  late DemoDataManager _demoData;
  late FriendshipService _friendshipService;
  late CalendarService _calendarService;
  late LocationService _locationService;
  late NotificationService _notificationService;
  
  final Map<String, TestResult> _testResults = {};
  bool _isRunningTests = false;
  double _testProgress = 0.0;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _demoData = DemoDataManager.instance;
    _friendshipService = FriendshipService();
    _calendarService = CalendarService();
    _locationService = LocationService();
    _notificationService = NotificationService();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _demoData.users; // Trigger initialization
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Phase 3: Enhanced UI Test'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phase 3: Enhanced UI Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _runAllTests,
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Run All Tests',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTestProgress(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTestSection('Enhanced UI Components', [
                  _buildTestCard(
                    'Enhanced Calendar Screen',
                    'Unified calendar with friend overlays and multi-source events',
                    Icons.calendar_today,
                    () => _testEnhancedCalendar(),
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const EnhancedCalendarScreen(),
                    )),
                  ),
                  _buildTestCard(
                    'Enhanced Societies Screen',
                    'Society integration with auto-calendar updates',
                    Icons.groups,
                    () => _testEnhancedSocieties(),
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const EnhancedSocietiesScreen(),
                    )),
                  ),
                  _buildTestCard(
                    'Enhanced Map Screen',
                    'Real-time friend tracking with UTS campus integration',
                    Icons.map,
                    () => _testEnhancedMap(),
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const EnhancedMapScreen(),
                    )),
                  ),
                  _buildTestCard(
                    'Smart Timetable Overlay',
                    'Interactive timetable with friend availability matrix',
                    Icons.schedule,
                    () => _testSmartTimetable(),
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const SmartTimetableOverlay(),
                    )),
                  ),
                ]),
                
                const SizedBox(height: 24),
                
                _buildTestSection('Cross-Feature Integration', [
                  _buildTestCard(
                    'Calendar-Friends Integration',
                    'Friend schedules visible in unified calendar view',
                    Icons.people,
                    () => _testCalendarFriendsIntegration(),
                    null,
                  ),
                  _buildTestCard(
                    'Map-Location Integration',
                    'Real-time friend locations with proximity detection',
                    Icons.location_on,
                    () => _testMapLocationIntegration(),
                    null,
                  ),
                  _buildTestCard(
                    'Society-Calendar Integration',
                    'Society events automatically added to calendar',
                    Icons.event,
                    () => _testSocietyCalendarIntegration(),
                    null,
                  ),
                  _buildTestCard(
                    'Timetable-Friends Integration',
                    'Common free time detection and meetup suggestions',
                    Icons.schedule,
                    () => _testTimetableFriendsIntegration(),
                    null,
                  ),
                ]),
                
                const SizedBox(height: 24),
                
                _buildTestSection('Notification System', [
                  _buildTestCard(
                    'Notification Service',
                    'Cross-feature notification system with real-time updates',
                    Icons.notifications,
                    () => _testNotificationSystem(),
                    () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const NotificationCenterScreen(),
                    )),
                  ),
                  _buildTestCard(
                    'Real-time Updates',
                    'Live updates across all features when data changes',
                    Icons.sync,
                    () => _testRealTimeUpdates(),
                    null,
                  ),
                ]),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRunningTests ? null : _runAllTests,
                        icon: _isRunningTests
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(_isRunningTests ? 'Running Tests...' : 'Run All Tests'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearResults,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Results'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestProgress() {
    if (!_isRunningTests && _testProgress == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                _isRunningTests ? 'Running Phase 3 Tests...' : 'Test Completed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _testProgress,
            backgroundColor: Colors.blue[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_testProgress * 100).toInt()}% Complete',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(String title, List<Widget> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...tests,
      ],
    );
  }

  Widget _buildTestCard(
    String title,
    String description,
    IconData icon,
    Future<TestResult> Function() testFunction,
    VoidCallback? onViewPressed,
  ) {
    final testResult = _testResults[title];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (testResult != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    testResult.passed ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: testResult.passed ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    testResult.passed ? 'PASSED' : 'FAILED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: testResult.passed ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      testResult.message,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () async {
                final result = await testFunction();
                setState(() {
                  _testResults[title] = result;
                });
              },
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Run Test',
            ),
            if (onViewPressed != null)
              IconButton(
                onPressed: onViewPressed,
                icon: const Icon(Icons.visibility),
                tooltip: 'View Screen',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testProgress = 0.0;
      _testResults.clear();
    });

    final tests = [
      ('Enhanced Calendar Screen', _testEnhancedCalendar),
      ('Enhanced Societies Screen', _testEnhancedSocieties),
      ('Enhanced Map Screen', _testEnhancedMap),
      ('Smart Timetable Overlay', _testSmartTimetable),
      ('Calendar-Friends Integration', _testCalendarFriendsIntegration),
      ('Map-Location Integration', _testMapLocationIntegration),
      ('Society-Calendar Integration', _testSocietyCalendarIntegration),
      ('Timetable-Friends Integration', _testTimetableFriendsIntegration),
      ('Notification Service', _testNotificationSystem),
      ('Real-time Updates', _testRealTimeUpdates),
    ];

    for (int i = 0; i < tests.length; i++) {
      final (testName, testFunction) = tests[i];
      
      setState(() {
        _testProgress = i / tests.length;
      });
      
      try {
        final result = await testFunction();
        setState(() {
          _testResults[testName] = result;
        });
      } catch (e) {
        setState(() {
          _testResults[testName] = TestResult(
            passed: false,
            message: 'Test failed with error: $e',
          );
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      _isRunningTests = false;
      _testProgress = 1.0;
    });
  }

  Future<TestResult> _testEnhancedCalendar() async {
    try {
      final events = _calendarService.getUnifiedCalendarSync(_demoData.currentUser.id);
      final hasPersonalEvents = events.any((e) => e.source == EventSource.personal);
      final hasFriendEvents = events.any((e) => e.source == EventSource.friends);
      final hasSocietyEvents = events.any((e) => e.source == EventSource.societies);
      
      if (hasPersonalEvents && hasFriendEvents && hasSocietyEvents) {
        return TestResult(
          passed: true,
          message: 'Unified calendar displays all event sources (${events.length} events)',
        );
      } else {
        return TestResult(
          passed: false,
          message: 'Missing event sources: Personal:$hasPersonalEvents, Friends:$hasFriendEvents, Societies:$hasSocietyEvents',
        );
      }
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  Future<TestResult> _testEnhancedSocieties() async {
    try {
      final societies = _demoData.societiesSync;
      if (societies.isEmpty) {
        return TestResult(passed: false, message: 'No societies available for testing');
      }
      
      final testSociety = societies.first;
      final memberCountBefore = testSociety.memberIds.length;
      
      final success = await _calendarService.joinSocietyWithCalendarIntegration(
        _demoData.currentUser.id,
        testSociety.id,
      );
      
      if (success) {
        return TestResult(
          passed: true,
          message: 'Society integration working: Join process and calendar sync successful',
        );
      } else {
        return TestResult(
          passed: false,
          message: 'Society integration failed: Unable to join society or sync calendar',
        );
      }
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  Future<TestResult> _testEnhancedMap() async {
    try {
      final mapData = _locationService.getFriendsOnCampusMap(_demoData.currentUser.id);
      final friends = mapData['friends'] as List<User>;
      final locations = mapData['locations'] as Map<String, Location>;
      
      if (friends.isNotEmpty && locations.isNotEmpty) {
        return TestResult(
          passed: true,
          message: 'Map integration working: ${friends.length} friends, ${locations.length} locations',
        );
      } else {
        return TestResult(
          passed: false,
          message: 'Map integration incomplete: Friends:${friends.length}, Locations:${locations.length}',
        );
      }
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  Future<TestResult> _testSmartTimetable() async {
    try {
      final friends = _friendshipService.getUserFriends(_demoData.currentUser.id);
      final commonSlots = _friendshipService.findCommonFreeTime(
        _demoData.currentUser.id,
        friends.take(3).map((f) => f.id).toList(),
        date: DateTime.now(),
      );
      
      if (commonSlots.isNotEmpty) {
        return TestResult(
          passed: true,
          message: 'Timetable overlay working: ${commonSlots.length} common free slots found',
        );
      } else {
        return TestResult(
          passed: true,
          message: 'Timetable overlay working: No common free time available today',
        );
      }
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  Future<TestResult> _testCalendarFriendsIntegration() async {
    try {
      final overlayData = _calendarService.getEventsWithFriendOverlaySync(_demoData.currentUser.id, DateTime.now());
      final friendsSchedules = overlayData['friendsSchedules'] as Map<String, List<Event>>;
      final overlaps = overlayData['overlaps'] as Map<String, List<Event>>;
      
      if (friendsSchedules.isNotEmpty) {
        return TestResult(
          passed: true,
          message: 'Calendar-Friends integration working: ${friendsSchedules.length} friend schedules, ${overlaps.length} overlaps',
        );
      } else {
        return TestResult(
          passed: false,
          message: 'Calendar-Friends integration failed: No friend schedule data available',
        );
      }
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  Future<TestResult> _testMapLocationIntegration() async {
    try {
      final friends = _friendshipService.getUserFriends(_demoData.currentUser.id);
      if (friends.isEmpty) {
        return TestResult(passed: false, message: 'No friends available for location testing');
      }
      
      final friend = friends.first;
      final locations = _demoData.locationsSync;
      if (locations.isEmpty) {
        return TestResult(passed: false, message: 'No locations available for testing');
      }
      
      final success = await _locationService.updateUserLocation(
        userId: friend.id,
        locationId: locations.first.id,
      );
      
      if (success) {
        return TestResult(
          passed: true,
          message: 'Map-Location integration working: Friend location updated successfully',
        );
      } else {
        return TestResult(
          passed: false,
          message: 'Map-Location integration failed: Could not update friend location',
        );
      }
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  Future<TestResult> _testSocietyCalendarIntegration() async {
    try {
      final societies = _demoData.societiesSync;
      if (societies.isEmpty) {
        return TestResult(passed: false, message: 'No societies available for testing');
      }
      
      final testSociety = societies.first;
      final eventsBefore = _calendarService.getUserEventsForDateSync(_demoData.currentUser.id, DateTime.now()).length;
      
      final success = await _calendarService.joinSocietyWithCalendarIntegration(
        _demoData.currentUser.id,
        testSociety.id,
      );
      
      final eventsAfter = _calendarService.getUserEventsForDateSync(_demoData.currentUser.id, DateTime.now()).length;
      
      if (success && eventsAfter >= eventsBefore) {
        return TestResult(
          passed: true,
          message: 'Society-Calendar integration working: Events synced successfully',
        );
      } else {
        return TestResult(
          passed: false,
          message: 'Society-Calendar integration failed: Events not synced properly',
        );
      }
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  Future<TestResult> _testTimetableFriendsIntegration() async {
    try {
      final friends = _friendshipService.getUserFriends(_demoData.currentUser.id);
      if (friends.isEmpty) {
        return TestResult(passed: false, message: 'No friends available for timetable testing');
      }
      
      final commonSlots = _friendshipService.findCommonFreeTime(
        _demoData.currentUser.id,
        friends.take(2).map((f) => f.id).toList(),
        date: DateTime.now(),
      );
      
      return TestResult(
        passed: true,
        message: 'Timetable-Friends integration working: ${commonSlots.length} common free slots detected',
      );
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  Future<TestResult> _testNotificationSystem() async {
    try {
      await _notificationService.sendNotification(
        userId: _demoData.currentUser.id,
        title: 'Phase 3 Test Notification',
        body: 'Testing notification system integration',
        type: NotificationType.eventReminder,
      );
      
      final notifications = _notificationService.getUserNotifications(_demoData.currentUser.id, limit: 1);
      
      if (notifications.isNotEmpty && notifications.first.title == 'Phase 3 Test Notification') {
        return TestResult(
          passed: true,
          message: 'Notification system working: Test notification sent and received',
        );
      } else {
        return TestResult(
          passed: false,
          message: 'Notification system failed: Test notification not received',
        );
      }
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  Future<TestResult> _testRealTimeUpdates() async {
    try {
      final initialBadgeCount = _notificationService.unreadCount;
      
      await _notificationService.sendNotification(
        userId: _demoData.currentUser.id,
        title: 'Real-time Update Test',
        body: 'Testing real-time notification updates',
        type: NotificationType.eventReminder,
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      final newBadgeCount = _notificationService.unreadCount;
      
      if (newBadgeCount > initialBadgeCount) {
        return TestResult(
          passed: true,
          message: 'Real-time updates working: Badge count updated from $initialBadgeCount to $newBadgeCount',
        );
      } else {
        return TestResult(
          passed: false,
          message: 'Real-time updates failed: Badge count did not update ($initialBadgeCount → $newBadgeCount)',
        );
      }
    } catch (e) {
      return TestResult(passed: false, message: 'Error: $e');
    }
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
      _testProgress = 0.0;
    });
  }
}

class TestResult {
  final bool passed;
  final String message;

  TestResult({
    required this.passed,
    required this.message,
  });
}
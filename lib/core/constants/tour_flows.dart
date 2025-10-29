import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'app_colors.dart';

class TourKeys {
  // Tour-active flag to control key creation
  static bool _tourActive = false;

  // Pre-allocated keys that are only assigned when tours are active
  static final Map<String, GlobalKey> _keys = {
    'homeWelcome': GlobalKey(debugLabel: 'home_welcome'),
    'homeHelpIcon': GlobalKey(debugLabel: 'home_helpIcon'),
    'homeTodaySchedule': GlobalKey(debugLabel: 'home_todaySchedule'),
    'homeQuickActions': GlobalKey(debugLabel: 'home_quickActions'),
    'homeReminders': GlobalKey(debugLabel: 'home_reminders'),
    'homeFriendActivity': GlobalKey(debugLabel: 'home_friendActivity'),
    'homeRecentMessages': GlobalKey(debugLabel: 'home_recentMessages'),
    'homeBottomNav': GlobalKey(debugLabel: 'navigation_bottomNav'),
    'calendarHeader': GlobalKey(debugLabel: 'calendar_header'),
    'calendarViewSelector': GlobalKey(debugLabel: 'calendar_viewSelector'),
    'calendarFilters': GlobalKey(debugLabel: 'calendar_filters'),
    'calendarTimetableToggle': GlobalKey(debugLabel: 'calendar_timetableToggle'),
    'calendarEvents': GlobalKey(debugLabel: 'calendar_events'),
    'calendarAddEvent': GlobalKey(debugLabel: 'calendar_addEvent'),
    'societiesHeader': GlobalKey(debugLabel: 'societies_header'),
    'societiesSearch': GlobalKey(debugLabel: 'societies_search'),
    'societiesTabs': GlobalKey(debugLabel: 'societies_tabs'),
    'societiesCards': GlobalKey(debugLabel: 'societies_cards'),
    'friendsHeader': GlobalKey(debugLabel: 'friends_header'),
    'friendsTabs': GlobalKey(debugLabel: 'friends_tabs'),
    'friendsList': GlobalKey(debugLabel: 'friends_list'),
    'friendsAddButton': GlobalKey(debugLabel: 'friends_addButton'),
    'messagesHeader': GlobalKey(debugLabel: 'messages_header'),
    'messagesChatList': GlobalKey(debugLabel: 'messages_chatList'),
    'messagesNewChat': GlobalKey(debugLabel: 'messages_newChat'),
    'messagesSearch': GlobalKey(debugLabel: 'messages_search'),
    'messagesFloatingButton': GlobalKey(debugLabel: 'messages_floatingButton'),
  };

  // Control method - called by TourManager
  static void setTourActive(bool active) {
    _tourActive = active;
    if (!active) {
      print('🔑 Tour keys deactivated');
    } else {
      print('🔑 Tour keys activated');
    }
  }

  // Key getters - only bottomNav is always available (shared across screens)
  // Home screen specific keys are conditional to prevent rebuild issues
  static GlobalKey? get homeWelcomeKey => _tourActive ? _keys['homeWelcome'] : null;
  static GlobalKey? get homeHelpIconKey => _tourActive ? _keys['homeHelpIcon'] : null;
  static GlobalKey? get homeTodayScheduleKey => _tourActive ? _keys['homeTodaySchedule'] : null;
  static GlobalKey? get homeQuickActionsKey => _tourActive ? _keys['homeQuickActions'] : null;
  static GlobalKey? get homeRemindersKey => _tourActive ? _keys['homeReminders'] : null;
  static GlobalKey? get homeFriendActivityKey => _tourActive ? _keys['homeFriendActivity'] : null;
  static GlobalKey? get homeRecentMessagesKey => _tourActive ? _keys['homeRecentMessages'] : null;
  static GlobalKey? get homeBottomNavKey => _keys['homeBottomNav']; // Always available - shared navigation

  static GlobalKey? get calendarHeaderKey => _tourActive ? _keys['calendarHeader'] : null;
  static GlobalKey? get calendarViewSelectorKey => _tourActive ? _keys['calendarViewSelector'] : null;
  static GlobalKey? get calendarFiltersKey => _tourActive ? _keys['calendarFilters'] : null;
  static GlobalKey? get calendarTimetableToggleKey => _tourActive ? _keys['calendarTimetableToggle'] : null;
  static GlobalKey? get calendarEventsKey => _tourActive ? _keys['calendarEvents'] : null;
  static GlobalKey? get calendarAddEventKey => _tourActive ? _keys['calendarAddEvent'] : null;

  static GlobalKey? get societiesHeaderKey => _tourActive ? _keys['societiesHeader'] : null;
  static GlobalKey? get societiesSearchKey => _tourActive ? _keys['societiesSearch'] : null;
  static GlobalKey? get societiesTabsKey => _tourActive ? _keys['societiesTabs'] : null;
  static GlobalKey? get societiesCardsKey => _tourActive ? _keys['societiesCards'] : null;

  static GlobalKey? get friendsHeaderKey => _tourActive ? _keys['friendsHeader'] : null;
  static GlobalKey? get friendsTabsKey => _tourActive ? _keys['friendsTabs'] : null;
  static GlobalKey? get friendsListKey => _tourActive ? _keys['friendsList'] : null;
  static GlobalKey? get friendsAddButtonKey => _tourActive ? _keys['friendsAddButton'] : null;

  static GlobalKey? get messagesHeaderKey => _tourActive ? _keys['messagesHeader'] : null;
  static GlobalKey? get messagesChatListKey => _tourActive ? _keys['messagesChatList'] : null;
  static GlobalKey? get messagesNewChatKey => _tourActive ? _keys['messagesNewChat'] : null;
  static GlobalKey? get messagesSearchKey => _tourActive ? _keys['messagesSearch'] : null;
  static GlobalKey? get messagesFloatingButtonKey => _tourActive ? _keys['messagesFloatingButton'] : null;


  // Method to get actual keys for tour flows (when we know tours are active)
  static GlobalKey? getKeyForTour(String keyName) {
    if (!_tourActive) {
      print('❌ Tour Error: Cannot get key $keyName - tours not active');
      return null;
    }

    if (!_keys.containsKey(keyName)) {
      print('❌ Tour Error: Key $keyName not found in tour keys');
      return null;
    }

    final key = _keys[keyName]!;

    // Validate that the key is actually attached to a widget in the render tree
    if (key.currentContext == null) {
      print('❌ Tour Error: Key $keyName has no context (widget not rendered)');
      return null;
    }

    if (key.currentContext?.findRenderObject() == null) {
      print('❌ Tour Error: Key $keyName has no render object (widget not in render tree)');
      return null;
    }

    // Additional check for widget mounted state
    if (!key.currentContext!.mounted) {
      print('❌ Tour Error: Key $keyName context not mounted');
      return null;
    }

    print('✅ Tour: Key $keyName validated successfully');
    return key;
  }

  // Debug method to check status of all keys
  static void debugKeyStatus() {
    if (!_tourActive) {
      print('🔍 Tour Debug: Tours not active, cannot check keys');
      return;
    }

    print('🔍 Tour Debug: Checking status of ${_keys.length} keys:');
    _keys.forEach((name, key) {
      final hasContext = key.currentContext != null;
      final hasRenderObject = hasContext ? key.currentContext?.findRenderObject() != null : false;
      final isMounted = hasContext ? key.currentContext!.mounted : false;

      print('   $name: context=$hasContext, renderObject=$hasRenderObject, mounted=$isMounted');
    });
  }

  // For backward compatibility - convert property access to getKeyForTour calls
  static GlobalKey? getKeyByName(String methodName) {
    final keyMap = {
      'calendarHeaderKey': 'calendarHeader',
      'calendarViewSelectorKey': 'calendarViewSelector',
      'calendarFiltersKey': 'calendarFilters',
      'calendarAddEventKey': 'calendarAddEvent',
      'societiesHeaderKey': 'societiesHeader',
      'societiesSearchKey': 'societiesSearch',
      'societiesTabsKey': 'societiesTabs',
      'societiesCardsKey': 'societiesCards',
      'friendsHeaderKey': 'friendsHeader',
      'friendsTabsKey': 'friendsTabs',
      'friendsListKey': 'friendsList',
      'messagesHeaderKey': 'messagesHeader',
      'messagesNewChatKey': 'messagesNewChat',
      'messagesChatListKey': 'messagesChatList',
    };

    final keyName = keyMap[methodName];
    return keyName != null && _tourActive ? _keys[keyName] : null;
  }

  // Method to reset all keys when tours end
  static void resetAllKeys() {
    setTourActive(false);
  }

  // Debug method to list all active keys
  static void printActiveKeys() {
    if (_tourActive) {
      print('🔑 Tour keys are active: ${_keys.keys.join(', ')}');
    } else {
      print('🔑 Tour keys are inactive');
    }
  }
}

class TourFlows {
  // Helper method to safely create TargetFocus with key validation
  static TargetFocus? _createTargetFocus({
    required String identify,
    required String keyName,
    required Alignment alignSkip,
    required List<TargetContent> contents,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    double radius = 8,
    bool enableOverlayTab = true,
  }) {
    final key = TourKeys.getKeyForTour(keyName);
    if (key == null) {
      print('⚠️ Tour: Skipping target $identify - key $keyName not available');
      return null;
    }

    return TargetFocus(
      identify: identify,
      keyTarget: key,
      alignSkip: alignSkip,
      enableOverlayTab: enableOverlayTab,
      contents: contents,
      shape: shape,
      radius: radius,
    );
  }

  // Helper method to filter out null targets
  static List<TargetFocus> _filterValidTargets(List<TargetFocus?> targets) {
    final validTargets = targets.where((target) => target != null).cast<TargetFocus>().toList();
    print('🎯 Tour: Created ${validTargets.length} valid targets out of ${targets.length} total');
    return validTargets;
  }

  // Home Screen Tour Flow
  static List<TargetFocus> getHomeScreenTargets() {
    final targets = [
      _createTargetFocus(
        identify: "home_welcome",
        keyName: 'homeWelcome',
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome to UniConnect! 🎉",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "This is your personalized home dashboard where you can see today's schedule, quick actions, and stay connected with your university community.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      _createTargetFocus(
        identify: "home_help_icon",
        keyName: 'homeHelpIcon',
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Help Always Available ℹ️",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tap this help icon anytime to access interactive tours, guides, or restart this walkthrough.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "home_today_schedule",
        keyTarget: TourKeys.getKeyForTour('homeTodaySchedule'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Schedule 📅",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "See your upcoming classes and events at a glance. Events are color-coded: blue for classes, green for societies.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
      TargetFocus(
        identify: "home_quick_actions",
        keyTarget: TourKeys.getKeyForTour('homeQuickActions'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quick Actions ⚡",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Fast access to key features:\n• Timetable: View your class schedule\n• Find Friends: Discover classmates\n• Society Events: Browse activities\n• Study Groups: Join collaborations",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Try tapping 'Timetable' to see your schedule!",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
      TargetFocus(
        identify: "home_bottom_nav",
        keyTarget: TourKeys.getKeyForTour('homeBottomNav'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Navigation Hub 🧭",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Use these tabs to explore UniConnect:\n• Home (Purple) - Your dashboard\n• Calendar (Blue) - Schedule & events\n• Societies (Green) - Clubs & activities\n• Friends (Bright Green) - Social connections\n• Messages (Bright Green) - Chat & communication",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Next: Let's explore your Calendar!",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
    ];

    return _filterValidTargets(targets);
  }

  // Calendar Screen Tour Flow
  static List<TargetFocus> getCalendarScreenTargets() {
    final targets = [
      _createTargetFocus(
        identify: "calendar_welcome",
        keyName: 'calendarHeader',
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Calendar 📅",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "This is your personalized calendar showing classes, events, and activities. Everything you need to stay organized!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      TargetFocus(
        identify: "calendar_views",
        keyTarget: TourKeys.getKeyForTour('calendarViewSelector'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "View Options 👀",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Switch between Day, Week, and Month views to see your schedule the way you prefer. Try tapping different views!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
      TargetFocus(
        identify: "calendar_filters",
        keyTarget: TourKeys.getKeyForTour('calendarFilters'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Smart Filters 🎯",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Filter your calendar by event type:\n• Academic - Classes and coursework\n• Social - Social events and activities\n• Society - Club events\n• Study Groups - Collaborative sessions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
      TargetFocus(
        identify: "calendar_add_event",
        keyTarget: TourKeys.getKeyForTour('calendarAddEvent'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create Events ✨",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Add your own events, study sessions, or reminders. You can even invite friends to join your events!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Next: Let's check out Societies!",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.Circle,
        radius: 8,
      ),
    ];

    return _filterValidTargets(targets);
  }

  // Societies Screen Tour Flow
  static List<TargetFocus> getSocietiesScreenTargets() {
    final targets = [
      _createTargetFocus(
        identify: "societies_welcome",
        keyName: 'societiesHeader',
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Societies & Events 🏛️",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Discover clubs, join societies, and find events that match your interests. This is where you connect with like-minded students!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      TargetFocus(
        identify: "societies_search",
        keyTarget: TourKeys.getKeyForTour('societiesSearch'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Find Your Community 🔍",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Search for societies by name or browse by category (Technology, Sports, Creative, etc.). Use filters to find exactly what you're looking for!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
      TargetFocus(
        identify: "societies_tabs",
        keyTarget: TourKeys.getKeyForTour('societiesTabs'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Explore Society Sections 📂",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• My Societies - Clubs you've joined\n• Discover - Find new societies\n• Events - All society events in one place",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Try switching between tabs to explore!",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
      TargetFocus(
        identify: "societies_cards",
        keyTarget: TourKeys.getKeyForTour('societiesCards'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Join & Explore 🚀",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tap society cards to view details, see member counts, and join clubs that interest you. Get notified about society events automatically!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Next: Let's connect with Friends!",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
    ];

    return _filterValidTargets(targets);
  }

  // Friends Screen Tour Flow
  static List<TargetFocus> getFriendsScreenTargets() {
    final targets = [
      _createTargetFocus(
        identify: "friends_welcome",
        keyName: 'friendsHeader',
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Friends & Social 👥",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Connect with classmates, find study partners, and build your university social network. See who's on campus and meet up between classes!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      TargetFocus(
        identify: "friends_tabs",
        keyTarget: TourKeys.getKeyForTour('friendsTabs'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Friend Features 🌟",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Friends - Your connections with online status\n• On Campus - Interactive map showing friend locations\n• Requests - Manage friend requests\n• Suggestions - Discover new connections",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
      TargetFocus(
        identify: "friends_list",
        keyTarget: TourKeys.getKeyForTour('friendsList'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Stay Connected 💚",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Green status means friends are active on campus - perfect for meeting up! Tap profiles for quick actions like messaging or viewing their schedule.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Next: Let's check out Messages!",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
    ];

    return _filterValidTargets(targets);
  }

  // Messages Screen Tour Flow
  static List<TargetFocus> getMessagesScreenTargets() {
    final targets = [
      _createTargetFocus(
        identify: "messages_welcome",
        keyName: 'messagesHeader',
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Messages & Chat 💬",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Stay connected with friends, coordinate study sessions, and participate in society discussions. All your conversations in one place!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      TargetFocus(
        identify: "messages_new_chat",
        keyTarget: TourKeys.getKeyForTour('messagesNewChat'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Start Conversations ✨",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Create direct messages with friends or start group chats for study sessions, project work, or society discussions.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.Circle,
        radius: 8,
      ),
      TargetFocus(
        identify: "messages_chat_list",
        keyTarget: TourKeys.getKeyForTour('messagesChatList'),
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "All Conversations 📱",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your messages are organized by recent activity. Unread message badges help you stay on top of important conversations.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "🎉 Congratulations! You've completed the UniConnect tour.",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "You're now ready to explore and connect with your university community!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 8,
      ),
    ];

    return _filterValidTargets(targets);
  }
}
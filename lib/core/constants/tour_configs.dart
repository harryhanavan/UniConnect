import 'package:flutter/material.dart';
import 'tour_flows.dart';

enum TourSection {
  home,
  calendar,
  societies,
  friends,
  messages,
}

class TourStep {
  final String id;
  final GlobalKey globalKey;
  final String title;
  final String description;
  final String? actionText;
  final ShapeBorder? shapeBorder;

  TourStep({
    required this.id,
    required this.globalKey,
    required this.title,
    required this.description,
    this.actionText,
    this.shapeBorder,
  });
}

class TourSectionConfig {
  final TourSection section;
  final List<TourStep> steps;
  final String title;
  final String description;

  TourSectionConfig({
    required this.section,
    required this.steps,
    required this.title,
    required this.description,
  });
}

class TourConfigs {
  // Note: GlobalKeys for tour elements are now managed by TourKeys class in tour_flows.dart
  // This provides better control over key lifecycle and prevents duplication conflicts

  // Global keys for calendar screen tour-able elements
  static final GlobalKey calendarViewSelectorKey = GlobalKey();
  static final GlobalKey calendarFiltersKey = GlobalKey();
  static final GlobalKey calendarTimetableToggleKey = GlobalKey();
  static final GlobalKey calendarEventsKey = GlobalKey();
  static final GlobalKey calendarAddEventKey = GlobalKey();

  // Global keys for societies screen tour-able elements
  static final GlobalKey societiesTabsKey = GlobalKey();
  static final GlobalKey societiesSearchKey = GlobalKey();
  static final GlobalKey societiesCategoriesKey = GlobalKey();
  static final GlobalKey societiesCardsKey = GlobalKey();

  // Global keys for friends screen tour-able elements
  static final GlobalKey friendsListKey = GlobalKey();
  static final GlobalKey friendsFindKey = GlobalKey();
  static final GlobalKey friendsRequestsKey = GlobalKey();
  static final GlobalKey friendsMapKey = GlobalKey();

  // Global keys for messages screen tour-able elements
  static final GlobalKey messagesChatListKey = GlobalKey();
  static final GlobalKey messagesSearchKey = GlobalKey();
  static final GlobalKey messagesNewChatKey = GlobalKey();

  // Tour step configurations
  static final Map<TourSection, TourSectionConfig> _configs = {
    TourSection.home: TourSectionConfig(
      section: TourSection.home,
      title: 'Home Screen Tour',
      description: 'Discover your personalized dashboard and quick actions',
      steps: [
        TourStep(
          id: 'home_welcome',
          globalKey: homeWelcomeKey,
          title: 'Welcome to UniConnect!',
          description: 'Your personalized home screen shows today\'s schedule, quick actions, and recent activity.',
          actionText: 'Next',
        ),
        TourStep(
          id: 'home_help_icon',
          globalKey: homeHelpIconKey,
          title: 'Need Help?',
          description: 'Tap this help icon anytime to restart tours or get help with specific features.',
          actionText: 'Got it',
          shapeBorder: const CircleBorder(),
        ),
        TourStep(
          id: 'home_today_schedule',
          globalKey: homeTodayScheduleKey,
          title: 'Today\'s Schedule',
          description: 'See your upcoming classes and events at a glance. Tap any event for more details.',
          actionText: 'Next',
        ),
        TourStep(
          id: 'home_quick_actions',
          globalKey: homeQuickActionsKey,
          title: 'Quick Actions',
          description: 'Fast access to your most-used features: view timetable, find friends, browse society events, and join study groups.',
          actionText: 'Next',
        ),
        TourStep(
          id: 'home_friend_activity',
          globalKey: homeFriendActivityKey,
          title: 'Friend Activity',
          description: 'Stay connected by seeing what your friends are up to around campus.',
          actionText: 'Next',
        ),
        TourStep(
          id: 'home_recent_messages',
          globalKey: homeRecentMessagesKey,
          title: 'Recent Messages',
          description: 'Quick preview of your latest conversations. Tap to open chats or view all messages.',
          actionText: 'Next',
        ),
        TourStep(
          id: 'home_bottom_nav',
          globalKey: TourKeys.homeBottomNavKey,
          title: 'Navigation',
          description: 'Use the bottom navigation to explore: Home, Calendar, Societies, Friends, and Messages.',
          actionText: 'Continue to Calendar',
        ),
      ],
    ),
    TourSection.calendar: TourSectionConfig(
      section: TourSection.calendar,
      title: 'Calendar & Timetable Tour',
      description: 'Master your schedule with powerful calendar features',
      steps: [
        TourStep(
          id: 'calendar_main',
          globalKey: calendarEventsKey,
          title: 'Your Calendar',
          description: 'Your personalized calendar with events, classes, and activities. Use the filters and views to organize your schedule the way you prefer.',
          actionText: 'Next',
        ),
        TourStep(
          id: 'calendar_add_event',
          globalKey: calendarAddEventKey,
          title: 'Create Events',
          description: 'Add your own events, study sessions, or reminders. You can also invite friends to join.',
          actionText: 'Continue to Societies',
        ),
      ],
    ),
    TourSection.societies: TourSectionConfig(
      section: TourSection.societies,
      title: 'Societies & Events Tour',
      description: 'Discover clubs, societies, and campus events',
      steps: [
        TourStep(
          id: 'societies_hub',
          globalKey: societiesCardsKey,
          title: 'Societies Hub',
          description: 'Explore societies through the tabs: your memberships, discover new ones, or browse events. Use search and filters to find specific clubs.',
          actionText: 'Continue to Friends',
        ),
      ],
    ),
    TourSection.friends: TourSectionConfig(
      section: TourSection.friends,
      title: 'Friends & Social Tour',
      description: 'Connect with classmates and build your university network',
      steps: [
        TourStep(
          id: 'friends_features',
          globalKey: friendsListKey,
          title: 'Friends Features',
          description: 'Browse your friends, see who\'s on campus, manage requests, and discover new connections through the tabs above.',
          actionText: 'Continue to Messages',
        ),
      ],
    ),
    TourSection.messages: TourSectionConfig(
      section: TourSection.messages,
      title: 'Messages & Chat Tour',
      description: 'Stay connected with friends and study groups',
      steps: [
        TourStep(
          id: 'messages_hub',
          globalKey: messagesChatListKey,
          title: 'Messages Hub',
          description: 'All your conversations in one place: direct messages with friends and group chats. Use the buttons above to search or start new chats.',
          actionText: 'Tour Complete!',
        ),
      ],
    ),
  };

  // Get configuration for a specific section
  static TourSectionConfig getSectionConfig(TourSection section) {
    return _configs[section] ?? _configs[TourSection.home]!;
  }

  // Get all available sections
  static List<TourSection> getAllSections() {
    return TourSection.values;
  }

  // Get all steps across all sections (for main tour)
  static List<TourStep> getAllSteps() {
    final List<TourStep> allSteps = [];
    for (final section in TourSection.values) {
      allSteps.addAll(_configs[section]?.steps ?? []);
    }
    return allSteps;
  }

  // Check if a global key has been assigned to showcase widgets
  static bool isKeyAssigned(GlobalKey key) {
    return getAllSteps().any((step) => step.globalKey == key);
  }
}
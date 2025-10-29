import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/tour_configs.dart';

class TourService {
  static final TourService _instance = TourService._internal();
  static TourService get instance => _instance;
  TourService._internal();

  // Tour completion tracking
  static const String _tourCompletedKey = 'tour_completed';
  static const String _homeScreenTourKey = 'home_screen_tour_completed';
  static const String _calendarTourKey = 'calendar_tour_completed';
  static const String _societiesTourKey = 'societies_tour_completed';
  static const String _friendsTourKey = 'friends_tour_completed';
  static const String _messagesTourKey = 'messages_tour_completed';
  static const String _firstLaunchKey = 'is_first_launch';

  // Check if this is the first time the user opens the app
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_firstLaunchKey) ?? true;
    if (isFirst) {
      await prefs.setBool(_firstLaunchKey, false);
    }
    return isFirst;
  }

  // Check if the main tour has been completed
  Future<bool> isMainTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tourCompletedKey) ?? false;
  }

  // Mark main tour as completed
  Future<void> markMainTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, true);
  }

  // Check if a specific section tour has been completed
  Future<bool> isSectionTourCompleted(TourSection section) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getSectionKey(section);
    return prefs.getBool(key) ?? false;
  }

  // Mark a specific section tour as completed
  Future<void> markSectionTourCompleted(TourSection section) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getSectionKey(section);
    await prefs.setBool(key, true);
  }

  // Reset all tour progress (for testing or user preference)
  Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, false);
    await prefs.setBool(_homeScreenTourKey, false);
    await prefs.setBool(_calendarTourKey, false);
    await prefs.setBool(_societiesTourKey, false);
    await prefs.setBool(_friendsTourKey, false);
    await prefs.setBool(_messagesTourKey, false);
  }

  // Get the appropriate key for a tour section
  String _getSectionKey(TourSection section) {
    switch (section) {
      case TourSection.home:
        return _homeScreenTourKey;
      case TourSection.calendar:
        return _calendarTourKey;
      case TourSection.societies:
        return _societiesTourKey;
      case TourSection.friends:
        return _friendsTourKey;
      case TourSection.messages:
        return _messagesTourKey;
    }
  }

  // Start the main comprehensive tour
  Future<void> startMainTour(BuildContext context) async {
    if (!context.mounted) return;

    // Show comprehensive guide dialog
    await _showFeatureGuideDialog(context, 'Complete App Tour', _getComprehensiveGuide());
    await markMainTourCompleted();
  }

  // Start a specific section tour
  Future<void> startSectionTour(BuildContext context, TourSection section) async {
    if (!context.mounted) return;

    final guide = _getSectionGuide(section);
    final sectionName = _getSectionName(section);

    await _showFeatureGuideDialog(context, sectionName, guide);
    await markSectionTourCompleted(section);
  }

  // Show tour menu dialog
  Future<void> showTourMenu(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App Tour'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a tour to get started or refresh your knowledge:'),
              const SizedBox(height: 16),
              _buildTourMenuButton(
                context,
                'Complete App Tour',
                'Full walkthrough of all features',
                Icons.tour,
                () => startMainTour(context),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Home Screen',
                'Quick actions and overview',
                Icons.home,
                () => startSectionTour(context, TourSection.home),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Calendar & Timetable',
                'Events and scheduling',
                Icons.calendar_today,
                () => startSectionTour(context, TourSection.calendar),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Societies & Events',
                'Clubs and activities',
                Icons.groups,
                () => startSectionTour(context, TourSection.societies),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Friends & Social',
                'Connect with classmates',
                Icons.people,
                () => startSectionTour(context, TourSection.friends),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Messages & Chat',
                'Communication features',
                Icons.message,
                () => startSectionTour(context, TourSection.messages),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTourMenuButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop(); // Close dialog
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Check if user should see tour prompt on app launch
  Future<bool> shouldShowTourPrompt() async {
    final isFirst = await isFirstLaunch();
    final isCompleted = await isMainTourCompleted();
    return isFirst && !isCompleted;
  }

  // Show welcome tour prompt for first-time users
  Future<void> showWelcomeTourPrompt(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to UniConnect!'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Would you like a quick tour to discover all the features that will help you connect with your university community?',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                '📅 Manage your schedule\n'
                '👥 Find and connect with friends\n'
                '🏛️ Join societies and events\n'
                '💬 Stay connected with messages',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                markMainTourCompleted(); // Skip tour
              },
              child: const Text('Skip for now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                startMainTour(context);
              },
              child: const Text('Start Tour'),
            ),
          ],
        );
      },
    );
  }

  // Show a feature guide dialog with scrollable content
  Future<void> _showFeatureGuideDialog(BuildContext context, String title, String content) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  // Get comprehensive guide text
  String _getComprehensiveGuide() {
    return '''
Welcome to UniConnect! 🎉

HOME SCREEN
• View today's schedule with upcoming classes and events
• Use Quick Actions for fast access to key features
• See friend activity and recent messages at a glance
• Access this help anytime via the ? icon in the header

CALENDAR & TIMETABLE
• Switch between Day, Week, and Month views
• Filter events by type (Academic, Social, Society, Study Groups)
• Toggle between calendar and compact timetable view
• Create your own events and invite friends

SOCIETIES & EVENTS
• Browse your joined societies in "My Societies"
• Discover new clubs in the "Discover" tab
• Find events across all societies in "Events"
• Search by name or filter by category

FRIENDS & SOCIAL
• View your friends list with online status
• See who's on campus with the map view
• Manage friend requests and suggestions
• Find new connections through mutual friends

MESSAGES & CHAT
• All conversations in one place
• Direct messages and group chats
• Search conversations and start new chats
• Stay connected with study groups and societies

Tap the help icon (?) anytime for section-specific guides!
    ''';
  }

  // Get section-specific guide text
  String _getSectionGuide(TourSection section) {
    switch (section) {
      case TourSection.home:
        return '''
HOME SCREEN GUIDE 🏠

TODAY'S SCHEDULE
• See your next class and upcoming events
• Color-coded by type (blue for classes, green for societies)
• Tap events for more details

QUICK ACTIONS
• Timetable: View your class schedule
• Find Friends: Discover classmates
• Society Events: Browse club activities
• Study Groups: Join collaborative sessions

FRIEND ACTIVITY
• See what friends are doing on campus
• Online status indicators
• Tap "View All" to see your full friends list

RECENT MESSAGES
• Preview of latest conversations
• Unread message counts
• Tap to open chats or view all messages

NAVIGATION
• Use bottom tabs to explore the app
• Purple = Home, Blue = Calendar, Green = Societies, Bright Green = Friends/Messages
        ''';

      case TourSection.calendar:
        return '''
CALENDAR & TIMETABLE GUIDE 📅

VIEW OPTIONS
• Day: Focus on today's schedule
• Week: See your weekly overview
• Month: Plan ahead with monthly view

FILTERS
• All: Show everything
• Academic: Classes and coursework only
• Social: Social events and activities
• Society: Club and organization events
• Study Groups: Collaborative sessions

TIMETABLE MODE
• Toggle between calendar and timetable view
• Timetable shows compact weekly schedule
• Perfect for seeing class patterns

FEATURES
• Tap events for details and RSVP
• Color coding helps identify event types
• Create new events with the + button
• Invite friends to your events
        ''';

      case TourSection.societies:
        return '''
SOCIETIES & EVENTS GUIDE 🏛️

MY SOCIETIES TAB
• Societies you've joined
• Quick access to society events
• Membership status and activities

DISCOVER TAB
• Find new societies to join
• Browse by category (Tech, Sports, etc.)
• See member counts and descriptions

EVENTS TAB
• All society events in one place
• Filter by society or event type
• RSVP and add to your calendar

SEARCH & FILTERS
• Search societies by name
• Filter by category for easier browsing
• Use both to find exactly what you want

JOINING SOCIETIES
• Tap society cards to view details
• Join with a simple button tap
• Get notified about society events
        ''';

      case TourSection.friends:
        return '''
FRIENDS & SOCIAL GUIDE 👥

FRIENDS TAB
• Your friends list with online status
• Green = active on campus
• Tap for profiles and quick actions

ON CAMPUS TAB
• Interactive campus map
• See friends' locations (with permission)
• Great for meeting up between classes

REQUESTS TAB
• Incoming friend requests
• Outgoing requests you've sent
• Accept, decline, or cancel requests

SUGGESTIONS TAB
• Discover new friends
• Based on mutual connections
• Classes and interests in common
• QR code scanning for in-person meetings

PRIVACY
• Control location sharing
• Manage who can find you
• Set your campus status
        ''';

      case TourSection.messages:
        return '''
MESSAGES & CHAT GUIDE 💬

YOUR CONVERSATIONS
• Direct messages with friends
• Group chats for study sessions
• Society discussions and announcements
• Organized by most recent activity

CHAT FEATURES
• Text messages and media sharing
• Real-time message delivery
• Unread message indicators
• Message search functionality

STARTING CHATS
• New chat button (✏️) in header
• Search button (🔍) to find conversations
• Create group chats for projects
• Add friends to existing groups

NOTIFICATIONS
• Badge counts on unread messages
• Push notifications for new messages
• Mark conversations as read/unread
• Customize notification preferences
        ''';
    }
  }

  // Get user-friendly section names
  String _getSectionName(TourSection section) {
    switch (section) {
      case TourSection.home:
        return 'Home Screen Guide';
      case TourSection.calendar:
        return 'Calendar & Timetable Guide';
      case TourSection.societies:
        return 'Societies & Events Guide';
      case TourSection.friends:
        return 'Friends & Social Guide';
      case TourSection.messages:
        return 'Messages & Chat Guide';
    }
  }
}
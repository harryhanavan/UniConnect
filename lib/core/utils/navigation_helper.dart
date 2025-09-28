import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../../shared/models/event_enums.dart';
import '../../features/calendar/enhanced_calendar_screen.dart';
import '../../shared/widgets/nav_wrapper.dart';

/// Navigation helper to handle different navigation patterns in the app
class NavigationHelper {
  /// Navigate to a main app tab by index
  /// This preserves the bottom navigation bar
  static void navigateToTab(BuildContext context, int tabIndex) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setNavIndex(tabIndex);
  }

  /// Navigate to a detail screen with optional bottom navigation persistence
  ///
  /// [context] - Build context for navigation
  /// [screen] - Widget to navigate to
  /// [keepBottomNav] - Whether to maintain bottom navigation (default: false)
  /// [title] - Optional title for screens that need custom app bar
  /// [appBarColor] - Optional app bar background color
  /// [appBarForegroundColor] - Optional app bar foreground color
  /// [bottom] - Optional bottom widget for app bar (like TabBar)
  /// [actions] - Optional action buttons for app bar
  static Future<T?> navigateToScreen<T>(
    BuildContext context,
    Widget screen, {
    bool keepBottomNav = false,
    String? title,
    Color? appBarColor,
    Color? appBarForegroundColor,
    PreferredSizeWidget? bottom,
    List<Widget>? actions,
  }) {
    if (keepBottomNav) {
      // Wrap the screen in NavWrapper to preserve bottom navigation
      return Navigator.push<T>(
        context,
        MaterialPageRoute(
          builder: (context) => NavWrapper(
            title: title,
            appBarColor: appBarColor,
            appBarForegroundColor: appBarForegroundColor,
            bottom: bottom,
            actions: actions,
            child: screen,
          ),
        ),
      );
    } else {
      // Standard navigation without bottom nav
      return Navigator.push<T>(
        context,
        MaterialPageRoute(
          builder: (context) => screen,
        ),
      );
    }
  }

  /// Navigate back to previous screen
  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Replace current screen with new screen
  static Future<T?> replaceScreen<T>(
    BuildContext context,
    Widget screen,
  ) {
    return Navigator.pushReplacement<T, void>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Clear navigation stack and go to specific tab
  static void resetToTab(BuildContext context, int tabIndex) {
    // Pop all screens in the stack
    Navigator.popUntil(context, (route) => route.isFirst);

    // Then navigate to the desired tab
    navigateToTab(context, tabIndex);
  }

  /// Smart navigation to Calendar tab with specific parameters
  static void navigateToCalendarWithParams(
    BuildContext context, {
    CalendarFilter? initialFilter,
    CalendarView? initialView,
    bool? initialUseTimetableView,
  }) {
    print('🧭 NavigationHelper: Setting calendar params - filter: $initialFilter, view: $initialView, timetable: $initialUseTimetableView');
    final appState = Provider.of<AppState>(context, listen: false);
    final params = CalendarTabParams(
      initialFilter: initialFilter,
      initialView: initialView,
      initialUseTimetableView: initialUseTimetableView,
    );
    appState.setNavIndexWithCalendarParams(calendarTab, params);
    print('🧭 NavigationHelper: Calendar params set, navigating to tab $calendarTab');
  }

  /// Smart navigation to Friends tab with specific parameters
  static void navigateToFriendsWithParams(
    BuildContext context, {
    int? initialTabIndex,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    final params = FriendsTabParams(initialTabIndex: initialTabIndex);
    appState.setNavIndexWithFriendsParams(friendsTab, params);
  }

  /// Smart navigation to Societies tab with specific parameters
  static void navigateToSocietiesWithParams(
    BuildContext context, {
    int? initialTabIndex,
  }) {
    final appState = Provider.of<AppState>(context, listen: false);
    final params = SocietiesTabParams(initialTabIndex: initialTabIndex);
    appState.setNavIndexWithSocietiesParams(societiesTab, params);
  }

  /// Navigation constants for main app tabs
  static const int homeTab = 0;
  static const int calendarTab = 1;
  static const int societiesTab = 2;
  static const int friendsTab = 3;
  static const int chatTab = 4;
}

/// Extension methods for convenient navigation
extension NavigationExtension on BuildContext {
  /// Quick access to navigation helper methods
  void navigateToTab(int tabIndex) => NavigationHelper.navigateToTab(this, tabIndex);

  Future<T?> navigateToScreen<T>(
    Widget screen, {
    bool keepBottomNav = false,
    String? title,
    Color? appBarColor,
    Color? appBarForegroundColor,
    PreferredSizeWidget? bottom,
    List<Widget>? actions,
  }) => NavigationHelper.navigateToScreen<T>(
    this,
    screen,
    keepBottomNav: keepBottomNav,
    title: title,
    appBarColor: appBarColor,
    appBarForegroundColor: appBarForegroundColor,
    bottom: bottom,
    actions: actions,
  );

  void goBack() => NavigationHelper.goBack(this);

  /// Smart navigation extension methods
  void navigateToCalendarWithParams({
    CalendarFilter? initialFilter,
    CalendarView? initialView,
    bool? initialUseTimetableView,
  }) => NavigationHelper.navigateToCalendarWithParams(
    this,
    initialFilter: initialFilter,
    initialView: initialView,
    initialUseTimetableView: initialUseTimetableView,
  );

  void navigateToFriendsWithParams({int? initialTabIndex}) =>
      NavigationHelper.navigateToFriendsWithParams(this, initialTabIndex: initialTabIndex);

  void navigateToSocietiesWithParams({int? initialTabIndex}) =>
      NavigationHelper.navigateToSocietiesWithParams(this, initialTabIndex: initialTabIndex);
}
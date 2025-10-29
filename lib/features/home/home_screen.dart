import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/app_state.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/tour_manager.dart';
import '../../core/constants/tour_flows.dart';
import '../../shared/models/event.dart';
import '../../shared/models/user.dart';
import '../../shared/models/chat_message.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_screen.dart';
import '../study_groups/study_groups_with_nav_screen.dart';
import '../../core/utils/navigation_helper.dart';
import '../../shared/widgets/reminder_widgets.dart';
import '../../core/services/notification_service.dart';
import '../notifications/notification_center_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final demoData = DemoDataManager.instance;
  bool _shouldStartPendingTour = false;

  // Add a rebuild trigger for when tour keys become active
  bool _tourKeysActive = false;

  // Notification tracking
  final NotificationService _notificationService = NotificationService();
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    // Check if there's a pending tour that should start when widgets are ready
    _shouldStartPendingTour = TourManager.instance.hasPendingTour();

    // Setup notification listeners
    _setupNotificationListeners();

    // Check if user should see the welcome tour prompt
    // Increased delay to ensure all widgets are fully rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _checkForWelcomeTour();
          // Also check for any tours that might have been queued during initialization
          _checkForNewlyQueuedTours();
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setupNotificationListeners() {
    // Listen to badge count changes
    _notificationService.badgeCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    });

    // Set initial count
    _unreadNotificationCount = _notificationService.unreadCount;
  }

  // Check if a tour was queued after the initial build
  void _checkForNewlyQueuedTours() {
    if (!mounted) return;

    final hasPendingTour = TourManager.instance.hasPendingTour();
    if (hasPendingTour && !_shouldStartPendingTour) {
      print('🔄 Tour: Detected newly queued tour, starting widget readiness check...');
      _shouldStartPendingTour = true;
      // Start the tour with simple timing
      _startPendingTour();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for pending tours AFTER this build completes
    _checkForPendingToursAfterBuild();

    // Check if tour keys just became active and trigger rebuild if needed
    final keysActive = TourKeys.homeWelcomeKey != null;
    if (keysActive != _tourKeysActive) {
      _tourKeysActive = keysActive;
      if (keysActive) {
        print('🔄 Tour: Tour keys became active, scheduling rebuild...');
        // Schedule a rebuild to apply the keys
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Use AppState.currentUser to get the correct user (new user or demo user)
        final currentUser = appState.currentUser;
        final firstName = currentUser.name.split(' ').first;
    final upcomingEvents = appState.getEventsByDate(DateTime.now());

    // Sort events by start time to get the chronologically next events
    upcomingEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Get the next few events today, filtering by type for display variety
    final nextClass = upcomingEvents.where((e) => e.type == EventType.class_).firstOrNull;
    final nextSocietyEvent = upcomingEvents.where((e) => e.type == EventType.society).firstOrNull;
    final nextAssignment = upcomingEvents.where((e) => e.type == EventType.assignment).firstOrNull;
    final nextPersonalEvent = upcomingEvents.where((e) => e.type == EventType.personal).firstOrNull;

    // Choose the most relevant events to display (prioritize time-sensitive ones)
    final nextEvent = nextAssignment ?? nextSocietyEvent ?? nextPersonalEvent;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: Column(
        children: [
          // Header Section
          _buildHeader(context, firstName, currentUser),

          // Content
          Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Schedule Section
                    Container(
                      key: TourKeys.homeTodayScheduleKey,
                      child: _buildTodaysScheduleSection(nextClass, nextEvent),
                    ),

                    const SizedBox(height: 20),

                    // Quick Actions
                    Container(
                      key: TourKeys.homeQuickActionsKey,
                      child: _buildModernQuickActions(context),
                    ),

                    const SizedBox(height: 20),

                    // Reminders & Notifications Section
                    Container(
                      key: TourKeys.homeRemindersKey,
                      child: const HomeReminderSection(),
                    ),

                    const SizedBox(height: 20),

                    // Friend Activity
                    Container(
                      key: TourKeys.homeFriendActivityKey,
                      child: _buildFriendActivityCard(appState.friends),
                    ),

                    const SizedBox(height: 20),

                    // Recent Messages
                    Container(
                      key: TourKeys.homeRecentMessagesKey,
                      child: _buildRecentMessagesCard(context),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
      },
    );
  }

  Future<void> _checkForWelcomeTour() async {
    if (!mounted) return;

    try {
      final shouldShow = await TourManager.instance.shouldShowTourPrompt();
      if (shouldShow && mounted) {
        // Additional delay before showing the welcome dialog
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await TourManager.instance.showWelcomeTourPrompt(context);
        }
      }
    } catch (e) {
      print('❌ Tour Error: Failed to check for welcome tour: $e');
    }
  }

  // Check for pending tours AFTER the build method completes
  void _checkForPendingToursAfterBuild() {
    if (!mounted) return;

    // Update pending tour status if it changed
    final hasPendingTour = TourManager.instance.hasPendingTour();
    if (hasPendingTour && !_shouldStartPendingTour) {
      _shouldStartPendingTour = true;
      print('🔄 Tour: Detected new pending tour, will start after widgets ready');
    }

    // Only proceed if we should start a tour
    if (!_shouldStartPendingTour) return;

    // Schedule simple tour start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _shouldStartPendingTour) {
          _startPendingTour();
        }
      });
    });
  }

  // Simple tour start - just pass to TourManager with timing
  void _startPendingTour() {
    if (!mounted || !_shouldStartPendingTour) return;

    print('✅ Tour: Starting pending tour with simple timing...');
    _shouldStartPendingTour = false;

    // Use PostFrameCallback + delay to ensure widgets are rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          // Get the pending tour type and start it
          final pendingTourType = TourManager.instance.getPendingTourType();
          if (pendingTourType != null) {
            print('🎯 Tour: Starting ${pendingTourType} tour...');
            TourManager.instance.startSectionTour(context, pendingTourType);
          }
        }
      });
    });
  }


  // DEPRECATED: Use _checkForPendingToursAfterBuild instead
  @deprecated
  void _checkForPendingTours() {
    if (!mounted) return;

    try {
      // Check if there are any pending tour requests and process them
      // Pass the current context which has access to the Scaffold
      TourManager.instance.checkForPendingTours(context);
    } catch (e) {
      print('❌ Tour Error: Failed to check for pending tours: $e');
    }
  }

  Widget _buildHeader(BuildContext context, String firstName, User currentUser) {
    final demoData = DemoDataManager.instance;
    final appState = Provider.of<AppState>(context, listen: true);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: appState.isTempStyleEnabled
              ? [AppColors.primaryDark, AppColors.primaryDark] // Option 3: Solid dark blue
              : [AppColors.homeColor, AppColors.homeColor.withValues(alpha: 0.8)], // Original purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                key: TourKeys.homeWelcomeKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + App Name row (no SizedBox wrapper)
                    Row(
                      children: [
                        Image.asset(
                          'assets/Logos/UniConnect Logo.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'UniConnect',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Welcome Back, $firstName!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Help Icon
              GestureDetector(
                key: TourKeys.homeHelpIconKey,
                onTap: () {
                  TourManager.instance.showTourMenu(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // Notification Bell
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  NavigationHelper.navigateToScreen(
                    context,
                    const ProfileScreen(),
                    keepBottomNav: true, // Keep bottom nav for frequently accessed screen
                  );
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: currentUser.profileImageUrl != null
                          ? NetworkImage(currentUser.profileImageUrl!)
                          : null,
                      backgroundColor: const Color(0xFFF5F5F0),
                      child: currentUser.profileImageUrl == null
                          ? Text(
                              currentUser.name[0],
                              style: TextStyle(
                                color: const Color(0xFF2C2C2C),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.online,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysScheduleSection(Event? nextClass, Event? nextEvent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontSize: 18,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            height: 1.33,
          ),
        ),

        const SizedBox(height: 12),

        // Show events if available, otherwise show fallback content
        if (nextClass != null || nextEvent != null) ...[
          if (nextClass != null)
            _buildModernEventCard(
              title: nextClass.title,
              subtitle: nextClass.courseCode ?? '',
              time: '${nextClass.startTime.hour}:${nextClass.startTime.minute.toString().padLeft(2, '0')}',
              location: nextClass.location,
              color: AppColors.personalColor,  // Classes are personal schedule
              type: 'Class',
            ),

          if (nextClass != null && nextEvent != null)
            const SizedBox(height: 12),

          if (nextEvent != null)
            _buildModernEventCard(
              title: nextEvent.title,
              subtitle: _getEventSubtitle(nextEvent),
              time: '${nextEvent.startTime.hour}:${nextEvent.startTime.minute.toString().padLeft(2, '0')}',
              location: nextEvent.location,
              color: _getEventColor(nextEvent.type),
              type: _getEventTypeLabel(nextEvent.type),
            ),
        ] else
          // Fallback content when no events are scheduled
          _buildNoEventsCard(),
      ],
    );
  }

  Widget _buildNoEventsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppTheme.getIconColor(context, opacity: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No events today',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enjoy your free time or add some events to your calendar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.getTextColor(context, opacity: 0.6),
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    NavigationHelper.navigateToCalendarWithParams(
                      context,
                    );
                  },
                  icon: Icon(Icons.schedule, size: 16, color: AppColors.personalColor),
                  label: Text('View Calendar', style: TextStyle(color: AppColors.personalColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.personalColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    NavigationHelper.navigateToSocietiesWithParams(
                      context,
                      initialTabIndex: 2, // Events tab
                    );
                  },
                  icon: Icon(Icons.event, size: 16, color: AppColors.societyColor),
                  label: Text('Find Events', style: TextStyle(color: AppColors.societyColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.societyColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEventCard({
    required String title,
    required String subtitle,
    required String time,
    required String location,
    required Color color,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: AppTheme.getIconColor(context, opacity: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: AppTheme.getTextColor(context, opacity: 0.6),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, size: 14, color: AppTheme.getIconColor(context, opacity: 0.6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: AppTheme.getTextColor(context, opacity: 0.6),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: ShapeDecoration(
                color: color.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontSize: 18,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            height: 1.33,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Timetable',
                Icons.schedule,
                AppColors.personalColor,  // Timetable is personal schedule
                () {
                  print('🏠 Timetable Quick Action clicked - setting calendar params');
                  // Navigate to Calendar tab with timetable view and academic filter
                  NavigationHelper.navigateToCalendarWithParams(
                    context,
                    initialUseTimetableView: true,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Find Friends',
                Icons.person_add,
                AppColors.socialColor,
                () {
                  print('🏠 Find Friends Quick Action clicked - setting friends params');
                  // Navigate to Friends tab with Requests tab (index 2) for finding friends
                  NavigationHelper.navigateToFriendsWithParams(
                    context,
                    initialTabIndex: 2, // Requests tab
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Society Events',
                Icons.event,
                AppColors.societyColor,
                () {
                  print('🏠 Society Events Quick Action clicked - setting societies params');
                  // Navigate to Societies tab with Events tab (index 2)
                  NavigationHelper.navigateToSocietiesWithParams(
                    context,
                    initialTabIndex: 2, // Events tab
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Study Groups',
                Icons.menu_book,
                AppColors.studyGroupColor,
                () {
                  print('🏠 Study Groups Quick Action clicked - navigating with bottom nav preserved');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudyGroupsWithNavScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFriendActivityCard(List<User> friends) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Friend Activity',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to Friends tab
                    NavigationHelper.navigateToTab(context, NavigationHelper.friendsTab);
                  },
                  child: Text(
                    'View All',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context, opacity: 0.6),
                      fontSize: 10,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Show content based on whether user has friends or not
            if (friends.isEmpty)
              // No friends state - encourage user to connect
              Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: AppTheme.getIconColor(context, opacity: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No friends yet',
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find classmates and connect with your university community',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context, opacity: 0.6),
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to Friends tab
                        NavigationHelper.navigateToTab(context, NavigationHelper.friendsTab);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.socialColor),
                        foregroundColor: AppColors.socialColor,
                      ),
                      child: Text('Find Friends'),
                    ),
                  ),
                ],
              )
            else
              // Show first friend's activity
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: friends.first.profileImageUrl != null
                        ? NetworkImage(friends.first.profileImageUrl!)
                        : null,
                    backgroundColor: const Color(0xFFF5F5F0),
                    child: friends.first.profileImageUrl == null
                        ? Text(
                            friends.first.name[0],
                            style: TextStyle(
                              color: const Color(0xFF2C2C2C),
                              fontSize: 16,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friends.first.name,
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Currently in class',
                          style: TextStyle(
                            color: AppTheme.getTextColor(context, opacity: 0.6),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: AppTheme.getIconColor(context, opacity: 0.6)),
                            const SizedBox(width: 2),
                            Text(
                              'Building 11, Level 5',
                              style: TextStyle(
                                color: AppTheme.getTextColor(context, opacity: 0.6),
                                fontSize: 10,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMessagesCard(BuildContext context) {
    final chatService = ChatService();
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final currentUserId = appState.currentUser.id;

    return Container(
      width: double.infinity,
      decoration: AppTheme.getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Messages',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to Chat tab
                    NavigationHelper.navigateToTab(context, NavigationHelper.chatTab);
                  },
                  child: Text(
                    'View All',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context, opacity: 0.6),
                      fontSize: 10,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            FutureBuilder<List<Chat>>(
              future: chatService.getUserChats(currentUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No recent messages',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context, opacity: 0.6),
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start connecting with friends to begin conversations',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context, opacity: 0.4),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                }

                final recentChats = snapshot.data!.take(2).toList();
                return Column(
                  children: recentChats.map((chat) => _buildChatPreview(context, chat, currentUserId)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildChatPreview(BuildContext context, Chat chat, String currentUserId) {
    final demoData = DemoDataManager.instance;
    final chatService = ChatService();
    
    String displayName;
    String? avatarUrl;
    
    if (chat.isDirectMessage) {
      final otherUserId = chat.participantIds.firstWhere((id) => id != currentUserId);
      final otherUser = demoData.usersSync.firstWhere((u) => u.id == otherUserId);
      displayName = otherUser.name.split(' ').first;
      avatarUrl = otherUser.profileImageUrl;
    } else {
      displayName = chat.name;
    }

    final unreadCount = chatService.getUnreadCount(chat.id, currentUserId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              backgroundColor: const Color(0xFFF5F5F0),
              child: avatarUrl == null 
                  ? Icon(
                      chat.isDirectMessage ? Icons.person : Icons.group,
                      color: AppColors.homeColor,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w400,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.homeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<List<ChatMessage>>(
                    future: chatService.getChatMessages(chat.id, limit: 1),
                    builder: (context, msgSnapshot) {
                      if (!msgSnapshot.hasData || msgSnapshot.data!.isEmpty) {
                        return Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        );
                      }
                      
                      final lastMessage = msgSnapshot.data!.last;
                      final isMyMessage = lastMessage.senderId == currentUserId;
                      
                      return Text(
                        '${isMyMessage ? 'You: ' : ''}${_getMessagePreview(lastMessage)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getSecondaryTextColor(context),
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMessagePreview(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return message.content.length > 30 
            ? '${message.content.substring(0, 27)}...'
            : message.content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.location:
        return '📍 Location';
      case MessageType.event:
        return '📅 Event';
      case MessageType.system:
        return message.content;
    }
  }

  // Figma Dashboard Card matching the exact design
  Widget _buildFigmaDashboardCard({
    required String title,
    required Widget content,
    required String actionLabel,
    required Color actionColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 20),
              content,
            ],
          ),
          
          // Action Button in top right
          Positioned(
            top: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: actionColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: AppTheme.getButtonTextColor(context),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: AppTheme.getButtonTextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8), // Match calendar cards
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8), // Match calendar cards
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05), // Lighter shadow for action cards
              blurRadius: 2,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for event display
  String _getEventSubtitle(Event event) {
    switch (event.type) {
      case EventType.assignment:
        return 'Assignment Due';
      case EventType.society:
        return 'Society Event';
      case EventType.personal:
        return 'Personal Event';
      case EventType.class_:
        return event.courseCode ?? 'Class';
    }
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.assignment:
        return AppColors.studyGroupColor;
      case EventType.society:
        return AppColors.societyColor;
      case EventType.personal:
        return AppColors.socialColor;
      case EventType.class_:
        return AppColors.personalColor;
    }
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.assignment:
        return 'Assignment';
      case EventType.society:
        return 'Society';
      case EventType.personal:
        return 'Personal';
      case EventType.class_:
        return 'Class';
    }
  }
}
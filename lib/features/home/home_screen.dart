import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/app_state.dart';
import '../../core/services/chat_service.dart';
import '../../shared/models/event.dart';
import '../../shared/models/user.dart';
import '../../shared/models/chat_message.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/chat_screen.dart';
import '../study_groups/study_groups_screen.dart';
import '../study_groups/study_groups_with_nav_screen.dart';
import '../achievements/achievements_screen.dart';
import '../search/advanced_search_screen.dart';
import '../privacy/privacy_settings_screen.dart';
import '../friends/interactive_map_screen.dart';
import '../friends/enhanced_friends_screen.dart';
import '../societies/enhanced_societies_screen.dart';
import '../../shared/models/event_enums.dart';
import '../calendar/enhanced_calendar_screen.dart';
import '../design_system/design_system_showcase_screen.dart';
import '../../core/utils/navigation_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final demoData = DemoDataManager.instance;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Use AppState.currentUser to get the correct user (new user or demo user)
        final currentUser = appState.currentUser;
        final firstName = currentUser.name.split(' ').first;
    final upcomingEvents = appState.getEventsByDate(DateTime.now());
    
    // Get next class and next event
    final nextClass = upcomingEvents.where((e) => e.type == EventType.class_).firstOrNull;
    final nextEvent = upcomingEvents.where((e) => e.type == EventType.society).firstOrNull;

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
                    if (nextClass != null || nextEvent != null)
                      _buildTodaysScheduleSection(nextClass, nextEvent),
                      
                    const SizedBox(height: 20),
                    
                    // Quick Actions
                    _buildModernQuickActions(context),
                    
                    const SizedBox(height: 20),
                    
                    // Friend Activity
                    _buildFriendActivityCard(appState.friends),
                    
                    const SizedBox(height: 20),
                    
                    // Recent Messages
                    _buildRecentMessagesCard(context),
                    
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
              Column(
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
            subtitle: 'Society Event',
            time: '${nextEvent.startTime.hour}:${nextEvent.startTime.minute.toString().padLeft(2, '0')}',
            location: nextEvent.location,
            color: AppColors.societyColor,
            type: 'Event',
          ),
      ],
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
                    initialFilter: CalendarFilter.academic,
                    initialView: CalendarView.week,
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
}
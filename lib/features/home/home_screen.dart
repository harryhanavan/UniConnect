import 'package:flutter/material.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/chat_service.dart';
import '../../shared/models/event.dart';
import '../../shared/models/chat_message.dart';
import '../../core/constants/app_colors.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/chat_screen.dart';
import '../study_groups/study_groups_screen.dart';
import '../achievements/achievements_screen.dart';
import '../search/advanced_search_screen.dart';
import '../privacy/privacy_settings_screen.dart';
import '../friends/interactive_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final demoData = DemoDataManager.instance;

  @override
  Widget build(BuildContext context) {
    // Data is already initialized by AppState
    final currentUser = demoData.currentUser;
    final firstName = currentUser.name.split(' ').first;
    final upcomingEvents = demoData.getEventsByDateRange(
      DateTime.now(),
      DateTime.now().add(const Duration(days: 7)),
    );
    
    // Get next class and next event
    final nextClass = upcomingEvents.where((e) => e.type == EventType.class_).firstOrNull;
    final nextEvent = upcomingEvents.where((e) => e.type == EventType.society).firstOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(context, firstName),
            
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
                    _buildFriendActivityCard(),
                    
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String firstName) {
    final demoData = DemoDataManager.instance;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.homeColor, AppColors.homeColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back, $firstName!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Ready to connect and learn today?',
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        demoData.currentUser.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    );
  }

  Widget _buildTodaysScheduleSection(Event? nextClass, Event? nextEvent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Schedule',
          style: TextStyle(
            color: Colors.black,
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
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
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
                    style: const TextStyle(
                      color: Colors.black,
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
                      Icon(Icons.schedule, size: 14, color: Colors.black.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, size: 14, color: Colors.black.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6),
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
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
            height: 1.33,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Campus Map',
                Icons.map,
                AppColors.socialColor,  // Campus map uses social palette
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InteractiveMapScreen()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Study Groups',
                Icons.groups,
                AppColors.studyGroupColor,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudyGroupsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Achievements',
                Icons.emoji_events,
                AppColors.studyGroupColor,  // Orange color for achievements
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFriendActivityCard() {
    final demoData = DemoDataManager.instance;
    
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Friend Activity',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'View All',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.socialColor,  // Friends are social
                  child: Text(
                    demoData.friends.first.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demoData.friends.first.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 2),
                      
                      Text(
                        'Currently in class',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      const SizedBox(height: 2),
                      
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.black.withValues(alpha: 0.6)),
                          const SizedBox(width: 2),
                          Text(
                            'Building 11, Level 5',
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.6),
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
    final demoData = DemoDataManager.instance;
    final currentUserId = demoData.usersSync.first.id;

    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Messages',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatListScreen()),
                    );
                  },
                  child: Text(
                    'View All',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
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
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start connecting with friends to begin conversations',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
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
              backgroundColor: AppColors.homeColor.withValues(alpha: 0.1),
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
                          color: Colors.black,
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
                            style: const TextStyle(
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
                            color: Colors.grey[600],
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
                          color: Colors.grey[600],
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
        color: AppColors.surface, // Card background
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
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

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Campus Map',
                Icons.map,
                AppColors.socialColor,  // Campus map uses social palette
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InteractiveMapScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Study Groups',
                Icons.groups,
                AppColors.studyGroupColor,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudyGroupsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Achievements',
                Icons.emoji_events,
                AppColors.studyGroupColor,  // Orange color for achievements
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Smart Search',
                Icons.search,
                AppColors.homeColor,  // Purple for search
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvancedSearchScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                'Privacy',
                Icons.security,
                AppColors.socialColor,  // Bright green for privacy
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()), // Empty space for alignment
          ],
        ),
      ],
    );
  }


  Widget _buildQuickActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: Colors.black.withValues(alpha: 0.10),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: ShapeDecoration(
                color: color.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
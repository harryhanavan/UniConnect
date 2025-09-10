import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/services/chat_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../features/home/home_screen.dart';
import '../../features/calendar/enhanced_calendar_screen.dart';
import '../../features/societies/enhanced_societies_screen.dart';
import '../../features/friends/enhanced_friends_screen.dart';
import '../../features/chat/chat_list_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final _chatService = ChatService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _listenToUnreadCount();
  }

  void _listenToUnreadCount() {
    // Listen to chat updates to update unread count
    _chatService.chatsStream.listen((_) {
      _updateUnreadCount();
    });
    _chatService.messagesStream.listen((_) {
      _updateUnreadCount();
    });
  }

  Future<void> _updateUnreadCount() async {
    // This would normally get the current user ID from app state
    try {
      final users = await DemoDataManager.instance.users;
      final currentUserId = users.first.id;
      final newCount = _chatService.getTotalUnreadCount(currentUserId);
      if (newCount != _unreadCount) {
        setState(() {
          _unreadCount = newCount;
        });
      }
    } catch (e) {
      // Handle initialization error gracefully
      print('Error updating unread count: $e');
    }
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0: return AppColors.homeColor;       // Home - Purple
      case 1: return AppColors.personalColor;  // Calendar - Blue
      case 2: return AppColors.socialColor;    // Messages - Bright Green (social)
      case 3: return AppColors.societyColor;   // Societies - Green
      case 4: return AppColors.socialColor;    // Friends - Bright Green (social)
      default: return AppColors.homeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          body: IndexedStack(
            index: appState.currentNavIndex,
            children: const [
              HomeScreen(),
              EnhancedCalendarScreen(),
              ChatListScreen(),
              EnhancedSocietiesScreen(), 
              EnhancedFriendsScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: appState.currentNavIndex,
            onTap: (index) {
              appState.setNavIndex(index);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: _getTabColor(appState.currentNavIndex),
            unselectedItemColor: AppColors.textSecondary,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.message),
                    if (_unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Messages',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.groups),
                label: 'Societies',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Friends',
              ),
            ],
          ),
        );
      },
    );
  }
}
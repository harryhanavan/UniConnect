import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/services/chat_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';

/// Wrapper widget that maintains the bottom navigation bar while displaying content above it
/// Used for screens that should preserve bottom nav functionality (like quick actions)
class NavWrapper extends StatefulWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Color? appBarColor;
  final Color? appBarForegroundColor;
  final PreferredSizeWidget? bottom;

  const NavWrapper({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.appBarColor,
    this.appBarForegroundColor,
    this.bottom,
  });

  @override
  State<NavWrapper> createState() => _NavWrapperState();
}

class _NavWrapperState extends State<NavWrapper> {
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
      case 2: return AppColors.societyColor;   // Societies - Green
      case 3: return AppColors.socialColor;    // Friends - Bright Green (social)
      case 4: return AppColors.socialColor;    // Messages - Bright Green (social)
      default: return AppColors.homeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: widget.title != null ? AppBar(
            title: Text(widget.title!),
            backgroundColor: widget.appBarColor,
            foregroundColor: widget.appBarForegroundColor,
            bottom: widget.bottom,
            actions: widget.actions,
          ) : null,
          body: widget.child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: appState.currentNavIndex,
            onTap: (index) {
              // When user taps bottom nav, go back to main navigation
              Navigator.of(context).pop();
              appState.setNavIndex(index);
            },
            type: BottomNavigationBarType.fixed,
            // CONDITIONAL STYLING BASED ON TEMP STYLE TOGGLE:
            // Original: Default background, colored selected icons, gray unselected
            // Temp Style: Dark blue background, white selected/unselected icons
            backgroundColor: appState.isTempStyleEnabled
                ? AppColors.primaryDark    // Dark blue background matching headers
                : null,                    // Default background when disabled
            selectedItemColor: appState.isTempStyleEnabled
                ? Colors.white             // White icons on blue background
                : _getTabColor(appState.currentNavIndex), // Colored icons for original style
            unselectedItemColor: appState.isTempStyleEnabled
                ? Colors.white70           // Semi-transparent white on blue
                : AppColors.textSecondary, // Gray for original style
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Calendar',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.groups),
                label: 'Societies',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Friends',
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
            ],
          ),
        );
      },
    );
  }
}
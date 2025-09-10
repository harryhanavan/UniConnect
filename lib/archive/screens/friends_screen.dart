import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../shared/models/user.dart';
import 'widgets/friend_card.dart';
import 'interactive_map_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Friends'),
            backgroundColor: AppColors.socialColor,
            elevation: 0,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.map),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InteractiveMapScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => _showAddFriendDialog(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'My Friends'),
                Tab(text: 'Discover'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Status bar and Search
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Friends status bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.online.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: AppColors.online, size: 12),
                          const SizedBox(width: 8),
                          Text(
                            '${DemoDataManager.instance.friends.where((f) => f.isOnline).length} friends on campus',
                            style: TextStyle(
                              color: AppColors.online,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const InteractiveMapScreen()),
                              );
                            },
                            child: const Text('View Map'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search friends...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // Current user card
              _buildCurrentUserCard(appState),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsTab(appState),
                    _buildDiscoverTab(appState),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: "add_friend",
            onPressed: () => _showAddFriendDialog(context),
            backgroundColor: AppColors.socialColor,
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildCurrentUserCard(AppState appState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: AppColors.socialColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.socialColor,
                child: Text(
                  appState.currentUser.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          appState.currentUser.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.socialColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'You',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${appState.currentUser.course} • ${appState.currentUser.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab(AppState appState) {
    final friends = appState.friends
        .where((user) => 
            user.name.toLowerCase().contains(_searchQuery) ||
            user.course.toLowerCase().contains(_searchQuery))
        .toList();

    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? 'No friends added yet'
                  : 'No friends match your search',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Use the Discover tab to find classmates',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        return FriendCard(
          user: friends[index],
          showAddButton: false,
          onActionPressed: () => _showFriendOptions(context, friends[index]),
        );
      },
    );
  }

  Widget _buildDiscoverTab(AppState appState) {
    final potentialFriends = appState.friends
        .where((user) => 
            user.name.toLowerCase().contains(_searchQuery) ||
            user.course.toLowerCase().contains(_searchQuery))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: potentialFriends.length,
      itemBuilder: (context, index) {
        return FriendCard(
          user: potentialFriends[index],
          showAddButton: true,
          onActionPressed: () => _sendFriendRequest(potentialFriends[index]),
        );
      },
    );
  }

  void _showFriendOptions(BuildContext context, User friend) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              friend.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('View Shared Timetable'),
              onTap: () {
                Navigator.pop(context);
                _showSharedTimetable(context, friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                _showMessageDialog(context, friend);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSharedTimetable(BuildContext context, User friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shared Timetable with ${friend.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Common free time slots:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Today 2:00 PM - 4:00 PM', 
                           style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Tomorrow 10:00 AM - 12:00 PM',
                           style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plan Meetup'),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(BuildContext context, User friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message ${friend.name}'),
        content: const Text('This is a demo app. In the full version, you would be able to send direct messages to your friends.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _sendFriendRequest(User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to ${user.name}')),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                hintText: 'Enter UTS email or student ID',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('QR Scanner opened (demo)')),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.socialColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Or search by name in the Discover tab',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Friend request sent!')),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
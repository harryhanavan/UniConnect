import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/friendship_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../shared/models/user.dart';
import '../../shared/models/chat_message.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> with TickerProviderStateMixin {
  final _chatService = ChatService();
  final _friendshipService = FriendshipService();
  final _demoData = DemoDataManager.instance;
  final _searchController = TextEditingController();
  
  late TabController _tabController;
  
  List<User> _friends = [];
  List<User> _allUsers = [];
  List<User> _filteredFriends = [];
  List<User> _filteredUsers = [];
  final List<User> _selectedUsers = [];
  
  String _groupName = '';
  bool _isLoading = true;
  
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _demoData.usersSync.first.id;
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final friends = _friendshipService.getUserFriends(_currentUserId);
      final allUsers = _demoData.usersSync
          .where((user) => user.id != _currentUserId)
          .toList();
      
      setState(() {
        _friends = friends;
        _allUsers = allUsers;
        _filteredFriends = friends;
        _filteredUsers = allUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredFriends = _friends;
        _filteredUsers = _allUsers;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    
    setState(() {
      _filteredFriends = _friends
          .where((user) => 
              user.name.toLowerCase().contains(lowercaseQuery) ||
              user.email.toLowerCase().contains(lowercaseQuery))
          .toList();
      
      _filteredUsers = _allUsers
          .where((user) => 
              user.name.toLowerCase().contains(lowercaseQuery) ||
              user.email.toLowerCase().contains(lowercaseQuery))
          .toList();
    });
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _startDirectChat(User user) async {
    try {
      final chat = await _chatService.createOrGetDirectChat(_currentUserId, user.id);
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  Future<void> _createGroupChat() async {
    if (_selectedUsers.isEmpty || _groupName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select users and enter a group name')),
      );
      return;
    }

    try {
      final participantIds = [_currentUserId, ..._selectedUsers.map((u) => u.id)];
      final chat = await _chatService.createGroupChat(
        name: _groupName.trim(),
        createdBy: _currentUserId,
        participantIds: participantIds,
        type: ChatType.group,
      );
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    }
  }

  Widget _buildUserTile(User user, {bool showSelect = false, VoidCallback? onTap}) {
    final isSelected = _selectedUsers.contains(user);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: showSelect && isSelected
            ? Border.all(color: AppColors.socialColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              backgroundColor: AppColors.socialColor.withOpacity(0.1),
              child: user.profileImageUrl == null
                  ? Text(
                      user.name.substring(0, 1),
                      style: TextStyle(
                        color: AppColors.socialColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (showSelect && isSelected)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.socialColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            if (user.course.isNotEmpty)
              Text(
                '${user.course} (Year ${user.year})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: showSelect
            ? null
            : Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        onTap: onTap ?? () {
          if (showSelect) {
            _toggleUserSelection(user);
          } else {
            _startDirectChat(user);
          }
        },
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredFriends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'No friends yet'
                    : 'No friends match your search',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with classmates to start chatting',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredFriends.length,
      itemBuilder: (context, index) {
        return _buildUserTile(_filteredFriends[index]);
      },
    );
  }

  Widget _buildDiscoverTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No users match your search',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserTile(_filteredUsers[index]);
      },
    );
  }

  Widget _buildGroupTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.group),
                ),
                onChanged: (value) {
                  setState(() {
                    _groupName = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Select Members',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_selectedUsers.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _selectedUsers[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: user.profileImageUrl != null
                                      ? NetworkImage(user.profileImageUrl!)
                                      : null,
                                  backgroundColor: AppColors.socialColor.withOpacity(0.1),
                                  child: user.profileImageUrl == null
                                      ? Text(
                                          user.name.substring(0, 1),
                                          style: TextStyle(
                                            color: AppColors.socialColor,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () => _toggleUserSelection(user),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.name.split(' ').first,
                              style: TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    return _buildUserTile(
                      _filteredUsers[index],
                      showSelect: true,
                      onTap: () => _toggleUserSelection(_filteredUsers[index]),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedUsers.isNotEmpty && _groupName.trim().isNotEmpty
                    ? _createGroupChat
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Create Group (${_selectedUsers.length})',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.socialColor, AppColors.socialColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'New Chat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.surface,
              labelColor: Theme.of(context).colorScheme.surface,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Friends'),
                Tab(text: 'Discover'),
                Tab(text: 'Group'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(),
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildDiscoverTab(),
                _buildGroupTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
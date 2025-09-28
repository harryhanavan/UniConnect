import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/friendship_service.dart';
import '../../core/services/chat_service.dart';
import '../../shared/models/user.dart';
import '../../features/chat/chat_screen.dart';

/// Reusable modal for displaying friend profiles throughout the app
/// Can be called from friends list, chat screens, event attendees, etc.
class FriendProfileModal extends StatefulWidget {
  final User friend;
  final User? currentUser;

  const FriendProfileModal({
    super.key,
    required this.friend,
    this.currentUser,
  });

  @override
  State<FriendProfileModal> createState() => _FriendProfileModalState();
}

class _FriendProfileModalState extends State<FriendProfileModal> {
  final DemoDataManager _demoData = DemoDataManager.instance;
  final FriendshipService _friendshipService = FriendshipService();
  final ChatService _chatService = ChatService();

  late User _currentUser;
  bool _isLoading = true;
  Map<String, bool> _privacyPermissions = {};
  List<User> _mutualFriends = [];
  List<String> _sharedClasses = [];
  List<String> _sharedSocieties = [];
  List<Map<String, dynamic>> _mutualStudyGroups = [];
  bool _isFriend = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser ?? _demoData.currentUser;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      // Load privacy permissions
      _privacyPermissions = {
        'canViewProfile': true, // For now, assume friends can view profiles
        'canViewLocation': _friendshipService.canViewLocation(_currentUser.id, widget.friend.id),
        'canViewTimetable': _friendshipService.canViewTimetable(_currentUser.id, widget.friend.id),
        'canViewFriends': true, // For now, assume friends can view friend lists
      };

      // Load mutual friends
      if (_privacyPermissions['canViewFriends'] == true) {
        _mutualFriends = await _friendshipService.getMutualFriends(_currentUser.id, widget.friend.id);
      }

      // Load shared academic and social data
      _sharedClasses = _getSharedClasses();
      _sharedSocieties = _getSharedSocieties();
      _mutualStudyGroups = _getMutualStudyGroups();

      // Check if they are friends
      _isFriend = _demoData.areFriends(_currentUser.id, widget.friend.id);

    } catch (e) {
      // Error loading profile data: $e
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _getSharedClasses() {
    // Mock some general education classes that students from different faculties might share
    final generalClasses = [
      'COMM1001 Communication Skills',
      'MATH1081 Statistics',
      'MGMT1001 Management Fundamentals',
      'ENGG1000 Engineering Design',
    ];

    // Simulate realistic overlap - students often share general education units
    if (widget.friend.id == 'user_002') { // Sarah Mitchell
      return ['COMM1001 Communication Skills', 'MGMT1001 Management Fundamentals'];
    } else if (widget.friend.id == 'user_005') { // James Kim
      return ['MATH1081 Statistics', 'ENGG1000 Engineering Design'];
    } else if (widget.friend.course == _currentUser.course) {
      // Same course = more shared classes
      return generalClasses.take(3).toList();
    }

    // Different course but might share one general class
    return [generalClasses.first];
  }

  List<String> _getSharedSocieties() {
    // Get actual society IDs for both users from the data
    final allSocieties = _demoData.societiesSync;
    final allUsers = _demoData.usersSync;

    // Find the actual user objects to get their society IDs
    final currentUserData = allUsers.firstWhere(
      (u) => u.id == _currentUser.id,
      orElse: () => _currentUser,
    );
    final friendUserData = allUsers.firstWhere(
      (u) => u.id == widget.friend.id,
      orElse: () => widget.friend,
    );

    // Find overlapping society IDs
    final sharedSocietyIds = currentUserData.societyIds
        .where((id) => friendUserData.societyIds.contains(id))
        .toList();

    // Get society names for the shared IDs
    final sharedSocieties = <String>[];
    for (final societyId in sharedSocietyIds) {
      try {
        final society = allSocieties.firstWhere((s) => s.id == societyId);
        sharedSocieties.add(society.name);
      } catch (e) {
        // Society not found, skip
      }
    }

    return sharedSocieties;
  }

  List<Map<String, dynamic>> _getMutualStudyGroups() {
    // Mock mutual study groups - interdisciplinary groups are common
    final studyGroups = <Map<String, dynamic>>[];

    // Everyone can be in general study groups
    studyGroups.add({'name': 'UTS Study Buddies', 'members': 12});

    // Add more specific groups based on who the friend is
    if (widget.friend.id == 'user_002' || widget.friend.id == 'user_005') {
      studyGroups.add({'name': 'Finals Prep Group', 'members': 8});
    }

    // Same course = more specific study groups
    if (widget.friend.course == _currentUser.course) {
      studyGroups.add({'name': 'Sports Science Lab Group', 'members': 5});
    }

    return studyGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar for swipe gesture
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Close button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                        _buildProfileSections(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Picture
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: widget.friend.profileImageUrl != null
                  ? NetworkImage(widget.friend.profileImageUrl!)
                  : null,
              backgroundColor: AppColors.socialColor,
              child: widget.friend.profileImageUrl == null
                  ? Text(
                      widget.friend.name[0],
                      style: const TextStyle(fontSize: 36, color: Colors.white),
                    )
                  : null,
            ),
            // Status indicator
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.friend.status.name),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Name and Status
        Text(
          widget.friend.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        // Status text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(widget.friend.status.name),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.friend.status.name.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: _getStatusColor(widget.friend.status.name),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Course and Year
        Text(
          '${widget.friend.course} • Year ${widget.friend.year}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),

        // Current Location (if shared and available)
        if (_privacyPermissions['canViewLocation'] == true && widget.friend.currentLocationId != null)
          _buildLocationInfo(),
      ],
    );
  }

  Widget _buildLocationInfo() {
    final location = _demoData.getLocationById(widget.friend.currentLocationId!);
    if (location == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            location.displayName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Message Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startChat,
            icon: const Icon(Icons.message, size: 18),
            label: const Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.socialColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // View Timetable Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _privacyPermissions['canViewTimetable'] == true
                ? _viewTimetable
                : null,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('Timetable'),
            style: OutlinedButton.styleFrom(
              backgroundColor: _privacyPermissions['canViewTimetable'] == true
                  ? AppColors.personalColor.withValues(alpha: 0.1)
                  : null,
              foregroundColor: _privacyPermissions['canViewTimetable'] == true
                  ? AppColors.personalColor
                  : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About Section
        if (widget.friend.statusMessage?.isNotEmpty == true) ...[
          _buildSectionHeader('About'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.friend.statusMessage!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Mutual Friends Section
        if (_privacyPermissions['canViewFriends'] == true && _mutualFriends.isNotEmpty) ...[
          _buildSectionHeader('Mutual Friends (${_mutualFriends.length})'),
          const SizedBox(height: 8),
          _buildMutualFriendsRow(),
          const SizedBox(height: 20),
        ],

        // Shared Classes Section
        if (_sharedClasses.isNotEmpty) ...[
          _buildSectionHeader('Shared Classes (${_sharedClasses.length})'),
          const SizedBox(height: 8),
          ..._sharedClasses.map((className) => _buildListItem(className, Icons.school)),
          const SizedBox(height: 20),
        ],

        // Shared Societies Section
        if (_sharedSocieties.isNotEmpty) ...[
          _buildSectionHeader('Shared Societies (${_sharedSocieties.length})'),
          const SizedBox(height: 8),
          ..._sharedSocieties.map((society) => _buildListItem(society, Icons.groups)),
          const SizedBox(height: 20),
        ],

        // Study Groups Section
        if (_mutualStudyGroups.isNotEmpty) ...[
          _buildSectionHeader('Mutual Study Groups (${_mutualStudyGroups.length})'),
          const SizedBox(height: 8),
          ..._mutualStudyGroups.map((group) =>
            _buildListItem('${group['name']} (${group['members']} members)', Icons.school)
          ),
          const SizedBox(height: 20),
        ],

        // Bottom Action Buttons
        const SizedBox(height: 20),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMutualFriendsRow() {
    return Row(
      children: [
        ...(_mutualFriends.take(4).map((friend) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: friend.profileImageUrl != null
                ? NetworkImage(friend.profileImageUrl!)
                : null,
            backgroundColor: AppColors.socialColor,
            child: friend.profileImageUrl == null
                ? Text(friend.name[0], style: const TextStyle(color: Colors.white))
                : null,
          ),
        ))),
        if (_mutualFriends.length > 4)
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: Text(
              '+${_mutualFriends.length - 4}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildListItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.socialColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'away':
        return Colors.orange;
      case 'busy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: _toggleFriendship,
            icon: Icon(
              _isFriend ? Icons.person_remove : Icons.person_add,
              size: 18,
            ),
            label: Text(_isFriend ? 'Unfriend' : 'Add Friend'),
            style: TextButton.styleFrom(
              foregroundColor: _isFriend ? Colors.red : AppColors.socialColor,
            ),
          ),
          TextButton.icon(
            onPressed: _showBlockConfirmation,
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Block'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
          TextButton.icon(
            onPressed: _adjustPrivacySettings,
            icon: const Icon(Icons.privacy_tip, size: 18),
            label: const Text('Privacy'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  void _startChat() async {
    Navigator.of(context).pop(); // Close modal first

    try {
      // Get or create direct chat with this friend
      final chat = await _chatService.createOrGetDirectChat(
        _currentUser.id,
        widget.friend.id,
      );

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      // If there's an error, show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat with ${widget.friend.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewTimetable() {
    Navigator.of(context).pop(); // Close modal first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${widget.friend.name}\'s timetable...'),
        backgroundColor: AppColors.personalColor,
      ),
    );
    // TODO: Navigate to timetable view with friend's schedule
  }

  void _toggleFriendship() {
    if (_isFriend) {
      _showUnfriendConfirmation();
    } else {
      // Send friend request
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to ${widget.friend.name}'),
          backgroundColor: AppColors.socialColor,
        ),
      );
      // TODO: Implement friend request functionality
    }
  }

  void _adjustPrivacySettings() {
    Navigator.of(context).pop(); // Close modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening privacy settings...'),
        backgroundColor: AppColors.primaryDark,
      ),
    );
    // TODO: Navigate to privacy settings for this friend
  }

  void _showUnfriendConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfriend'),
        content: Text('Are you sure you want to unfriend ${widget.friend.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close modal
              // TODO: Implement unfriend functionality
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${widget.friend.name}? They will not be able to contact you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close modal
              // TODO: Implement block functionality
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the friend profile modal from anywhere in the app
Future<void> showFriendProfileModal(BuildContext context, User friend, {User? currentUser}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FriendProfileModal(
      friend: friend,
      currentUser: currentUser,
    ),
  );
}
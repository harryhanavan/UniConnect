import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/friendship_service.dart';
import '../models/user.dart';

enum FriendshipStatus {
  notFriend,
  friend,
  requestSent,
  requestReceived,
  self,
}

class UserProfileCard extends StatefulWidget {
  final User user;
  final VoidCallback? onClose;
  final bool showFullProfile;

  const UserProfileCard({
    super.key,
    required this.user,
    this.onClose,
    this.showFullProfile = true,
  });

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  final DemoDataManager _demoData = DemoDataManager.instance;
  final FriendshipService _friendshipService = FriendshipService();

  FriendshipStatus _friendshipStatus = FriendshipStatus.notFriend;
  bool _isLoading = false;
  List<User> _mutualFriends = [];
  List<String> _sharedCourses = [];
  List<String> _sharedSocieties = [];

  @override
  void initState() {
    super.initState();
    _loadUserRelationshipData();
  }

  void _loadUserRelationshipData() {
    final currentUser = _demoData.currentUser;

    // Determine friendship status
    if (widget.user.id == currentUser.id) {
      _friendshipStatus = FriendshipStatus.self;
    } else if (_demoData.areFriends(currentUser.id, widget.user.id)) {
      _friendshipStatus = FriendshipStatus.friend;
    } else {
      // Check for pending requests
      final sentRequests = _demoData.getSentFriendRequests(currentUser.id);
      final receivedRequests = _demoData.getPendingFriendRequests(currentUser.id);

      if (sentRequests.any((r) => r.receiverId == widget.user.id)) {
        _friendshipStatus = FriendshipStatus.requestSent;
      } else if (receivedRequests.any((r) => r.senderId == widget.user.id)) {
        _friendshipStatus = FriendshipStatus.requestReceived;
      } else {
        _friendshipStatus = FriendshipStatus.notFriend;
      }
    }

    // Load mutual connections if they're friends or connected
    if (_friendshipStatus == FriendshipStatus.friend) {
      _loadMutualConnections();
    }

    _loadSharedInterests();
  }

  void _loadMutualConnections() {
    final currentUser = _demoData.currentUser;
    _mutualFriends = _friendshipService.getMutualFriendsSync(currentUser.id, widget.user.id);
  }

  void _loadSharedInterests() {
    final currentUser = _demoData.currentUser;

    // Find shared course elements
    final currentCourseWords = currentUser.course.toLowerCase().split(' ');
    final userCourseWords = widget.user.course.toLowerCase().split(' ');
    _sharedCourses = currentCourseWords
        .where((word) => userCourseWords.contains(word) && word.length > 3)
        .toList();

    // Find shared societies (simplified - in real app would check actual membership)
    final currentSocieties = _demoData.societiesSync
        .where((s) => currentUser.societyIds.contains(s.id))
        .map((s) => s.name)
        .toList();

    _sharedSocieties = currentSocieties.take(2).toList(); // Simplified for demo
  }

  Future<void> _handleFriendAction() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _demoData.currentUser;

      switch (_friendshipStatus) {
        case FriendshipStatus.notFriend:
          await _friendshipService.sendFriendRequest(
            currentUser.id,
            widget.user.id,
            message: 'Hi ${widget.user.name}! Let\'s connect on UniConnect.',
          );
          setState(() {
            _friendshipStatus = FriendshipStatus.requestSent;
          });
          _showSnackBar('Friend request sent to ${widget.user.name}');
          break;

        case FriendshipStatus.requestReceived:
          // Accept the request
          final requests = _demoData.getPendingFriendRequests(currentUser.id);
          final request = requests.firstWhere((r) => r.senderId == widget.user.id);

          await _friendshipService.acceptFriendRequest(request.id);
          setState(() {
            _friendshipStatus = FriendshipStatus.friend;
          });
          _loadMutualConnections();
          _showSnackBar('You and ${widget.user.name} are now friends! 🎉');
          break;

        case FriendshipStatus.friend:
          await _friendshipService.removeFriend(currentUser.id, widget.user.id);
          setState(() {
            _friendshipStatus = FriendshipStatus.notFriend;
            _mutualFriends.clear();
          });
          _showSnackBar('Removed ${widget.user.name} from friends');
          break;

        case FriendshipStatus.requestSent:
          _showSnackBar('Friend request already sent');
          break;

        case FriendshipStatus.self:
          break;
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeclineRequest() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _demoData.currentUser;
      final requests = _demoData.getPendingFriendRequests(currentUser.id);
      final request = requests.firstWhere((r) => r.senderId == widget.user.id);

      await _friendshipService.declineFriendRequest(request.id);
      setState(() {
        _friendshipStatus = FriendshipStatus.notFriend;
      });
      _showSnackBar('Friend request declined');
    } catch (e) {
      _showSnackBar('Error declining request: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showFullProfile) {
      return _buildFullProfile();
    } else {
      return _buildCompactProfile();
    }
  }

  Widget _buildFullProfile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Close button
          if (widget.onClose != null)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ),

          // Profile header
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // Friend status and actions
          _buildFriendActions(),
          const SizedBox(height: 24),

          // User details
          _buildUserDetails(),

          // Mutual connections and shared interests
          if (_friendshipStatus == FriendshipStatus.friend ||
              _sharedCourses.isNotEmpty ||
              _sharedSocieties.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildConnectionsAndInterests(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactProfile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.user.name[0],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.user.course} • ${widget.user.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                _buildFriendshipStatusChip(),
              ],
            ),
          ),

          // Action button
          _buildCompactActionButton(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar with status
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Text(
                widget.user.name[0],
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.user.status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Name and course
        Text(
          widget.user.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.user.course} • ${widget.user.year}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        _buildFriendshipStatusChip(),
      ],
    );
  }

  Widget _buildFriendshipStatusChip() {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (_friendshipStatus) {
      case FriendshipStatus.friend:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        statusText = 'Friends';
        break;
      case FriendshipStatus.requestSent:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        statusText = 'Request Sent';
        break;
      case FriendshipStatus.requestReceived:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        statusText = 'Request Received';
        break;
      case FriendshipStatus.self:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[700]!;
        statusText = 'You';
        break;
      case FriendshipStatus.notFriend:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        statusText = 'Not Connected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildFriendActions() {
    if (_friendshipStatus == FriendshipStatus.self) {
      return const SizedBox();
    }

    if (_friendshipStatus == FriendshipStatus.requestReceived) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleDeclineRequest,
              icon: const Icon(Icons.close),
              label: const Text('Decline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleFriendAction,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleFriendAction,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _getFriendActionIcon(),
        label: Text(_getFriendActionText()),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getFriendActionColor(),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCompactActionButton() {
    if (_friendshipStatus == FriendshipStatus.self) {
      return const SizedBox();
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _handleFriendAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getFriendActionColor(),
        foregroundColor: Colors.white,
        minimumSize: const Size(80, 36),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_getFriendActionText()),
    );
  }

  Widget _buildUserDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          Icons.person,
          'Status',
          _getStatusText(widget.user.status),
        ),
        if (widget.user.statusMessage != null) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.message,
            'Status Message',
            widget.user.statusMessage!,
          ),
        ],
        const SizedBox(height: 8),
        _buildDetailRow(
          Icons.school,
          'Course',
          widget.user.course,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          Icons.calendar_today,
          'Year',
          widget.user.year,
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionsAndInterests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_mutualFriends.isNotEmpty) ...[
          const Text(
            'Mutual Friends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _mutualFriends.map((f) => f.name).join(', '),
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
        ],

        if (_sharedCourses.isNotEmpty) ...[
          const Text(
            'Shared Interests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ..._sharedCourses.map((course) => Chip(
                label: Text(course.toUpperCase()),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              )),
              ..._sharedSocieties.map((society) => Chip(
                label: Text(society),
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              )),
            ],
          ),
        ],
      ],
    );
  }

  Icon _getFriendActionIcon() {
    switch (_friendshipStatus) {
      case FriendshipStatus.notFriend:
        return const Icon(Icons.person_add);
      case FriendshipStatus.friend:
        return const Icon(Icons.person_remove);
      case FriendshipStatus.requestSent:
        return const Icon(Icons.schedule);
      case FriendshipStatus.requestReceived:
        return const Icon(Icons.check);
      case FriendshipStatus.self:
        return const Icon(Icons.person);
    }
  }

  String _getFriendActionText() {
    switch (_friendshipStatus) {
      case FriendshipStatus.notFriend:
        return 'Add Friend';
      case FriendshipStatus.friend:
        return 'Remove';
      case FriendshipStatus.requestSent:
        return 'Pending';
      case FriendshipStatus.requestReceived:
        return 'Accept';
      case FriendshipStatus.self:
        return 'You';
    }
  }

  Color _getFriendActionColor() {
    switch (_friendshipStatus) {
      case FriendshipStatus.notFriend:
        return AppColors.primary;
      case FriendshipStatus.friend:
        return Colors.red;
      case FriendshipStatus.requestSent:
        return Colors.orange;
      case FriendshipStatus.requestReceived:
        return Colors.green;
      case FriendshipStatus.self:
        return Colors.grey;
    }
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return Colors.green;
      case UserStatus.offline:
        return Colors.grey;
      case UserStatus.busy:
        return Colors.red;
      case UserStatus.away:
        return Colors.orange;
      case UserStatus.inClass:
        return Colors.blue;
      case UserStatus.studying:
        return Colors.purple;
    }
  }

  String _getStatusText(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.offline:
        return 'Offline';
      case UserStatus.busy:
        return 'Busy';
      case UserStatus.away:
        return 'Away';
      case UserStatus.inClass:
        return 'In Class';
      case UserStatus.studying:
        return 'Studying';
    }
  }
}
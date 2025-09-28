import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user.dart';
import '../../shared/models/friend_request.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class FriendCardEnhanced extends StatelessWidget {
  final User friend;
  final User currentUser;
  final VoidCallback? onTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onProfileTap;
  final bool showQuickActions;

  const FriendCardEnhanced({
    super.key,
    required this.friend,
    required this.currentUser,
    this.onTap,
    this.onMessageTap,
    this.onProfileTap,
    this.showQuickActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () => _navigateToProfile(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar with status
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: friend.profileImageUrl != null
                        ? NetworkImage(friend.profileImageUrl!)
                        : null,
                    child: friend.profileImageUrl == null
                        ? Text(friend.name[0], style: const TextStyle(fontSize: 20))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _getStatusColor(friend.status),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Friend info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${friend.course} • ${friend.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    if (friend.statusMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        friend.statusMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(friend.status),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Quick Actions
              if (showQuickActions) ...[
                // Message Button
                IconButton(
                  icon: const Icon(Icons.message_outlined),
                  color: AppColors.socialColor,
                  onPressed: onMessageTap ?? () => _navigateToChat(context),
                  tooltip: 'Send Message',
                ),
                // Profile Button
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  color: AppColors.personalColor,
                  onPressed: onProfileTap ?? () => _navigateToProfile(context),
                  tooltip: 'View Profile',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(user: friend),
      ),
    );
  }

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: '${currentUser.id}_${friend.id}',
          recipientName: friend.name,
          recipientId: friend.id,
          recipientAvatar: friend.profileImageUrl,
        ),
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
}

class FriendRequestCardEnhanced extends StatelessWidget {
  final FriendRequest request;
  final User? sender;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool showProfileButton;

  const FriendRequestCardEnhanced({
    super.key,
    required this.request,
    required this.sender,
    required this.onAccept,
    required this.onDecline,
    this.showProfileButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (sender == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: sender!.profileImageUrl != null
                      ? NetworkImage(sender!.profileImageUrl!)
                      : null,
                  child: sender!.profileImageUrl == null
                      ? Text(sender!.name[0], style: const TextStyle(fontSize: 20))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sender!.course} • ${sender!.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showProfileButton)
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    color: AppColors.personalColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(user: sender!),
                        ),
                      );
                    },
                    tooltip: 'View Profile',
                  ),
              ],
            ),
            if (request.message?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.message!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDecline,
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.socialColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddFriendFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const AddFriendFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.socialColor,
      icon: const Icon(Icons.person_add, color: Colors.white),
      label: const Text(
        'Add Friend',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class FriendsSuggestionBadge extends StatelessWidget {
  final int count;

  const FriendsSuggestionBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.socialColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count new',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
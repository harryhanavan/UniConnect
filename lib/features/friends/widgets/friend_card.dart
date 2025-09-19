import 'package:flutter/material.dart';
import '../../../shared/models/user.dart';
import '../../../core/constants/app_colors.dart';

class FriendCard extends StatelessWidget {
  final User user;
  final bool showAddButton;
  final VoidCallback onActionPressed;

  const FriendCard({
    super.key,
    required this.user,
    this.showAddButton = false,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                backgroundColor: const Color(0xFFF5F5F0),
                child: user.profileImageUrl == null
                    ? Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: const Color(0xFF2C2C2C),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              if (!showAddButton) // Only show status for existing friends
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: user.isOnline ? AppColors.online : AppColors.offline,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user.course} • ${user.year}'),
              if (!user.isOnline && user.lastSeen != null)
                Text(
                  'Last seen ${_formatLastSeen(user.lastSeen!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
            ],
          ),
          trailing: showAddButton
              ? IconButton(
                  onPressed: onActionPressed,
                  icon: const Icon(Icons.person_add, color: AppColors.socialColor),
                )
              : IconButton(
                  onPressed: onActionPressed,
                  icon: const Icon(Icons.more_vert),
                ),
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/notification_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';
import '../notifications/reminder_preferences_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription<AppNotification> _notificationSubscription;
  late StreamSubscription<int> _badgeSubscription;
  
  final NotificationService _notificationService = NotificationService();
  final DemoDataManager _demoData = DemoDataManager.instance;
  
  List<AppNotification> _allNotifications = [];
  List<AppNotification> _unreadNotifications = [];
  List<AppNotification> _reminderNotifications = [];
  int _badgeCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
    _setupNotificationListeners();
  }

  void _loadNotifications() {
    _allNotifications = _notificationService.getUserNotifications(_demoData.currentUser.id);
    _unreadNotifications = _allNotifications.where((n) => !n.isRead).toList();
    _reminderNotifications = _allNotifications.where((n) =>
      n.type == NotificationType.eventReminder ||
      (n.data['isReminder'] == true)
    ).toList();
    _badgeCount = _notificationService.unreadCount;
    setState(() {});
  }

  void _setupNotificationListeners() {
    _notificationSubscription = _notificationService.notificationStream.listen(
      (notification) {
        _loadNotifications();
      },
    );
    
    _badgeSubscription = _notificationService.badgeCountStream.listen(
      (count) {
        setState(() {
          _badgeCount = count;
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationSubscription.cancel();
    _badgeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_unreadNotifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark All Read'),
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear_all', child: Text('Clear All')),
              const PopupMenuItem(value: 'reminder_settings', child: Text('Reminder Preferences')),
              const PopupMenuItem(value: 'settings', child: Text('Notification Settings')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              text: 'All',
              icon: _allNotifications.isNotEmpty
                  ? Badge(
                      label: Text('${_allNotifications.length}'),
                      child: const Icon(Icons.inbox),
                    )
                  : const Icon(Icons.inbox),
            ),
            Tab(
              text: 'Unread',
              icon: _badgeCount > 0
                  ? Badge(
                      label: Text('$_badgeCount'),
                      child: const Icon(Icons.circle),
                    )
                  : const Icon(Icons.circle),
            ),
            Tab(
              text: 'Reminders',
              icon: _reminderNotifications.isNotEmpty
                  ? Badge(
                      label: Text('${_reminderNotifications.length}'),
                      child: const Icon(Icons.alarm),
                    )
                  : const Icon(Icons.alarm),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(_allNotifications),
          _buildNotificationsList(_unreadNotifications),
          _buildRemindersList(_reminderNotifications),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadNotifications();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you receive notifications, they\'ll appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateSampleNotifications,
            icon: const Icon(Icons.add),
            label: const Text('Generate Sample Notifications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : Colors.blue[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildNotificationIcon(notification.type),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _formatNotificationTime(notification.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (notification.senderId != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${_getSenderName(notification.senderId!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleNotificationAction(value, notification),
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(value: 'mark_read', child: Text('Mark as Read')),
            if (notification.actionUrl != null)
              const PopupMenuItem(value: 'view', child: Text('View')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.friendRequest:
        iconData = Icons.person_add;
        color = Colors.blue;
        break;
      case NotificationType.friendAccepted:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.eventInvitation:
        iconData = Icons.event;
        color = Colors.purple;
        break;
      case NotificationType.eventReminder:
        iconData = Icons.alarm;
        color = Colors.orange;
        break;
      case NotificationType.locationUpdate:
        iconData = Icons.location_on;
        color = Colors.red;
        break;
      case NotificationType.studyGroupInvite:
        iconData = Icons.group;
        color = Colors.teal;
        break;
      case NotificationType.societyEvent:
        iconData = Icons.groups;
        color = Colors.indigo;
        break;
      case NotificationType.timetableConflict:
        iconData = Icons.warning;
        color = Colors.amber;
        break;
      case NotificationType.nearbyFriend:
        iconData = Icons.near_me;
        color = Colors.pink;
        break;
      case NotificationType.meetupSuggestion:
        iconData = Icons.coffee;
        color = Colors.brown;
        break;
      case NotificationType.chatMessage:
        iconData = Icons.message;
        color = Colors.blueAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    if (notification.actionUrl != null) {
      _navigateToActionUrl(notification.actionUrl!);
    }
  }

  void _handleNotificationAction(String action, AppNotification notification) {
    switch (action) {
      case 'mark_read':
        _notificationService.markAsRead(notification.id);
        break;
      case 'view':
        if (notification.actionUrl != null) {
          _navigateToActionUrl(notification.actionUrl!);
        }
        break;
      case 'delete':
        _notificationService.deleteNotification(notification.id);
        break;
    }
  }

  void _navigateToActionUrl(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'reminder_settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReminderPreferencesScreen(),
          ),
        );
        break;
      case 'settings':
        _showNotificationSettings();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _notificationService.clearAllNotifications(_demoData.currentUser.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notification settings would be configured here in a real app.'),
            SizedBox(height: 16),
            Text('This includes:'),
            Text('• Push notification preferences'),
            Text('• Notification sound settings'),
            Text('• Quiet hours configuration'),
            Text('• Category-specific controls'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    _notificationService.markAllAsRead(_demoData.currentUser.id);
  }

  void _generateSampleNotifications() async {
    await _notificationService.sendFriendRequestNotification(
      _demoData.currentUser.id,
      _demoData.friends.first.id,
    );

    await _notificationService.sendNotification(
      userId: _demoData.currentUser.id,
      title: 'Study Session Reminder',
      body: 'Your study session starts in 15 minutes in Building 11',
      type: NotificationType.eventReminder,
      data: {'location': 'Building 11'},
    );

    await _notificationService.sendNotification(
      userId: _demoData.currentUser.id,
      title: 'Friend Location Update',
      body: 'Sarah is now at the Central Library',
      type: NotificationType.locationUpdate,
      data: {'friendName': 'Sarah', 'location': 'Central Library'},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample notifications generated!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _getSenderName(String senderId) {
    final sender = _demoData.getUserById(senderId);
    return sender?.name.split(' ')[0] ?? 'Unknown';
  }

  Widget _buildRemindersList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyReminderState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadNotifications();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildReminderCard(notification);
        },
      ),
    );
  }

  Widget _buildEmptyReminderState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders set',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reminders for upcoming events\nand deadlines will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReminderPreferencesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('Reminder Preferences'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(AppNotification notification) {
    final isDeadlineReminder = notification.data['isDeadline'] == true;
    final reminderType = notification.data['reminderType'] ?? '';
    final eventType = notification.data['eventType'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : Colors.orange[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDeadlineReminder ? Icons.assignment_late : Icons.alarm,
            color: Colors.orange,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (reminderType.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reminderType,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (eventType.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      eventType.split('.').last,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatNotificationTime(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleReminderAction(value, notification),
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(value: 'mark_read', child: Text('Mark as Read')),
            if (!isDeadlineReminder) ...[
              const PopupMenuItem(value: 'snooze_5', child: Text('Snooze 5 min')),
              const PopupMenuItem(value: 'snooze_15', child: Text('Snooze 15 min')),
            ],
            if (isDeadlineReminder)
              const PopupMenuItem(value: 'mark_complete', child: Text('Mark Complete')),
            if (notification.actionUrl != null)
              const PopupMenuItem(value: 'view', child: Text('View Event')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  void _handleReminderAction(String action, AppNotification notification) {
    switch (action) {
      case 'mark_read':
        _notificationService.markAsRead(notification.id);
        break;
      case 'view':
        if (notification.actionUrl != null) {
          _navigateToActionUrl(notification.actionUrl!);
        }
        break;
      case 'delete':
        _notificationService.deleteNotification(notification.id);
        break;
      case 'snooze_5':
        _snoozeReminder(notification, 5);
        break;
      case 'snooze_15':
        _snoozeReminder(notification, 15);
        break;
      case 'mark_complete':
        _markEventComplete(notification);
        break;
    }
  }

  void _snoozeReminder(AppNotification notification, int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder snoozed for $minutes minutes'),
        duration: const Duration(seconds: 2),
      ),
    );
    _notificationService.deleteNotification(notification.id);
  }

  void _markEventComplete(AppNotification notification) {
    final eventId = notification.data['eventId'];
    if (eventId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event marked as complete'),
          duration: Duration(seconds: 2),
        ),
      );
      _notificationService.deleteNotification(notification.id);
    }
  }
}
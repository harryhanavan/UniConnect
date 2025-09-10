import 'dart:async';
import 'package:flutter/material.dart';
import '../demo_data/demo_data_manager.dart';
import '../../shared/models/user.dart';
import '../../shared/models/event.dart';

enum NotificationType {
  friendRequest,
  friendAccepted,
  eventInvitation,
  eventReminder,
  locationUpdate,
  studyGroupInvite,
  societyEvent,
  timetableConflict,
  nearbyFriend,
  meetupSuggestion,
  chatMessage,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? actionUrl;
  final String? senderId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.data = const {},
    this.isRead = false,
    this.actionUrl,
    this.senderId,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
    String? actionUrl,
    String? senderId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      senderId: senderId ?? this.senderId,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<AppNotification> _notificationController = 
      StreamController<AppNotification>.broadcast();
  final StreamController<int> _badgeCountController = 
      StreamController<int>.broadcast();

  Stream<AppNotification> get notificationStream => _notificationController.stream;
  Stream<int> get badgeCountStream => _badgeCountController.stream;

  final List<AppNotification> _notifications = [];
  final Map<String, List<String>> _userSubscriptions = {};

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<AppNotification> getUserNotifications(String userId, {int? limit}) {
    final userNotifications = _notifications
        .where((n) => _isNotificationForUser(n, userId))
        .toList();
    
    userNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && limit > 0) {
      return userNotifications.take(limit).toList();
    }
    
    return userNotifications;
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? senderId,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      data: data ?? {},
      actionUrl: actionUrl,
      senderId: senderId,
    );

    _notifications.add(notification);
    _notificationController.add(notification);
    _badgeCountController.add(unreadCount);

    await _processNotificationActions(notification, userId);
  }

  Future<void> sendFriendRequestNotification(String receiverId, String senderId) async {
    final sender = DemoDataManager.instance.getUserById(senderId);
    if (sender == null) return;

    await sendNotification(
      userId: receiverId,
      title: 'New Friend Request',
      body: '${sender.name} sent you a friend request',
      type: NotificationType.friendRequest,
      data: {
        'senderId': senderId,
        'senderName': sender.name,
        'senderAvatar': sender.profileImageUrl,
      },
      actionUrl: '/friends/requests',
      senderId: senderId,
    );
  }

  Future<void> sendFriendAcceptedNotification(String receiverId, String accepterId) async {
    final accepter = DemoDataManager.instance.getUserById(accepterId);
    if (accepter == null) return;

    await sendNotification(
      userId: receiverId,
      title: 'Friend Request Accepted',
      body: '${accepter.name} accepted your friend request',
      type: NotificationType.friendAccepted,
      data: {
        'accepterId': accepterId,
        'accepterName': accepter.name,
        'accepterAvatar': accepter.profileImageUrl,
      },
      actionUrl: '/friends',
      senderId: accepterId,
    );
  }

  Future<void> sendEventInvitation(List<String> inviteeIds, Event event, String inviterId) async {
    final inviter = DemoDataManager.instance.getUserById(inviterId);
    if (inviter == null) return;

    for (final inviteeId in inviteeIds) {
      await sendNotification(
        userId: inviteeId,
        title: 'Event Invitation',
        body: '${inviter.name} invited you to ${event.title}',
        type: NotificationType.eventInvitation,
        data: {
          'eventId': event.id,
          'eventTitle': event.title,
          'eventStart': event.startTime.toIso8601String(),
          'inviterId': inviterId,
          'inviterName': inviter.name,
        },
        actionUrl: '/calendar/event/${event.id}',
        senderId: inviterId,
      );
    }
  }

  Future<void> sendEventReminder(String userId, Event event) async {
    final reminderTime = event.startTime.subtract(const Duration(minutes: 15));
    if (DateTime.now().isBefore(reminderTime)) return;

    await sendNotification(
      userId: userId,
      title: 'Event Reminder',
      body: '${event.title} starts in 15 minutes at ${event.location}',
      type: NotificationType.eventReminder,
      data: {
        'eventId': event.id,
        'eventTitle': event.title,
        'eventLocation': event.location,
        'eventStart': event.startTime.toIso8601String(),
      },
      actionUrl: '/calendar/event/${event.id}',
    );
  }

  Future<void> sendLocationUpdateNotification(String userId, String friendId, String locationName) async {
    final friend = DemoDataManager.instance.getUserById(friendId);
    if (friend == null) return;

    await sendNotification(
      userId: userId,
      title: 'Friend Location Update',
      body: '${friend.name} is now at $locationName',
      type: NotificationType.locationUpdate,
      data: {
        'friendId': friendId,
        'friendName': friend.name,
        'locationName': locationName,
      },
      actionUrl: '/map',
      senderId: friendId,
    );
  }

  Future<void> sendNearbyFriendNotification(String userId, String nearbyFriendId, String locationName) async {
    final friend = DemoDataManager.instance.getUserById(nearbyFriendId);
    if (friend == null) return;

    await sendNotification(
      userId: userId,
      title: 'Friend Nearby',
      body: '${friend.name} is nearby at $locationName. Say hi!',
      type: NotificationType.nearbyFriend,
      data: {
        'friendId': nearbyFriendId,
        'friendName': friend.name,
        'locationName': locationName,
      },
      actionUrl: '/map',
      senderId: nearbyFriendId,
    );
  }

  Future<void> sendStudyGroupInvite(List<String> inviteeIds, String groupName, String inviterId) async {
    final inviter = DemoDataManager.instance.getUserById(inviterId);
    if (inviter == null) return;

    for (final inviteeId in inviteeIds) {
      await sendNotification(
        userId: inviteeId,
        title: 'Study Group Invitation',
        body: '${inviter.name} invited you to join $groupName',
        type: NotificationType.studyGroupInvite,
        data: {
          'groupName': groupName,
          'inviterId': inviterId,
          'inviterName': inviter.name,
        },
        actionUrl: '/study-groups',
        senderId: inviterId,
      );
    }
  }

  Future<void> sendSocietyEventNotification(List<String> memberIds, Event event, String societyId) async {
    final societies = await DemoDataManager.instance.societies;
    final society = societies.firstWhere((s) => s.id == societyId);

    for (final memberId in memberIds) {
      await sendNotification(
        userId: memberId,
        title: 'New Society Event',
        body: '${society.name}: ${event.title} on ${_formatEventDate(event.startTime)}',
        type: NotificationType.societyEvent,
        data: {
          'eventId': event.id,
          'eventTitle': event.title,
          'societyId': societyId,
          'societyName': society.name,
          'eventStart': event.startTime.toIso8601String(),
        },
        actionUrl: '/calendar/event/${event.id}',
      );
    }
  }

  Future<void> sendTimetableConflictNotification(String userId, Event conflictEvent1, Event conflictEvent2) async {
    await sendNotification(
      userId: userId,
      title: 'Schedule Conflict Detected',
      body: 'You have overlapping events: ${conflictEvent1.title} and ${conflictEvent2.title}',
      type: NotificationType.timetableConflict,
      data: {
        'event1Id': conflictEvent1.id,
        'event1Title': conflictEvent1.title,
        'event2Id': conflictEvent2.id,
        'event2Title': conflictEvent2.title,
      },
      actionUrl: '/calendar',
    );
  }

  Future<void> sendMeetupSuggestion(String userId, List<String> friendIds, DateTime suggestedTime) async {
    final friends = friendIds.map((id) => DemoDataManager.instance.getUserById(id))
        .where((user) => user != null)
        .cast<User>()
        .toList();
    
    if (friends.isEmpty) return;

    final friendNames = friends.map((f) => f.name.split(' ')[0]).join(', ');

    await sendNotification(
      userId: userId,
      title: 'Meetup Suggestion',
      body: 'You and $friendNames are all free at ${_formatTime(suggestedTime)}. Perfect for a meetup!',
      type: NotificationType.meetupSuggestion,
      data: {
        'friendIds': friendIds,
        'suggestedTime': suggestedTime.toIso8601String(),
        'friendNames': friendNames,
      },
      actionUrl: '/calendar',
    );
  }

  Future<void> sendChatMessage({
    required String toUserId,
    required String fromUserId,
    required String chatName,
    required String messageContent,
    String? chatId,
  }) async {
    final sender = DemoDataManager.instance.getUserById(fromUserId);
    if (sender == null) return;

    await sendNotification(
      userId: toUserId,
      title: chatName,
      body: messageContent.length > 50 
          ? '${messageContent.substring(0, 47)}...'
          : messageContent,
      type: NotificationType.chatMessage,
      data: {
        'chatId': chatId,
        'senderId': fromUserId,
        'senderName': sender.name,
        'senderAvatar': sender.profileImageUrl,
        'messageContent': messageContent,
      },
      actionUrl: chatId != null ? '/chat/$chatId' : '/messages',
      senderId: fromUserId,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _badgeCountController.add(unreadCount);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_isNotificationForUser(_notifications[i], userId) && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _badgeCountController.add(unreadCount);
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _badgeCountController.add(unreadCount);
  }

  Future<void> clearAllNotifications(String userId) async {
    _notifications.removeWhere((n) => _isNotificationForUser(n, userId));
    _badgeCountController.add(unreadCount);
  }

  void subscribeToNotificationUpdates(String userId, String feature) {
    if (!_userSubscriptions.containsKey(userId)) {
      _userSubscriptions[userId] = [];
    }
    if (!_userSubscriptions[userId]!.contains(feature)) {
      _userSubscriptions[userId]!.add(feature);
    }
  }

  void unsubscribeFromNotificationUpdates(String userId, String feature) {
    if (_userSubscriptions.containsKey(userId)) {
      _userSubscriptions[userId]!.remove(feature);
    }
  }

  Future<void> _processNotificationActions(AppNotification notification, String userId) async {
    switch (notification.type) {
      case NotificationType.eventReminder:
        await _scheduleEventReminders(notification);
        break;
      case NotificationType.locationUpdate:
        await _checkForNearbyFriends(notification, userId);
        break;
      case NotificationType.timetableConflict:
        await _suggestConflictResolution(notification, userId);
        break;
      default:
        break;
    }
  }

  Future<void> _scheduleEventReminders(AppNotification notification) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _checkForNearbyFriends(AppNotification notification, String userId) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _suggestConflictResolution(AppNotification notification, String userId) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  bool _isNotificationForUser(AppNotification notification, String userId) {
    return notification.data.containsKey('userId') 
        ? notification.data['userId'] == userId
        : true;
  }

  String _formatEventDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void dispose() {
    _notificationController.close();
    _badgeCountController.close();
  }
}

class NotificationListenerWidget extends StatefulWidget {
  final Widget child;
  final String userId;

  const NotificationListenerWidget({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<NotificationListenerWidget> createState() => _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState extends State<NotificationListenerWidget> {
  late StreamSubscription<AppNotification> _notificationSubscription;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationSubscription = _notificationService.notificationStream.listen(
      (notification) {
        if (_isNotificationForCurrentUser(notification)) {
          _showInAppNotification(notification);
        }
      },
    );
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  bool _isNotificationForCurrentUser(AppNotification notification) {
    return notification.data.containsKey('userId') 
        ? notification.data['userId'] == widget.userId
        : true;
  }

  void _showInAppNotification(AppNotification notification) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: _getNotificationColor(notification.type),
        duration: const Duration(seconds: 4),
        action: notification.actionUrl != null
            ? SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => _handleNotificationAction(notification),
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        return Colors.blue;
      case NotificationType.eventInvitation:
      case NotificationType.eventReminder:
        return Colors.green;
      case NotificationType.locationUpdate:
      case NotificationType.nearbyFriend:
        return Colors.orange;
      case NotificationType.timetableConflict:
        return Colors.red;
      case NotificationType.studyGroupInvite:
        return Colors.purple;
      case NotificationType.societyEvent:
        return Colors.teal;
      case NotificationType.meetupSuggestion:
        return Colors.indigo;
      case NotificationType.chatMessage:
        return Colors.blueAccent;
    }
  }

  void _handleNotificationAction(AppNotification notification) {
    _notificationService.markAsRead(notification.id);
  }
}
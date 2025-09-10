import 'dart:async';
import '../demo_data/demo_data_manager.dart';
import '../../shared/models/chat_message.dart';
import 'notification_service.dart';
import 'loading_state_manager.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _demoData = DemoDataManager.instance;
  final _notificationService = NotificationService();
  final _loadingManager = LoadingStateManager();
  bool _isInitialized = false;
  
  // Ensure data is loaded before using any methods
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _loadingManager.withLoading(LoadingOperations.loadingChats, () async {
        await _demoData.users; // This triggers async initialization
        _isInitialized = true;
      });
    }
  }
  
  // Stream controllers for real-time updates
  final _messagesController = StreamController<List<ChatMessage>>.broadcast();
  final _chatsController = StreamController<List<Chat>>.broadcast();
  final _typingController = StreamController<Map<String, List<String>>>.broadcast();

  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;
  Stream<List<Chat>> get chatsStream => _chatsController.stream;
  Stream<Map<String, List<String>>> get typingStream => _typingController.stream;

  // In-memory storage for demo purposes
  final Map<String, List<ChatMessage>> _chatMessages = {};
  final Map<String, Chat> _chats = {};
  final Map<String, List<String>> _typingUsers = {}; // chatId -> list of typing userIds
  final Map<String, DateTime> _lastSeen = {}; // userId -> last seen timestamp

  void dispose() {
    _messagesController.close();
    _chatsController.close();
    _typingController.close();
  }

  // Initialize with demo data
  void _initializeDemoChats() {
    if (_chats.isNotEmpty) return;

    final users = _demoData.usersSync;
    final currentUserId = users.first.id;

    // Create demo direct message chats
    for (int i = 1; i < users.length && i <= 5; i++) {
      final otherUser = users[i];
      final chatId = _generateChatId([currentUserId, otherUser.id]);
      
      _chats[chatId] = Chat(
        id: chatId,
        name: otherUser.name,
        type: ChatType.direct,
        participantIds: [currentUserId, otherUser.id],
        createdAt: DateTime.now().subtract(Duration(days: i * 2)),
        createdBy: currentUserId,
        lastActivity: DateTime.now().subtract(Duration(hours: i)),
      );

      // Add demo messages
      _initializeDemoMessages(chatId, [currentUserId, otherUser.id]);
    }

    // Create demo group chat
    final groupChatId = 'group_study_cs101';
    _chats[groupChatId] = Chat(
      id: groupChatId,
      name: 'CS 101 Study Group',
      type: ChatType.studyGroup,
      participantIds: users.take(4).map((u) => u.id).toList(),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      createdBy: currentUserId,
      lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
    );
    _initializeDemoMessages(groupChatId, users.take(4).map((u) => u.id).toList());

    _chatsController.add(_chats.values.toList());
  }

  void _initializeDemoMessages(String chatId, List<String> participantIds) {
    _chatMessages[chatId] = [];
    
    final demoTexts = [
      "Hey! How's the assignment going?",
      "Pretty well, just working on the algorithm part",
      "Need any help with it?",
      "Actually yes, could you explain the sorting section?",
      "Sure! Let's meet at the library tomorrow?",
      "Sounds good! 2 PM work for you?",
      "Perfect, see you then!",
    ];

    for (int i = 0; i < demoTexts.length; i++) {
      final senderId = participantIds[i % participantIds.length];
      final message = ChatMessage(
        id: 'msg_${chatId}_$i',
        senderId: senderId,
        chatId: chatId,
        content: demoTexts[i],
        type: MessageType.text,
        timestamp: DateTime.now().subtract(Duration(hours: demoTexts.length - i)),
        status: MessageStatus.read,
      );
      
      _chatMessages[chatId]!.add(message);
    }

    // Update last message
    if (_chatMessages[chatId]!.isNotEmpty) {
      final lastMessage = _chatMessages[chatId]!.last;
      _chats[chatId] = _chats[chatId]!.copyWith(
        lastMessageId: lastMessage.id,
        lastActivity: lastMessage.timestamp,
      );
    }
  }

  String _generateChatId(List<String> participantIds) {
    final sorted = List<String>.from(participantIds)..sort();
    return 'chat_${sorted.join('_')}';
  }

  // Get user's chats
  Future<List<Chat>> getUserChats(String userId) async {
    await _ensureInitialized();
    _initializeDemoChats();
    
    final userChats = _chats.values
        .where((chat) => chat.participantIds.contains(userId))
        .toList();
    
    // Sort by last activity
    userChats.sort((a, b) => (b.lastActivity ?? b.createdAt)
        .compareTo(a.lastActivity ?? a.createdAt));
    
    return userChats;
  }

  // Get messages for a chat
  Future<List<ChatMessage>> getChatMessages(String chatId, {int limit = 50}) async {
    _initializeDemoChats();
    
    final messages = _chatMessages[chatId] ?? [];
    return messages.reversed.take(limit).toList().reversed.toList();
  }

  // Send a message
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    return await _loadingManager.withLoading(LoadingOperations.sendingMessage, () async {
      _initializeDemoChats();
      
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
      final message = ChatMessage(
        id: messageId,
        senderId: senderId,
        chatId: chatId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );

      // Add message to chat
      _chatMessages[chatId] = _chatMessages[chatId] ?? [];
      _chatMessages[chatId]!.add(message);

      // Update chat's last activity
      _chats[chatId] = _chats[chatId]!.copyWith(
        lastMessageId: messageId,
        lastActivity: message.timestamp,
      );

      // Simulate message delivery
      Timer(const Duration(milliseconds: 500), () {
        _updateMessageStatus(messageId, MessageStatus.delivered);
      });

      // Simulate read status
      Timer(const Duration(seconds: 2), () {
        _updateMessageStatus(messageId, MessageStatus.read);
      });

      // Notify streams
      _messagesController.add(_chatMessages[chatId]!);
      _chatsController.add(_chats.values.toList());

      // Send notification to other participants
      final chat = _chats[chatId]!;
      final otherParticipants = chat.participantIds.where((id) => id != senderId);
      for (final participantId in otherParticipants) {
        _notificationService.sendChatMessage(
          toUserId: participantId,
          fromUserId: senderId,
          chatName: chat.name,
          messageContent: content,
        );
      }

      return message;
    });
  }

  // Update message status
  void _updateMessageStatus(String messageId, MessageStatus status) {
    for (final messages in _chatMessages.values) {
      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        messages[messageIndex] = messages[messageIndex].copyWith(status: status);
        _messagesController.add(messages);
        break;
      }
    }
  }

  // Create or get direct message chat
  Future<Chat> createOrGetDirectChat(String userId, String otherUserId) async {
    _initializeDemoChats();
    
    final chatId = _generateChatId([userId, otherUserId]);
    
    if (_chats.containsKey(chatId)) {
      return _chats[chatId]!;
    }

    // Get other user info for chat name
    final users = _demoData.usersSync;
    final otherUser = users.firstWhere((u) => u.id == otherUserId);

    final chat = Chat(
      id: chatId,
      name: otherUser.name,
      type: ChatType.direct,
      participantIds: [userId, otherUserId],
      createdAt: DateTime.now(),
      createdBy: userId,
    );

    _chats[chatId] = chat;
    _chatMessages[chatId] = [];
    
    _chatsController.add(_chats.values.toList());
    
    return chat;
  }

  // Create group chat
  Future<Chat> createGroupChat({
    required String name,
    required String createdBy,
    required List<String> participantIds,
    ChatType type = ChatType.group,
  }) async {
    final chatId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    
    final chat = Chat(
      id: chatId,
      name: name,
      type: type,
      participantIds: participantIds,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    _chats[chatId] = chat;
    _chatMessages[chatId] = [];
    
    // Send system message
    final systemMessage = ChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      chatId: chatId,
      content: 'Group chat created',
      type: MessageType.system,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    
    _chatMessages[chatId]!.add(systemMessage);
    
    _chatsController.add(_chats.values.toList());
    _messagesController.add(_chatMessages[chatId]!);
    
    return chat;
  }

  // Typing indicators
  void startTyping(String chatId, String userId) {
    _typingUsers[chatId] = _typingUsers[chatId] ?? [];
    if (!_typingUsers[chatId]!.contains(userId)) {
      _typingUsers[chatId]!.add(userId);
      _typingController.add(Map.from(_typingUsers));
    }
  }

  void stopTyping(String chatId, String userId) {
    _typingUsers[chatId]?.remove(userId);
    if (_typingUsers[chatId]?.isEmpty ?? false) {
      _typingUsers.remove(chatId);
    }
    _typingController.add(Map.from(_typingUsers));
  }

  // Get typing users for chat
  List<String> getTypingUsers(String chatId, String currentUserId) {
    return (_typingUsers[chatId] ?? [])
        .where((id) => id != currentUserId)
        .toList();
  }

  // Search messages
  Future<List<ChatMessage>> searchMessages({
    required String query,
    String? chatId,
    String? userId,
  }) async {
    final results = <ChatMessage>[];
    
    final chatsToSearch = chatId != null 
        ? [chatId]
        : _chatMessages.keys;
    
    for (final id in chatsToSearch) {
      final messages = _chatMessages[id] ?? [];
      for (final message in messages) {
        if (userId != null && !_chats[id]!.participantIds.contains(userId)) {
          continue;
        }
        
        if (message.content.toLowerCase().contains(query.toLowerCase())) {
          results.add(message);
        }
      }
    }
    
    // Sort by relevance and recency
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return results.take(50).toList();
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    final messages = _chatMessages[chatId] ?? [];
    bool hasChanges = false;
    
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].senderId != userId && messages[i].status != MessageStatus.read) {
        messages[i] = messages[i].copyWith(status: MessageStatus.read);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      _messagesController.add(messages);
    }
    
    _lastSeen[userId] = DateTime.now();
  }

  // Get unread message count
  int getUnreadCount(String chatId, String userId) {
    final messages = _chatMessages[chatId] ?? [];
    return messages
        .where((m) => m.senderId != userId && m.status != MessageStatus.read)
        .length;
  }

  // Get total unread count for user
  int getTotalUnreadCount(String userId) {
    int total = 0;
    for (final chatId in _chats.keys) {
      if (_chats[chatId]!.participantIds.contains(userId)) {
        total += getUnreadCount(chatId, userId);
      }
    }
    return total;
  }
}
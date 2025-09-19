import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/app_state.dart';
import '../../core/services/chat_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/models/user.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();
  final _demoData = DemoDataManager.instance;
  
  List<Chat> _chats = [];
  final Map<String, User> _userCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _listenToUpdates();
  }

  Future<void> _loadChats() async {
    try {
      // Data is already initialized by AppState, but use async to be safe
      final users = await _demoData.users;
      final currentUserId = users.first.id;
      final chats = await _chatService.getUserChats(currentUserId);
      
      // Cache users for display
      for (final user in users) {
        _userCache[user.id] = user;
      }
      
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenToUpdates() {
    _chatService.chatsStream.listen((chats) {
      if (mounted) {
        setState(() {
          _chats = chats;
        });
      }
    });
  }

  String _getChatDisplayName(Chat chat, String currentUserId) {
    if (chat.isDirectMessage) {
      final otherUserId = chat.participantIds
          .firstWhere((id) => id != currentUserId);
      return _userCache[otherUserId]?.name ?? 'Unknown User';
    }
    return chat.name;
  }

  String? _getChatAvatar(Chat chat, String currentUserId) {
    if (chat.isDirectMessage) {
      final otherUserId = chat.participantIds
          .firstWhere((id) => id != currentUserId);
      return _userCache[otherUserId]?.profileImageUrl;
    }
    return null; // Group chats can have their own avatars later
  }

  Widget _buildChatTile(Chat chat) {
    final currentUserId = _demoData.usersSync.first.id;
    final displayName = _getChatDisplayName(chat, currentUserId);
    final avatarUrl = _getChatAvatar(chat, currentUserId);
    final unreadCount = _chatService.getUnreadCount(chat.id, currentUserId);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: AppTheme.getCardDecoration(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: avatarUrl != null 
              ? NetworkImage(avatarUrl) 
              : null,
          backgroundColor: const Color(0xFFF5F5F0),
          child: avatarUrl == null 
              ? Icon(
                  chat.isDirectMessage ? Icons.person : Icons.group,
                  color: const Color(0xFF2C2C2C),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.lastActivity != null)
              Text(
                _formatTime(chat.lastActivity!),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: FutureBuilder<List<ChatMessage>>(
                future: _chatService.getChatMessages(chat.id, limit: 1),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text(
                      chat.isDirectMessage 
                          ? 'Start a conversation...' 
                          : 'No messages yet...',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  
                  final lastMessage = snapshot.data!.last;
                  final sender = lastMessage.senderId == currentUserId 
                      ? 'You: ' 
                      : (chat.isDirectMessage 
                          ? '' 
                          : '${_userCache[lastMessage.senderId]?.name.split(' ').first ?? 'Unknown'}: ');
                  
                  return Text(
                    '$sender${_getMessagePreview(lastMessage)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? AppTheme.getTextColor(context)
                          : AppTheme.getSecondaryTextColor(context),
                      fontWeight: unreadCount > 0 
                          ? FontWeight.w500 
                          : FontWeight.normal,
                    ),
                  );
                },
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: AppTheme.getButtonTextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.getSecondaryIconColor(context),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chat: chat),
            ),
          );
        },
      ),
    );
  }

  String _getMessagePreview(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.location:
        return '📍 Location';
      case MessageType.event:
        return '📅 Event';
      case MessageType.system:
        return message.content;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildHeader() {
    final appState = Provider.of<AppState>(context, listen: true);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: appState.isTempStyleEnabled
              ? [AppColors.primaryDark, AppColors.primaryDark] // Option 3: Solid dark blue
              : [AppColors.socialColor, AppColors.socialColor.withValues(alpha: 0.8)], // Original bright green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Stay connected with friends',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewChatScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement search functionality
                      },
                    ),
                  ],
                ),
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
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _chats.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadChats,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _chats.length,
                          itemBuilder: (context, index) {
                            return _buildChatTile(_chats[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "new_chat",
        backgroundColor: const Color(0xFFF5F5F0),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewChatScreen(),
            ),
          );
        },
        child: const Icon(Icons.message_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.getSecondaryIconColor(context),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start connecting with friends and study groups to begin conversations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewChatScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Start New Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
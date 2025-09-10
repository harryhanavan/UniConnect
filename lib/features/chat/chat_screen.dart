import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../shared/models/chat_message.dart';
import '../../shared/models/user.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({
    super.key,
    required this.chat,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _demoData = DemoDataManager.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  final Map<String, User> _userCache = {};
  List<String> _typingUsers = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _replyingToMessageId;
  
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }
  
  Future<void> _initializeChat() async {
    final users = _demoData.usersSync;
    _currentUserId = users.first.id;
    _loadMessages();
    await _cacheUsers();
    _listenToUpdates();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.stopTyping(widget.chat.id, _currentUserId);
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getChatMessages(widget.chat.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cacheUsers() async {
    final users = _demoData.usersSync;
    for (final user in users) {
      _userCache[user.id] = user;
    }
  }

  void _listenToUpdates() {
    _chatService.messagesStream.listen((messages) {
      if (mounted && messages.isNotEmpty && messages.first.chatId == widget.chat.id) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    });

    _chatService.typingStream.listen((typingMap) {
      if (mounted) {
        setState(() {
          _typingUsers = _chatService.getTypingUsers(widget.chat.id, _currentUserId);
        });
      }
    });
  }

  void _markAsRead() {
    _chatService.markChatAsRead(widget.chat.id, _currentUserId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(
        chatId: widget.chat.id,
        senderId: _currentUserId,
        content: content,
        replyToMessageId: _replyingToMessageId,
      );
      
      _messageController.clear();
      _replyingToMessageId = null;
      _chatService.stopTyping(widget.chat.id, _currentUserId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _onTyping() {
    _chatService.startTyping(widget.chat.id, _currentUserId);
    
    // Stop typing after 3 seconds of inactivity
    Future.delayed(const Duration(seconds: 3), () {
      _chatService.stopTyping(widget.chat.id, _currentUserId);
    });
  }

  String _getChatTitle() {
    if (widget.chat.isDirectMessage) {
      final otherUserId = widget.chat.participantIds
          .firstWhere((id) => id != _currentUserId);
      return _userCache[otherUserId]?.name ?? 'Unknown User';
    }
    return widget.chat.name;
  }

  String? _getChatSubtitle() {
    if (widget.chat.isDirectMessage) {
      final otherUserId = widget.chat.participantIds
          .firstWhere((id) => id != _currentUserId);
      return 'Online'; // Could implement real online status
    } else {
      return '${widget.chat.participantIds.length} members';
    }
  }

  Widget _buildMessage(ChatMessage message, {bool showAvatar = true}) {
    final isMe = message.senderId == _currentUserId;
    final user = _userCache[message.senderId];
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: user?.profileImageUrl != null
                  ? NetworkImage(user!.profileImageUrl!)
                  : null,
              backgroundColor: AppColors.socialColor.withValues(alpha: 0.1),
              child: user?.profileImageUrl == null
                  ? Text(
                      user?.name.substring(0, 1) ?? '?',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.socialColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe && !showAvatar) ...[
            const SizedBox(width: 40),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && !widget.chat.isDirectMessage && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      user?.name ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (message.replyToMessageId != null)
                  _buildReplyPreview(message.replyToMessageId!),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.socialColor
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _getStatusIcon(message.status),
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(String messageId) {
    final replyMessage = _messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => ChatMessage(
        id: '',
        senderId: '',
        chatId: '',
        content: 'Message not found',
        type: MessageType.text,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      ),
    );
    
    final replyUser = _userCache[replyMessage.senderId];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppColors.socialColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyUser?.name ?? 'Unknown',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.socialColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyMessage.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (_typingUsers.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.socialColor.withValues(alpha: 0.1),
            child: Text(
              _userCache[_typingUsers.first]?.name.substring(0, 1) ?? '?',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.socialColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _typingUsers.length == 1
                ? '${_userCache[_typingUsers.first]?.name.split(' ').first} is typing...'
                : 'Multiple people are typing...',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.socialColor, AppColors.socialColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getChatTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_getChatSubtitle() != null)
                    Text(
                      _getChatSubtitle()!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Implement chat info/settings
              },
              icon: const Icon(Icons.more_vert, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final previousMessage = index > 0 ? _messages[index - 1] : null;
                      final showAvatar = previousMessage == null ||
                          previousMessage.senderId != message.senderId ||
                          message.timestamp.difference(previousMessage.timestamp).inMinutes > 5;
                      
                      return GestureDetector(
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          // TODO: Show message options (reply, copy, delete, etc.)
                        },
                        child: _buildMessage(message, showAvatar: showAvatar),
                      );
                    },
                  ),
          ),
          _buildTypingIndicator(),
          if (_replyingToMessageId != null) _buildReplyBar(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    final replyMessage = _messages.firstWhere(
      (m) => m.id == _replyingToMessageId,
      orElse: () => ChatMessage(
        id: '',
        senderId: '',
        chatId: '',
        content: 'Message not found',
        type: MessageType.text,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      ),
    );
    
    final replyUser = _userCache[replyMessage.senderId];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.socialColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${replyUser?.name ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.socialColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyMessage.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _replyingToMessageId = null;
              });
            },
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _onTyping(),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.socialColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
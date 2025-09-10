class ChatMessage {
  final String id;
  final String senderId;
  final String chatId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.chatId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    this.replyToMessageId,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? chatId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;
  bool get isLocation => type == MessageType.location;
  bool get isEvent => type == MessageType.event;
  bool get isVoice => type == MessageType.voice;
  bool get isReply => replyToMessageId != null;
  
  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isRead => status == MessageStatus.read;
  bool get isFailed => status == MessageStatus.failed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'chatId': chatId,
      'content': content,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      chatId: json['chatId'],
      content: json['content'],
      type: MessageType.values[json['type']],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values[json['status']],
      replyToMessageId: json['replyToMessageId'],
      metadata: json['metadata'],
    );
  }
}

enum MessageType {
  text,
  image,
  file,
  voice,
  location,
  event,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Chat {
  final String id;
  final String name;
  final ChatType type;
  final List<String> participantIds;
  final String? lastMessageId;
  final DateTime? lastActivity;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final String? createdBy;

  const Chat({
    required this.id,
    required this.name,
    required this.type,
    required this.participantIds,
    this.lastMessageId,
    this.lastActivity,
    this.settings,
    required this.createdAt,
    this.createdBy,
  });

  Chat copyWith({
    String? id,
    String? name,
    ChatType? type,
    List<String>? participantIds,
    String? lastMessageId,
    DateTime? lastActivity,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastActivity: lastActivity ?? this.lastActivity,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool get isDirectMessage => type == ChatType.direct;
  bool get isGroupChat => type == ChatType.group;
  bool get isStudyGroup => type == ChatType.studyGroup;
  bool get isSocietyChat => type == ChatType.society;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'participantIds': participantIds,
      'lastMessageId': lastMessageId,
      'lastActivity': lastActivity?.toIso8601String(),
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      type: ChatType.values[json['type']],
      participantIds: List<String>.from(json['participantIds']),
      lastMessageId: json['lastMessageId'],
      lastActivity: json['lastActivity'] != null 
          ? DateTime.parse(json['lastActivity']) 
          : null,
      settings: json['settings'],
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
    );
  }
}

enum ChatType {
  direct,
  group,
  studyGroup,
  society,
}
enum EventType {
  class_,
  society,
  personal,
  assignment
}

enum EventSource {
  personal,
  friends,
  societies,
  shared,
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final EventType type;
  final EventSource source;
  final String? societyId;
  final String? courseCode;
  final bool isAllDay;
  final List<String> attendeeIds;
  final String creatorId;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.type,
    this.source = EventSource.personal,
    this.societyId,
    this.courseCode,
    this.isAllDay = false,
    this.attendeeIds = const [],
    required this.creatorId,
  });

  static EventType _parseEventType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'class':
        return EventType.class_;
      case 'society':
        return EventType.society;
      case 'personal':
        return EventType.personal;
      case 'assignment':
        return EventType.assignment;
      default:
        return EventType.personal;
    }
  }

  static String _eventTypeToString(EventType type) {
    switch (type) {
      case EventType.class_:
        return 'class';
      case EventType.society:
        return 'society';
      case EventType.personal:
        return 'personal';
      case EventType.assignment:
        return 'assignment';
    }
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: DateTime.parse(json['scheduledDate'] as String),
      endTime: DateTime.parse(json['endDate'] as String),
      location: json['location'] as String,
      type: _parseEventType(json['type'] as String),
      source: EventSource.values.firstWhere(
        (e) => e.toString().split('.').last == json['source'],
        orElse: () => EventSource.personal,
      ),
      societyId: json['societyId'] as String?,
      courseCode: json['courseCode'] as String?,
      isAllDay: json['isAllDay'] as bool? ?? false,
      attendeeIds: List<String>.from(json['attendeeIds'] ?? []),
      creatorId: json['creatorId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledDate': startTime.toIso8601String(),
      'endDate': endTime.toIso8601String(),
      'location': location,
      'type': _eventTypeToString(type),
      'source': source.toString().split('.').last,
      'societyId': societyId,
      'courseCode': courseCode,
      'isAllDay': isAllDay,
      'attendeeIds': attendeeIds,
      'creatorId': creatorId,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    EventType? type,
    EventSource? source,
    String? societyId,
    String? courseCode,
    bool? isAllDay,
    List<String>? attendeeIds,
    String? creatorId,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      type: type ?? this.type,
      source: source ?? this.source,
      societyId: societyId ?? this.societyId,
      courseCode: courseCode ?? this.courseCode,
      isAllDay: isAllDay ?? this.isAllDay,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      creatorId: creatorId ?? this.creatorId,
    );
  }
}
enum StudyGroupType {
  assignment,
  exam,
  project,
  general,
}

enum StudyGroupStatus {
  active,
  completed,
  archived,
}

class StudyGroup {
  final String id;
  final String name;
  final String description;
  final String courseCode;
  final String courseName;
  final StudyGroupType type;
  final StudyGroupStatus status;
  final String creatorId;
  final List<String> memberIds;
  final List<String> invitedUserIds;
  final int maxMembers;
  final DateTime createdAt;
  final DateTime? completionDate;
  final DateTime? nextMeetingAt;
  final String? nextMeetingLocation;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.courseCode,
    required this.courseName,
    required this.type,
    this.status = StudyGroupStatus.active,
    required this.creatorId,
    required this.memberIds,
    this.invitedUserIds = const [],
    this.maxMembers = 8,
    required this.createdAt,
    this.completionDate,
    this.nextMeetingAt,
    this.nextMeetingLocation,
    this.tags = const [],
    this.metadata = const {},
  });

  StudyGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? courseCode,
    String? courseName,
    StudyGroupType? type,
    StudyGroupStatus? status,
    String? creatorId,
    List<String>? memberIds,
    List<String>? invitedUserIds,
    int? maxMembers,
    DateTime? createdAt,
    DateTime? completionDate,
    DateTime? nextMeetingAt,
    String? nextMeetingLocation,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return StudyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      type: type ?? this.type,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      invitedUserIds: invitedUserIds ?? this.invitedUserIds,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
      completionDate: completionDate ?? this.completionDate,
      nextMeetingAt: nextMeetingAt ?? this.nextMeetingAt,
      nextMeetingLocation: nextMeetingLocation ?? this.nextMeetingLocation,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isActive => status == StudyGroupStatus.active;
  bool get isFull => memberIds.length >= maxMembers;
  bool get hasUpcomingMeeting => nextMeetingAt != null && nextMeetingAt!.isAfter(DateTime.now());
  
  int get availableSpots => maxMembers - memberIds.length;
  
  String get typeDisplayName {
    switch (type) {
      case StudyGroupType.assignment:
        return 'Assignment';
      case StudyGroupType.exam:
        return 'Exam Prep';
      case StudyGroupType.project:
        return 'Project';
      case StudyGroupType.general:
        return 'General Study';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case StudyGroupStatus.active:
        return 'Active';
      case StudyGroupStatus.completed:
        return 'Completed';
      case StudyGroupStatus.archived:
        return 'Archived';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class StudySession {
  final String id;
  final String studyGroupId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? locationId;
  final List<String> attendeeIds;
  final List<String> materials;
  final String? notes;
  final DateTime createdAt;
  final String creatorId;

  const StudySession({
    required this.id,
    required this.studyGroupId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.locationId,
    required this.attendeeIds,
    this.materials = const [],
    this.notes,
    required this.createdAt,
    required this.creatorId,
  });

  StudySession copyWith({
    String? id,
    String? studyGroupId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? locationId,
    List<String>? attendeeIds,
    List<String>? materials,
    String? notes,
    DateTime? createdAt,
    String? creatorId,
  }) {
    return StudySession(
      id: id ?? this.id,
      studyGroupId: studyGroupId ?? this.studyGroupId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      locationId: locationId ?? this.locationId,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      materials: materials ?? this.materials,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      creatorId: creatorId ?? this.creatorId,
    );
  }

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing => DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);
  bool get isCompleted => endTime.isBefore(DateTime.now());
  
  Duration get duration => endTime.difference(startTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
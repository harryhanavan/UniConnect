import 'event.dart';
import 'event_enums.dart';

/// Enhanced Event model for Phase 2 implementation
/// Includes two-tier categorization, relationships, and privacy settings
class EventV2 {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  
  // Enhanced categorization
  final EventCategory category;
  final EventSubType subType;
  final EventOrigin origin;
  
  // Relationships
  final String creatorId;
  final List<String> organizerIds;
  final List<String> attendeeIds;
  final List<String> invitedIds;
  final List<String> interestedIds;
  
  // Privacy and sharing
  final EventPrivacyLevel privacyLevel;
  final EventSharingPermission sharingPermission;
  final EventDiscoverability discoverability;
  
  // Additional metadata
  final String? societyId;
  final String? courseCode;
  final bool isAllDay;
  final bool isRecurring;
  final String? recurringPattern;
  final String? parentEventId; // For recurring events
  final Map<String, dynamic>? customFields; // Extensible fields
  
  // Academic semester fields
  final String? semesterType; // "spring", "autumn", "summer", "winter"
  final int? semesterYear;
  final DateTime? semesterStartDate;
  final DateTime? semesterEndDate;
  final int? academicWeek; // Week number within semester
  
  // Direct date scheduling (NEW - replaces complex timing system)
  final DateTime? scheduledDate; // Primary scheduling field - when event occurs
  final DateTime? endDate; // When event ends (if different from calculated endTime)
  final bool isRecurringInstance; // True if this is an instance of a recurring event
  final DateTime? nextOccurrence; // For recurring events, when is the next occurrence
  final String? recurringRule; // RRULE or simple pattern for recurring events

  // Legacy date handling (DEPRECATED - to be removed after migration)
  final bool useAbsoluteDate; // If true, use exactDate instead of relative calculation
  final DateTime? exactDate; // For specific dated events
  final String? dayOfWeek; // For recurring weekly events
  final String? timeOfDay; // Time within the day (HH:mm format)
  final bool driftAdjustment; // Flag for demo data drift adjustment
  
  // Import metadata
  final String? importSource;
  final String? importId;
  final DateTime? lastSyncTime;
  final Map<String, dynamic>? importPeriod; // Semester period metadata for imports

  // Reminder settings
  final bool enableReminders;
  final List<int>? reminderMinutesBefore; // e.g., [5, 15, 60, 1440] for 5min, 15min, 1hr, 1day
  final bool? customReminderSound;
  final String? reminderNote;
  
  const EventV2({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.category,
    required this.subType,
    required this.origin,
    required this.creatorId,
    this.organizerIds = const [],
    this.attendeeIds = const [],
    this.invitedIds = const [],
    this.interestedIds = const [],
    this.privacyLevel = EventPrivacyLevel.friendsOnly,
    this.sharingPermission = EventSharingPermission.canSuggest,
    this.discoverability = EventDiscoverability.feedVisible,
    this.societyId,
    this.courseCode,
    this.isAllDay = false,
    this.isRecurring = false,
    this.recurringPattern,
    this.parentEventId,
    this.customFields,
    this.semesterType,
    this.semesterYear,
    this.semesterStartDate,
    this.semesterEndDate,
    this.academicWeek,
    // New direct date scheduling fields
    this.scheduledDate,
    this.endDate,
    this.isRecurringInstance = false,
    this.nextOccurrence,
    this.recurringRule,
    // Legacy fields (DEPRECATED)
    this.useAbsoluteDate = false,
    this.exactDate,
    this.dayOfWeek,
    this.timeOfDay,
    this.driftAdjustment = false,
    this.importSource,
    this.importId,
    this.lastSyncTime,
    this.importPeriod,
    // Reminder settings
    this.enableReminders = true,
    this.reminderMinutesBefore,
    this.customReminderSound,
    this.reminderNote,
  });
  
  /// Get user's relationship to this event
  EventRelationship getUserRelationship(String userId) {
    if (creatorId == userId) return EventRelationship.owner;
    if (organizerIds.contains(userId)) return EventRelationship.organizer;
    if (attendeeIds.contains(userId)) return EventRelationship.attendee;
    if (invitedIds.contains(userId)) return EventRelationship.invited;
    if (interestedIds.contains(userId)) return EventRelationship.interested;
    
    // Check if user can see based on privacy
    if (privacyLevel == EventPrivacyLevel.public ||
        privacyLevel == EventPrivacyLevel.university) {
      return EventRelationship.observer;
    }
    
    return EventRelationship.none;
  }
  
  /// Check if user can view this event
  bool canUserView(String userId, {
    List<String>? userFriendIds,
    List<String>? userSocietyIds,
    String? userFaculty,
  }) {
    // Owner and organizers can always view
    if (creatorId == userId || organizerIds.contains(userId)) return true;
    
    // Check based on privacy level
    switch (privacyLevel) {
      case EventPrivacyLevel.public:
        return true;
      case EventPrivacyLevel.university:
        return true; // Assuming all users are uni students
      case EventPrivacyLevel.faculty:
        // Would need to check faculty match
        return userFaculty != null && courseCode?.startsWith(userFaculty) == true;
      case EventPrivacyLevel.societyOnly:
        return societyId != null && userSocietyIds?.contains(societyId) == true;
      case EventPrivacyLevel.friendsOnly:
        return userFriendIds?.contains(creatorId) == true;
      case EventPrivacyLevel.friendsOfFriends:
        // Would need friend-of-friend check
        return false; // Simplified for now
      case EventPrivacyLevel.inviteOnly:
        return invitedIds.contains(userId) || attendeeIds.contains(userId);
      case EventPrivacyLevel.private:
        return creatorId == userId;
    }
  }
  
  /// Check if user can edit this event
  bool canUserEdit(String userId) {
    return creatorId == userId || organizerIds.contains(userId);
  }
  
  /// Check if user can share this event
  bool canUserShare(String userId) {
    if (sharingPermission == EventSharingPermission.hidden) return false;
    if (sharingPermission == EventSharingPermission.noShare) {
      return creatorId == userId || organizerIds.contains(userId);
    }
    return canUserView(userId);
  }
  
  /// Create from legacy Event model
  factory EventV2.fromLegacyEvent(Event legacyEvent) {
    final subType = EventTypeHelper.fromLegacyType(
      legacyEvent.type.toString().split('.').last
    );
    final category = EventTypeHelper.getCategoryForSubType(subType);
    
    // Determine origin based on legacy source
    EventOrigin origin;
    switch (legacyEvent.source) {
      case EventSource.personal:
        origin = legacyEvent.creatorId == 'system' 
            ? EventOrigin.system 
            : EventOrigin.user;
        break;
      case EventSource.societies:
        origin = EventOrigin.society;
        break;
      case EventSource.friends:
        origin = EventOrigin.friend;
        break;
      case EventSource.shared:
        origin = EventOrigin.user;
        break;
    }
    
    // Determine privacy based on legacy data
    EventPrivacyLevel privacy;
    if (legacyEvent.societyId != null) {
      privacy = EventPrivacyLevel.societyOnly;
    } else if (legacyEvent.attendeeIds.isNotEmpty) {
      privacy = EventPrivacyLevel.inviteOnly;
    } else if (legacyEvent.source == EventSource.friends) {
      privacy = EventPrivacyLevel.friendsOnly;
    } else {
      privacy = EventPrivacyLevel.friendsOnly;
    }
    
    return EventV2(
      id: legacyEvent.id,
      title: legacyEvent.title,
      description: legacyEvent.description,
      startTime: legacyEvent.startTime,
      endTime: legacyEvent.endTime,
      location: legacyEvent.location,
      category: category,
      subType: subType,
      origin: origin,
      creatorId: legacyEvent.creatorId,
      attendeeIds: legacyEvent.attendeeIds,
      privacyLevel: privacy,
      societyId: legacyEvent.societyId,
      courseCode: legacyEvent.courseCode,
      isAllDay: legacyEvent.isAllDay,
    );
  }
  
  /// Convert to legacy Event model for backward compatibility
  Event toLegacyEvent() {
    // Map category/subtype back to legacy EventType
    EventType legacyType;
    switch (subType) {
      case EventSubType.lecture:
      case EventSubType.tutorial:
      case EventSubType.lab:
        legacyType = EventType.class_;
        break;
      case EventSubType.assignment:
      case EventSubType.exam:
        legacyType = EventType.assignment;
        break;
      case EventSubType.meeting:
      case EventSubType.societyWorkshop:
      case EventSubType.competition:
      case EventSubType.fundraiser:
      case EventSubType.societyEvent:
        legacyType = EventType.society;
        break;
      default:
        legacyType = EventType.personal;
        break;
    }
    
    // Map origin to legacy EventSource
    EventSource legacySource;
    switch (origin) {
      case EventOrigin.society:
        legacySource = EventSource.societies;
        break;
      case EventOrigin.friend:
        legacySource = EventSource.friends;
        break;
      case EventOrigin.system:
      case EventOrigin.user:
        legacySource = EventSource.personal;
        break;
      default:
        legacySource = EventSource.shared;
        break;
    }
    
    return Event(
      id: id,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      type: legacyType,
      source: legacySource,
      creatorId: creatorId,
      attendeeIds: attendeeIds,
      societyId: societyId,
      courseCode: courseCode,
      isAllDay: isAllDay,
    );
  }
  
  EventV2 copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    EventCategory? category,
    EventSubType? subType,
    EventOrigin? origin,
    String? creatorId,
    List<String>? organizerIds,
    List<String>? attendeeIds,
    List<String>? invitedIds,
    List<String>? interestedIds,
    EventPrivacyLevel? privacyLevel,
    EventSharingPermission? sharingPermission,
    EventDiscoverability? discoverability,
    String? societyId,
    String? courseCode,
    bool? isAllDay,
    bool? isRecurring,
    String? recurringPattern,
    String? parentEventId,
    Map<String, dynamic>? customFields,
    // New direct date scheduling fields
    DateTime? scheduledDate,
    DateTime? endDate,
    bool? isRecurringInstance,
    DateTime? nextOccurrence,
    String? recurringRule,
    // Legacy fields
    String? importSource,
    String? importId,
    DateTime? lastSyncTime,
    // Reminder fields
    bool? enableReminders,
    List<int>? reminderMinutesBefore,
    bool? customReminderSound,
    String? reminderNote,
  }) {
    return EventV2(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      category: category ?? this.category,
      subType: subType ?? this.subType,
      origin: origin ?? this.origin,
      creatorId: creatorId ?? this.creatorId,
      organizerIds: organizerIds ?? this.organizerIds,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      invitedIds: invitedIds ?? this.invitedIds,
      interestedIds: interestedIds ?? this.interestedIds,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      sharingPermission: sharingPermission ?? this.sharingPermission,
      discoverability: discoverability ?? this.discoverability,
      societyId: societyId ?? this.societyId,
      courseCode: courseCode ?? this.courseCode,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      parentEventId: parentEventId ?? this.parentEventId,
      customFields: customFields ?? this.customFields,
      // New direct date scheduling fields
      scheduledDate: scheduledDate ?? this.scheduledDate,
      endDate: endDate ?? this.endDate,
      isRecurringInstance: isRecurringInstance ?? this.isRecurringInstance,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      recurringRule: recurringRule ?? this.recurringRule,
      // Legacy fields
      importSource: importSource ?? this.importSource,
      importId: importId ?? this.importId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      // Reminder fields
      enableReminders: enableReminders ?? this.enableReminders,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      customReminderSound: customReminderSound ?? this.customReminderSound,
      reminderNote: reminderNote ?? this.reminderNote,
    );
  }

  /// Get the actual date when this event occurs (prioritizes scheduledDate over startTime)
  DateTime get actualEventDate => scheduledDate ?? startTime;

  /// Get the actual end date when this event ends (prioritizes endDate over endTime)
  DateTime get actualEndDate => endDate ?? endTime;

  /// Check if this event uses the new direct date scheduling system
  bool get usesDirectDateScheduling => scheduledDate != null;

  /// Convert EventV2 to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'category': category.toString(),
      'subType': subType.toString(),
      'origin': origin.toString(),
      'creatorId': creatorId,
      'organizerIds': organizerIds,
      'attendeeIds': attendeeIds,
      'invitedIds': invitedIds,
      'interestedIds': interestedIds,
      'privacyLevel': privacyLevel.toString(),
      'sharingPermission': sharingPermission.toString(),
      'discoverability': discoverability.toString(),
      'societyId': societyId,
      'courseCode': courseCode,
      'isAllDay': isAllDay,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'parentEventId': parentEventId,
      'customFields': customFields,
      'semesterType': semesterType,
      'semesterYear': semesterYear,
      'semesterStartDate': semesterStartDate?.toIso8601String(),
      'semesterEndDate': semesterEndDate?.toIso8601String(),
      'academicWeek': academicWeek,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isRecurringInstance': isRecurringInstance,
      'nextOccurrence': nextOccurrence?.toIso8601String(),
      'recurringRule': recurringRule,
      'useAbsoluteDate': useAbsoluteDate,
      'exactDate': exactDate?.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'timeOfDay': timeOfDay,
      'driftAdjustment': driftAdjustment,
      'importSource': importSource,
      'importId': importId,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'importPeriod': importPeriod,
      'enableReminders': enableReminders,
      'reminderMinutesBefore': reminderMinutesBefore,
      'customReminderSound': customReminderSound,
      'reminderNote': reminderNote,
    };
  }

  /// Create EventV2 from JSON
  static EventV2 fromJson(Map<String, dynamic> json) {
    return EventV2(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      location: json['location'],
      category: EventCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => EventCategory.personal,
      ),
      subType: EventSubType.values.firstWhere(
        (e) => e.toString() == json['subType'],
        orElse: () => EventSubType.personalGoal,
      ),
      origin: EventOrigin.values.firstWhere(
        (e) => e.toString() == json['origin'],
        orElse: () => EventOrigin.user,
      ),
      creatorId: json['creatorId'],
      organizerIds: List<String>.from(json['organizerIds'] ?? []),
      attendeeIds: List<String>.from(json['attendeeIds'] ?? []),
      invitedIds: List<String>.from(json['invitedIds'] ?? []),
      interestedIds: List<String>.from(json['interestedIds'] ?? []),
      privacyLevel: EventPrivacyLevel.values.firstWhere(
        (e) => e.toString() == json['privacyLevel'],
        orElse: () => EventPrivacyLevel.friendsOnly,
      ),
      sharingPermission: EventSharingPermission.values.firstWhere(
        (e) => e.toString() == json['sharingPermission'],
        orElse: () => EventSharingPermission.canSuggest,
      ),
      discoverability: EventDiscoverability.values.firstWhere(
        (e) => e.toString() == json['discoverability'],
        orElse: () => EventDiscoverability.feedVisible,
      ),
      societyId: json['societyId'],
      courseCode: json['courseCode'],
      isAllDay: json['isAllDay'] ?? false,
      isRecurring: json['isRecurring'] ?? false,
      recurringPattern: json['recurringPattern'],
      parentEventId: json['parentEventId'],
      customFields: json['customFields'] != null
          ? Map<String, dynamic>.from(json['customFields'])
          : null,
      semesterType: json['semesterType'],
      semesterYear: json['semesterYear'],
      semesterStartDate: json['semesterStartDate'] != null
          ? DateTime.parse(json['semesterStartDate'])
          : null,
      semesterEndDate: json['semesterEndDate'] != null
          ? DateTime.parse(json['semesterEndDate'])
          : null,
      academicWeek: json['academicWeek'],
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      isRecurringInstance: json['isRecurringInstance'] ?? false,
      nextOccurrence: json['nextOccurrence'] != null
          ? DateTime.parse(json['nextOccurrence'])
          : null,
      recurringRule: json['recurringRule'],
      useAbsoluteDate: json['useAbsoluteDate'] ?? false,
      exactDate: json['exactDate'] != null
          ? DateTime.parse(json['exactDate'])
          : null,
      dayOfWeek: json['dayOfWeek'],
      timeOfDay: json['timeOfDay'],
      driftAdjustment: json['driftAdjustment'] ?? false,
      importSource: json['importSource'],
      importId: json['importId'],
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'])
          : null,
      importPeriod: json['importPeriod'] != null
          ? Map<String, dynamic>.from(json['importPeriod'])
          : null,
      enableReminders: json['enableReminders'] ?? true,
      reminderMinutesBefore: json['reminderMinutesBefore'] != null
          ? List<int>.from(json['reminderMinutesBefore'])
          : null, // Will be set to defaults in UI when needed
      customReminderSound: json['customReminderSound'],
      reminderNote: json['reminderNote'],
    );
  }

  /// Get default reminder settings based on event type
  static List<int>? getDefaultRemindersForType(EventSubType subType) {
    switch (subType) {
      case EventSubType.lecture:
      case EventSubType.tutorial:
      case EventSubType.lab:
        return [15]; // 15 minutes before class
      case EventSubType.exam:
        return [60, 1440]; // 1 hour and 1 day before exam
      case EventSubType.assignment:
        return [1440]; // 1 day before assignment due
      case EventSubType.meeting:
        return [15]; // 15 minutes before meeting
      case EventSubType.studySession:
        return [15]; // 15 minutes before study session
      case EventSubType.party:
      case EventSubType.meetup:
      case EventSubType.networking:
      case EventSubType.gameNight:
      case EventSubType.casualHangout:
        return [30]; // 30 minutes before social events
      case EventSubType.societyEvent:
        return [30, 60]; // 30 minutes and 1 hour before society events
      default:
        return [15]; // Default 15 minutes for other events
    }
  }
}
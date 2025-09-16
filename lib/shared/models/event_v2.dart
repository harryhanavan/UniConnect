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
  
  // Enhanced date handling
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
    this.useAbsoluteDate = false,
    this.exactDate,
    this.dayOfWeek,
    this.timeOfDay,
    this.driftAdjustment = false,
    this.importSource,
    this.importId,
    this.lastSyncTime,
    this.importPeriod,
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
    String? importSource,
    String? importId,
    DateTime? lastSyncTime,
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
      importSource: importSource ?? this.importSource,
      importId: importId ?? this.importId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}
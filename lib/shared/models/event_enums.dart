/// Enhanced event enums for Phase 2 implementation
/// Provides two-tier event categorization and relationship modeling

// Event Category - Top level grouping
enum EventCategory {
  academic,
  social,
  society,
  personal,
  university,
}

// Event Sub-Types - Specific types within each category
enum EventSubType {
  // Academic types
  lecture,
  tutorial,
  lab,
  exam,
  assignment,
  presentation,
  workshop,
  
  // Social types
  party,
  meetup,
  networking,
  gameNight,
  casualHangout,
  
  // Society types
  meeting,
  societyWorkshop,
  competition,
  fundraiser,
  societyEvent,
  
  // Personal types
  studySession,
  appointment,
  task,
  break_,
  personalGoal,
  
  // University types
  orientation,
  careerFair,
  guestLecture,
  administrative,
  ceremony,
}

// User's relationship to the event
enum EventRelationship {
  owner,        // I created this event
  organizer,    // I'm helping organize
  attendee,     // I'm attending
  invited,      // I'm invited but not confirmed
  interested,   // I marked interest
  observer,     // I can see but not invited
  none,         // No direct relationship
}

// Event origin - where the event came from
enum EventOrigin {
  system,       // Auto-generated from timetable
  user,         // Manually created
  society,      // From joined societies
  university,   // Official uni events
  friend,       // Shared by friend
  import,       // From external calendar
  aiSuggested,  // Smart recommendations
}

// Privacy levels for events
enum EventPrivacyLevel {
  public,           // Anyone can see/join
  university,       // Any uni student
  faculty,          // Students in same faculty/course
  societyOnly,      // Society members only
  friendsOnly,      // Only friends can see
  friendsOfFriends, // Extended network
  inviteOnly,       // Only specific invitees
  private,          // Only me
}

// Sharing permissions
enum EventSharingPermission {
  canShare,     // Others can share/invite
  canSuggest,   // Can suggest to friends
  noShare,      // Locked to current audience
  hidden,       // Doesn't appear in any feeds
}

// Event discoverability
enum EventDiscoverability {
  searchable,   // Appears in search
  recommended,  // Can be AI-suggested
  feedVisible,  // Shows in activity feeds
  calendarOnly, // Only in calendars
}

/// Helper class to manage event type relationships
class EventTypeHelper {
  /// Map sub-types to their categories
  static EventCategory getCategoryForSubType(EventSubType subType) {
    switch (subType) {
      case EventSubType.lecture:
      case EventSubType.tutorial:
      case EventSubType.lab:
      case EventSubType.exam:
      case EventSubType.assignment:
      case EventSubType.presentation:
      case EventSubType.workshop:
        return EventCategory.academic;
        
      case EventSubType.party:
      case EventSubType.meetup:
      case EventSubType.networking:
      case EventSubType.gameNight:
      case EventSubType.casualHangout:
        return EventCategory.social;
        
      case EventSubType.meeting:
      case EventSubType.societyWorkshop:
      case EventSubType.competition:
      case EventSubType.fundraiser:
      case EventSubType.societyEvent:
        return EventCategory.society;
        
      case EventSubType.studySession:
      case EventSubType.appointment:
      case EventSubType.task:
      case EventSubType.break_:
      case EventSubType.personalGoal:
        return EventCategory.personal;
        
      case EventSubType.orientation:
      case EventSubType.careerFair:
      case EventSubType.guestLecture:
      case EventSubType.administrative:
      case EventSubType.ceremony:
        return EventCategory.university;
    }
  }
  
  /// Get display name for sub-type
  static String getSubTypeDisplayName(EventSubType subType) {
    switch (subType) {
      case EventSubType.lecture: return 'Lecture';
      case EventSubType.tutorial: return 'Tutorial';
      case EventSubType.lab: return 'Lab';
      case EventSubType.exam: return 'Exam';
      case EventSubType.assignment: return 'Assignment';
      case EventSubType.presentation: return 'Presentation';
      case EventSubType.workshop: return 'Workshop';
      case EventSubType.party: return 'Party';
      case EventSubType.meetup: return 'Meetup';
      case EventSubType.networking: return 'Networking';
      case EventSubType.gameNight: return 'Game Night';
      case EventSubType.casualHangout: return 'Hangout';
      case EventSubType.meeting: return 'Meeting';
      case EventSubType.societyWorkshop: return 'Workshop';
      case EventSubType.competition: return 'Competition';
      case EventSubType.fundraiser: return 'Fundraiser';
      case EventSubType.societyEvent: return 'Event';
      case EventSubType.studySession: return 'Study Session';
      case EventSubType.appointment: return 'Appointment';
      case EventSubType.task: return 'Task';
      case EventSubType.break_: return 'Break';
      case EventSubType.personalGoal: return 'Personal Goal';
      case EventSubType.orientation: return 'Orientation';
      case EventSubType.careerFair: return 'Career Fair';
      case EventSubType.guestLecture: return 'Guest Lecture';
      case EventSubType.administrative: return 'Administrative';
      case EventSubType.ceremony: return 'Ceremony';
    }
  }
  
  /// Convert legacy EventType to new SubType
  static EventSubType fromLegacyType(String legacyType) {
    switch (legacyType) {
      case 'class_':
      case 'class':
        return EventSubType.lecture;
      case 'assignment':
        return EventSubType.assignment;
      case 'society':
        return EventSubType.societyEvent;
      case 'personal':
        return EventSubType.task;
      default:
        return EventSubType.task;
    }
  }
}
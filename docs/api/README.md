# API Documentation

## Overview

This documentation covers the service layer APIs and data models used throughout UniConnect. While the app currently uses demo data, the service layer is designed to easily transition to a real API backend.

## Service APIs

### 1. FriendshipService

**Location**: `lib/core/services/friendship_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getFriends` | `String userId` | `List<User>` | Get all friends for a user |
| `getPendingRequests` | `String userId` | `List<FriendRequest>` | Get pending friend requests |
| `getSentRequests` | `String userId` | `List<FriendRequest>` | Get sent friend requests |
| `sendFriendRequest` | `String fromId, String toId, String? message` | `Future<bool>` | Send a friend request |
| `acceptFriendRequest` | `String requestId` | `Future<bool>` | Accept a friend request |
| `declineFriendRequest` | `String requestId` | `Future<bool>` | Decline a friend request |
| `removeFriend` | `String userId, String friendId` | `Future<bool>` | Remove a friend |
| `areFriends` | `String userId1, String userId2` | `bool` | Check if two users are friends |

---

### 2. CalendarService

**Location**: `lib/core/services/calendar_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getEvents` | `DateTime date` | `List<Event>` | Get events for a specific date |
| `getEventsByDateRange` | `DateTime start, DateTime end` | `List<Event>` | Get events in date range |
| `getTodayEvents` | - | `List<Event>` | Get today's events |
| `getUpcomingEvents` | `int days` | `List<Event>` | Get upcoming events |
| `addEvent` | `Event event` | `Future<bool>` | Add a new event |
| `updateEvent` | `Event event` | `Future<bool>` | Update existing event |
| `deleteEvent` | `String eventId` | `Future<bool>` | Delete an event |
| `getEventById` | `String eventId` | `Event?` | Get specific event |

---

### 3. ChatService

**Location**: `lib/core/services/chat_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getChats` | `String userId` | `List<Chat>` | Get all chats for user |
| `getChatMessages` | `String chatId` | `Stream<List<ChatMessage>>` | Stream of chat messages |
| `sendMessage` | `String chatId, ChatMessage message` | `Future<bool>` | Send a message |
| `markAsRead` | `String chatId, String userId` | `Future<void>` | Mark chat as read |
| `createChat` | `List<String> participants` | `Future<Chat>` | Create new chat |
| `getUnreadCount` | `String userId` | `int` | Get unread message count |

---

### 4. LocationService

**Location**: `lib/core/services/location_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `updateUserLocation` | `String userId, double lat, double lng` | `Future<void>` | Update user location |
| `getFriendLocations` | `String userId` | `List<UserLocation>` | Get friend locations |
| `getNearbyUsers` | `double lat, double lng, double radius` | `List<User>` | Find nearby users |
| `getLocationById` | `String locationId` | `Location?` | Get location details |
| `checkPrivacy` | `String userId, String viewerId` | `bool` | Check location privacy |

---

### 5. PrivacyService

**Location**: `lib/core/services/privacy_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getPrivacySettings` | `String userId` | `PrivacySettings` | Get user privacy settings |
| `updatePrivacySettings` | `PrivacySettings settings` | `Future<bool>` | Update privacy settings |
| `canViewLocation` | `String userId, String viewerId` | `bool` | Check location visibility |
| `canViewTimetable` | `String userId, String viewerId` | `bool` | Check timetable visibility |
| `canViewOnlineStatus` | `String userId, String viewerId` | `bool` | Check online status visibility |

---

### 6. NotificationService

**Location**: `lib/core/services/notification_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getNotifications` | `String userId` | `List<Notification>` | Get user notifications |
| `markAsRead` | `String notificationId` | `Future<void>` | Mark notification as read |
| `clearAll` | `String userId` | `Future<void>` | Clear all notifications |
| `sendNotification` | `Notification notification` | `Future<void>` | Send a notification |
| `getUnreadCount` | `String userId` | `int` | Get unread count |

---

### 7. StudyGroupService

**Location**: `lib/core/services/study_group_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getStudyGroups` | `String userId` | `List<StudyGroup>` | Get user's study groups |
| `createStudyGroup` | `StudyGroup group` | `Future<StudyGroup>` | Create new study group |
| `joinStudyGroup` | `String groupId, String userId` | `Future<bool>` | Join a study group |
| `leaveStudyGroup` | `String groupId, String userId` | `Future<bool>` | Leave a study group |
| `findStudyGroups` | `String subject` | `List<StudyGroup>` | Find study groups by subject |

---

### 8. SearchService

**Location**: `lib/core/services/search_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `searchUsers` | `String query` | `List<User>` | Search for users |
| `searchSocieties` | `String query` | `List<Society>` | Search for societies |
| `searchEvents` | `String query` | `List<Event>` | Search for events |
| `globalSearch` | `String query` | `SearchResults` | Search across all types |

---

### 9. RecommendationService

**Location**: `lib/core/services/recommendation_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getRecommendedFriends` | `String userId` | `List<User>` | Get friend recommendations |
| `getRecommendedSocieties` | `String userId` | `List<Society>` | Get society recommendations |
| `getRecommendedEvents` | `String userId` | `List<Event>` | Get event recommendations |

---

### 10. AchievementService

**Location**: `lib/core/services/achievement_service.dart`

#### Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `getUserAchievements` | `String userId` | `List<Achievement>` | Get user achievements |
| `unlockAchievement` | `String userId, String achievementId` | `Future<bool>` | Unlock an achievement |
| `getProgress` | `String userId` | `AchievementProgress` | Get achievement progress |

## Data Models

### User Model

**Location**: `lib/shared/models/user.dart`

```dart
class User {
  final String id;
  final String name;
  final String email;
  final String course;
  final String year;
  final String profileImageUrl;
  final bool isOnline;
  final UserStatus status;
  final String? currentLocationId;
  final String? currentBuilding;
  final String? currentRoom;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;
  final String? statusMessage;
  final List<String> friendIds;
  final List<String> pendingFriendRequests;
  final List<String> sentFriendRequests;
  final String privacySettingsId;
}

enum UserStatus {
  online,
  offline,
  busy,
  away,
  inClass,
  studying
}
```

### Event Model

**Location**: `lib/shared/models/event.dart`

```dart
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final EventType type;
  final EventSource source;
  final bool isAllDay;
  final String? societyId;
  final String? courseCode;
  final String? creatorId;
  final List<String> attendeeIds;
}

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
  shared
}
```

### Society Model

**Location**: `lib/shared/models/society.dart`

```dart
class Society {
  final String id;
  final String name;
  final String description;
  final String category;
  final String logoUrl;
  final int memberCount;
  final List<String> tags;
  final bool isJoined;
  final List<String> memberIds;
  final List<String> adminIds;
}
```

### Location Model

**Location**: `lib/shared/models/location.dart`

```dart
class Location {
  final String id;
  final String name;
  final String building;
  final String room;
  final String floor;
  final LocationType type;
  final double latitude;
  final double longitude;
  final String? description;
  final bool isAccessible;
  final int? capacity;
  final List<String> amenities;
  final DateTime createdAt;
}

enum LocationType {
  classroom,
  library,
  cafeteria,
  common,
  outdoor,
  study,
  lab,
  office,
  other
}
```

### PrivacySettings Model

**Location**: `lib/shared/models/privacy_settings.dart`

```dart
class PrivacySettings {
  final String id;
  final String userId;
  final DateTime createdAt;
  final LocationSharingLevel locationSharing;
  final bool shareExactLocation;
  final bool shareBuildingOnly;
  final TimetableSharingLevel timetableSharing;
  final bool shareFreeTimes;
  final bool shareClassDetails;
  final OnlineStatusVisibility onlineStatusVisibility;
  final bool showLastSeen;
  final Map<String, CustomPrivacyRule>? customRules;
}

enum LocationSharingLevel {
  nobody,
  friends,
  friendsOfFriends,
  everyone
}

enum TimetableSharingLevel {
  nobody,
  friends,
  everyone
}

enum OnlineStatusVisibility {
  nobody,
  friends,
  everyone
}
```

### FriendRequest Model

**Location**: `lib/shared/models/friend_request.dart`

```dart
class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;
}

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  cancelled
}
```

### ChatMessage Model

**Location**: `lib/shared/models/chat_message.dart`

```dart
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
}

enum MessageType {
  text,
  image,
  location,
  event
}
```

## Response Formats

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data
  },
  "message": "Operation successful"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description"
  }
}
```

## Error Codes

| Code | Description |
|------|-------------|
| `AUTH_REQUIRED` | Authentication required |
| `PERMISSION_DENIED` | No permission for operation |
| `NOT_FOUND` | Resource not found |
| `INVALID_INPUT` | Invalid input data |
| `RATE_LIMIT` | Rate limit exceeded |
| `SERVER_ERROR` | Internal server error |

## Future API Integration

The service layer is designed to easily transition from demo data to a real API:

1. **Replace DemoDataManager** with API client
2. **Add HTTP methods** to services
3. **Implement caching** for offline support
4. **Add error handling** for network issues
5. **Implement authentication** flow
6. **Add pagination** for large datasets
7. **Implement real-time updates** via WebSockets
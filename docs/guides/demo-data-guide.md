# UniConnect Demo Data Management Guide

## Overview

The UniConnect application uses a comprehensive demo data system managed through `DemoDataManager` located at `lib/core/demo_data/demo_data_manager.dart`. This singleton class provides all mock data for the application, including users, societies, events, locations, privacy settings, and friend relationships.

## Architecture

### Singleton Pattern
```dart
DemoDataManager.instance  // Access the singleton instance
```

The manager initializes all interconnected data automatically when first accessed.

## Data Categories

### 1. Users (`User`)
**Location**: `lib/shared/models/user.dart`

**Key Fields**:
- Personal info: `id`, `name`, `email`, `course`, `year`
- Status: `status` (online/offline/busy/away/inClass/studying)
- Location: `currentLocationId`, `currentBuilding`, `currentRoom`, `latitude`, `longitude`
- Relationships: `friendIds`, `pendingFriendRequests`, `sentFriendRequests`
- Privacy: `privacySettingsId`

**Current Demo Users**:
- `user_001`: Andrea Fernandez (current logged-in user)
- `user_002`: Sarah Mitchell
- `user_003`: Marcus Rodriguez
- `user_004`: Emma Watson
- `user_005`: James Kim

### 2. Societies (`Society`)
**Location**: `lib/shared/models/society.dart`

**Key Fields**:
- Basic: `id`, `name`, `description`, `category`
- Metadata: `memberCount`, `tags`, `logoUrl`
- Relationships: `memberIds`, `adminIds`
- State: `isJoined`

**Demo Societies** (lines 27-83):
- `soc_001`: UTS Programmers Society
- `soc_002`: Design Collective
- `soc_003`: Basketball Club
- `soc_004`: International Student Society
- `soc_005`: Entrepreneur Society

### 3. Events (`Event`)
**Location**: `lib/shared/models/event.dart`

**Key Fields**:
- Basic: `id`, `title`, `description`, `location`
- Timing: `startTime`, `endTime`, `isAllDay`
- Classification: `type` (class_/society/personal/assignment), `source` (personal/friends/societies/shared)
- Relationships: `societyId`, `courseCode`, `creatorId`, `attendeeIds`

**Event Generation** (lines 86-232):
Events are dynamically generated based on the current date and include:
- Today's classes
- Tomorrow's events
- Weekly events
- Personal events
- Friend events
- Society events

### 4. Locations (`Location`)
**Location**: `lib/shared/models/location.dart`

**Key Fields**:
- Basic: `id`, `name`, `building`, `room`, `floor`
- Type: `type` (classroom/library/cafeteria/common/outdoor/study/lab/office/other)
- Coordinates: `latitude`, `longitude`
- Metadata: `capacity`, `amenities`, `isAccessible`

**Demo Locations** (lines 305-414):
- `loc_001`: Interactive Design Studio
- `loc_002`: Database Lab
- `loc_003`: Student Hub
- `loc_004`: Library Study Area
- `loc_005`: Design Studio
- `loc_006`: Building 1 Lobby
- `loc_007`: Student Centre

### 5. Privacy Settings (`PrivacySettings`)
**Location**: `lib/shared/models/privacy_settings.dart`

**Key Features**:
- Location sharing controls
- Timetable visibility settings
- Online status preferences
- Per-friend customization options

**Demo Settings** (lines 417-490):
Each user has customized privacy settings:
- Andrea: Moderate privacy
- Sarah: Open privacy
- Marcus: Private settings
- Emma: Default settings
- James: Selective sharing

### 6. Friend Requests (`FriendRequest`)
**Location**: `lib/shared/models/friend_request.dart`

**Key Fields**:
- `id`, `senderId`, `receiverId`
- `status` (pending/accepted/declined/cancelled)
- `message`, `createdAt`, `respondedAt`

**Demo Requests** (lines 602-635):
- Pending: Marcus → Andrea
- Accepted: Andrea ↔ Sarah, Andrea ↔ James

## Adding New Demo Data

### Step 1: Add New Users

```dart
// In _createDemoUsersWithRelationships() method (line 493)
User(
  id: 'user_006',
  name: 'Alex Thompson',
  email: 'alex.thompson@student.uts.edu.au',
  course: 'Bachelor of Science',
  year: '2nd Year',
  privacySettingsId: 'privacy_006',
  profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Alex',
  isOnline: true,
  status: UserStatus.studying,
  currentLocationId: 'loc_004',
  currentBuilding: 'UTS Library',
  currentRoom: 'Level 2',
  latitude: -33.8841,
  longitude: 151.2006,
  locationUpdatedAt: now.subtract(const Duration(minutes: 15)),
  statusMessage: 'Preparing for exams',
  friendIds: ['user_001'],
  pendingFriendRequests: [],
  sentFriendRequests: [],
),
```

### Step 2: Add New Societies

```dart
// In _societies list (line 27)
Society(
  id: 'soc_006',
  name: 'Photography Club',
  description: 'Capture moments, share perspectives. Weekly photo walks and workshops.',
  category: 'Creative',
  logoUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=photography',
  memberCount: 150,
  tags: ['Photography', 'Art', 'Creative', 'Workshops'],
  isJoined: false,
  adminIds: ['user_006'],
),
```

### Step 3: Add New Events

```dart
// In _generateDemoEvents() method (line 86)
Event(
  id: 'event_011',
  title: 'Photo Walk: Sydney Harbour',
  description: 'Join us for a sunset photography session at Sydney Harbour',
  startTime: today.add(const Duration(days: 6, hours: 17)),
  endTime: today.add(const Duration(days: 6, hours: 19)),
  location: 'Meet at Circular Quay',
  type: EventType.society,
  source: EventSource.societies,
  societyId: 'soc_006',
  creatorId: 'user_006',
  attendeeIds: ['user_001', 'user_006'],
),
```

### Step 4: Add New Locations

```dart
// In _createDemoLocations() method (line 305)
Location(
  id: 'loc_008',
  name: 'Sports Hall',
  building: 'Building 5',
  room: 'Main Hall',
  floor: 'G',
  type: LocationType.other,
  latitude: -33.8840,
  longitude: 151.2005,
  description: 'Indoor sports facilities',
  isAccessible: true,
  capacity: 200,
  amenities: ['Basketball courts', 'Volleyball nets', 'Change rooms'],
  createdAt: now,
),
```

### Step 5: Add Privacy Settings for New Users

```dart
// In _createDemoPrivacySettings() method (line 417)
PrivacySettings(
  id: 'privacy_006',
  userId: 'user_006',
  createdAt: now,
  locationSharing: LocationSharingLevel.friends,
  shareExactLocation: true,
  shareBuildingOnly: false,
  timetableSharing: TimetableSharingLevel.everyone,
  shareFreeTimes: true,
  shareClassDetails: true,
  onlineStatusVisibility: OnlineStatusVisibility.everyone,
  showLastSeen: true,
),
```

### Step 6: Add Friend Relationships

```dart
// In _createDemoFriendRequests() method (line 602)
FriendRequest(
  id: 'freq_004',
  senderId: 'user_006',
  receiverId: 'user_001',
  status: FriendRequestStatus.accepted,
  createdAt: now.subtract(const Duration(days: 7)),
  respondedAt: now.subtract(const Duration(days: 6)),
  message: 'Fellow photographer! Let\'s connect.',
),
```

## Editing Existing Demo Data

### Modifying User Properties

```dart
// Find the user in _createDemoUsersWithRelationships() 
// Example: Change Sarah's status and location (line 519)
User(
  id: 'user_002',
  name: 'Sarah Mitchell',
  // ... other properties
  status: UserStatus.inClass,  // Changed from studying
  currentLocationId: 'loc_005',  // Changed location
  currentBuilding: 'Building 6',
  currentRoom: 'Studio A',
  statusMessage: 'In design workshop',  // Updated message
  // ...
),
```

### Updating Society Membership

```dart
// Modify in _societies list
Society(
  id: 'soc_001',
  // ... other properties
  memberCount: 500,  // Increased from 450
  isJoined: false,    // Changed from true
  tags: ['Programming', 'AI', 'Machine Learning'],  // Added new tags
  // ...
),
```

### Changing Event Times

```dart
// In _generateDemoEvents()
Event(
  id: 'event_001',
  title: 'Interactive Design Lecture',
  // ... other properties
  startTime: today.add(const Duration(hours: 11)),  // Changed from 10
  endTime: today.add(const Duration(hours: 13)),    // Changed from 12
  location: 'CB02.05.30',  // Changed room
  // ...
),
```

## Helper Methods

The DemoDataManager provides several helper methods:

### Getters
- `currentUser`: Get the logged-in user
- `users`: All demo users
- `societies`: All societies
- `events`: All events (dynamically generated)
- `friends`: Friends of current user
- `joinedSocieties`: Societies current user has joined
- `todayEvents`: Events happening today
- `locations`: All demo locations
- `privacySettings`: All privacy settings
- `friendRequests`: All friend requests

### Query Methods
- `getUserById(String id)`: Get specific user
- `getSocietyById(String id)`: Get specific society
- `getLocationById(String id)`: Get specific location
- `getPrivacySettingsForUser(String userId)`: Get user's privacy settings
- `getEventsByDateRange(DateTime start, DateTime end)`: Get events in date range
- `getPendingFriendRequests(String userId)`: Get pending requests for user
- `getSentFriendRequests(String userId)`: Get sent requests by user
- `getFriendsForUser(String userId)`: Get user's friends
- `areFriends(String userId1, String userId2)`: Check if two users are friends

### Modification Methods
- `joinSociety(String societyId)`: Join a society
- `leaveSociety(String societyId)`: Leave a society

## Best Practices

1. **Maintain Relationships**: When adding users, ensure friend relationships are bidirectional
2. **Unique IDs**: Always use unique IDs following the pattern: `type_XXX` (e.g., `user_001`, `soc_001`)
3. **Time-based Data**: Events use relative dates from `DateTime.now()` to stay current
4. **Privacy Consistency**: Each user must have corresponding privacy settings
5. **Location Accuracy**: Use realistic UTS coordinates (around -33.88, 151.20)
6. **Profile Images**: Use dicebear API with consistent seed for avatars

## Testing Your Changes

After modifying demo data:

1. Hot reload the app to see changes immediately
2. Navigate to relevant screens to verify data appears correctly
3. Check relationships work (e.g., friends appear in friends list)
4. Verify privacy settings are respected
5. Test time-based features (events, online status)

## Common Issues and Solutions

### Issue: New user doesn't appear
**Solution**: Ensure user is added to `_createDemoUsersWithRelationships()` return list

### Issue: Friend relationship not working
**Solution**: Add friendIds to both users and create corresponding FriendRequest

### Issue: Events not showing
**Solution**: Check event dates are relative to `DateTime.now()` and within view range

### Issue: Location not found
**Solution**: Verify location ID matches between user/event and location definition

### Issue: Privacy settings not applied
**Solution**: Ensure privacySettingsId in User matches PrivacySettings id
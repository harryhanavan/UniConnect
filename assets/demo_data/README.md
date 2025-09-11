# Demo Data Management Guide

This directory contains JSON files that define the demo data for UniConnect. All data is loaded from these files when the app starts, making it easy to modify demo content without touching code.

## File Structure

- **`users.json`** - User accounts, profiles, and relationships
- **`societies.json`** - University societies/clubs information
- **`events.json`** - Enhanced events with two-tier categorization, relationships, and privacy controls
- **`locations.json`** - Campus locations and buildings
- **`privacy_settings.json`** - User privacy preferences
- **`friend_requests.json`** - Friend request data

## Managing Demo Data

### Adding a New User

1. **Add user to `users.json`**:
   ```json
   {
     "id": "user_006",
     "name": "Alex Johnson",
     "email": "alex.johnson@student.uts.edu.au",
     "course": "Bachelor of Computer Science",
     "year": "1st Year",
     "privacySettingsId": "privacy_006",
     "profileImageUrl": "https://api.dicebear.com/7.x/avataaars/png?seed=Alex",
     "isOnline": true,
     "status": "online",
     "statusMessage": "New student!",
     "friendIds": ["user_001"],
     "pendingFriendRequests": [],
     "sentFriendRequests": []
   }
   ```

2. **Add privacy settings in `privacy_settings.json`**:
   ```json
   {
     "id": "privacy_006",
     "userId": "user_006",
     "locationSharing": "friends",
     "timetableSharing": "friends",
     "onlineStatusVisibility": "friends"
   }
   ```

3. **Update friend relationships** - If the new user has friends, add their ID to those friends' `friendIds` arrays (relationships must be bidirectional).

### Adding Friend Relationships

Friend relationships must be **bidirectional** - if User A is friends with User B, then:
- User A's `friendIds` must contain User B's ID
- User B's `friendIds` must contain User A's ID

**Example**: Making user_006 friends with user_001:

In `users.json`, update both users:
```json
// user_001
"friendIds": ["user_002", "user_005", "user_006"]

// user_006  
"friendIds": ["user_001"]
```

### Adding Events

Events use **relative dates** and **enhanced categorization** for comprehensive event management:

```json
{
  "id": "event_020",
  "title": "New Workshop",
  "description": "Description of the workshop",
  "daysFromNow": 7,
  "hoursFromStart": 14,
  "duration": 2,
  "location": "Building 11, Room 450",
  "type": "society",
  "subType": "workshop",
  "category": "social",
  "origin": "society",
  "societyId": "soc_001",
  "organizerIds": ["user_002"],
  "attendeeIds": ["user_001", "user_002"],
  "invitedIds": ["user_003"],
  "interestedIds": ["user_004"],
  "privacyLevel": "societyOnly",
  "sharingPermission": "canShare",
  "discoverability": "friendsOnly",
  "isRecurring": false
}
```

**Date Fields**:
- `daysFromNow`: Number of days from today (0 = today, 1 = tomorrow, etc.)
- `hoursFromStart`: Hour of day (24-hour format)
- `duration`: Length in hours (can use decimals like 1.5)
- `isAllDay`: Set to true for all-day events (omit hoursFromStart and duration)

**Event Classification**:
- **Type**: `class`, `assignment`, `society`, `personal` (legacy compatibility)
- **SubType**: `lecture`, `tutorial`, `lab`, `exam`, `meeting`, `social`, `workshop`, `study`, `assignment`, `project`, `deadline`, `reminder`, `other`
- **Category**: `academic`, `social`, `personal`, `sports`, `cultural`
- **Origin**: `system`, `user`, `society`, `imported`

**Relationship Fields**:
- `organizerIds`: Event organizers (who can manage the event)
- `attendeeIds`: Confirmed attendees
- `invitedIds`: Users invited but not yet responded
- `interestedIds`: Users who marked interest

**Privacy and Sharing**:
- **Privacy Levels**: `public`, `friendsOnly`, `societyOnly`, `courseOnly`, `yearOnly`, `facultyOnly`, `closeOnly`, `personal`
- **Sharing Permissions**: `canShare`, `canSuggest`, `viewOnly`, `noSharing`
- **Discoverability**: `public`, `friendsOnly`, `societyOnly`, `private`

**Recurring Events**:
- `isRecurring`: Boolean indicating if event repeats
- `recurringPattern`: Pattern like "WEEKLY:MON:10:00", "DAILY", "MONTHLY:15"

### Adding Societies

```json
{
  "id": "soc_010",
  "name": "New Society",
  "description": "Brief description",
  "aboutUs": "Detailed description...",
  "category": "Technology",
  "logoUrl": "https://example.com/logo.png",
  "memberCount": 50,
  "tags": ["tag1", "tag2", "tag3"],
  "isJoined": false,
  "adminIds": ["user_002"]
}
```

### Adding Locations

```json
{
  "id": "loc_008",
  "name": "New Lab",
  "building": "Building 12",
  "room": "05.123",
  "floor": "5",
  "type": "lab",
  "latitude": -33.8840,
  "longitude": 151.2005,
  "description": "Description of the location",
  "isAccessible": true,
  "capacity": 30,
  "amenities": ["Computers", "WiFi", "Projector"]
}
```

**Location Types**: `classroom`, `lab`, `common`, `study`

## Data Validation

The app automatically validates data integrity when loading. It checks for:

- **Bidirectional friendships**: If A is friends with B, B must be friends with A
- **Privacy settings**: Every user must have corresponding privacy settings
- **Valid references**: Event attendees, society admins, etc. must reference existing users
- **Society references**: Events with `societyId` must reference existing societies

**Validation warnings** are printed to the console when the app starts.

## ID Conventions

Use consistent ID patterns:
- Users: `user_XXX` (e.g., `user_001`, `user_002`)
- Societies: `soc_XXX` (e.g., `soc_001`, `soc_002`)
- Events: `event_XXX` (e.g., `event_001`, `event_002`)
- Locations: `loc_XXX` (e.g., `loc_001`, `loc_002`)
- Privacy: `privacy_XXX` (e.g., `privacy_001`, `privacy_002`)
- Friend Requests: `freq_XXX` (e.g., `freq_001`, `freq_002`)

## Common Tasks

### Making Two Users Friends
1. Add each user's ID to the other's `friendIds` array
2. Remove any pending friend requests between them
3. Optionally add a completed friend request to `friend_requests.json`

### Creating a Society Event
1. Add event to `events.json` with `type: "society"` and `source: "societies"`
2. Set `societyId` to the society's ID
3. Add attending members to `attendeeIds`
4. Set `creatorId` to a society admin

### Removing a User
1. Remove user from `users.json`
2. Remove their privacy settings from `privacy_settings.json`
3. Remove their ID from all other users' `friendIds`, `pendingFriendRequests`, `sentFriendRequests`
4. Remove them from event `attendeeIds` and society `adminIds`
5. Remove their friend requests from `friend_requests.json`

## Tips

- **Start Small**: When adding new data, start with minimal fields and add details later
- **Test Relationships**: After making changes, check the console for validation warnings
- **Use Realistic Data**: Keep names, courses, and locations realistic for better demo experience
- **Time Sensitivity**: Events use relative dates, so they'll always appear in the future
- **Backup**: Keep a backup of working data before making major changes

## Troubleshooting

**Common Issues**:

1. **"User has no privacy settings"** - Add matching privacy settings entry
2. **"Friend relationship not bidirectional"** - Ensure both users list each other as friends
3. **"Event references non-existent society"** - Check `societyId` matches a society in `societies.json`
4. **"Non-existent attendee"** - Check all IDs in `attendeeIds` exist in `users.json`

**Testing Changes**:
1. Make your changes to the JSON files
2. Run `flutter clean` (optional, for major changes)
3. Run `flutter run`
4. Check console for validation warnings
5. Test the affected features in the app

This JSON-based approach makes it much easier to manage demo data, add new scenarios, and collaborate on content without touching the codebase.
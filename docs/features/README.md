# Features Documentation

## Overview

This section documents each feature module in UniConnect, including functionality, user flows, and implementation details.

## Feature Modules

### 1. Home Feature

**Location**: `lib/features/home/`

#### Functionality
- Dashboard view with personalized content
- Quick access to key features
- Today's schedule overview
- Friend activity feed
- Recommended connections

#### Key Components
- `HomeScreen`: Main dashboard screen
- `QuickActions`: Shortcuts to common tasks
- `ActivityFeed`: Recent friend activities
- `TodaySchedule`: Today's events widget

#### User Flows
1. **View Dashboard**: Open app → See personalized home screen
2. **Quick Actions**: Tap action → Navigate to feature
3. **View Schedule**: See today's events → Tap for details

---

### 2. Calendar Feature

**Location**: `lib/features/calendar/`

#### Functionality
- Monthly/weekly/daily calendar views
- Event management (create, edit, delete)
- Class schedule integration
- Society event tracking
- Assignment deadlines
- Personal events

#### Key Components
- `CalendarScreen`: Main calendar view
- `EventDetailScreen`: Event information
- `AddEventScreen`: Create/edit events
- `CalendarWidget`: Custom calendar component

#### User Flows
1. **View Calendar**: Navigate to Calendar → See month view
2. **Add Event**: Tap + → Fill details → Save
3. **Edit Event**: Tap event → Edit → Save changes
4. **Delete Event**: Tap event → Delete → Confirm

#### Event Types
- **Classes**: Academic lectures and tutorials
- **Assignments**: Due dates and submissions
- **Society Events**: Club meetings and activities
- **Personal**: User-created events
- **Social**: Friend gatherings

---

### 3. Chat Feature

**Location**: `lib/features/chat/`

#### Functionality
- Direct messaging with friends
- Group chat support
- Message status (sent, delivered, read)
- Typing indicators
- Unread message badges
- Message search

#### Key Components
- `ChatsListScreen`: List of conversations
- `ChatScreen`: Individual chat view
- `MessageBubble`: Message display widget
- `ChatInput`: Message input component

#### User Flows
1. **Start Chat**: Friends list → Select friend → Send message
2. **View Messages**: Chat list → Select chat → Read/reply
3. **Create Group**: New chat → Select multiple → Create group

#### Message Types
- Text messages
- Location sharing
- Event invitations
- Study group invites

---

### 4. Friends Feature

**Location**: `lib/features/friends/`

#### Functionality
- Friends list management
- Friend requests (send, accept, decline)
- Friend search
- Friend profiles
- Location sharing with friends
- Friend recommendations

#### Key Components
- `FriendsScreen`: Main friends list
- `FriendRequestsScreen`: Pending requests
- `FriendProfileScreen`: Friend details
- `AddFriendScreen`: Search and add friends

#### User Flows
1. **Add Friend**: Search → Send request → Wait for acceptance
2. **Accept Request**: Requests tab → Accept/Decline
3. **View Profile**: Friends list → Tap friend → View details
4. **Remove Friend**: Friend profile → Remove → Confirm

#### Friend Features
- **Location Sharing**: See friends on campus map
- **Schedule Comparison**: Find common free time
- **Study Groups**: Create groups with friends
- **Event Invites**: Invite friends to events

---

### 5. Societies Feature

**Location**: `lib/features/societies/`

#### Functionality
- Browse all university societies
- Join/leave societies
- View society events
- Member lists
- Society information
- Category filtering

#### Key Components
- `SocietiesScreen`: Society list/grid
- `SocietyDetailScreen`: Society information
- `SocietyEventsTab`: Upcoming events
- `SocietyMembersTab`: Member list

#### User Flows
1. **Join Society**: Browse → Select → Join
2. **View Events**: My Societies → Select → Events tab
3. **Leave Society**: Society details → Leave → Confirm

#### Society Categories
- Academic
- Sports
- Cultural
- Creative
- Professional
- Social
- Volunteering

---

### 6. Privacy Feature

**Location**: `lib/features/privacy/`

#### Functionality
- Location sharing controls
- Timetable visibility settings
- Online status management
- Custom privacy rules
- Per-friend settings
- Privacy zones

#### Key Components
- `PrivacySettingsScreen`: Main privacy controls
- `LocationPrivacyScreen`: Location settings
- `TimetablePrivacyScreen`: Schedule visibility
- `CustomRulesScreen`: Friend-specific rules

#### User Flows
1. **Update Privacy**: Settings → Privacy → Modify → Save
2. **Custom Rules**: Privacy → Custom rules → Add rule
3. **Privacy Zones**: Set areas where location is hidden

#### Privacy Levels
- **Location**: Nobody, Friends, Friends of Friends, Everyone
- **Timetable**: Nobody, Friends, Everyone
- **Online Status**: Nobody, Friends, Everyone
- **Last Seen**: Show/Hide

---

### 7. Settings Feature

**Location**: `lib/features/settings/`

#### Functionality
- Profile management
- App preferences
- Theme selection (light/dark)
- Notification settings
- Account management
- About section

#### Key Components
- `SettingsScreen`: Main settings menu
- `ProfileEditScreen`: Edit user profile
- `NotificationSettingsScreen`: Notification preferences
- `AppearanceScreen`: Theme and display settings

#### User Flows
1. **Edit Profile**: Settings → Profile → Edit → Save
2. **Change Theme**: Settings → Appearance → Select theme
3. **Notifications**: Settings → Notifications → Toggle preferences

---

## Cross-Feature Interactions

### Location Integration
- **Friends**: Share real-time location
- **Chat**: Send current location
- **Events**: Navigate to event location

### Social Integration
- **Societies** → **Events**: Society events in calendar
- **Friends** → **Chat**: Message friends directly
- **Calendar** → **Friends**: Invite to events

### Privacy Integration
- All features respect privacy settings
- Location features check privacy before sharing
- Timetable visibility in friend profiles

## Feature Permissions

| Feature | Required Permissions |
|---------|---------------------|
| Location Sharing | Location access |
| Chat | Notification permission |
| Calendar | Calendar access (optional) |
| Camera | Camera permission (profile photo) |

## Upcoming Features

### Planned Enhancements
1. **Voice/Video Calls**: Real-time communication
2. **File Sharing**: Share documents in chat
3. **Event RSVP**: Respond to event invitations
4. **Study Rooms**: Book study spaces
5. **Lost & Found**: Campus lost item board
6. **Marketplace**: Student marketplace
7. **Polls**: Create polls in societies
8. **Achievements**: Gamification system

### Future Integrations
- University LMS integration
- Library system connection
- Campus navigation (AR)
- Public transport integration
- Food ordering system

## Feature Analytics

### Key Metrics
- **Engagement**: Daily active users per feature
- **Retention**: Feature usage over time
- **Performance**: Load times and responsiveness
- **Errors**: Feature-specific error rates

### User Feedback
- Feature request tracking
- Bug report system
- User satisfaction surveys
- A/B testing framework
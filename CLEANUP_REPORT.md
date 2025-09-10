# UniConnect App Cleanup & Data Audit Report

## Navigation & Screen Status

### ACTIVE SCREENS (Currently in use)
#### Primary Navigation (Tab Bar)
1. **HomeScreen** - Tab 0
2. **EnhancedCalendarScreen** - Tab 1  
3. **ChatListScreen** - Tab 2
4. **EnhancedSocietiesScreen** - Tab 3
5. **EnhancedFriendsScreen** - Tab 4

#### Secondary Navigation (Linked from primary)
- ProfileScreen
- ChatScreen
- StudyGroupsScreen
- AchievementsScreen
- AdvancedSearchScreen
- PrivacySettingsScreen
- InteractiveMapScreen
- SocietyDetailScreen
- StudyGroupDetailScreen
- CreateStudyGroupScreen
- NewChatScreen

#### Authentication Flow
- WelcomeScreen (Entry)
- OnboardingSignupScreen
- LoginScreen

### ORPHANED SCREENS (To be removed/archived)
- **CalendarScreen** → Superseded by EnhancedCalendarScreen
- **SocietiesScreen** → Superseded by EnhancedSocietiesScreen
- **FriendsScreen** → Superseded by EnhancedFriendsScreen
- **FriendsMapScreen** → Potentially duplicate of InteractiveMapScreen
- **EnhancedMapScreen** → Not linked anywhere

### DUPLICATE MAP SCREENS (Need consolidation)
- InteractiveMapScreen (ACTIVE - linked from friends)
- FriendsMapScreen (ORPHANED)
- EnhancedMapScreen (ORPHANED)

## Data Model Requirements

### Society Data Issues
**Current Problems:**
- Missing `aboutUs` field for many societies
- Inconsistent data structure
- Some societies lack complete information

**Required Fields:**
- id
- name
- description
- aboutUs (MISSING for some)
- category
- logoUrl
- memberCount
- tags
- isJoined
- adminIds

### User Data Requirements
**Required Fields:**
- id
- name
- email
- course
- year
- profileImageUrl
- isOnline
- lastSeen
- status
- currentLocationId
- statusMessage
- friendIds
- pendingFriendRequests
- sentFriendRequests
- privacySettingsId

### Event Data Requirements
**Required Fields:**
- id
- title
- description
- startTime
- endTime
- location
- type (class_, society, personal, assignment)
- creatorId
- societyId (for society events)
- attendeeIds
- color
- isRecurring

## Cleanup Action Plan

### Phase 1: Screen Cleanup
- [ ] Archive orphaned screens
- [ ] Remove duplicate map screens
- [ ] Update navigation references

### Phase 2: Data Cleanup
- [ ] Add missing aboutUs to all societies
- [ ] Standardize society data structure
- [ ] Ensure all users have complete profiles
- [ ] Verify event data matches UI requirements

### Phase 3: Testing
- [ ] Test all navigation paths
- [ ] Verify data displays correctly
- [ ] Check for broken references

## Data Amendments Needed

### Societies Missing AboutUs
- UTS Programmers Society
- UTS Engineering Society
- UTS Car Society
- CIAO Society
- UTS Law Students Society
- (and others...)

### Users Needing Profile Updates
- Verify all demo users have:
  - Complete course information
  - Valid year levels
  - Privacy settings
  - Status messages
  - Friend relationships

### Events Needing Updates
- Ensure events have proper:
  - Event types
  - Color coding
  - Location information
  - Attendee lists
  - Society associations

## Next Steps
1. Create archive folder for obsolete screens
2. Move orphaned screens to archive
3. Update DemoDataManager with complete data
4. Remove references to archived screens
5. Test complete navigation flow
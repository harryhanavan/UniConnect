# UniConnect Page-to-Palette Color Mapping

## Color Palette Overview

### Primary Palettes (Five-Color System)
1. **🏠 Home/Main**: `#8B5CF6` (Purple) - Central hub, primary actions
2. **📅 Personal**: `#0D99FF` (Blue) - Personal schedule, timetables, academic
3. **🏛️ Societies**: `#4CAF50` (Green) - Clubs, organizations, society events
4. **👥 Social**: `#31E615` (Bright Green) - Friends, social events, campus map
5. **📚 Study Groups**: `#FF7A00` (Orange) - Collaborative learning, study sessions

---

## Feature Module Color Assignments

### 🏠 **HOME MODULE** → Home Palette (Purple)
- `home/home_screen.dart` - Main dashboard
  - Primary actions: Purple
  - Quick access buttons: Purple accents
  - Navigation highlights: Purple

---

### 📅 **CALENDAR/TIMETABLE MODULE** → Personal Palette (Blue)
- `calendar/calendar_screen.dart` - Calendar view
- `calendar/enhanced_calendar_screen.dart` - Enhanced calendar
- `timetable/*` - All timetable components
  - Classes/lectures: Blue
  - Personal events: Blue
  - Assignments: Blue
  - Academic schedule: Blue

---

### 🏛️ **SOCIETIES MODULE** → Societies Palette (Green)
- `societies/societies_screen.dart` - Societies list
- `societies/enhanced_societies_screen.dart` - Enhanced societies
- `societies/society_detail_screen.dart` - Society details
  - Society cards: Green
  - Join/leave buttons: Green
  - Society events: Green
  - Member badges: Green

---

### 👥 **FRIENDS MODULE** → Social Palette (Bright Green)
- `friends/friends_screen.dart` - Friends list
- `friends/enhanced_friends_screen.dart` - Enhanced friends
- `friends/friends_map_screen.dart` - Friends on map
- `friends/enhanced_map_screen.dart` - Enhanced map
- `friends/interactive_map_screen.dart` - Interactive campus map
  - Friend status indicators: Bright Green
  - Location sharing: Bright Green
  - Social connections: Bright Green
  - Campus map elements: Bright Green

---

### 💬 **CHAT MODULE** → Social Palette (Bright Green)
- `chat/chat_screen.dart` - Individual chat
- `chat/chat_list_screen.dart` - Chat list
- `chat/new_chat_screen.dart` - New chat creation
  - Message bubbles: Bright Green accents
  - Online status: Bright Green
  - Chat actions: Bright Green

---

### 📚 **STUDY GROUPS MODULE** → Study Groups Palette (Orange)
- `study_groups/study_groups_screen.dart` - Study groups list
- `study_groups/study_group_detail_screen.dart` - Group details
- `study_groups/create_study_group_screen.dart` - Create group
  - Group cards: Orange
  - Join/create buttons: Orange
  - Collaboration indicators: Orange
  - Study session events: Orange

---

### 🏆 **ACHIEVEMENTS MODULE** → Study Groups Palette (Orange)
- `achievements/achievements_screen.dart` - Achievements display
  - Achievement badges: Orange
  - Progress bars: Orange
  - Unlocked achievements: Orange highlights

---

### 👤 **PROFILE MODULE** → Mixed (Context-dependent)
- `profile/profile_screen.dart` - User profile
  - Personal info section: Personal Palette (Blue)
  - Social connections: Social Palette (Bright Green)
  - Society memberships: Societies Palette (Green)
  - Academic info: Personal Palette (Blue)

---

### 🔍 **SEARCH MODULE** → Home Palette (Purple)
- `search/advanced_search_screen.dart` - Advanced search
  - Search actions: Purple
  - Filter buttons: Purple
  - Search highlights: Purple

---

### 🔔 **NOTIFICATIONS MODULE** → Mixed (Type-dependent)
- `notifications/notification_center_screen.dart`
  - Social notifications: Bright Green
  - Society notifications: Green
  - Academic notifications: Blue
  - System notifications: Purple

---

### 🔒 **PRIVACY MODULE** → Social Palette (Bright Green)
- `privacy/privacy_settings_screen.dart` - Privacy settings
- `privacy/friend_privacy_overrides_screen.dart` - Friend overrides
  - Privacy toggles: Bright Green
  - Location sharing: Bright Green
  - Visibility settings: Bright Green

---

### ⚙️ **SETTINGS MODULE** → Home Palette (Purple)
- `settings/settings_screen.dart` - App settings
  - Settings categories: Purple
  - Toggle switches: Purple accents
  - Action buttons: Purple

---

### 🚀 **ONBOARDING/AUTH MODULE** → Home Palette (Purple)
- `onboarding/welcome_screen.dart` - Welcome screen
- `onboarding/signup_screen.dart` - Sign up
- `auth/login_screen.dart` - Login
  - Primary buttons: Purple
  - Onboarding flow: Purple accents
  - Auth actions: Purple

---

### 📊 **RECOMMENDATIONS MODULE** → Mixed (Content-dependent)
- `recommendations/*` - Recommendation widgets
  - Friend recommendations: Bright Green
  - Society recommendations: Green
  - Study group recommendations: Orange
  - Event recommendations: Based on event type

---

### 🧪 **TESTING MODULE** → Neutral/Debug
- `testing/phase1_test_screen.dart`
- `testing/phase2_test_screen.dart`
- `testing/phase3_test_screen.dart`
  - Use default Material Design colors or grayscale

---

## Special Color Cases & Sub-Accents

### Status Indicators (System Colors)
- Online status: `AppColors.online` (Green)
- Offline status: `AppColors.offline` (Gray)
- Busy status: `AppColors.busy` (Red)
- Away status: `AppColors.away` (Yellow)

### System States (UI Colors)
- Success messages: `AppColors.success`
- Error messages: `AppColors.error`
- Warning messages: `AppColors.warning`
- Info messages: `AppColors.info`

### Navigation & Structure
- Bottom navigation: Active tab uses feature color
- App bar: Uses current feature's primary color
- FABs: Uses current feature's primary color
- Drawer: Home palette (Purple) for main structure

---

## Implementation Todo List

### Phase 1: Core Feature Pages
- [ ] Update home_screen.dart - Apply Purple palette consistently
- [ ] Update calendar screens - Apply Blue palette
- [ ] Update societies screens - Apply Green palette
- [ ] Update friends/map screens - Apply Bright Green palette
- [ ] Update study_groups screens - Apply Orange palette

### Phase 2: Communication Features
- [ ] Update chat screens - Apply Bright Green palette
- [ ] Update notification_center - Apply mixed palette based on type

### Phase 3: User Features
- [ ] Update profile_screen - Apply mixed palette by section
- [ ] Update privacy screens - Apply Bright Green palette
- [ ] Update settings_screen - Apply Purple palette

### Phase 4: Support Features
- [ ] Update search_screen - Apply Purple palette
- [ ] Update achievements_screen - Apply Orange palette
- [ ] Update onboarding/auth - Apply Purple palette

### Phase 5: Component Updates
- [ ] Update shared widgets to respect parent feature colors
- [ ] Update navigation components for active state colors
- [ ] Update cards/tiles to use appropriate feature colors
- [ ] Update buttons to use contextual feature colors

---

## Color Usage Rules

### Primary Actions
- Use feature's primary color for main CTAs
- Use feature's primary color with opacity for hover/pressed states

### Secondary Actions
- Use feature's primary color at 70% opacity
- Or use `AppColors.textSecondary` for subtle actions

### Backgrounds
- Cards: `AppColors.surface` (white)
- Page background: `AppColors.background`
- Feature accent backgrounds: Feature color at 10% opacity

### Text on Colored Backgrounds
- On feature colors: Always use white text
- On light backgrounds: Use `AppColors.textPrimary`
- On accent backgrounds: Use feature color for text

### Borders & Dividers
- Default: `AppColors.border`
- Feature-specific: Feature color at 30% opacity
- Active/selected: Feature color at 100%

---

## Notes for Implementation

1. **Gradual Migration**: Update one module at a time
2. **Test Dark Mode**: Ensure colors work in both light/dark themes
3. **Accessibility**: Maintain WCAG AA contrast ratios
4. **Consistency**: Use the same shade/opacity patterns across features
5. **Documentation**: Update CHANGES_STACK.md after each module update

---

*Last Updated: September 2025*
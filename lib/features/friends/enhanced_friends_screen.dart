import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/app_state.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/friendship_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/calendar_service.dart';
import '../../core/utils/ui_helpers.dart';
import '../../shared/models/user.dart';
import '../../shared/models/friend_request.dart';
import '../../shared/models/location.dart';
import '../../shared/models/event.dart';
import '../../shared/widgets/friend_profile_modal.dart';
import 'interactive_map_screen.dart';
import '../search/advanced_search_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class EnhancedFriendsScreen extends StatefulWidget {
  final int? initialTabIndex;

  const EnhancedFriendsScreen({
    super.key,
    this.initialTabIndex,
  });

  @override
  State<EnhancedFriendsScreen> createState() => _EnhancedFriendsScreenState();
}

class _EnhancedFriendsScreenState extends State<EnhancedFriendsScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  late TabController _tabController;
  final DemoDataManager _demoData = DemoDataManager.instance;
  final FriendshipService _friendshipService = FriendshipService();
  final LocationService _locationService = LocationService();
  final CalendarService _calendarService = CalendarService();
  
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Check for pending AppState parameters FIRST
    final appState = Provider.of<AppState>(context, listen: false);
    final pendingParams = appState.consumeFriendsParams();

    int initialTabIndex;
    if (pendingParams?.initialTabIndex != null) {
      print('👥 Friends: Found pending params - tab: ${pendingParams!.initialTabIndex}');
      initialTabIndex = pendingParams.initialTabIndex!;
    } else {
      print('👥 Friends: No pending params, using widget param - tab: ${widget.initialTabIndex}');
      initialTabIndex = widget.initialTabIndex ?? 0;
    }

    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialTabIndex,
    );
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _demoData.users; // Trigger initialization
      // Get current user from AppState
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUserId = appState.currentUser.id;
      // Initialize services by calling async methods
      await _friendshipService.getFriendSuggestions(currentUserId);
      await _calendarService.getUnifiedCalendar(currentUserId);
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Check for pending AppState parameters every time the widget builds
    final appState = Provider.of<AppState>(context, listen: false);
    final pendingParams = appState.consumeFriendsParams();

    if (pendingParams?.initialTabIndex != null) {
      print('👥 Friends: Found pending params in build() - tab: ${pendingParams!.initialTabIndex}');

      // Update tab controller with the new tab index
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != pendingParams.initialTabIndex) {
          _tabController.animateTo(pendingParams.initialTabIndex!);
        }
      });
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final currentUser = appState.currentUser;

        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          body: Column(
            children: [
              // Header with real-time status
              _buildHeader(currentUser),

              // Tab Navigation
              _buildTabBar(),

              // Tab Content
              Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFriendsTab(currentUser),
                      _buildOnCampusTab(currentUser),
                      _buildRequestsTab(currentUser),
                      _buildSuggestionsTab(currentUser),
                    ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "friends_add_friend_fab",
            onPressed: () {
              // Navigate directly to People tab in search screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedSearchScreen.people(),
                ),
              );
            },
            backgroundColor: AppColors.socialColor,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Add Friend',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(User currentUser) {
    final friendsCount = currentUser.friendIds.length;
    final appState = Provider.of<AppState>(context, listen: true);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: appState.isTempStyleEnabled
              ? [AppColors.primaryDark, AppColors.primaryDark] // Option 3: Solid dark blue
              : [AppColors.socialColor, AppColors.socialColor.withValues(alpha: 0.8)], // Original bright green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UniMates',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    friendsCount == 0
                        ? 'Connect with fellow students'
                        : 'Stay connected with your friends',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InteractiveMapScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    onPressed: () => _showQRScanner(),
                  ),
                ],
              ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final pendingCount = _demoData.getPendingFriendRequests(_demoData.currentUser.id).length;
    final sentCount = _demoData.getSentFriendRequests(_demoData.currentUser.id).length;
    final totalRequestCount = pendingCount + sentCount;

    return Container(
      color: AppTheme.getSurfaceColor(context),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.socialColor,
        unselectedLabelColor: AppTheme.getSecondaryTextColor(context),
        indicatorColor: AppColors.socialColor,
        tabs: [
          const Tab(text: 'Friends'),
          const Tab(text: 'On Campus'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(child: Text('Requests', overflow: TextOverflow.ellipsis)),
                if (totalRequestCount > 0) ...[
                  const SizedBox(width: 4),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: pendingCount > 0 ? Colors.red : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$totalRequestCount',
                          style: TextStyle(
                            color: const Color(0xFF2C2C2C),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Show a small indicator if there are both types
                      if (pendingCount > 0 && sentCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: 'Discover'),
        ],
      ),
    );
  }

  // Friends Tab with Timetable Integration
  Widget _buildFriendsTab(User currentUser) {
    final appState = Provider.of<AppState>(context, listen: false);
    final friends = appState.friends;
    
    if (friends.isEmpty) {
      return _buildEmptyState(
        'No friends yet',
        'Add friends to see their schedules and plan together!',
        Icons.group_add,
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Common Free Time Banner
        _buildCommonFreeTimeBanner(currentUser, friends),
        
        const SizedBox(height: 20),
        
        // Friends List with Enhanced Info
        ...friends.map((friend) => _buildEnhancedFriendCard(currentUser, friend)),
      ],
    );
  }

  // On Campus Tab with Real-time Locations
  Widget _buildOnCampusTab(User currentUser) {
    final campusData = _locationService.getFriendsOnCampusMap(currentUser.id);
    final friendsOnCampus = (campusData['friends'] as List<dynamic>?)?.cast<User>() ?? <User>[];
    
    if (friendsOnCampus.isEmpty) {
      return _buildEmptyState(
        'No friends on campus',
        'Your friends will appear here when they\'re on campus',
        Icons.location_on,
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Meetup Suggestions
        _buildMeetupSuggestions(currentUser),
        
        const SizedBox(height: 20),
        
        Text(
          'Friends on Campus (${friendsOnCampus.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...friendsOnCampus.map((friend) => _buildLocationFriendCard(
          friend, 
          campusData['locations'][friend.id] as Location?,
          campusData['distances'][friend.id] as double?,
        )),
      ],
    );
  }

  // Friend Requests Tab
  Widget _buildRequestsTab(User currentUser) {
    final pendingRequests = _demoData.getPendingFriendRequests(currentUser.id);
    final sentRequests = _demoData.getSentFriendRequests(currentUser.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Incoming friend requests
        if (pendingRequests.isNotEmpty) ...[
          const Text(
            'Pending Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...pendingRequests.map((request) => _buildFriendRequestCard(request)),
          const SizedBox(height: 20),
        ],

        // Outgoing friend requests
        if (sentRequests.isNotEmpty) ...[
          const Text(
            'Sent Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...sentRequests.map((request) => _buildSentFriendRequestCard(request)),
          const SizedBox(height: 20),
        ],

        const Text(
          'Add Friends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildAddFriendOptions(),
      ],
    );
  }

  // Enhanced Discovery Tab with Multiple Discovery Methods
  Widget _buildSuggestionsTab(User currentUser) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Discovery Categories Header
        const Text(
          'Discover People',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Find friends based on shared interests and activities',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        
        // From Your Classes
        _buildDiscoverySection(
          'From Your Classes',
          'Students in your courses',
          Icons.school,
          () => _getClassmates(currentUser),
          AppColors.personalColor,
        ),
        
        const SizedBox(height: 16),
        
        // From Your Societies
        _buildDiscoverySection(
          'From Your Societies',
          'Members of societies you joined',
          Icons.groups,
          () => _getSocietyMembers(currentUser),
          AppColors.societyColor,
        ),
        
        const SizedBox(height: 16),
        
        // From Events You Attend
        _buildDiscoverySection(
          'From Events You Attend',
          'People attending the same events',
          Icons.event,
          () => _getEventAttendees(currentUser),
          Colors.purple,
        ),
        
        const SizedBox(height: 16),
        
        // Mutual Friends
        _buildDiscoverySection(
          'Friends of Friends',
          'Connected through mutual friends',
          Icons.people_outline,
          () => _getMutualFriends(currentUser),
          AppColors.socialColor,
        ),
        
        const SizedBox(height: 16),
        
        // Similar Interests
        _buildDiscoverySection(
          'Similar Interests',
          'Based on your course and activities',
          Icons.favorite,
          () => _getSimilarInterests(currentUser),
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildCommonFreeTimeBanner(User currentUser, List<User> friends) {
    // Get common free times for today
    final commonTimes = <Map<String, dynamic>>[];
    for (final friend in friends.take(3)) { // Check top 3 friends
      final freeSlots = _friendshipService.findCommonFreeTime(currentUser.id, [friend.id]);
      for (final slot in freeSlots) {
        commonTimes.add({
          'friend': friend,
          'slot': slot,
        });
      }
    }
    
    if (commonTimes.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, color: AppColors.socialColor),
              SizedBox(width: 8),
              Text(
                'Common Free Time Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...commonTimes.take(2).map((timeData) {
            final friend = timeData['friend'] as User;
            final slot = timeData['slot'] as Map<String, dynamic>;
            final startTime = slot['startTime'] as DateTime;
            return Text(
              '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${slot['suggestion']} with ${friend.name}',
              style: TextStyle(fontSize: 14),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEnhancedFriendCard(User currentUser, User friend) {
    final canViewTimetable = _friendshipService.canViewTimetable(currentUser.id, friend.id);
    final canViewLocation = _friendshipService.canViewLocation(currentUser.id, friend.id);
    final currentLocation = friend.currentLocationId != null
        ? _demoData.getLocationById(friend.currentLocationId!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.getCardDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showFriendProfile(friend),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with status indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: friend.profileImageUrl != null
                          ? NetworkImage(friend.profileImageUrl!)
                          : null,
                      backgroundColor: const Color(0xFFF5F5F0),
                      child: friend.profileImageUrl == null
                          ? Text(
                              friend.name[0],
                              style: TextStyle(
                                color: const Color(0xFF2C2C2C),
                                fontSize: 20,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getStatusColor(friend.status),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Friend info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${friend.course} • ${friend.year}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friend.statusMessage ?? _getStatusText(friend.status),
                        style: TextStyle(
                          color: _getStatusColor(friend.status),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (canViewLocation && currentLocation != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentLocation.building,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Actions column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (canViewTimetable)
                      GestureDetector(
                        onTap: () => _showTimetableOverlay(currentUser, friend),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.personalColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: Text(
                            'Timetable',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                              color: AppColors.personalColor,
                            ),
                          ),
                        ),
                      ),
                    if (friend.isOnline && canViewLocation) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '• Online',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Roboto',
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFriendCard(User friend, Location? location, double? distance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.getCardDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showFriendProfile(friend),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundImage: friend.profileImageUrl != null
                      ? NetworkImage(friend.profileImageUrl!)
                      : null,
                  backgroundColor: const Color(0xFFF5F5F0),
                  child: friend.profileImageUrl == null
                      ? Text(
                          friend.name[0],
                          style: TextStyle(
                            color: const Color(0xFF2C2C2C),
                            fontSize: 20,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Friend info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (location != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (distance != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          distance < 1000 
                              ? '${distance.round()}m away'
                              : '${(distance / 1000).toStringAsFixed(1)}km away',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Message button
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.socialColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          )
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => _navigateToChat(friend),
                        icon: const Icon(
                          Icons.message_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    // Meet button
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.personalColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          )
                        ],
                      ),
                      child: TextButton(
                        onPressed: () => _suggestMeetup(friend),
                        child: Text(
                          'Meet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard(FriendRequest request) {
    final sender = _demoData.getUserById(request.senderId);
    if (sender == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.getCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: sender.profileImageUrl != null
                      ? NetworkImage(sender.profileImageUrl!)
                      : null,
                  backgroundColor: const Color(0xFFF5F5F0),
                  child: sender.profileImageUrl == null
                      ? Text(
                          sender.name[0],
                          style: TextStyle(
                            color: const Color(0xFF2C2C2C),
                            fontSize: 20,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sender.course} • ${sender.year}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: Text(
                  request.message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      width: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => _handleFriendRequest(request, false),
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.personalColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => _handleFriendRequest(request, true),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentFriendRequestCard(FriendRequest request) {
    final recipient = _demoData.getUserById(request.receiverId);
    if (recipient == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: 1,
          color: Colors.orange.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: recipient.profileImageUrl != null
                          ? NetworkImage(recipient.profileImageUrl!)
                          : null,
                      backgroundColor: const Color(0xFFF5F5F0),
                      child: recipient.profileImageUrl == null
                          ? Text(
                              recipient.name[0],
                              style: TextStyle(
                                color: const Color(0xFF2C2C2C),
                                fontSize: 20,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.schedule,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipient.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'Roboto',
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${recipient.course} • ${recipient.year}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: Text(
                  request.message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sent ${_formatTimeAgo(request.createdAt)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      width: 1,
                      color: Colors.orange,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => _cancelFriendRequest(request),
                    child: const Text(
                      'Cancel Request',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetupSuggestions(User currentUser) {
    final suggestions = _locationService.getMeetupSuggestions(currentUser.id);
    
    if (suggestions.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: 1,
          color: Colors.orange.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.coffee, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Meetup Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...suggestions.take(2).map((suggestion) {
            final friend = suggestion['friend'] as User;
            final suggestionText = suggestion['suggestion'] as String;
            final location = suggestion['location'] as Location?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _handleMeetupSuggestion(friend, location, suggestionText),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          suggestionText,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Meet Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _handleMeetupSuggestion(User friend, Location? location, String suggestionText) async {
    // Show confirmation dialog
    UIHelpers.showConfirmationDialog(
      context,
      title: 'Meet Up Suggestion',
      message: 'Would you like to suggest meeting up with ${friend.name}?\n\n$suggestionText',
      confirmText: 'Send Suggestion',
      onConfirm: () async {
        // Show loading
        UIHelpers.showLoadingDialog(context, message: 'Sending meetup suggestion...');

        try {
          // Simulate sending meetup suggestion
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            UIHelpers.hideLoadingDialog(context);
            UIHelpers.showSnackBar(
              context,
              'Meetup suggestion sent to ${friend.name}! 📍',
              type: SnackBarType.success,
            );
          }
        } catch (e) {
          if (mounted) {
            UIHelpers.hideLoadingDialog(context);
            UIHelpers.showSnackBar(
              context,
              'Failed to send meetup suggestion: ${e.toString()}',
              type: SnackBarType.error,
            );
          }
        }
      },
    );
  }

  Widget _buildAddFriendOptions() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.qr_code_scanner, color: AppColors.socialColor),
          title: const Text('Scan QR Code'),
          subtitle: const Text('Add friends by scanning their QR code'),
          onTap: () => _showQRScanner(),
        ),
        ListTile(
          leading: const Icon(Icons.search, color: AppColors.socialColor),
          title: const Text('Search by Name'),
          subtitle: const Text('Find friends by their name or email'),
          onTap: () => _showSearchDialog(),
        ),
        ListTile(
          leading: const Icon(Icons.contacts, color: AppColors.socialColor),
          title: const Text('Import Contacts'),
          subtitle: const Text('Find friends from your contacts'),
          onTap: () => _showContactsImport(),
        ),
        ListTile(
          leading: const Icon(Icons.school, color: AppColors.socialColor),
          title: const Text('Find from Classes & Societies'),
          subtitle: const Text('Discover people from your courses and societies'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdvancedSearchScreen.people(),
              ),
            ).then((_) {
              // Refresh when returning from search
              if (mounted) setState(() {});
            });
          },
        ),
      ],
    );
  }

  Widget _buildDiscoverySection(String title, String subtitle, IconData icon, 
      List<Map<String, dynamic>> Function() getUsersFunction, Color accentColor) {
    final discoveryData = getUsersFunction();
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (discoveryData.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${discoveryData.length}',
                      style: TextStyle(
                        color: const Color(0xFF2C2C2C),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          if (discoveryData.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No suggestions available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            )
          else
            ...discoveryData.take(3).map((data) => _buildDiscoveryUserCard(data, accentColor)),
          
          // View More Button
          if (discoveryData.length > 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () => _showFullDiscoveryList(title, discoveryData, accentColor),
                  child: Text(
                    'View ${discoveryData.length - 3} more',
                    style: TextStyle(color: accentColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryUserCard(Map<String, dynamic> data, Color accentColor) {
    final user = data['user'] as User;
    final connectionReason = data['reason'] as String;
    final commonItems = data['commonItems'] as List<String>? ?? [];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          )
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            backgroundColor: const Color(0xFFF5F5F0),
            child: user.profileImageUrl == null
                ? Text(
                    user.name[0],
                    style: TextStyle(
                      color: const Color(0xFF2C2C2C),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${user.course} • ${user.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  connectionReason,
                  style: TextStyle(
                    fontSize: 12,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (commonItems.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: commonItems.take(2).map((item) => Chip(
                      label: Text(
                        item,
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: accentColor.withValues(alpha: 0.1),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
              ],
            ),
          ),
          
          // Add Button
          SizedBox(
            width: 70,
            height: 32,
            child: ElevatedButton(
              onPressed: () => _sendFriendRequest(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F0),
                foregroundColor: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: TextStyle(fontSize: 12),
              ),
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          backgroundColor: const Color(0xFFF5F5F0),
          child: user.profileImageUrl == null
              ? Text(
                  user.name[0],
                  style: TextStyle(color: const Color(0xFF2C2C2C), fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(user.name),
        subtitle: Text('${user.course} • ${user.year}'),
        trailing: ElevatedButton(
          onPressed: () => _sendFriendRequest(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF5F5F0),
            foregroundColor: Theme.of(context).colorScheme.surface,
            minimumSize: const Size(60, 30),
          ),
          child: const Text('Add', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return Colors.green;
      case UserStatus.offline:
        return Colors.grey;
      case UserStatus.busy:
        return Colors.red;
      case UserStatus.away:
        return Colors.orange;
      case UserStatus.inClass:
        return Colors.blue;
      case UserStatus.studying:
        return Colors.purple;
    }
  }

  String _getStatusText(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.offline:
        return 'Offline';
      case UserStatus.busy:
        return 'Busy';
      case UserStatus.away:
        return 'Away';
      case UserStatus.inClass:
        return 'In Class';
      case UserStatus.studying:
        return 'Studying';
    }
  }

  // Event Handlers
  void _showQRScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Scanner would open here')),
    );
  }

  void _showSearchDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvancedSearchScreen.people(),
      ),
    ).then((_) {
      // Refresh the friends screen when returning from search
      // in case any friend requests were made
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showContactsImport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacts import would be implemented here')),
    );
  }

  void _sendFriendRequest(User user) async {
    // Show loading immediately
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text('Sending friend request to ${user.name}...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await _friendshipService.sendFriendRequest(
        _demoData.currentUser.id,
        user.id,
        message: 'Hi ${user.name}! Let\'s connect on UniConnect.',
      );

      if (mounted) {
        // Clear loading snackbar
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.send, color: Colors.white),
                const SizedBox(width: 8),
                Text('Friend request sent to ${user.name}'),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      // Clear loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('Failed to send friend request: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleFriendRequest(FriendRequest request, bool accept) async {
    // Show loading dialog
    UIHelpers.showLoadingDialog(
      context,
      message: accept ? 'Accepting friend request...' : 'Declining friend request...',
    );

    try {
      if (accept) {
        await _friendshipService.acceptFriendRequest(request.id);
        if (mounted) {
          UIHelpers.hideLoadingDialog(context);
          final senderName = _demoData.getUserById(request.senderId)?.name ?? 'this user';
          UIHelpers.showSnackBar(
            context,
            'You and $senderName are now friends! 🎉',
            type: SnackBarType.success,
          );
        }
      } else {
        await _friendshipService.declineFriendRequest(request.id);
        if (mounted) {
          UIHelpers.hideLoadingDialog(context);
          UIHelpers.showSnackBar(
            context,
            'Friend request declined',
            type: SnackBarType.info,
          );
        }
      }

      // Refresh UI data
      setState(() {});

      // Also refresh the tab controller to update badge counts
      if (mounted) {
        // Force rebuild of tab bar with updated counts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.hideLoadingDialog(context);
        UIHelpers.showSnackBar(
          context,
          'Failed to handle friend request: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _cancelFriendRequest(FriendRequest request) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Friend Request'),
        content: Text('Are you sure you want to cancel your friend request to ${_demoData.getUserById(request.receiverId)?.name ?? 'this user'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading immediately
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Cancelling friend request...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await _friendshipService.cancelFriendRequest(request.id);
      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Text('Friend request to ${_demoData.getUserById(request.receiverId)?.name ?? 'this user'} cancelled'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Refresh UI data
      setState(() {});

      // Also refresh the tab controller to update badge counts
      if (mounted) {
        // Force rebuild of tab bar with updated counts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    } catch (e) {
      // Clear loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('Failed to cancel friend request: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showTimetableOverlay(User currentUser, User friend) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${friend.name}\'s Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Timetable overlay functionality would be implemented here.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFriendProfile(User friend) {
    // Show friend profile modal
    try {
      showFriendProfileModal(context, friend, currentUser: _demoData.currentUser);
    } catch (e) {
      UIHelpers.showSnackBar(
        context,
        'Error loading profile: $e',
        type: SnackBarType.error,
      );
    }
  }

  void _navigateToChat(User friend) {
    try {
      // ChatScreen needs a Chat object, not individual parameters
      UIHelpers.showSnackBar(
        context,
        'Starting chat with ${friend.name} - feature coming soon!',
        type: SnackBarType.info,
      );
    } catch (e) {
      UIHelpers.showSnackBar(
        context,
        'Chat feature not available yet',
        type: SnackBarType.info,
      );
    }
  }

  void _suggestMeetup(User friend) {
    UIHelpers.showConfirmationDialog(
      context,
      title: 'Suggest Meetup',
      message: 'Would you like to suggest meeting up with ${friend.name}?',
      confirmText: 'Send Suggestion',
      onConfirm: () async {
        UIHelpers.showLoadingDialog(context, message: 'Sending meetup suggestion...');

        try {
          // Simulate sending meetup suggestion
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            UIHelpers.hideLoadingDialog(context);
            UIHelpers.showSnackBar(
              context,
              'Meetup suggestion sent to ${friend.name}! 📍',
              type: SnackBarType.success,
            );
          }
        } catch (e) {
          if (mounted) {
            UIHelpers.hideLoadingDialog(context);
            UIHelpers.showSnackBar(
              context,
              'Failed to send meetup suggestion: ${e.toString()}',
              type: SnackBarType.error,
            );
          }
        }
      },
    );
  }

  void _showStatusPicker(User currentUser) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Status picker would be implemented here.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }


  // Discovery Helper Methods
  
  List<Map<String, dynamic>> _getClassmates(User currentUser) {
    final classmates = <Map<String, dynamic>>[];
    final currentCourse = currentUser.course.toLowerCase();
    final currentYear = currentUser.year;
    
    // Get all events the current user attends that are classes
    final userEvents = _calendarService.getUnifiedCalendarSync(currentUser.id)
        .where((e) => e.type == EventType.class_)
        .toList();
    
    for (final user in _demoData.usersSync) {
      if (user.id == currentUser.id || 
          currentUser.friendIds.contains(user.id) ||
          currentUser.pendingFriendRequests.contains(user.id) ||
          currentUser.sentFriendRequests.contains(user.id)) continue;
      
      // Check if they share classes or same course/year
      final sharedClasses = <String>[];
      final otherUserEvents = _calendarService.getUnifiedCalendarSync(user.id)
          .where((e) => e.type == EventType.class_)
          .toList();
      
      // Find shared class events
      for (final myEvent in userEvents) {
        for (final theirEvent in otherUserEvents) {
          if (myEvent.title.toLowerCase().contains(theirEvent.title.toLowerCase()) ||
              theirEvent.title.toLowerCase().contains(myEvent.title.toLowerCase())) {
            sharedClasses.add(myEvent.title.split(' - ').first);
            break;
          }
        }
      }
      
      // Same course and year
      if (user.course.toLowerCase().contains(currentCourse) || 
          currentCourse.contains(user.course.toLowerCase())) {
        if (user.year == currentYear) {
          classmates.add({
            'user': user,
            'reason': 'Same course and year',
            'commonItems': [user.course, 'Year $currentYear'],
          });
        } else {
          classmates.add({
            'user': user,
            'reason': 'Same course (${user.year})',
            'commonItems': [user.course],
          });
        }
      } else if (sharedClasses.isNotEmpty) {
        classmates.add({
          'user': user,
          'reason': '${sharedClasses.length} shared class${sharedClasses.length > 1 ? 'es' : ''}',
          'commonItems': sharedClasses,
        });
      }
    }
    
    return classmates..sort((a, b) => (b['commonItems'] as List).length.compareTo((a['commonItems'] as List).length));
  }
  
  List<Map<String, dynamic>> _getSocietyMembers(User currentUser) {
    final societyMembers = <Map<String, dynamic>>[];
    final joinedSocieties = _demoData.societiesSync.where((s) => _demoData.currentUser.societyIds.contains(s.id)).toList();
    
    if (joinedSocieties.isEmpty) return [];
    
    for (final user in _demoData.usersSync) {
      if (user.id == currentUser.id || 
          currentUser.friendIds.contains(user.id) ||
          currentUser.pendingFriendRequests.contains(user.id) ||
          currentUser.sentFriendRequests.contains(user.id)) continue;
      
      final sharedSocieties = <String>[];
      
      // Check if they're likely members of societies based on course similarity
      for (final society in joinedSocieties) {
        bool isLikelyMember = false;
        
        // Technology societies - match with CS/IT/Engineering courses
        if (society.category == 'Technology') {
          if (user.course.toLowerCase().contains('computer') ||
              user.course.toLowerCase().contains('software') ||
              user.course.toLowerCase().contains('engineering') ||
              user.course.toLowerCase().contains('information')) {
            isLikelyMember = true;
          }
        }
        // Academic societies - match with relevant courses
        else if (society.category == 'Academic') {
          if (society.name.toLowerCase().contains('law') && 
              user.course.toLowerCase().contains('law')) {
            isLikelyMember = true;
          } else if (society.name.toLowerCase().contains('engineering') && 
                     user.course.toLowerCase().contains('engineering')) {
            isLikelyMember = true;
          }
        }
        // Cultural societies - broader match
        else if (society.category == 'Cultural') {
          // Random chance for cultural society membership
          if (user.id.hashCode % 3 == 0) {
            isLikelyMember = true;
          }
        }
        
        if (isLikelyMember) {
          sharedSocieties.add(society.name);
        }
      }
      
      if (sharedSocieties.isNotEmpty) {
        societyMembers.add({
          'user': user,
          'reason': '${sharedSocieties.length} shared societ${sharedSocieties.length > 1 ? 'ies' : 'y'}',
          'commonItems': sharedSocieties.take(2).toList(),
        });
      }
    }
    
    return societyMembers..sort((a, b) => (b['commonItems'] as List).length.compareTo((a['commonItems'] as List).length));
  }
  
  List<Map<String, dynamic>> _getEventAttendees(User currentUser) {
    final eventAttendees = <Map<String, dynamic>>[];
    final userEvents = _calendarService.getUnifiedCalendarSync(currentUser.id);
    
    for (final user in _demoData.usersSync) {
      if (user.id == currentUser.id || 
          currentUser.friendIds.contains(user.id) ||
          currentUser.pendingFriendRequests.contains(user.id) ||
          currentUser.sentFriendRequests.contains(user.id)) continue;
      
      final otherUserEvents = _calendarService.getUnifiedCalendarSync(user.id);
      final sharedEvents = <String>[];
      
      // Find events where both users are attendees
      for (final myEvent in userEvents) {
        if (myEvent.attendeeIds.contains(user.id)) {
          sharedEvents.add(myEvent.title);
        }
        
        // Also check for similar event names/times
        for (final theirEvent in otherUserEvents) {
          if (myEvent.title.toLowerCase().contains(theirEvent.title.toLowerCase()) ||
              theirEvent.title.toLowerCase().contains(myEvent.title.toLowerCase())) {
            if (!sharedEvents.contains(myEvent.title)) {
              sharedEvents.add(myEvent.title);
            }
          }
        }
      }
      
      if (sharedEvents.isNotEmpty) {
        eventAttendees.add({
          'user': user,
          'reason': '${sharedEvents.length} shared event${sharedEvents.length > 1 ? 's' : ''}',
          'commonItems': sharedEvents.take(2).toList(),
        });
      }
    }
    
    return eventAttendees..sort((a, b) => (b['commonItems'] as List).length.compareTo((a['commonItems'] as List).length));
  }
  
  List<Map<String, dynamic>> _getMutualFriends(User currentUser) {
    final mutualFriendsMap = <User, List<String>>{};
    
    for (final user in _demoData.usersSync) {
      if (user.id == currentUser.id || 
          currentUser.friendIds.contains(user.id) ||
          currentUser.pendingFriendRequests.contains(user.id) ||
          currentUser.sentFriendRequests.contains(user.id)) continue;
      
      final mutualFriendNames = <String>[];
      
      // Find mutual friends
      for (final friendId in currentUser.friendIds) {
        if (user.friendIds.contains(friendId)) {
          final friend = _demoData.getUserById(friendId);
          if (friend != null) {
            mutualFriendNames.add(friend.name);
          }
        }
      }
      
      if (mutualFriendNames.isNotEmpty) {
        mutualFriendsMap[user] = mutualFriendNames;
      }
    }
    
    return mutualFriendsMap.entries.map((entry) => {
      'user': entry.key,
      'reason': '${entry.value.length} mutual friend${entry.value.length > 1 ? 's' : ''}',
      'commonItems': entry.value.take(2).toList(),
    }).toList()..sort((a, b) => (b['commonItems'] as List).length.compareTo((a['commonItems'] as List).length));
  }
  
  List<Map<String, dynamic>> _getSimilarInterests(User currentUser) {
    final similarUsers = <Map<String, dynamic>>[];
    final currentCourseKeywords = currentUser.course.toLowerCase().split(' ');
    
    for (final user in _demoData.usersSync) {
      if (user.id == currentUser.id || 
          currentUser.friendIds.contains(user.id) ||
          currentUser.pendingFriendRequests.contains(user.id) ||
          currentUser.sentFriendRequests.contains(user.id)) continue;
      
      final similarities = <String>[];
      final otherCourseKeywords = user.course.toLowerCase().split(' ');
      
      // Find common course keywords
      for (final keyword in currentCourseKeywords) {
        if (otherCourseKeywords.contains(keyword) && keyword.length > 3) {
          similarities.add(keyword.toUpperCase());
        }
      }
      
      // Similar year level
      if (user.year == currentUser.year) {
        similarities.add('Year ${user.year}');
      }
      
      // Similar status patterns (both online, both studying, etc.)
      if (user.status == currentUser.status && user.status != UserStatus.offline) {
        similarities.add(_getStatusText(user.status));
      }
      
      if (similarities.isNotEmpty) {
        similarUsers.add({
          'user': user,
          'reason': 'Similar interests',
          'commonItems': similarities.take(2).toList(),
        });
      }
    }
    
    return similarUsers..sort((a, b) => (b['commonItems'] as List).length.compareTo((a['commonItems'] as List).length));
  }
  
  void _showFullDiscoveryList(String title, List<Map<String, dynamic>> users, Color accentColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.people, color: accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // User List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: users.length,
                  itemBuilder: (context, index) => _buildDiscoveryUserCard(users[index], accentColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/friendship_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/calendar_service.dart';
import '../../shared/models/user.dart';
import '../../shared/models/friend_request.dart';
import '../../shared/models/location.dart';
import '../../shared/models/event.dart';
import 'interactive_map_screen.dart';

class EnhancedFriendsScreen extends StatefulWidget {
  const EnhancedFriendsScreen({super.key});

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
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _demoData.users; // Trigger initialization
      // Initialize services by calling async methods
      await _friendshipService.getFriendSuggestions(_demoData.currentUser.id);
      await _calendarService.getUnifiedCalendar(_demoData.currentUser.id);
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final currentUser = _demoData.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
      ),
    );
  }

  Widget _buildHeader(User currentUser) {
    final friendsCount = currentUser.friendIds.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.socialColor, AppColors.socialColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
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
                    style: const TextStyle(
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
    );
  }

  Widget _buildTabBar() {
    final pendingCount = _demoData.getPendingFriendRequests(_demoData.currentUser.id).length;
    
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.socialColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.socialColor,
        tabs: [
          const Tab(text: 'Friends'),
          const Tab(text: 'On Campus'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(child: Text('Requests', overflow: TextOverflow.ellipsis)),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    final friends = _demoData.getFriendsForUser(currentUser.id);
    
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
    final friendsOnCampus = campusData['friends'] as List<User>;
    
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
          style: const TextStyle(
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
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
        const Text(
          'Find friends based on shared interests and activities',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
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
              style: const TextStyle(fontSize: 14),
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
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
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
                      backgroundColor: const Color(0xFF0D99FF),
                      child: Text(
                        friend.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${friend.course} • ${friend.year}',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.50),
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
                              color: Colors.black.withValues(alpha: 0.50),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentLocation.building,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                color: Colors.black.withValues(alpha: 0.50),
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
                          decoration: ShapeDecoration(
                            color: const Color(0xFF0D99FF).withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFF0D99FF).withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Timetable',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0D99FF),
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
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _showFriendProfile(friend),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF0D99FF),
                  child: Text(
                    friend.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Friend info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: const TextStyle(
                          color: Colors.black,
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
                              color: Colors.black.withValues(alpha: 0.50),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.70),
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
                            color: Colors.black.withValues(alpha: 0.50),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Meet button
                Container(
                  decoration: ShapeDecoration(
                    color: const Color(0xFF0D99FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => _suggestMeetup(friend),
                    child: const Text(
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
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF0D99FF),
                  child: Text(
                    sender.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sender.course} • ${sender.year}',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.50),
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
                decoration: ShapeDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  request.message!,
                  style: const TextStyle(
                    color: Colors.black,
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
                  decoration: ShapeDecoration(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: Colors.black.withValues(alpha: 0.20),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => _handleFriendRequest(request, false),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const ShapeDecoration(
                    color: Color(0xFF0D99FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => _handleFriendRequest(request, true),
                    child: const Text(
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

  Widget _buildMeetupSuggestions(User currentUser) {
    final suggestions = _locationService.getMeetupSuggestions(currentUser.id);
    
    if (suggestions.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFF3E0),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.orange.withValues(alpha: 0.20),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(suggestionText, style: const TextStyle(fontSize: 14)),
            );
          }),
        ],
      ),
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
          onTap: () => _tabController.animateTo(3), // Navigate to Discover tab
        ),
      ],
    );
  }

  Widget _buildDiscoverySection(String title, String subtitle, IconData icon, 
      List<Map<String, dynamic>> Function() getUsersFunction, Color accentColor) {
    final discoveryData = getUsersFunction();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
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
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
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
                          color: Colors.grey.shade600,
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
                      style: const TextStyle(
                        color: Colors.white,
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
                  color: Colors.grey.shade600,
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: accentColor,
            child: Text(
              user.name[0],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${user.course} • ${user.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
                        style: const TextStyle(fontSize: 10),
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
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(fontSize: 12),
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
          backgroundColor: AppColors.socialColor,
          child: Text(
            user.name[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name),
        subtitle: Text('${user.course} • ${user.year}'),
        trailing: ElevatedButton(
          onPressed: () => _sendFriendRequest(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.socialColor,
            foregroundColor: Colors.white,
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
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
    // Implementation for search dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Friends'),
        content: const Text('Friend search functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactsImport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacts import would be implemented here')),
    );
  }

  void _sendFriendRequest(User user) async {
    try {
      await _friendshipService.sendFriendRequest(
        _demoData.currentUser.id,
        user.id,
        message: 'Hi ${user.name}! Let\'s connect on UniConnect.',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent to ${user.name}')),
        );
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send friend request')),
      );
    }
  }

  void _handleFriendRequest(FriendRequest request, bool accept) async {
    try {
      if (accept) {
        await _friendshipService.acceptFriendRequest(request.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request accepted! 🎉')),
          );
        }
      } else {
        await _friendshipService.declineFriendRequest(request.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request declined')),
          );
        }
      }
      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to handle friend request')),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    // Navigate to friend profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${friend.name}\'s profile would open here')),
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

  void _suggestMeetup(User friend) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Meetup suggestion sent to ${friend.name}')),
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
    final joinedSocieties = _demoData.societiesSync.where((s) => s.isJoined).toList();
    
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
          decoration: const BoxDecoration(
            color: Colors.white,
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
                  color: Colors.grey.shade300,
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
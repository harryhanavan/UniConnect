import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../../shared/models/user.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/event_relationship_service.dart';
import '../../shared/widgets/enhanced_event_card.dart';

class SocietyDetailScreen extends StatefulWidget {
  final Society society;

  const SocietyDetailScreen({
    super.key,
    required this.society,
  });

  @override
  State<SocietyDetailScreen> createState() => _SocietyDetailScreenState();
}

class _SocietyDetailScreenState extends State<SocietyDetailScreen> {
  late Society currentSociety;
  List<EventV2> upcomingEvents = [];
  List<Map<String, dynamic>> eventsWithStatus = [];
  bool notificationsEnabled = true;
  bool _isInitialized = false;
  
  final CalendarService _calendarService = CalendarService();
  final EventRelationshipService _eventRelationshipService = EventRelationshipService();

  @override
  void initState() {
    super.initState();
    currentSociety = widget.society;
    _initializeData();
    
    // Listen for external event relationship changes
    _eventRelationshipService.relationshipChangeNotifier.addListener(_onExternalEventRelationshipChange);
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await DemoDataManager.instance.enhancedEvents; // Trigger EventV2 initialization
      await _loadUpcomingEvents();
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadUpcomingEvents() async {
    // Get events with relationship status for this society
    eventsWithStatus = await _calendarService.getSocietyEventsWithStatus(
      DemoDataManager.instance.currentUser.id,
      widget.society.id,
    );
    
    // Extract events for backward compatibility
    upcomingEvents = eventsWithStatus
        .map((eventData) => eventData['event'] as EventV2)
        .take(5)
        .toList();
  }

  void _toggleJoinSociety() {
    final demoData = DemoDataManager.instance;
    final isCurrentlyJoined = demoData.currentUser.societyIds.contains(currentSociety.id);
    
    setState(() {
      if (isCurrentlyJoined) {
        demoData.leaveSociety(currentSociety.id);
      } else {
        demoData.joinSociety(currentSociety.id);
      }
      // Refresh the current society data from the updated data manager
      currentSociety = demoData.getSocietyById(currentSociety.id) ?? currentSociety;
    });
    
    // Reload events to reflect any membership changes
    _loadUpcomingEvents().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onEventRelationshipChanged(EventV2 event, EventRelationship newRelationship) {
    // Refresh the events list to show updated status
    _loadUpcomingEvents().then((_) {
      if (mounted) setState(() {});
    });
  }
  
  void _onExternalEventRelationshipChange() {
    // Handle external event relationship changes (from other screens)
    if (mounted && _isInitialized) {
      _loadUpcomingEvents().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onEventTap(EventV2 event) {
    // Show event details modal or navigate to event detail screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${event.startTime.day}/${event.startTime.month}/${event.startTime.year} at ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              EnhancedEventCard(
                event: event,
                userId: DemoDataManager.instance.currentUser.id,
                onRelationshipChanged: _onEventRelationshipChanged,
                showFullDetails: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // Society Header Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Society Image/Logo Section  
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Logo/Image
                              Center(
                                child: currentSociety.logoUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: currentSociety.logoUrl!,
                                        fit: BoxFit.contain,
                                        height: 120,
                                        placeholder: (context, url) => SizedBox(
                                          height: 120,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => 
                                            _buildSocietyPlaceholder(),
                                      )
                                    : _buildSocietyPlaceholder(),
                              ),
                              
                              // Category Tag
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: ShapeDecoration(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        bottomRight: Radius.circular(6),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    currentSociety.category,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w500,
                                      height: 1.33,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Society Info Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Society Name
                              Text(
                                currentSociety.name,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Member Count
                              Text(
                                '${currentSociety.memberCount} members',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.50),
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.67,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Tags
                              if (currentSociety.tags.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: currentSociety.tags.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: ShapeDecoration(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          width: 0.50,
                                          color: Colors.black.withValues(alpha: 0.10),
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w400,
                                        height: 1.33,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              
                              const SizedBox(height: 16),
                              
                              // Join Society Button
                              Container(
                                width: double.infinity,
                                height: 48,
                                decoration: ShapeDecoration(
                                  color: DemoDataManager.instance.currentUser.societyIds.contains(currentSociety.id)
                                      ? const Color(0xFF34C759) 
                                      : const Color(0xFF0D99FF),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: Colors.black.withValues(alpha: 0.1),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: _toggleJoinSociety,
                                  child: Text(
                                    DemoDataManager.instance.currentUser.societyIds.contains(currentSociety.id) ? 'Joined' : 'Join Society',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Short Description and Contact Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                          Text(
                            currentSociety.description,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Contact email
                          if (currentSociety.id == 'soc_001') ...
                          [
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening email client...')),
                                );
                              },
                              child: Text(
                                'uxidsoc@activateuts.com.au',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // About Us Section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                          const Text(
                            'About Us',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentSociety.aboutUs ?? currentSociety.description,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Website link for UXID Society
                          if (currentSociety.id == 'soc_001') ...
                          [
                            GestureDetector(
                              onTap: () {
                                // Website link functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening UXID Society website...')),
                                );
                              },
                              child: Text(
                                'Check out our Website!',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Members Section
                  _buildMembersSection(),

                  // Upcoming Events Section
                  if (upcomingEvents.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                        child: Text(
                          '${upcomingEvents.length} upcoming events',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    // Event Cards
                    ...upcomingEvents.map((event) => Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: EnhancedEventCard(
                        event: event,
                        userId: DemoDataManager.instance.currentUser.id,
                        onEventTap: _onEventTap,
                        onRelationshipChanged: _onEventRelationshipChanged,
                      ),
                    )),
                  ],

                  // Sample Announcement
                  _buildAnnouncementCard(),

                  // Notifications Section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Notification toggles
                          _buildNotificationToggle('Event Reminders', notificationsEnabled),
                          const SizedBox(height: 16),
                          _buildNotificationToggle('New announcements', true),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }


  Widget _buildAnnouncementCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      width: double.infinity,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Welcome New Members!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '2 days ago',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'Welcome to all our new members! We\'re excited to have you join our community. Don\'t forget to introduce yourself in our Discord channel.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.67,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(String title, bool isEnabled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 0.5,
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            width: 64,
            height: 28,
            decoration: ShapeDecoration(
              color: isEnabled 
                  ? const Color(0xFF34C759) 
                  : Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: isEnabled ? 23 : 2,
                  top: 2,
                  child: Container(
                    width: 39,
                    height: 24,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildMembersSection() {
    final demoData = DemoDataManager.instance;
    final members = demoData.usersSync.where((user) => currentSociety.memberIds.contains(user.id)).toList();
    final currentUserFriends = demoData.getFriendsForUser(demoData.currentUser.id);
    final friendsInSociety = members.where((member) => currentUserFriends.any((friend) => friend.id == member.id)).toList();
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members (${members.length})',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (friendsInSociety.isNotEmpty)
                  Text(
                    '${friendsInSociety.length} friend${friendsInSociety.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Show first few members with avatars
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.take(8).map((member) {
                final isFriend = currentUserFriends.any((friend) => friend.id == member.id);
                return _buildMemberAvatar(member, isFriend);
              }).toList(),
            ),
            
            if (members.length > 8) ...[
              const SizedBox(height: 8),
              Text(
                '... and ${members.length - 8} more members',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMemberAvatar(User member, bool isFriend) {
    return Column(
      children: [
        Stack(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isFriend ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: member.profileImageUrl ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${member.name}',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 24),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 24),
                  ),
                ),
              ),
            ),
            
            // Friend indicator
            if (isFriend)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Name
        SizedBox(
          width: 48,
          child: Text(
            member.name.split(' ').first,
            style: TextStyle(
              color: isFriend ? Colors.blue[600] : Colors.black,
              fontSize: 10,
              fontFamily: 'Roboto',
              fontWeight: isFriend ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSocietyPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.group,
        size: 40,
        color: Colors.grey[600],
      ),
    );
  }

  @override
  void dispose() {
    _eventRelationshipService.relationshipChangeNotifier.removeListener(_onExternalEventRelationshipChange);
    super.dispose();
  }
}
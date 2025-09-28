import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../../shared/models/user.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/app_state.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/event_relationship_service.dart';
import '../../core/constants/app_theme.dart';
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
  List<EventV2> upcomingEvents = [];
  List<Map<String, dynamic>> eventsWithStatus = [];
  bool notificationsEnabled = true;
  bool _isInitialized = false;
  bool _isProcessingJoin = false;
  String? _lastError;
  
  final CalendarService _calendarService = CalendarService();
  final EventRelationshipService _eventRelationshipService = EventRelationshipService();

  // Helper method to get current society data
  Society? get currentSociety {
    try {
      return DemoDataManager.instance.getSocietyById(widget.society.id);
    } catch (e) {
      // Return the original society if demo data isn't initialized yet
      return widget.society;
    }
  }

  // Helper method to safely check if user is joined to society
  // Returns null when state is unknown/loading
  bool? get isUserJoined {
    if (!_isInitialized || _isProcessingJoin) {
      return null; // Unknown state - show loading
    }
    try {
      final demoData = DemoDataManager.instance;
      final society = currentSociety;
      return society != null && _currentUser.societyIds.contains(society.id);
    } catch (e) {
      print('Error checking join status: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Listen for society membership changes
    DemoDataManager.instance.societyMembershipNotifier.addListener(_onMembershipChanged);

    // Listen for external event relationship changes
    _eventRelationshipService.relationshipChangeNotifier.addListener(_onExternalEventRelationshipChange);
  }

  void _onMembershipChanged() {
    if (mounted) {
      try {
        final membershipChange = DemoDataManager.instance.societyMembershipNotifier.value;

        // Check if this change is relevant to the current society
        if (membershipChange.isNotEmpty && membershipChange['societyId'] == widget.society.id) {
          print('Society membership changed: ${membershipChange['action']} for society ${membershipChange['societyId']}');

          // Force a refresh of the current state
          setState(() {}); // Refresh UI when membership changes

          // Reload events if needed
          if (_isInitialized && !_isProcessingJoin) {
            _loadUpcomingEvents().then((_) {
              if (mounted) setState(() {});
            });
          }
        } else {
          // Generic membership change, still refresh UI
          setState(() {});
        }
      } catch (e) {
        print('Error handling membership change: $e');
        // Fallback to generic refresh
        setState(() {});
      }
    }
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      // Initialize all demo data first
      final demoData = DemoDataManager.instance;
      await demoData.users; // This triggers full initialization
      await demoData.societies; // Ensure societies are loaded
      await demoData.enhancedEvents; // Trigger EventV2 initialization
      await _loadUpcomingEvents();
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      // Ensure demo data is initialized before accessing currentUser
      final demoData = DemoDataManager.instance;
      if (!_isInitialized) {
        // Skip loading events if not initialized yet
        eventsWithStatus = [];
        upcomingEvents = [];
        return;
      }

      // Get the current user ID safely
      String currentUserId;
      try {
        currentUserId = _currentUser.id;
      } catch (e) {
        // If currentUser fails, try async version
        final user = await demoData.currentUserAsync;
        currentUserId = user.id;
      }

      // Get events with relationship status for this society
      eventsWithStatus = await _calendarService.getSocietyEventsWithStatus(
        currentUserId,
        widget.society.id,
      );

      // Extract events for backward compatibility
      upcomingEvents = eventsWithStatus
          .map((eventData) => eventData['event'] as EventV2)
          .take(5)
          .toList();
    } catch (e) {
      // If there's an error loading events, set empty lists
      eventsWithStatus = [];
      upcomingEvents = [];
      print('Error loading upcoming events: $e');
    }
  }

  void _toggleJoinSociety() async {
    // Prevent concurrent operations
    if (_isProcessingJoin) return;

    setState(() {
      _isProcessingJoin = true;
      _lastError = null;
    });

    try {
      if (!_isInitialized) {
        await _initializeData();
      }

      final demoData = DemoDataManager.instance;
      final society = demoData.getSocietyById(widget.society.id);

      if (society == null) {
        throw Exception('Society not found');
      }

      final isCurrentlyJoined = _currentUser.societyIds.contains(society.id);
      final action = isCurrentlyJoined ? 'leave' : 'join';

      // Perform the operation
      if (isCurrentlyJoined) {
        demoData.leaveSociety(society.id);
      } else {
        demoData.joinSociety(society.id);
      }

      // Reload events to reflect membership changes
      await _loadUpcomingEvents();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyJoined ? 'Left ${society.name}' : 'Joined ${society.name}!',
            ),
            backgroundColor: isCurrentlyJoined ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      _lastError = e.toString();
      print('Error toggling society membership: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isProcessingJoin ? "update membership" : "join society"}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingJoin = false;
        });
      }
    }
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
                userId: _currentUser.id,
                onRelationshipChanged: _onEventRelationshipChanged,
                showFullDetails: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get current user from AppState
  User get _currentUser {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      return appState.currentUser;
    } catch (e) {
      // Fallback to demo data manager if AppState is not available
      return DemoDataManager.instance.currentUser;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!_isInitialized) {
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
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
                      color: AppTheme.getCardColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Match calendar cards
                      ),
                      shadows: [
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
                        // Society Image/Logo Section  
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8), // Match calendar cards
                              topRight: Radius.circular(8), // Match calendar cards
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Logo/Image
                              Center(
                                child: currentSociety?.logoUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: currentSociety!.logoUrl!,
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
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8), // Match calendar cards
                                        bottomRight: Radius.circular(8), // Match calendar cards
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    currentSociety?.category ?? '',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
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
                                currentSociety?.name ?? 'Unknown Society',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 24,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Member Count
                              Text(
                                '${currentSociety?.memberCount ?? 0} members',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.67,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Tags
                              if (currentSociety?.tags.isNotEmpty == true)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: (currentSociety?.tags ?? []).map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: ShapeDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          width: 0.50,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                        borderRadius: BorderRadius.circular(8), // Match calendar cards
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
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
                                  color: _getButtonColor(),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8), // Match calendar cards
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: isUserJoined == null ? null : _toggleJoinSociety,
                                  child: _buildButtonContent(),
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
                      color: AppTheme.getCardColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Match calendar cards
                      ),
                      shadows: [
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
                          Text(
                            currentSociety?.description ?? 'No description available.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Contact email
                          if (currentSociety?.id == 'soc_001') ...
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
                      color: AppTheme.getCardColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Match calendar cards
                      ),
                      shadows: [
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
                          Text(
                            'About Us',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentSociety?.aboutUs ?? currentSociety?.description ?? 'No information available.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Website link for UXID Society
                          if (currentSociety?.id == 'soc_001') ...
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
                        color: AppTheme.getCardColor(context),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(8), // Match calendar cards
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '${upcomingEvents.length} upcoming events',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
                        userId: _currentUser.id,
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
                      color: AppTheme.getCardColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Match calendar cards
                      ),
                      shadows: [
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
                          Text(
                            'Notifications',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
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
      },
    );
  }


  Widget _buildAnnouncementCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      width: double.infinity,
      decoration: ShapeDecoration(
        color: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(8), // Match calendar cards
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
                  'Welcome New Members!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '2 days ago',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'Welcome to all our new members! We\'re excited to have you join our community. Don\'t forget to introduce yourself in our Discord channel.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
    final members = demoData.usersSync.where((user) => currentSociety?.memberIds.contains(user.id) == true).toList();
    final currentUserFriends = demoData.getFriendsForUser(_currentUser.id);
    final friendsInSociety = members.where((member) => currentUserFriends.any((friend) => friend.id == member.id)).toList();
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: ShapeDecoration(
        color: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(8), // Match calendar cards
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
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
                  imageUrl: member.profileImageUrl ?? 'https://api.dicebear.com/9.x/micah/png?seed=${member.name}&hair=dannyPhantom,fonze,full,pixie&mouth=laughing,smile,smirk',
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
              color: isFriend ? Colors.blue[600] : Theme.of(context).colorScheme.onSurface,
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

  Color _getButtonColor() {
    final joinStatus = isUserJoined;
    if (joinStatus == null) {
      // Loading state
      return Colors.grey;
    } else if (joinStatus) {
      // Joined state
      return const Color(0xFF34C759);
    } else {
      // Not joined state
      return const Color(0xFF0D99FF);
    }
  }

  Widget _buildButtonContent() {
    final joinStatus = isUserJoined;

    if (joinStatus == null) {
      // Loading state
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isProcessingJoin ? 'Processing...' : 'Loading...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      // Normal state
      return Text(
        joinStatus ? 'Joined' : 'Join Society',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  @override
  void dispose() {
    DemoDataManager.instance.societyMembershipNotifier.removeListener(_onMembershipChanged);
    _eventRelationshipService.relationshipChangeNotifier.removeListener(_onExternalEventRelationshipChange);
    super.dispose();
  }
}
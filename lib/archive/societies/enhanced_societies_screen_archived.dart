import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/friendship_service.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/user.dart';

class EnhancedSocietiesScreen extends StatefulWidget {
  const EnhancedSocietiesScreen({super.key});

  @override
  State<EnhancedSocietiesScreen> createState() => _EnhancedSocietiesScreenState();
}

class _EnhancedSocietiesScreenState extends State<EnhancedSocietiesScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final DemoDataManager _demoData = DemoDataManager.instance;
  final CalendarService _calendarService = CalendarService();
  final FriendshipService _friendshipService = FriendshipService();

  final List<String> _categories = [
    'All', 'Technology', 'Creative', 'Sports', 'Cultural', 'Business', 'Academic'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDiscoverTab(),
                  _buildMySocietiesTab(),
                  _buildEventsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final joinedSocieties = _demoData.joinedSocieties;
    final upcomingSocietyEvents = _calendarService.getEventsBySource(
      _demoData.currentUser.id,
      EventSource.societies,
    ).where((event) => event.startTime.isAfter(DateTime.now())).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.societyColor, AppColors.societyColor.withValues(alpha: 0.8)],
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
              const Text(
                'Societies',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: () => _showQRScanner(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Society overview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${joinedSocieties.length} Societies Joined',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$upcomingSocietyEvents upcoming events',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQuickStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final friends = _demoData.getFriendsForUser(_demoData.currentUser.id);
    final mutualSocietyConnections = _calculateMutualSocietyConnections(friends);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                '$mutualSocietyConnections',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Friend\nConnections',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search societies...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppColors.societyColor.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.societyColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.societyColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.societyColor,
        tabs: const [
          Tab(text: 'Discover'),
          Tab(text: 'My Societies'),
          Tab(text: 'Events'),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    final filteredSocieties = _getFilteredSocieties();
    
    if (filteredSocieties.isEmpty) {
      return const Center(
        child: Text('No societies found matching your criteria'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSocieties.length,
      itemBuilder: (context, index) {
        return _buildSocietyCard(filteredSocieties[index]);
      },
    );
  }

  Widget _buildMySocietiesTab() {
    final joinedSocieties = _demoData.joinedSocieties;
    
    if (joinedSocieties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No societies joined yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore the Discover tab to find societies that match your interests!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.societyColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Discover Societies'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: joinedSocieties.length,
      itemBuilder: (context, index) {
        return _buildJoinedSocietyCard(joinedSocieties[index]);
      },
    );
  }

  Widget _buildEventsTab() {
    final societyEvents = _calendarService.getEventsBySource(
      _demoData.currentUser.id,
      EventSource.societies,
    );
    
    // Group events by date
    final eventsByDate = <String, List<Event>>{};
    for (final event in societyEvents) {
      final dateKey = '${event.startTime.year}-${event.startTime.month}-${event.startTime.day}';
      eventsByDate.putIfAbsent(dateKey, () => []).add(event);
    }
    
    if (eventsByDate.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No society events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Join societies to see their events here!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: eventsByDate.length,
      itemBuilder: (context, index) {
        final dateKey = eventsByDate.keys.elementAt(index);
        final events = eventsByDate[dateKey]!;
        final date = events.first.startTime;
        
        return _buildEventDateSection(date, events);
      },
    );
  }

  Widget _buildSocietyCard(Society society) {
    final friends = _demoData.getFriendsForUser(_demoData.currentUser.id);
    final friendsInSociety = _getFriendsInSociety(society, friends);
    final upcomingEvents = _demoData.eventsSync
        .where((event) => event.societyId == society.id && event.startTime.isAfter(DateTime.now()))
        .length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.societyColor.withValues(alpha: 0.1),
                  child: Text(
                    society.name[0],
                    style: TextStyle(
                      color: AppColors.societyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        society.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${society.memberCount} members • $upcomingEvents upcoming events',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              society.description,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 12),
            
            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: society.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.societyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.societyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
            
            // Friend connections
            if (friendsInSociety.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      '${friendsInSociety.length} friends may be here',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _showSocietyDetails(society),
                  child: const Text('View Details'),
                ),
                ElevatedButton(
                  onPressed: () => _joinSociety(society),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.societyColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(society.isJoined ? 'Joined' : 'Join'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinedSocietyCard(Society society) {
    final upcomingEvents = _demoData.eventsSync
        .where((event) => event.societyId == society.id && event.startTime.isAfter(DateTime.now()))
        .take(3)
        .toList();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.societyColor.withValues(alpha: 0.1),
                  child: Text(
                    society.name[0],
                    style: TextStyle(
                      color: AppColors.societyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        society.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Member since ${DateTime.now().month}/2024',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'notifications',
                      child: Text('Notification Settings'),
                    ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Leave Society'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'leave') {
                      _leaveSociety(society);
                    } else if (value == 'notifications') {
                      _showNotificationSettings(society);
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Upcoming events preview
            if (upcomingEvents.isNotEmpty) ...[
              const Text(
                'Upcoming Events:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...upcomingEvents.map((event) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${event.startTime.day}/${event.startTime.month}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )),
            ] else ...[
              const Text(
                'No upcoming events',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showSocietyDetails(society),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showSocietyEvents(society),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.societyColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Events'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDateSection(DateTime date, List<Event> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '${date.day}/${date.month}/${date.year}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.societyColor,
            ),
          ),
        ),
        ...events.map((event) => _buildEventCard(event)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    final society = _demoData.getSocietyById(event.societyId!);
    final attendees = event.attendeeIds.length;
    final friendsAttending = _getFriendsAttendingEvent(event);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.societyColor.withValues(alpha: 0.1),
          child: Text(
            society?.name[0] ?? 'S',
            style: TextStyle(
              color: AppColors.societyColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(society?.name ?? 'Society Event'),
            Text('${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} • ${event.location}'),
            if (friendsAttending.isNotEmpty)
              Text(
                '👥 ${friendsAttending.length} friends attending',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$attendees',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Text(
              'attending',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  // Helper Methods
  List<Society> _getFilteredSocieties() {
    return _demoData.societiesSync.where((society) {
      if (_searchQuery.isNotEmpty && 
          !society.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !society.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      
      if (_selectedCategory != 'All' && society.category != _selectedCategory) {
        return false;
      }
      
      return true;
    }).toList();
  }

  int _calculateMutualSocietyConnections(List<User> friends) {
    int connections = 0;
    final joinedSocieties = _demoData.joinedSocieties;
    
    for (final friend in friends) {
      // Simple heuristic: friends in same course likely share societies
      if (friend.course.contains(_demoData.currentUser.course.split(' ').last)) {
        connections++;
      }
    }
    
    return connections;
  }

  List<User> _getFriendsInSociety(Society society, List<User> friends) {
    // Simplified logic - in real app would check actual society membership
    return friends.where((friend) => 
      friend.course.contains(society.category) || 
      society.tags.any((tag) => friend.course.contains(tag))
    ).take(3).toList();
  }

  List<User> _getFriendsAttendingEvent(Event event) {
    final friends = _demoData.getFriendsForUser(_demoData.currentUser.id);
    return friends.where((friend) => event.attendeeIds.contains(friend.id)).toList();
  }

  // Event Handlers
  void _showQRScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR scanner for society invites would open here')),
    );
  }

  void _joinSociety(Society society) async {
    try {
      final success = await _calendarService.joinSocietyWithCalendarIntegration(
        _demoData.currentUser.id,
        society.id,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined ${society.name}! Events added to your calendar.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join society'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _leaveSociety(Society society) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Society'),
        content: Text('Are you sure you want to leave ${society.name}? This will remove all society events from your calendar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final success = await _calendarService.leaveSocietyWithCalendarCleanup(
          _demoData.currentUser.id,
          society.id,
        );
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Left ${society.name}. Events removed from calendar.'),
            ),
          );
          setState(() {}); // Refresh UI
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to leave society'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSocietyDetails(Society society) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                society.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(society.description),
              const SizedBox(height: 12),
              Text('Members: ${society.memberCount}'),
              Text('Category: ${society.category}'),
              const SizedBox(height: 16),
              const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 6,
                children: society.tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  if (!society.isJoined)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _joinSociety(society);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.societyColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Join'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSocietyEvents(Society society) {
    final societyEvents = _demoData.eventsSync.where((event) => event.societyId == society.id).toList();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${society.name} Events',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: societyEvents.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(societyEvents[index].title),
                      subtitle: Text('${societyEvents[index].startTime.day}/${societyEvents[index].startTime.month} at ${societyEvents[index].startTime.hour}:${societyEvents[index].startTime.minute.toString().padLeft(2, '0')}'),
                      trailing: Icon(
                        societyEvents[index].attendeeIds.contains(_demoData.currentUser.id) 
                          ? Icons.check_circle 
                          : Icons.circle_outlined,
                        color: Colors.green,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${event.title} details would open here')),
    );
  }

  void _showNotificationSettings(Society society) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${society.name} Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notification preferences for this society:'),
            SizedBox(height: 12),
            Text('• Event announcements'),
            Text('• Meeting reminders'),
            Text('• Society updates'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
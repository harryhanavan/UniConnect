import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/friendship_service.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/user.dart';
import 'society_detail_screen.dart';

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
  
  bool _isInitialized = false;

  final List<String> _categories = [
    'All', 'Technology', 'Creative', 'Sports', 'Cultural', 'Business', 'Academic'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _demoData.users; // Trigger initialization
      _isInitialized = true;
      if (mounted) setState(() {});
    }
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Societies',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    joinedSocieties.isEmpty 
                        ? 'Discover your community at UTS'
                        : 'Your campus community awaits',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: () => _showQRScanner(),
              ),
            ],
          ),
        ],
      ),
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
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Browse All Societies Grid Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                // Section Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Browse All Societies',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Grid of Society Cards
                ...List.generate((filteredSocieties.length / 2).ceil(), (rowIndex) {
                  final startIndex = rowIndex * 2;
                  final endIndex = (startIndex + 2).clamp(0, filteredSocieties.length);
                  final rowSocieties = filteredSocieties.sublist(startIndex, endIndex);
                  
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ...rowSocieties.map((society) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: rowSocieties.indexOf(society) == 0 && rowSocieties.length > 1 ? 4 : 0,
                              left: rowSocieties.indexOf(society) == 1 ? 4 : 0,
                            ),
                            child: _buildFigmaDiscoverCard(society),
                          ),
                        )),
                        // Add empty expanded widget if odd number of societies in last row
                        if (rowSocieties.length == 1) const Expanded(child: SizedBox()),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
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
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Societies',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 1.33,
                    ),
                  ),
                ),

              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Society List
          Expanded(
            child: ListView.builder(
              itemCount: joinedSocieties.length,
              itemBuilder: (context, index) {
                return _buildFigmaYourSocietyCard(joinedSocieties[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    final societyEvents = _calendarService.getEventsBySourceSync(
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

  Widget _buildFigmaDiscoverCard(Society society) {
    return GestureDetector(
      onTap: () => _showSocietyDetails(society),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
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
            // Image Section
            Container(
              width: double.infinity,
              height: 164,
              child: Stack(
                children: [
                  // Background/Image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    child: society.logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: society.logoUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            errorWidget: (context, url, error) => 
                                _buildSocietyPlaceholder(society),
                          )
                        : _buildSocietyPlaceholder(society),
                  ),
                  
                  // Category Tag
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
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
                        society.category,
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
            
            // Content Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    society.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'Join now!',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 1.50,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFigmaYourSocietyCard(Society society) {
    return GestureDetector(
      onTap: () => _showSocietyDetails(society),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Society Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
              ),
              child: society.logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: society.logoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => 
                          _buildSocietyPlaceholder(society),
                    )
                  : _buildSocietyPlaceholder(society),
            ),
            
            const SizedBox(width: 12),
            
            // Society Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    society.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    '${society.memberCount} members',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.50),
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.67,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Tags
                  if (society.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: society.tags.take(2).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: ShapeDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.50,
                              color: Colors.black.withValues(alpha: 0.10),
                            ),
                            borderRadius: BorderRadius.circular(2),
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
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    society.description.length > 50 
                        ? '${society.description.substring(0, 50)}...'
                        : society.description,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.67,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            // Society Logo with Gradient Overlay and Date
            Container(
              width: 80,
              height: 80,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Stack(
                children: [
                  // Society Logo Background
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    child: society?.logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: society!.logoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            errorWidget: (context, url, error) => 
                                _buildSocietyPlaceholder(society),
                          )
                        : _buildSocietyPlaceholder(society ?? Society(
                            id: 'unknown',
                            name: 'Unknown Society',
                            description: '',
                            category: 'Academic',
                            logoUrl: null,
                            memberCount: 0,
                            tags: [],
                            isJoined: false,
                            adminIds: [],
                          )),
                  ),
                  
                  // Black/Grey Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  
                  // Date Details in White Text
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Day Number
                        Text(
                          '${event.startTime.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                        
                        // Month
                        Text(
                          _getShortMonthName(event.startTime.month),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        // Time
                        Text(
                          '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Event Details
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      society?.name ?? 'Society Event',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    Text(
                      event.location,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Attendee Count
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${event.attendeeIds.length}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'attending',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Widget _buildSocietyPlaceholder(Society society) {
    // Create a color based on society category
    final colors = {
      'Technology': Colors.blue,
      'Creative': Colors.purple,
      'Sports': Colors.green,
      'Cultural': Colors.orange,
      'Business': Colors.red,
      'Academic': Colors.indigo,
      'Entertainment': Colors.pink,
    };
    
    final color = colors[society.category] ?? Colors.grey;
    
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              color: color,
              size: 30,
            ),
            const SizedBox(height: 4),
            Text(
              society.name.split(' ').map((word) => word[0]).take(3).join(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getShortMonthName(int month) {
    const months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month];
  }

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SocietyDetailScreen(society: society),
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
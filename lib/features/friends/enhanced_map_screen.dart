import 'package:flutter/material.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/location_service.dart';
import '../../core/services/friendship_service.dart';
import '../../core/services/calendar_service.dart';
import '../../shared/models/user.dart';
import '../../shared/models/location.dart';
import '../../shared/models/event.dart';
import '../../core/constants/app_colors.dart';
import 'interactive_map_screen.dart';

class EnhancedMapScreen extends StatefulWidget {
  const EnhancedMapScreen({super.key});

  @override
  State<EnhancedMapScreen> createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedView = 'friends';
  bool _showHeatmap = false;
  
  final DemoDataManager _demoData = DemoDataManager.instance;
  final LocationService _locationService = LocationService();
  final FriendshipService _friendshipService = FriendshipService();
  final CalendarService _calendarService = CalendarService();
  
  bool _isInitialized = false;

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
            _buildControls(),
            Expanded(child: _buildMapContent()),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final campusData = _locationService.getFriendsOnCampusMap(_demoData.currentUser.id);
    final friendsOnCampus = (campusData['friends'] as List<User>).length;
    
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
              const Text(
                'Campus Map',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.layers, color: Colors.white),
                    onPressed: () => _toggleMapLayers(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () => _centerOnUser(),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Real-time campus overview
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
                        '$friendsOnCampus friends on campus',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Live location updates',
                        style: TextStyle(
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
    final nearbyCount = _locationService.findNearbyFriends(_demoData.currentUser.id, maxDistance: 500).length;
    final meetupSuggestions = _locationService.getMeetupSuggestions(_demoData.currentUser.id).length;
    
    return Row(
      children: [
        _buildStatBadge('$nearbyCount', 'Nearby'),
        const SizedBox(width: 8),
        _buildStatBadge('$meetupSuggestions', 'Suggestions'),
      ],
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildViewToggle('friends', 'Friends', Icons.people),
                  const SizedBox(width: 8),
                  _buildViewToggle('events', 'Events', Icons.event),
                  const SizedBox(width: 8),
                  _buildViewToggle('buildings', 'Buildings', Icons.business),
                  const SizedBox(width: 8),
                  _buildViewToggle('study', 'Study Spots', Icons.school),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _showHeatmap ? Icons.visibility_off : Icons.visibility,
              color: AppColors.socialColor,
            ),
            onPressed: () {
              setState(() {
                _showHeatmap = !_showHeatmap;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(String value, String label, IconData icon) {
    final isSelected = _selectedView == value;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 16, 
            color: isSelected ? Colors.white : AppColors.socialColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.socialColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedView = value;
        });
      },
      selectedColor: AppColors.socialColor,
      checkmarkColor: Colors.transparent,
    );
  }

  Widget _buildMapContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Interactive map message with button to open full map
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Interactive Campus Map',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View friends, events, and locations\non the campus map',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InteractiveMapScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.launch),
                    label: const Text('Open Interactive Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.socialColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Overlay content based on selected view
            if (_selectedView == 'friends') _buildFriendsOverlay(),
            if (_selectedView == 'events') _buildEventsOverlay(),
            if (_selectedView == 'buildings') _buildBuildingsOverlay(),
            if (_selectedView == 'study') _buildStudySpotOverlay(),
            
            // Heatmap overlay
            if (_showHeatmap) _buildHeatmapOverlay(),
            
            // User location indicator
            _buildUserLocationIndicator(),
            
            // Map controls
            _buildMapControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusMap() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Stack(
        children: [
          // UTS Campus layout (simplified)
          Positioned(
            left: 50,
            top: 50,
            child: _buildMapBuilding('Building 1', 60, 40, Colors.blue.shade300),
          ),
          Positioned(
            left: 150,
            top: 80,
            child: _buildMapBuilding('Building 2', 80, 50, Colors.blue.shade300),
          ),
          Positioned(
            left: 100,
            top: 180,
            child: _buildMapBuilding('Library', 90, 60, Colors.purple.shade300),
          ),
          Positioned(
            left: 250,
            top: 120,
            child: _buildMapBuilding('Building 11', 70, 80, Colors.blue.shade300),
          ),
          Positioned(
            left: 200,
            top: 220,
            child: _buildMapBuilding('Building 6', 60, 45, Colors.blue.shade300),
          ),
          
          // Campus pathways
          CustomPaint(
            size: const Size(400, 300),
            painter: CampusPathwaysPainter(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBuilding(String name, double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26, width: 1),
      ),
      child: Center(
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFriendsOverlay() {
    final campusData = _locationService.getFriendsOnCampusMap(_demoData.currentUser.id);
    final friends = campusData['friends'] as List<User>;
    final locations = campusData['locations'] as Map<String, Location>;
    
    return Stack(
      children: friends.map((friend) {
        final location = locations[friend.id];
        if (location == null) return const SizedBox();
        
        final position = _getMapPosition(location.building);
        
        return Positioned(
          left: position['x']! + 10,
          top: position['y']! - 10,
          child: _buildFriendPin(friend, location),
        );
      }).toList(),
    );
  }

  Widget _buildEventsOverlay() {
    final todayEvents = _calendarService.getUnifiedCalendarSync(
      _demoData.currentUser.id,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 1)),
    ).where((event) => event.location.isNotEmpty).toList();
    
    return Stack(
      children: todayEvents.map((event) {
        final position = _getMapPositionFromLocation(event.location);
        
        return Positioned(
          left: position['x']!,
          top: position['y']!,
          child: _buildEventPin(event),
        );
      }).toList(),
    );
  }

  Widget _buildBuildingsOverlay() {
    final buildings = _demoData.locationsSync;
    
    return Stack(
      children: buildings.map((building) {
        final position = _getMapPosition(building.building);
        
        return Positioned(
          left: position['x']! + 5,
          top: position['y']! + 5,
          child: _buildBuildingInfo(building),
        );
      }).toList(),
    );
  }

  Widget _buildStudySpotOverlay() {
    final studySpots = _demoData.locationsSync
        .where((loc) => loc.type == LocationType.library || loc.type == LocationType.study)
        .toList();
    
    return Stack(
      children: studySpots.map((spot) {
        final position = _getMapPosition(spot.building);
        final studyGroup = _locationService.getStudyGroupSuggestions(_demoData.currentUser.id)
            .where((suggestion) => (suggestion['location'] as Location).id == spot.id)
            .toList();
        
        return Positioned(
          left: position['x']!,
          top: position['y']!,
          child: _buildStudySpotPin(spot, studyGroup.isNotEmpty),
        );
      }).toList(),
    );
  }

  Widget _buildHeatmapOverlay() {
    final heatmapData = _locationService.getCampusActivityHeatmap(_demoData.currentUser.id);
    
    return Stack(
      children: heatmapData.entries.map((entry) {
        final location = _demoData.getLocationById(entry.key);
        if (location == null) return const SizedBox();
        
        final position = _getMapPosition(location.building);
        final intensity = (entry.value / 3).clamp(0.0, 1.0); // Normalize to 0-1
        
        return Positioned(
          left: position['x']! - 20,
          top: position['y']! - 20,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: intensity * 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserLocationIndicator() {
    final currentUser = _demoData.currentUser;
    if (currentUser.currentLocationId == null) return const SizedBox();
    
    final location = _demoData.getLocationById(currentUser.currentLocationId!);
    if (location == null) return const SizedBox();
    
    final position = _getMapPosition(location.building);
    
    return Positioned(
      left: position['x']!,
      top: position['y']!,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.socialColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.person,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      top: 16,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: "zoom_in",
            onPressed: () => _zoomIn(),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "zoom_out",
            onPressed: () => _zoomOut(),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendPin(User friend, Location location) {
    return GestureDetector(
      onTap: () => _showFriendLocationDetails(friend, location),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: _getStatusColor(friend.status),
              child: Text(
                friend.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              friend.name.split(' ')[0],
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventPin(Event event) {
    return GestureDetector(
      onTap: () => _showEventLocationDetails(event),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _getEventColor(event),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _getEventIcon(event.type),
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBuildingInfo(Location building) {
    return GestureDetector(
      onTap: () => _showBuildingDetails(building),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          building.room ?? building.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildStudySpotPin(Location spot, bool hasGroup) {
    return GestureDetector(
      onTap: () => _showStudySpotDetails(spot),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: hasGroup ? Colors.orange : Colors.blue,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          hasGroup ? Icons.group : Icons.school,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuickActions(),
          const SizedBox(height: 12),
          _buildNearbyFriendsList(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickAction('Find Friends', Icons.search, () => _findNearbyFriends()),
        _buildQuickAction('Study Groups', Icons.group_work, () => _showStudyGroups()),
        _buildQuickAction('Meetup', Icons.coffee, () => _suggestMeetup()),
      ],
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.socialColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.socialColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyFriendsList() {
    final nearbyFriends = _locationService.findNearbyFriends(_demoData.currentUser.id, maxDistance: 500);
    
    if (nearbyFriends.isEmpty) {
      return const Text(
        'No friends nearby',
        style: TextStyle(color: Colors.grey),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Friends',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: nearbyFriends.length,
            itemBuilder: (context, index) {
              final nearbyData = nearbyFriends[index];
              final friend = nearbyData['friend'] as User;
              final distance = nearbyData['distance'] as double;
              
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.socialColor,
                      child: Text(
                        friend.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${distance.round()}m',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Map<String, double> _getMapPosition(String building) {
    // Simplified building positions on map
    switch (building) {
      case 'Building 1':
        return {'x': 50, 'y': 50};
      case 'Building 2':
        return {'x': 150, 'y': 80};
      case 'Library':
        return {'x': 100, 'y': 180};
      case 'Building 11':
        return {'x': 250, 'y': 120};
      case 'Building 6':
        return {'x': 200, 'y': 220};
      default:
        return {'x': 150, 'y': 150};
    }
  }

  Map<String, double> _getMapPositionFromLocation(String locationString) {
    if (locationString.contains('Building 1')) return {'x': 60, 'y': 60};
    if (locationString.contains('Building 2')) return {'x': 160, 'y': 90};
    if (locationString.contains('Library')) return {'x': 110, 'y': 190};
    if (locationString.contains('Building 11')) return {'x': 260, 'y': 130};
    if (locationString.contains('Building 6')) return {'x': 210, 'y': 230};
    return {'x': 150, 'y': 150};
  }

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

  Color _getEventColor(Event event) {
    switch (event.type) {
      case EventType.class_:
        return AppColors.personalColor;  // Classes are personal schedule
      case EventType.society:
        return AppColors.societyColor;
      case EventType.personal:
        return AppColors.personalColor;
      case EventType.assignment:
        return AppColors.personalColor;  // Assignments are personal academic
    }
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.class_:
        return Icons.school;
      case EventType.society:
        return Icons.groups;
      case EventType.personal:
        return Icons.person;
      case EventType.assignment:
        return Icons.assignment;
    }
  }

  // Event Handlers
  void _toggleMapLayers() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Map Layers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Activity Heatmap'),
              value: _showHeatmap,
              onChanged: (value) {
                setState(() {
                  _showHeatmap = value ?? false;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _centerOnUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Centered on your location')),
    );
  }

  void _zoomIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zoom in')),
    );
  }

  void _zoomOut() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zoom out')),
    );
  }

  void _showFriendLocationDetails(User friend, Location location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(friend.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${friend.statusMessage ?? friend.status.toString().split('.').last}'),
            Text('Location: ${location.displayName}'),
            if (friend.locationUpdatedAt != null)
              Text('Updated: ${_formatTime(friend.locationUpdatedAt!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _suggestMeetupWithFriend(friend);
            },
            child: const Text('Suggest Meetup'),
          ),
        ],
      ),
    );
  }

  void _showEventLocationDetails(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${event.title} at ${event.location}')),
    );
  }

  void _showBuildingDetails(Location building) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${building.name}: ${building.description ?? 'Building information'}')),
    );
  }

  void _showStudySpotDetails(Location spot) {
    final studyGroups = _locationService.getStudyGroupSuggestions(_demoData.currentUser.id)
        .where((suggestion) => (suggestion['location'] as Location).id == spot.id)
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(spot.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(spot.description ?? ''),
            if (studyGroups.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Active Study Groups:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...studyGroups.map((group) => Text('• ${group['suggestion']}')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (studyGroups.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joining study group...')),
                );
              },
              child: const Text('Join Group'),
            ),
        ],
      ),
    );
  }

  void _findNearbyFriends() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Searching for nearby friends...')),
    );
  }

  void _showStudyGroups() {
    final studyGroups = _locationService.getStudyGroupSuggestions(_demoData.currentUser.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Study Groups'),
        content: studyGroups.isEmpty
            ? const Text('No active study groups found')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: studyGroups.map((group) => 
                  ListTile(
                    title: Text(group['suggestion'] as String),
                    onTap: () => Navigator.pop(context),
                  )
                ).toList(),
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

  void _suggestMeetup() {
    final suggestions = _locationService.getMeetupSuggestions(_demoData.currentUser.id);
    
    if (suggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No meetup suggestions available')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Meetup Suggestions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions.take(3).map((suggestion) => 
            ListTile(
              title: Text(suggestion['suggestion'] as String),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meetup suggestion sent!')),
                );
              },
            )
          ).toList(),
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

  void _suggestMeetupWithFriend(User friend) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Meetup suggestion sent to ${friend.name}')),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Custom painter for campus pathways
class CampusPathwaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Main pathway
    path.moveTo(50, 200);
    path.lineTo(300, 200);
    
    // Cross pathways
    path.moveTo(150, 100);
    path.lineTo(150, 250);
    
    path.moveTo(250, 150);
    path.lineTo(250, 250);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/location_service.dart';
import '../../core/services/friendship_service.dart';
import '../../core/services/calendar_service.dart';
import '../../shared/models/user.dart';
import '../../shared/models/location.dart';
import '../../shared/models/event.dart';
import '../../core/constants/app_colors.dart';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MapController _mapController;
  String _selectedView = 'friends';
  bool _showHeatmap = false;
  
  final DemoDataManager _demoData = DemoDataManager.instance;
  final LocationService _locationService = LocationService();
  final FriendshipService _friendshipService = FriendshipService();
  final CalendarService _calendarService = CalendarService();
  
  bool _isInitialized = false;

  // UTS Campus coordinates (UTS Building 1)
  static const LatLng _utsCenter = LatLng(-33.8836, 151.2002);
  static const double _initialZoom = 17.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mapController = MapController();
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
            children: [
              Icon(Icons.map, color: Theme.of(context).colorScheme.surface, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$friendsOnCampus friends on campus',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // View selector
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildViewButton('friends', 'Friends', Icons.people, AppColors.online),
                      const SizedBox(width: 8),
                      _buildViewButton('events', 'Events', Icons.event, AppColors.socialColor),
                      const SizedBox(width: 8),
                      _buildViewButton('buildings', 'Buildings', Icons.location_city, Colors.grey),
                      const SizedBox(width: 8),
                      _buildViewButton('study', 'Study Spots', Icons.menu_book, AppColors.studyColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Additional controls
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.my_location, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'UTS Sydney Campus',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _showHeatmap,
                onChanged: (value) {
                  setState(() {
                    _showHeatmap = value;
                  });
                },
                activeThumbColor: AppColors.socialColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Heatmap',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String view, String label, IconData icon, Color color) {
    final isSelected = _selectedView == view;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = view;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _utsCenter,
            initialZoom: _initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.uniconnect.app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: _buildMarkers(),
            ),
            if (_showHeatmap) _buildHeatmapLayer(),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Add user's location
    markers.add(
      Marker(
        point: _utsCenter,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.socialColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );

    switch (_selectedView) {
      case 'friends':
        markers.addAll(_buildFriendMarkers());
        break;
      case 'events':
        markers.addAll(_buildEventMarkers());
        break;
      case 'buildings':
        markers.addAll(_buildBuildingMarkers());
        break;
      case 'study':
        markers.addAll(_buildStudySpotMarkers());
        break;
    }

    return markers;
  }

  List<Marker> _buildFriendMarkers() {
    final markers = <Marker>[];
    final campusData = _locationService.getFriendsOnCampusMap(_demoData.currentUser.id);
    final friendsOnCampus = campusData['friends'] as List<User>;

    // UTS Campus coordinates for friends locations
    final demoCoordinates = [
      LatLng(-33.8841, 151.2006), // UTS Library - Sarah
      LatLng(-33.8842, 151.2004), // Building 11 - James
      LatLng(-33.8836, 151.2002), // Building 1 - Marcus
      LatLng(-33.8839, 151.2001), // Building 6 - Emma
      LatLng(-33.8840, 151.2005), // Additional friend location
    ];

    for (int i = 0; i < friendsOnCampus.length && i < demoCoordinates.length; i++) {
      final friend = friendsOnCampus[i];
      final position = demoCoordinates[i];

      markers.add(
        Marker(
          point: position,
          width: 60,
          height: 80,
          child: GestureDetector(
            onTap: () => _showFriendPopup(friend),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: friend.profileImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: friend.profileImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.online,
                              child: Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.online,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    friend.name.split(' ').first,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Marker> _buildEventMarkers() {
    final markers = <Marker>[];
    
    // Get today's events
    final allTodayEvents = _calendarService.getUnifiedCalendarSync(
      _demoData.currentUser.id,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 1)),
    );
    final todayEvents = allTodayEvents.where((event) => event.location.isNotEmpty).toList();

    final eventCoordinates = [
      LatLng(-33.8838, 151.2003), // Interactive Design Lecture - Building 2
      LatLng(-33.8842, 151.2004), // Database Systems Lab - Building 11
      LatLng(-33.8836, 151.2002), // Society Event - Building 1
    ];

    for (int i = 0; i < todayEvents.length && i < eventCoordinates.length; i++) {
      final event = todayEvents[i];
      final position = eventCoordinates[i];

      markers.add(
        Marker(
          point: position,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showEventPopup(event),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.socialColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.event,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Marker> _buildBuildingMarkers() {
    final markers = <Marker>[];
    final campusLocations = _demoData.locationsSync;

    // Use actual coordinates from demo data locations
    for (final location in campusLocations) {
      markers.add(
        Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showLocationPopup(location),
            child: Container(
              decoration: BoxDecoration(
                color: _getLocationTypeColor(location.type),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getLocationTypeIcon(location.type),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Color _getLocationTypeColor(LocationType type) {
    switch (type) {
      case LocationType.classroom:
        return AppColors.socialColor;
      case LocationType.lab:
        return Colors.purple;
      case LocationType.study:
        return AppColors.studyColor;
      case LocationType.library:
        return AppColors.studyColor;
      case LocationType.common:
        return Colors.orange;
      case LocationType.cafeteria:
        return Colors.green;
      case LocationType.outdoor:
        return Colors.teal;
      case LocationType.office:
        return Colors.blueGrey;
      case LocationType.other:
        return Colors.grey;
    }
  }

  IconData _getLocationTypeIcon(LocationType type) {
    switch (type) {
      case LocationType.classroom:
        return Icons.school;
      case LocationType.lab:
        return Icons.computer;
      case LocationType.study:
        return Icons.menu_book;
      case LocationType.library:
        return Icons.local_library;
      case LocationType.common:
        return Icons.people;
      case LocationType.cafeteria:
        return Icons.restaurant;
      case LocationType.outdoor:
        return Icons.park;
      case LocationType.office:
        return Icons.business;
      case LocationType.other:
        return Icons.location_on;
    }
  }

  List<Marker> _buildStudySpotMarkers() {
    final markers = <Marker>[];
    final allLocations = _demoData.locationsSync;
    final studyLocations = allLocations
        .where((loc) => loc.type == LocationType.study)
        .toList();

    for (final location in studyLocations) {
      markers.add(
        Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showLocationPopup(location),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.studyColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildHeatmapLayer() {
    // Heatmap showing student activity density around campus
    return MarkerLayer(
      markers: [
        // High activity - UTS Library
        Marker(
          point: LatLng(-33.8841, 151.2006),
          width: 120,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.3),
            ),
          ),
        ),
        // Medium activity - Building 11 (Computer Labs)
        Marker(
          point: LatLng(-33.8842, 151.2004),
          width: 90,
          height: 90,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
        ),
        // Medium activity - Building 2 (Design Studios)
        Marker(
          point: LatLng(-33.8838, 151.2003),
          width: 80,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.25),
            ),
          ),
        ),
        // Lower activity - Building 1 (Student Services)
        Marker(
          point: LatLng(-33.8836, 151.2002),
          width: 70,
          height: 70,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.yellow.withOpacity(0.3),
            ),
          ),
        ),
        // Lower activity - Building 6
        Marker(
          point: LatLng(-33.8839, 151.2001),
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.yellow.withOpacity(0.25),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _mapController.move(_utsCenter, _initialZoom);
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Center on Campus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.socialColor,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    // TODO: Open navigation to selected location
                  },
                  icon: const Icon(Icons.directions),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: AppColors.socialColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendPopup(User friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(friend.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course: ${friend.course}'),
            Text('Year: ${friend.year}'),
            Text('Status: ${friend.status.toString().split('.').last}'),
            if (friend.currentBuilding != null)
              Text('Location: ${friend.currentBuilding}'),
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
              // TODO: Navigate to chat with friend
            },
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }

  void _showEventPopup(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${event.location}'),
            Text('Time: ${_formatTime(event.startTime)}'),
            if (event.description.isNotEmpty)
              Text('Description: ${event.description}'),
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

  void _showLocationPopup(Location location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(location.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Building: ${location.building}'),
            if (location.floor != null)
              Text('Floor: ${location.floor}'),
            if (location.room != null)
              Text('Room: ${location.room}'),
            if (location.description != null)
              Text('Description: ${location.description}'),
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

  void _showStudySpotPopup(Location studySpot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(studySpot.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Building: ${studySpot.building}'),
            if (studySpot.room != null)
              Text('Room: ${studySpot.room}'),
            if (studySpot.capacity != null)
              Text('Capacity: ${studySpot.capacity} people'),
            Text('Type: ${studySpot.type.toString().split('.').last}'),
            if (studySpot.amenities.isNotEmpty)
              Text('Amenities: ${studySpot.amenities.join(', ')}'),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
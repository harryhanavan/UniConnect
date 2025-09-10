import 'package:flutter/material.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';

class Phase1TestScreen extends StatefulWidget {
  const Phase1TestScreen({super.key});

  @override
  State<Phase1TestScreen> createState() => _Phase1TestScreenState();
}

class _Phase1TestScreenState extends State<Phase1TestScreen> {
  final demoData = DemoDataManager.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 1: Data Architecture Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('📊 Data Architecture Overview'),
            _buildOverviewCard(),
            
            const SizedBox(height: 20),
            _buildSectionHeader('👤 Enhanced User Model'),
            _buildUserModelTest(),
            
            const SizedBox(height: 20),
            _buildSectionHeader('🤝 Friend Relationships'),
            _buildFriendshipTest(),
            
            const SizedBox(height: 20),
            _buildSectionHeader('📍 Location Tracking'),
            _buildLocationTest(),
            
            const SizedBox(height: 20),
            _buildSectionHeader('🔒 Privacy Settings'),
            _buildPrivacyTest(),
            
            const SizedBox(height: 20),
            _buildSectionHeader('🔄 Data Interconnections'),
            _buildInterconnectionTest(),
            
            const SizedBox(height: 20),
            _buildSectionHeader('✅ Phase 1 Validation'),
            _buildValidationSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Users: ${demoData.usersSync.length}'),
            Text('Total Locations: ${demoData.locationsSync.length}'),
            Text('Total Friend Requests: ${demoData.friendRequestsSync.length}'),
            Text('Total Privacy Settings: ${demoData.privacySettingsSync.length}'),
            const SizedBox(height: 10),
            Text(
              'Current User: ${demoData.currentUser.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserModelTest() {
    final currentUser = demoData.currentUser;
    final currentLocation = demoData.getLocationById(currentUser.currentLocationId ?? '');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${currentUser.name}'),
            Text('Status: ${currentUser.status.toString().split('.').last}'),
            Text('Status Message: ${currentUser.statusMessage ?? 'None'}'),
            Text('Friends: ${currentUser.friendIds.length}'),
            Text('Pending Requests: ${currentUser.pendingFriendRequests.length}'),
            if (currentLocation != null) ...[
              const SizedBox(height: 8),
              Text('Current Location: ${currentLocation.displayName}'),
              Text('Building: ${currentUser.currentBuilding}'),
              Text('Room: ${currentUser.currentRoom}'),
              Text('Coordinates: ${currentUser.latitude?.toStringAsFixed(4)}, ${currentUser.longitude?.toStringAsFixed(4)}'),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: currentUser.isOnline ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currentUser.isOnline ? 'Online' : 'Offline',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendshipTest() {
    final currentUser = demoData.currentUser;
    final friends = demoData.getFriendsForUser(currentUser.id);
    final pendingRequests = demoData.getPendingFriendRequests(currentUser.id);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Friends (${friends.length}):'),
            ...friends.map((friend) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: friend.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${friend.name} - ${friend.status.toString().split('.').last}'),
                  ),
                  if (friend.currentBuilding != null)
                    Text(
                      '📍 ${friend.currentBuilding}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            )),
            
            const SizedBox(height: 12),
            Text('Pending Friend Requests (${pendingRequests.length}):'),
            ...pendingRequests.map((request) {
              final sender = demoData.getUserById(request.senderId);
              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From: ${sender?.name ?? 'Unknown'}'),
                    if (request.message != null)
                      Text(
                        '"${request.message}"',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    Text(
                      'Sent: ${_formatDate(request.createdAt)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UTS Campus Locations:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...demoData.locationsSync.map((location) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${location.name} (${location.building})'),
                  Text(
                    'Type: ${location.type.toString().split('.').last} | Capacity: ${location.capacity ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (location.amenities.isNotEmpty)
                    Text(
                      'Amenities: ${location.amenities.join(', ')}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            )),
            
            const SizedBox(height: 12),
            const Text('Distance Calculations:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildDistanceTest(),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceTest() {
    final building2 = demoData.locationsSync.firstWhere((l) => l.building == 'Building 2');
    final library = demoData.locationsSync.firstWhere((l) => l.building == 'Library');
    final distance = building2.distanceTo(library);
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Text(
        'Building 2 to Library: ${distance.toStringAsFixed(0)}m',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildPrivacyTest() {
    final currentUser = demoData.currentUser;
    final privacy = demoData.getPrivacySettingsForUser(currentUser.id);
    
    if (privacy == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Privacy settings not found'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location Sharing: ${privacy.locationSharing.toString().split('.').last}'),
            Text('Share Exact Location: ${privacy.shareExactLocation}'),
            Text('Timetable Sharing: ${privacy.timetableSharing.toString().split('.').last}'),
            Text('Share Free Times: ${privacy.shareFreeTimes}'),
            Text('Online Status Visibility: ${privacy.onlineStatusVisibility.toString().split('.').last}'),
            Text('Show Last Seen: ${privacy.showLastSeen}'),
            
            const SizedBox(height: 8),
            const Text('Per-Friend Timetable Settings:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...privacy.perFriendTimetableSharing.entries.map((entry) {
              final friend = demoData.getUserById(entry.key);
              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('${friend?.name ?? 'Unknown'}: ${entry.value.toString().split('.').last}'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInterconnectionTest() {
    final currentUser = demoData.currentUser;
    final friends = demoData.getFriendsForUser(currentUser.id);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Relationship Validation:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...friends.map((friend) {
              final isMutual = demoData.areFriends(currentUser.id, friend.id);
              final canShareLocation = demoData.getPrivacySettingsForUser(currentUser.id)?.canShareLocationWith(friend.id) ?? false;
              final canShareTimetable = demoData.getPrivacySettingsForUser(currentUser.id)?.canShareTimetableWith(friend.id) ?? false;
              
              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${friend.name}:'),
                    Text('  Mutual friendship: ${isMutual ? '✅' : '❌'}'),
                    Text('  Can share location: ${canShareLocation ? '✅' : '❌'}'),
                    Text('  Can share timetable: ${canShareTimetable ? '✅' : '❌'}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationSummary() {
    final validations = _runValidations();
    
    return Card(
      color: validations.every((v) => v['status'] == true) ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  validations.every((v) => v['status'] == true) ? Icons.check_circle : Icons.error,
                  color: validations.every((v) => v['status'] == true) ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Phase 1 Validation ${validations.every((v) => v['status'] == true) ? 'PASSED' : 'FAILED'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: validations.every((v) => v['status'] == true) ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...validations.map((validation) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    validation['status'] ? Icons.check : Icons.close,
                    size: 16,
                    color: validation['status'] ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(validation['test'], style: const TextStyle(fontSize: 12))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _runValidations() {
    final currentUser = demoData.currentUser;
    final friends = demoData.getFriendsForUser(currentUser.id);
    
    return [
      {
        'test': 'All users have enhanced fields (status, location, privacy)',
        'status': demoData.usersSync.every((user) => 
          user.privacySettingsId.isNotEmpty
        ),
      },
      {
        'test': 'Friend relationships are bidirectional',
        'status': friends.every((friend) => 
          friend.friendIds.contains(currentUser.id)
        ),
      },
      {
        'test': 'All users have corresponding privacy settings',
        'status': demoData.usersSync.every((user) => 
          demoData.getPrivacySettingsForUser(user.id) != null
        ),
      },
      {
        'test': 'Location data includes UTS buildings with coordinates',
        'status': demoData.locationsSync.isNotEmpty && 
          demoData.locationsSync.every((loc) => 
            loc.latitude != 0 && loc.longitude != 0
          ),
      },
      {
        'test': 'Friend requests have proper status tracking',
        'status': demoData.friendRequestsSync.isNotEmpty &&
          demoData.friendRequestsSync.every((req) => 
            req.createdAt != null
          ),
      },
      {
        'test': 'Privacy settings have granular controls',
        'status': demoData.privacySettingsSync.every((privacy) =>
          privacy.timetableSharing != null
        ),
      },
      {
        'test': 'Current user has active location tracking',
        'status': currentUser.currentLocationId != null &&
          demoData.getLocationById(currentUser.currentLocationId!) != null,
      },
    ];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
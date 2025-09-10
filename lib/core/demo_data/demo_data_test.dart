import 'demo_data_manager.dart';

/// Simple test function to validate demo data loading
/// Call this from main.dart to test the implementation
Future<void> testDemoDataLoading() async {
  print('Testing demo data loading...');
  
  final manager = DemoDataManager.instance;
  
  try {
    // Test loading all data types
    final users = await manager.users;
    final societies = await manager.societies;
    final events = await manager.events;
    final locations = await manager.locations;
    final privacySettings = await manager.privacySettings;
    final friendRequests = await manager.friendRequests;
    
    print('✓ Successfully loaded:');
    print('  - ${users.length} users');
    print('  - ${societies.length} societies');
    print('  - ${events.length} events');
    print('  - ${locations.length} locations');
    print('  - ${privacySettings.length} privacy settings');
    print('  - ${friendRequests.length} friend requests');
    
    // Test sync methods after async loading
    final currentUser = manager.currentUser;
    print('✓ Current user: ${currentUser.name}');
    
    final friends = manager.friends;
    print('✓ Friends: ${friends.length}');
    
    final joinedSocieties = manager.joinedSocieties;
    print('✓ Joined societies: ${joinedSocieties.length}');
    
    final todayEvents = manager.todayEvents;
    print('✓ Today\'s events: ${todayEvents.length}');
    
    print('✓ Demo data loading test completed successfully!');
    
  } catch (e) {
    print('✗ Demo data loading failed: $e');
    rethrow;
  }
}

/// Test individual data validation
Future<void> testDataValidation() async {
  print('\\nTesting data validation...');
  
  final manager = DemoDataManager.instance;
  
  // Ensure data is loaded
  await manager.users;
  
  // Test friend relationships
  final users = manager.usersSync;
  for (final user in users) {
    for (final friendId in user.friendIds) {
      final friend = manager.getUserById(friendId);
      if (friend == null) {
        print('✗ User ${user.id} has non-existent friend: $friendId');
      } else if (!friend.friendIds.contains(user.id)) {
        print('✗ Non-bidirectional friendship: ${user.id} -> $friendId');
      }
    }
  }
  
  // Test privacy settings
  for (final user in users) {
    final privacy = manager.getPrivacySettingsForUser(user.id);
    if (privacy == null) {
      print('✗ User ${user.id} has no privacy settings');
    }
  }
  
  print('✓ Data validation completed');
}
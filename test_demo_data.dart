import 'lib/core/demo_data/demo_data_manager.dart';

void main() async {
  print('Testing demo data management...');
  
  final manager = DemoDataManager.instance;
  
  try {
    // Test synchronous access (should work now)
    print('Testing synchronous access...');
    final users = manager.users;
    final societies = manager.societies;
    final events = manager.events;
    
    print('✓ Synchronous access works');
    print('  - Users: ${users.length}');
    print('  - Societies: ${societies.length}');
    print('  - Events: ${events.length}');
    
    // Test async access (should load from JSON)
    print('\\nTesting async access...');
    final asyncUsers = await manager.usersAsync;
    final asyncSocieties = await manager.societiesAsync;
    final asyncEvents = await manager.eventsAsync;
    
    print('✓ Async access works');
    print('  - Users: ${asyncUsers.length}');
    print('  - Societies: ${asyncSocieties.length}');
    print('  - Events: ${asyncEvents.length}');
    
    print('\\n✅ All tests passed!');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
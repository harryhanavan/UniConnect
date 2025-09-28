import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/location.dart';
import '../../shared/models/privacy_settings.dart';
import '../../shared/models/friend_request.dart';
import '../demo_data/demo_data_loader.dart';
import 'repositories/user_repository.dart';
import 'repositories/society_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/location_repository.dart';
import 'repositories/privacy_settings_repository.dart';
import 'repositories/friend_request_repository.dart';
import 'database_helper.dart';

class DataSeeder {
  static const String _seedVersionKey = 'db_seed_version';
  static const int _currentSeedVersion = 1;

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final UserRepository _userRepository = UserRepository();
  final SocietyRepository _societyRepository = SocietyRepository();
  final EventRepository _eventRepository = EventRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final PrivacySettingsRepository _privacySettingsRepository = PrivacySettingsRepository();
  final FriendRequestRepository _friendRequestRepository = FriendRequestRepository();

  Future<bool> needsSeeding() async {
    try {
      // Check if database is healthy
      if (!await _databaseHelper.isDatabaseHealthy()) {
        if (kDebugMode) {
          print('Database is not healthy, seeding required');
        }
        return true;
      }

      // Check if we have any data
      final stats = await _databaseHelper.getDatabaseStats();
      final totalRecords = stats.values.fold(0, (sum, count) => sum + (count > 0 ? count : 0));

      if (totalRecords == 0) {
        if (kDebugMode) {
          print('Database is empty, seeding required');
        }
        return true;
      }

      // Check seed version (future-proofing for data updates)
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_seedVersionKey) ?? 0;

      if (currentVersion < _currentSeedVersion) {
        if (kDebugMode) {
          print('Database seed version outdated ($currentVersion < $_currentSeedVersion), seeding required');
        }
        return true;
      }

      if (kDebugMode) {
        print('Database seeding not needed. Records: $totalRecords, Version: $currentVersion');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking seed status: $e');
      }
      return true; // If we can't check, assume we need seeding
    }
  }

  Future<void> seedDatabase({bool forceReseed = false}) async {
    try {
      if (!forceReseed && !await needsSeeding()) {
        if (kDebugMode) {
          print('Database seeding skipped - not needed');
        }
        return;
      }

      if (kDebugMode) {
        print('Starting database seeding...');
      }

      final stopwatch = Stopwatch()..start();

      // Clear existing data if force reseeding
      if (forceReseed) {
        await _databaseHelper.clearAllTables();
        if (kDebugMode) {
          print('Cleared existing data for reseed');
        }
      }

      // Load data from JSON files using existing DemoDataLoader
      if (kDebugMode) {
        print('Loading data from JSON files...');
      }

      final users = await DemoDataLoader.loadUsers();
      final societies = await DemoDataLoader.loadSocieties();
      final locations = await DemoDataLoader.loadLocations();
      final privacySettings = await DemoDataLoader.loadPrivacySettings();
      final friendRequests = await DemoDataLoader.loadFriendRequests();
      final eventsV2 = await DemoDataLoader.loadEnhancedEvents();

      if (kDebugMode) {
        print('Loaded ${users.length} users, ${societies.length} societies, '
              '${locations.length} locations, ${privacySettings.length} privacy settings, '
              '${friendRequests.length} friend requests, ${eventsV2.length} events');
      }

      // Seed data in dependency order
      await _seedLocations(locations);
      await _seedSocieties(societies);
      await _seedUsers(users);
      await _seedPrivacySettings(privacySettings);
      await _seedEvents(eventsV2);
      await _seedFriendRequests(friendRequests);

      // Update seed version
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_seedVersionKey, _currentSeedVersion);

      stopwatch.stop();

      if (kDebugMode) {
        print('Database seeding completed in ${stopwatch.elapsedMilliseconds}ms');
        final stats = await _databaseHelper.getDatabaseStats();
        print('Final database stats: $stats');
      }

      // Validate data integrity
      await _validateDataIntegrity();

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error during database seeding: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<void> _seedLocations(List<Location> locations) async {
    if (kDebugMode) {
      print('Seeding ${locations.length} locations...');
    }

    await _locationRepository.insertBatch(locations);

    if (kDebugMode) {
      print('Locations seeded successfully');
    }
  }

  Future<void> _seedSocieties(List<Society> societies) async {
    if (kDebugMode) {
      print('Seeding ${societies.length} societies...');
    }

    await _societyRepository.insertBatch(societies);

    if (kDebugMode) {
      print('Societies seeded successfully');
    }
  }

  Future<void> _seedUsers(List<User> users) async {
    if (kDebugMode) {
      print('Seeding ${users.length} users...');
    }

    // Insert users one by one to handle relationships properly
    for (final user in users) {
      await _userRepository.insert(user);
    }

    if (kDebugMode) {
      print('Users seeded successfully');
    }
  }

  Future<void> _seedPrivacySettings(List<PrivacySettings> privacySettings) async {
    if (kDebugMode) {
      print('Seeding ${privacySettings.length} privacy settings...');
    }

    await _privacySettingsRepository.insertBatch(privacySettings);

    if (kDebugMode) {
      print('Privacy settings seeded successfully');
    }
  }

  Future<void> _seedEvents(List<EventV2> events) async {
    if (kDebugMode) {
      print('Seeding ${events.length} events...');
    }

    // Insert events one by one to handle participants properly
    for (final event in events) {
      await _eventRepository.insert(event);
    }

    if (kDebugMode) {
      print('Events seeded successfully');
    }
  }

  Future<void> _seedFriendRequests(List<FriendRequest> friendRequests) async {
    if (kDebugMode) {
      print('Seeding ${friendRequests.length} friend requests...');
    }

    await _friendRequestRepository.insertBatch(friendRequests);

    if (kDebugMode) {
      print('Friend requests seeded successfully');
    }
  }

  Future<void> _validateDataIntegrity() async {
    if (kDebugMode) {
      print('Validating data integrity...');
    }

    final warnings = <String>[];

    try {
      // Check that all users have corresponding privacy settings
      final users = await _userRepository.getAll();
      for (final user in users) {
        final privacySettings = await _privacySettingsRepository.getByUserId(user.id);
        if (privacySettings == null) {
          warnings.add('User ${user.id} (${user.name}) has no privacy settings');
        }
      }

      // Check that all friend relationships are bidirectional
      for (final user in users) {
        final friends = await _userRepository.getFriends(user.id);
        for (final friend in friends) {
          final areFriends = await _userRepository.areFriends(friend.id, user.id);
          if (!areFriends) {
            warnings.add('Friend relationship between ${user.id} and ${friend.id} is not bidirectional');
          }
        }
      }

      // Check that society memberships are consistent
      final societies = await _societyRepository.getAll();
      for (final society in societies) {
        final members = await _userRepository.getSocietyMembers(society.id);
        if (members.length != society.memberCount) {
          warnings.add('Society ${society.id} (${society.name}) member count mismatch: expected ${society.memberCount}, found ${members.length}');
        }
      }

      if (warnings.isNotEmpty) {
        if (kDebugMode) {
          print('Data integrity warnings found:');
          for (final warning in warnings) {
            print('  - $warning');
          }
        }
      } else {
        if (kDebugMode) {
          print('Data integrity validation passed');
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error during data integrity validation: $e');
      }
    }
  }

  // Utility method to clear all data and reseed
  Future<void> clearAndReseed() async {
    if (kDebugMode) {
      print('Clearing database and reseeding...');
    }

    await seedDatabase(forceReseed: true);
  }

  // Get seeding status information
  Future<Map<String, dynamic>> getSeedStatus() async {
    final stats = await _databaseHelper.getDatabaseStats();
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = prefs.getInt(_seedVersionKey) ?? 0;

    return {
      'seedVersion': currentVersion,
      'currentVersion': _currentSeedVersion,
      'needsSeeding': await needsSeeding(),
      'isHealthy': await _databaseHelper.isDatabaseHealthy(),
      'tableStats': stats,
    };
  }
}
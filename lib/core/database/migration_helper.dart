import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../demo_data/demo_data_manager.dart';
import '../demo_data/demo_data_manager_v3.dart';

enum DataManagerVersion {
  v2,  // JSON-based manager
  v3,  // Database-backed manager
}

class MigrationHelper {
  static MigrationHelper? _instance;
  static MigrationHelper get instance => _instance ??= MigrationHelper._();
  MigrationHelper._();

  static const String _versionPreferenceKey = 'data_manager_version';

  // Get the preferred data manager version
  Future<DataManagerVersion> getPreferredVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final versionString = prefs.getString(_versionPreferenceKey);

      if (versionString == 'v3') {
        return DataManagerVersion.v3;
      } else {
        return DataManagerVersion.v2; // Default to v2 for backward compatibility
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting preferred version: $e');
      }
      return DataManagerVersion.v2;
    }
  }

  // Set the preferred data manager version
  Future<void> setPreferredVersion(DataManagerVersion version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_versionPreferenceKey, version.name);

      if (kDebugMode) {
        print('Set preferred data manager version to: ${version.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting preferred version: $e');
      }
    }
  }

  // Get the appropriate data manager instance
  Future<dynamic> getDataManager() async {
    final version = await getPreferredVersion();

    switch (version) {
      case DataManagerVersion.v2:
        return DemoDataManager.instance;
      case DataManagerVersion.v3:
        return DemoDataManagerV3.instance;
    }
  }

  // Migrate from v2 to v3
  Future<bool> migrateToV3() async {
    try {
      if (kDebugMode) {
        print('Starting migration from v2 (JSON) to v3 (Database)...');
      }

      final stopwatch = Stopwatch()..start();

      // Initialize v3 data manager (this will seed the database)
      final v3Manager = DemoDataManagerV3.instance;
      await v3Manager.users; // Trigger initialization

      // Set preference to v3
      await setPreferredVersion(DataManagerVersion.v3);

      stopwatch.stop();

      if (kDebugMode) {
        print('Migration to v3 completed in ${stopwatch.elapsedMilliseconds}ms');

        // Show database stats
        final stats = await v3Manager.getDatabaseStats();
        print('Database stats after migration: $stats');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error during migration to v3: $e');
      }
      return false;
    }
  }

  // Rollback to v2
  Future<bool> rollbackToV2() async {
    try {
      if (kDebugMode) {
        print('Rolling back to v2 (JSON) data manager...');
      }

      // Set preference back to v2
      await setPreferredVersion(DataManagerVersion.v2);

      if (kDebugMode) {
        print('Rollback to v2 completed');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error during rollback to v2: $e');
      }
      return false;
    }
  }

  // Check if migration is needed
  Future<bool> needsMigration() async {
    final currentVersion = await getPreferredVersion();

    // If we're on v2 and want to upgrade to v3
    if (currentVersion == DataManagerVersion.v2) {
      // Check if v3 is available and healthy
      try {
        final v3Manager = DemoDataManagerV3.instance;
        final isHealthy = await v3Manager.isDatabaseHealthy();
        return !isHealthy; // Need migration if database is not healthy
      } catch (e) {
        return true; // Need migration if we can't check
      }
    }

    return false;
  }

  // Get migration status info
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final currentVersion = await getPreferredVersion();
    final needsMigration = await this.needsMigration();

    Map<String, dynamic> v3Status = {};
    try {
      final v3Manager = DemoDataManagerV3.instance;
      v3Status = await v3Manager.getDatabaseStatus();
    } catch (e) {
      v3Status = {'error': e.toString()};
    }

    return {
      'currentVersion': currentVersion.name,
      'needsMigration': needsMigration,
      'v3DatabaseStatus': v3Status,
      'availableVersions': ['v2', 'v3'],
    };
  }

  // Performance comparison utility
  Future<Map<String, dynamic>> performPerformanceComparison() async {
    if (kDebugMode) {
      print('Running performance comparison between v2 and v3...');
    }

    final results = <String, dynamic>{};

    try {
      // Test v2 performance
      final v2Manager = DemoDataManager.instance;
      final v2Stopwatch = Stopwatch()..start();

      final v2Users = await v2Manager.users;
      final v2Events = await v2Manager.enhancedEvents;
      final v2Societies = await v2Manager.societies;

      v2Stopwatch.stop();

      results['v2'] = {
        'loadTimeMs': v2Stopwatch.elapsedMilliseconds,
        'userCount': v2Users.length,
        'eventCount': v2Events.length,
        'societyCount': v2Societies.length,
      };

      // Test v3 performance
      final v3Manager = DemoDataManagerV3.instance;
      final v3Stopwatch = Stopwatch()..start();

      final v3Users = await v3Manager.users;
      final v3Events = await v3Manager.enhancedEvents;
      final v3Societies = await v3Manager.societies;

      v3Stopwatch.stop();

      results['v3'] = {
        'loadTimeMs': v3Stopwatch.elapsedMilliseconds,
        'userCount': v3Users.length,
        'eventCount': v3Events.length,
        'societyCount': v3Societies.length,
      };

      results['comparison'] = {
        'speedImprovement': v2Stopwatch.elapsedMilliseconds > 0
            ? (v2Stopwatch.elapsedMilliseconds - v3Stopwatch.elapsedMilliseconds) / v2Stopwatch.elapsedMilliseconds
            : 0.0,
        'winner': v3Stopwatch.elapsedMilliseconds < v2Stopwatch.elapsedMilliseconds ? 'v3' : 'v2',
      };

      if (kDebugMode) {
        print('Performance comparison results: $results');
      }

    } catch (e) {
      results['error'] = e.toString();
      if (kDebugMode) {
        print('Error during performance comparison: $e');
      }
    }

    return results;
  }

  // Clean migration - completely reset and reseed
  Future<bool> cleanMigration() async {
    try {
      if (kDebugMode) {
        print('Performing clean migration to v3...');
      }

      final v3Manager = DemoDataManagerV3.instance;

      // Clear and reseed database
      await v3Manager.reseedDatabase();

      // Set preference to v3
      await setPreferredVersion(DataManagerVersion.v3);

      if (kDebugMode) {
        print('Clean migration completed successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error during clean migration: $e');
      }
      return false;
    }
  }

  // Validate data consistency between managers
  Future<Map<String, dynamic>> validateDataConsistency() async {
    try {
      if (kDebugMode) {
        print('Validating data consistency between v2 and v3...');
      }

      final v2Manager = DemoDataManager.instance;
      final v3Manager = DemoDataManagerV3.instance;

      final v2Users = await v2Manager.users;
      final v3Users = await v3Manager.users;

      final v2Events = await v2Manager.enhancedEvents;
      final v3Events = await v3Manager.enhancedEvents;

      final v2Societies = await v2Manager.societies;
      final v3Societies = await v3Manager.societies;

      final validation = {
        'users': {
          'v2Count': v2Users.length,
          'v3Count': v3Users.length,
          'consistent': v2Users.length == v3Users.length,
        },
        'events': {
          'v2Count': v2Events.length,
          'v3Count': v3Events.length,
          'consistent': v2Events.length == v3Events.length,
        },
        'societies': {
          'v2Count': v2Societies.length,
          'v3Count': v3Societies.length,
          'consistent': v2Societies.length == v3Societies.length,
        },
      };

      final usersConsistent = (validation['users']! as Map<String, Object>)['consistent'] as bool;
      final eventsConsistent = (validation['events']! as Map<String, Object>)['consistent'] as bool;
      final societiesConsistent = (validation['societies']! as Map<String, Object>)['consistent'] as bool;

      validation['overallConsistent'] = {
        'consistent': usersConsistent && eventsConsistent && societiesConsistent,
      };

      if (kDebugMode) {
        print('Data consistency validation: $validation');
      }

      return validation;
    } catch (e) {
      if (kDebugMode) {
        print('Error during data consistency validation: $e');
      }
      return {'error': e.toString()};
    }
  }
}


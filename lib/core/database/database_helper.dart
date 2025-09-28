import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();
  DatabaseHelper._();

  static Database? _database;
  static const String _databaseName = 'uniconnect.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);

    if (kDebugMode) {
      print('Database path: $path');
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Users table
    batch.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        course TEXT NOT NULL,
        year TEXT NOT NULL,
        privacy_settings_id TEXT NOT NULL,
        profile_image_url TEXT,
        is_online INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'offline',
        current_location_id TEXT,
        current_building TEXT,
        current_room TEXT,
        latitude REAL,
        longitude REAL,
        status_message TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Societies table
    batch.execute('''
      CREATE TABLE societies (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        member_count INTEGER NOT NULL DEFAULT 0,
        is_featured INTEGER NOT NULL DEFAULT 0,
        image_url TEXT,
        contact_email TEXT,
        meeting_schedule TEXT,
        location TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Locations table
    batch.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        building TEXT NOT NULL,
        room TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        floor_level INTEGER,
        capacity INTEGER,
        facilities TEXT,
        accessibility_features TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Privacy settings table
    batch.execute('''
      CREATE TABLE privacy_settings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL UNIQUE,
        show_online_status INTEGER NOT NULL DEFAULT 1,
        show_location INTEGER NOT NULL DEFAULT 1,
        show_calendar INTEGER NOT NULL DEFAULT 1,
        show_friends INTEGER NOT NULL DEFAULT 1,
        show_societies INTEGER NOT NULL DEFAULT 1,
        allow_friend_requests INTEGER NOT NULL DEFAULT 1,
        allow_event_invitations INTEGER NOT NULL DEFAULT 1,
        allow_study_group_invitations INTEGER NOT NULL DEFAULT 1,
        allow_location_sharing INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Events table (supporting both legacy and v2 models)
    batch.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        location TEXT,
        type TEXT NOT NULL,
        sub_type TEXT,
        category TEXT NOT NULL,
        source TEXT NOT NULL,
        origin TEXT NOT NULL,
        course_code TEXT,
        creator_id TEXT,
        privacy_level TEXT NOT NULL DEFAULT 'public',
        sharing_permission TEXT NOT NULL DEFAULT 'canSuggest',
        discoverability TEXT NOT NULL DEFAULT 'searchable',
        scheduled_date TEXT NOT NULL,
        end_date TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_rule TEXT,
        is_recurring_instance INTEGER NOT NULL DEFAULT 0,
        next_occurrence TEXT,
        duration INTEGER,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Friend requests table
    batch.execute('''
      CREATE TABLE friend_requests (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        message TEXT,
        sent_at TEXT NOT NULL,
        responded_at TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(sender_id, receiver_id)
      )
    ''');

    // Junction tables for many-to-many relationships

    // User-Society memberships
    batch.execute('''
      CREATE TABLE user_societies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        society_id TEXT NOT NULL,
        joined_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        role TEXT DEFAULT 'member',
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (society_id) REFERENCES societies (id) ON DELETE CASCADE,
        UNIQUE(user_id, society_id)
      )
    ''');

    // User-User friendships
    batch.execute('''
      CREATE TABLE user_friends (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        friend_id TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, friend_id)
      )
    ''');

    // Event participants (replaces multiple ID arrays in JSON)
    batch.execute('''
      CREATE TABLE event_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        relationship TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(event_id, user_id, relationship)
      )
    ''');

    // Create indexes for performance
    batch.execute('CREATE INDEX idx_users_email ON users(email)');
    batch.execute('CREATE INDEX idx_users_status ON users(status)');
    batch.execute('CREATE INDEX idx_events_date ON events(scheduled_date)');
    batch.execute('CREATE INDEX idx_events_category ON events(category)');
    batch.execute('CREATE INDEX idx_events_creator ON events(creator_id)');
    batch.execute('CREATE INDEX idx_friend_requests_receiver ON friend_requests(receiver_id)');
    batch.execute('CREATE INDEX idx_friend_requests_status ON friend_requests(status)');
    batch.execute('CREATE INDEX idx_user_societies_user ON user_societies(user_id)');
    batch.execute('CREATE INDEX idx_user_societies_society ON user_societies(society_id)');
    batch.execute('CREATE INDEX idx_user_friends_user ON user_friends(user_id)');
    batch.execute('CREATE INDEX idx_event_participants_event ON event_participants(event_id)');
    batch.execute('CREATE INDEX idx_event_participants_user ON event_participants(user_id)');

    await batch.commit();

    if (kDebugMode) {
      print('Database created successfully with version $_databaseVersion');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Upgrading database from version $oldVersion to $newVersion');
    }

    // Handle database migrations here
    // For now, we'll implement future migrations as needed
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Downgrading database from version $oldVersion to $newVersion');
    }

    // Handle database downgrades here if needed
    // Generally not recommended - consider migration strategy
  }

  // Utility methods for common database operations

  Future<void> clearAllTables() async {
    final db = await database;
    final batch = db.batch();

    // Delete in order to respect foreign key constraints
    batch.delete('event_participants');
    batch.delete('user_friends');
    batch.delete('user_societies');
    batch.delete('friend_requests');
    batch.delete('events');
    batch.delete('privacy_settings');
    batch.delete('locations');
    batch.delete('societies');
    batch.delete('users');

    await batch.commit();

    if (kDebugMode) {
      print('All tables cleared');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);

    await close();

    if (await File(path).exists()) {
      await File(path).delete();
      if (kDebugMode) {
        print('Database deleted: $path');
      }
    }
  }

  // Database health check
  Future<bool> isDatabaseHealthy() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Database health check failed: $e');
      }
      return false;
    }
  }

  // Get database stats
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final stats = <String, int>{};

    final tables = [
      'users', 'societies', 'locations', 'privacy_settings',
      'events', 'friend_requests', 'user_societies',
      'user_friends', 'event_participants'
    ];

    for (final table in tables) {
      try {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        stats[table] = result.first['count'] as int;
      } catch (e) {
        stats[table] = -1; // Error indicator
      }
    }

    return stats;
  }
}
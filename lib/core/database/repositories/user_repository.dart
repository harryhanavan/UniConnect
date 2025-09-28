import 'package:sqflite/sqflite.dart';
import '../../../shared/models/user.dart';
import '../base_repository.dart';
import '../database_helper.dart';

class UserRepository extends BaseRepository<User> {
  @override
  String get tableName => 'users';

  @override
  User fromMap(Map<String, dynamic> map) {
    // Handle JSON string arrays for friend and society IDs
    List<String> friendIds = [];
    if (map['friend_ids'] != null && map['friend_ids'].isNotEmpty) {
      try {
        final friendIdsStr = map['friend_ids'] as String;
        friendIds = friendIdsStr.split(',').where((id) => id.isNotEmpty).toList();
      } catch (e) {
        friendIds = [];
      }
    }

    List<String> societyIds = [];
    if (map['society_ids'] != null && map['society_ids'].isNotEmpty) {
      try {
        final societyIdsStr = map['society_ids'] as String;
        societyIds = societyIdsStr.split(',').where((id) => id.isNotEmpty).toList();
      } catch (e) {
        societyIds = [];
      }
    }

    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      course: map['course'] as String,
      year: map['year'] as String,
      privacySettingsId: map['privacy_settings_id'] as String,
      profileImageUrl: map['profile_image_url'] as String?,
      isOnline: (map['is_online'] as int) == 1,
      status: UserStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => UserStatus.offline,
      ),
      currentLocationId: map['current_location_id'] as String?,
      currentBuilding: map['current_building'] as String?,
      currentRoom: map['current_room'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      statusMessage: map['status_message'] as String?,
      friendIds: friendIds,
      pendingFriendRequests: [], // Will be loaded separately
      sentFriendRequests: [], // Will be loaded separately
      societyIds: societyIds,
    );
  }

  @override
  Map<String, dynamic> toMap(User user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'course': user.course,
      'year': user.year,
      'privacy_settings_id': user.privacySettingsId,
      'profile_image_url': user.profileImageUrl,
      'is_online': user.isOnline ? 1 : 0,
      'status': user.status.toString().split('.').last,
      'current_location_id': user.currentLocationId,
      'current_building': user.currentBuilding,
      'current_room': user.currentRoom,
      'latitude': user.latitude,
      'longitude': user.longitude,
      'status_message': user.statusMessage,
      'friend_ids': user.friendIds.join(','),
      'society_ids': user.societyIds.join(','),
    };
  }

  // Override insert to handle relationships
  @override
  Future<String> insert(User user) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // Insert user
      final userMap = toMap(user);
      userMap['created_at'] = DateTime.now().toIso8601String();
      userMap['updated_at'] = DateTime.now().toIso8601String();

      await txn.insert(
        tableName,
        userMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert friend relationships
      await _insertFriendRelationships(txn, user.id, user.friendIds);

      // Insert society memberships
      await _insertSocietyMemberships(txn, user.id, user.societyIds);
    });

    return user.id;
  }

  // Override update to handle relationships
  @override
  Future<int> update(User user) async {
    final db = await DatabaseHelper.instance.database;

    return await db.transaction((txn) async {
      // Update user
      final userMap = toMap(user);
      userMap['updated_at'] = DateTime.now().toIso8601String();

      final updateCount = await txn.update(
        tableName,
        userMap,
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // Update relationships
      await _deleteFriendRelationships(txn, user.id);
      await _insertFriendRelationships(txn, user.id, user.friendIds);

      await _deleteSocietyMemberships(txn, user.id);
      await _insertSocietyMemberships(txn, user.id, user.societyIds);

      return updateCount;
    });
  }

  // Load user with complete relationship data
  Future<User?> getByIdWithRelationships(String id) async {
    final user = await getById(id);
    if (user == null) return null;

    final db = await DatabaseHelper.instance.database;

    // Load friend IDs
    final friendRows = await db.query(
      'user_friends',
      columns: ['friend_id'],
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [id],
    );
    final friendIds = friendRows.map((row) => row['friend_id'] as String).toList();

    // Load society IDs
    final societyRows = await db.query(
      'user_societies',
      columns: ['society_id'],
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [id],
    );
    final societyIds = societyRows.map((row) => row['society_id'] as String).toList();

    return user.copyWith(
      friendIds: friendIds,
      societyIds: societyIds,
    );
  }

  Future<List<User>> getAllWithRelationships() async {
    final users = await getAll();
    final List<User> usersWithRelationships = [];

    for (final user in users) {
      final userWithRelationships = await getByIdWithRelationships(user.id);
      if (userWithRelationships != null) {
        usersWithRelationships.add(userWithRelationships);
      }
    }

    return usersWithRelationships;
  }

  Future<User?> getByEmail(String email) async {
    final users = await query(
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    return users.isNotEmpty ? users.first : null;
  }

  Future<List<User>> getOnlineUsers() async {
    return await query(
      where: 'is_online = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  Future<List<User>> getFriends(String userId) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN user_friends uf ON u.id = uf.friend_id
      WHERE uf.user_id = ?
      ORDER BY u.name ASC
    ''', [userId]);

    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  Future<List<User>> getSocietyMembers(String societyId) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN user_societies us ON u.id = us.user_id
      WHERE us.society_id = ? AND us.is_active = 1
      ORDER BY us.joined_at ASC
    ''', [societyId]);

    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  // Relationship management helpers
  Future<void> _insertFriendRelationships(Transaction txn, String userId, List<String> friendIds) async {
    for (final friendId in friendIds) {
      await txn.insert(
        'user_friends',
        {
          'user_id': userId,
          'friend_id': friendId,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _deleteFriendRelationships(Transaction txn, String userId) async {
    await txn.delete(
      'user_friends',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> _insertSocietyMemberships(Transaction txn, String userId, List<String> societyIds) async {
    for (final societyId in societyIds) {
      await txn.insert(
        'user_societies',
        {
          'user_id': userId,
          'society_id': societyId,
          'joined_at': DateTime.now().toIso8601String(),
          'role': 'member',
          'is_active': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _deleteSocietyMemberships(Transaction txn, String userId) async {
    await txn.delete(
      'user_societies',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Society membership management
  Future<void> addSocietyMembership(String userId, String societyId) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert(
      'user_societies',
      {
        'user_id': userId,
        'society_id': societyId,
        'joined_at': DateTime.now().toIso8601String(),
        'role': 'member',
        'is_active': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeSocietyMembership(String userId, String societyId) async {
    final db = await DatabaseHelper.instance.database;

    await db.delete(
      'user_societies',
      where: 'user_id = ? AND society_id = ?',
      whereArgs: [userId, societyId],
    );
  }

  // Friend management
  Future<void> addFriend(String userId, String friendId) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // Add bidirectional friendship
      await txn.insert(
        'user_friends',
        {
          'user_id': userId,
          'friend_id': friendId,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await txn.insert(
        'user_friends',
        {
          'user_id': friendId,
          'friend_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // Remove bidirectional friendship
      await txn.delete(
        'user_friends',
        where: 'user_id = ? AND friend_id = ?',
        whereArgs: [userId, friendId],
      );

      await txn.delete(
        'user_friends',
        where: 'user_id = ? AND friend_id = ?',
        whereArgs: [friendId, userId],
      );
    });
  }

  Future<bool> areFriends(String userId, String friendId) async {
    final count = await this.count(
      where: 'user_id = ? AND friend_id = ?',
      whereArgs: [userId, friendId],
    );
    return count > 0;
  }
}
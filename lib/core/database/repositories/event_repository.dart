import 'package:sqflite/sqflite.dart';
import '../../../shared/models/event_v2.dart';
import '../../../shared/models/event_enums.dart';
import '../base_repository.dart';
import '../database_helper.dart';

class EventRepository extends BaseRepository<EventV2> {
  @override
  String get tableName => 'events';

  @override
  EventV2 fromMap(Map<String, dynamic> map) {
    final scheduledDate = DateTime.parse(map['scheduled_date'] as String);
    final endDate = map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null;

    return EventV2(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      startTime: scheduledDate,
      endTime: endDate ?? scheduledDate.add(const Duration(hours: 1)),
      location: map['location'] as String? ?? '',
      category: EventCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => EventCategory.personal,
      ),
      subType: EventSubType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['sub_type'] ?? 'other'),
        orElse: () => EventSubType.task,
      ),
      origin: EventOrigin.values.firstWhere(
        (e) => e.toString().split('.').last == map['origin'],
        orElse: () => EventOrigin.system,
      ),
      creatorId: map['creator_id'] as String? ?? 'system',
      organizerIds: _parseStringList(map['organizer_ids']),
      attendeeIds: _parseStringList(map['attendee_ids']),
      invitedIds: _parseStringList(map['invited_ids']),
      interestedIds: _parseStringList(map['interested_ids']),
      privacyLevel: EventPrivacyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == map['privacy_level'],
        orElse: () => EventPrivacyLevel.friendsOnly,
      ),
      sharingPermission: EventSharingPermission.values.firstWhere(
        (e) => e.toString().split('.').last == map['sharing_permission'],
        orElse: () => EventSharingPermission.canSuggest,
      ),
      discoverability: EventDiscoverability.values.firstWhere(
        (e) => e.toString().split('.').last == map['discoverability'],
        orElse: () => EventDiscoverability.feedVisible,
      ),
      courseCode: map['course_code'] as String?,
      isRecurring: (map['is_recurring'] as int) == 1,
      recurringRule: map['recurring_rule'] as String?,
      isRecurringInstance: (map['is_recurring_instance'] as int) == 1,
      nextOccurrence: map['next_occurrence'] != null ? DateTime.parse(map['next_occurrence'] as String) : null,
      scheduledDate: scheduledDate,
      endDate: endDate,
    );
  }

  @override
  Map<String, dynamic> toMap(EventV2 event) {
    return {
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'location': event.location,
      'type': 'event', // Default type for events
      'sub_type': event.subType.toString().split('.').last,
      'category': event.category.toString().split('.').last,
      'source': 'personal', // Default source
      'origin': event.origin.toString().split('.').last,
      'course_code': event.courseCode,
      'creator_id': event.creatorId,
      'organizer_ids': event.organizerIds.join(','),
      'attendee_ids': event.attendeeIds.join(','),
      'invited_ids': event.invitedIds.join(','),
      'interested_ids': event.interestedIds.join(','),
      'privacy_level': event.privacyLevel.toString().split('.').last,
      'sharing_permission': event.sharingPermission.toString().split('.').last,
      'discoverability': event.discoverability.toString().split('.').last,
      'scheduled_date': (event.scheduledDate ?? event.startTime).toIso8601String(),
      'end_date': (event.endDate ?? event.endTime).toIso8601String(),
      'is_recurring': event.isRecurring ? 1 : 0,
      'recurring_rule': event.recurringRule,
      'is_recurring_instance': event.isRecurringInstance ? 1 : 0,
      'next_occurrence': event.nextOccurrence?.toIso8601String(),
      'duration': event.endTime.difference(event.startTime).inHours,
    };
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null || value.toString().isEmpty) return [];
    return value.toString().split(',').where((id) => id.isNotEmpty).toList();
  }

  // Override insert to handle participants
  @override
  Future<String> insert(EventV2 event) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // Insert event
      final eventMap = toMap(event);
      eventMap['created_at'] = DateTime.now().toIso8601String();
      eventMap['updated_at'] = DateTime.now().toIso8601String();

      await txn.insert(
        tableName,
        eventMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert participants
      await _insertParticipants(txn, event);
    });

    return event.id;
  }

  // Override update to handle participants
  @override
  Future<int> update(EventV2 event) async {
    final db = await DatabaseHelper.instance.database;

    return await db.transaction((txn) async {
      // Update event
      final eventMap = toMap(event);
      eventMap['updated_at'] = DateTime.now().toIso8601String();

      final updateCount = await txn.update(
        tableName,
        eventMap,
        where: 'id = ?',
        whereArgs: [event.id],
      );

      // Update participants
      await _deleteParticipants(txn, event.id);
      await _insertParticipants(txn, event);

      return updateCount;
    });
  }

  Future<void> _insertParticipants(Transaction txn, EventV2 event) async {
    final participants = <Map<String, dynamic>>[];

    // Add organizers
    for (final organizerId in event.organizerIds) {
      participants.add({
        'event_id': event.id,
        'user_id': organizerId,
        'relationship': 'organizer',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Add attendees
    for (final attendeeId in event.attendeeIds) {
      participants.add({
        'event_id': event.id,
        'user_id': attendeeId,
        'relationship': 'attendee',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Add invited users
    for (final invitedId in event.invitedIds) {
      participants.add({
        'event_id': event.id,
        'user_id': invitedId,
        'relationship': 'invited',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Add interested users
    for (final interestedId in event.interestedIds) {
      participants.add({
        'event_id': event.id,
        'user_id': interestedId,
        'relationship': 'interested',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    for (final participant in participants) {
      await txn.insert(
        'event_participants',
        participant,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _deleteParticipants(Transaction txn, String eventId) async {
    await txn.delete(
      'event_participants',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  // Query methods for specific date ranges
  Future<List<EventV2>> getEventsByDateRange(DateTime startDate, DateTime endDate) async {
    return await query(
      where: 'scheduled_date >= ? AND scheduled_date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'scheduled_date ASC',
    );
  }

  Future<List<EventV2>> getTodayEvents() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await getEventsByDateRange(startOfDay, endOfDay);
  }

  Future<List<EventV2>> getUpcomingEvents({int days = 7}) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    return await query(
      where: 'scheduled_date >= ? AND scheduled_date <= ?',
      whereArgs: [now.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'scheduled_date ASC',
    );
  }

  Future<List<EventV2>> getEventsByCategory(EventCategory category) async {
    return await query(
      where: 'category = ?',
      whereArgs: [category.toString().split('.').last],
      orderBy: 'scheduled_date ASC',
    );
  }

  Future<List<EventV2>> getEventsByCreator(String creatorId) async {
    return await query(
      where: 'creator_id = ?',
      whereArgs: [creatorId],
      orderBy: 'scheduled_date DESC',
    );
  }

  Future<List<EventV2>> getEventsForUser(String userId) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT e.* FROM events e
      LEFT JOIN event_participants ep ON e.id = ep.event_id
      WHERE e.creator_id = ? OR ep.user_id = ?
      ORDER BY e.scheduled_date ASC
    ''', [userId, userId]);

    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  Future<List<EventV2>> getRecurringEvents() async {
    return await query(
      where: 'is_recurring = ?',
      whereArgs: [1],
      orderBy: 'scheduled_date ASC',
    );
  }

  Future<List<EventV2>> searchEvents(String searchTerm) async {
    return await query(
      where: 'title LIKE ? OR description LIKE ? OR location LIKE ?',
      whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
      orderBy: 'scheduled_date ASC',
    );
  }

  // Participant management
  Future<void> addParticipant(String eventId, String userId, String relationship) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert(
      'event_participants',
      {
        'event_id': eventId,
        'user_id': userId,
        'relationship': relationship,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeParticipant(String eventId, String userId, String relationship) async {
    final db = await DatabaseHelper.instance.database;

    await db.delete(
      'event_participants',
      where: 'event_id = ? AND user_id = ? AND relationship = ?',
      whereArgs: [eventId, userId, relationship],
    );
  }

  Future<List<String>> getParticipants(String eventId, String relationship) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'event_participants',
      columns: ['user_id'],
      where: 'event_id = ? AND relationship = ?',
      whereArgs: [eventId, relationship],
    );

    return maps.map((map) => map['user_id'] as String).toList();
  }

  Future<Map<String, List<String>>> getAllParticipants(String eventId) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'event_participants',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );

    final participants = <String, List<String>>{};
    for (final map in maps) {
      final relationship = map['relationship'] as String;
      final userId = map['user_id'] as String;

      participants.putIfAbsent(relationship, () => []).add(userId);
    }

    return participants;
  }

  // Privacy and permissions
  Future<List<EventV2>> getPublicEvents() async {
    return await query(
      where: 'privacy_level = ?',
      whereArgs: ['public'],
      orderBy: 'scheduled_date ASC',
    );
  }

  Future<List<EventV2>> getDiscoverableEvents() async {
    return await query(
      where: 'discoverability = ?',
      whereArgs: ['searchable'],
      orderBy: 'scheduled_date ASC',
    );
  }

  // Statistics
  Future<Map<String, int>> getEventStatsByCategory() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM events
      GROUP BY category
      ORDER BY count DESC
    ''');

    final stats = <String, int>{};
    for (final map in maps) {
      stats[map['category'] as String] = map['count'] as int;
    }

    return stats;
  }

  Future<int> getEventCountForUser(String userId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT e.id) as count FROM events e
      LEFT JOIN event_participants ep ON e.id = ep.event_id
      WHERE e.creator_id = ? OR ep.user_id = ?
    ''', [userId, userId]);

    return result.first['count'] as int;
  }
}
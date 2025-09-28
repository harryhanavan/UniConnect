import '../../../shared/models/friend_request.dart';
import '../base_repository.dart';
import '../database_helper.dart';

class FriendRequestRepository extends BaseRepository<FriendRequest> {
  @override
  String get tableName => 'friend_requests';

  @override
  FriendRequest fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] as String,
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      message: map['message'] as String?,
      createdAt: DateTime.parse(map['sent_at'] as String),
      respondedAt: map['responded_at'] != null ? DateTime.parse(map['responded_at'] as String) : null,
    );
  }

  @override
  Map<String, dynamic> toMap(FriendRequest request) {
    return {
      'id': request.id,
      'sender_id': request.senderId,
      'receiver_id': request.receiverId,
      'status': request.status.toString().split('.').last,
      'message': request.message,
      'sent_at': request.createdAt.toIso8601String(),
      'responded_at': request.respondedAt?.toIso8601String(),
    };
  }

  Future<List<FriendRequest>> getPendingRequestsForUser(String userId) async {
    return await query(
      where: 'receiver_id = ? AND status = ?',
      whereArgs: [userId, 'pending'],
      orderBy: 'sent_at DESC',
    );
  }

  Future<List<FriendRequest>> getSentRequestsByUser(String userId) async {
    return await query(
      where: 'sender_id = ? AND status = ?',
      whereArgs: [userId, 'pending'],
      orderBy: 'sent_at DESC',
    );
  }

  Future<List<FriendRequest>> getRequestHistory(String userId) async {
    return await query(
      where: 'sender_id = ? OR receiver_id = ?',
      whereArgs: [userId, userId],
      orderBy: 'sent_at DESC',
    );
  }

  Future<FriendRequest?> getRequestBetweenUsers(String senderId, String receiverId) async {
    final results = await query(
      where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [senderId, receiverId, receiverId, senderId],
      orderBy: 'sent_at DESC',
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<bool> hasPendingRequestBetweenUsers(String senderId, String receiverId) async {
    final count = await this.count(
      where: '((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)) AND status = ?',
      whereArgs: [senderId, receiverId, receiverId, senderId, 'pending'],
    );

    return count > 0;
  }

  Future<int> acceptRequest(String requestId) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      tableName,
      {
        'status': 'accepted',
        'responded_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND status = ?',
      whereArgs: [requestId, 'pending'],
    );
  }

  Future<int> declineRequest(String requestId) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      tableName,
      {
        'status': 'declined',
        'responded_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND status = ?',
      whereArgs: [requestId, 'pending'],
    );
  }

  Future<int> cancelRequest(String requestId) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      tableName,
      {
        'status': 'cancelled',
        'responded_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND status = ?',
      whereArgs: [requestId, 'pending'],
    );
  }

  Future<List<FriendRequest>> getRequestsByStatus(String status) async {
    return await query(
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'sent_at DESC',
    );
  }

  Future<int> getPendingRequestCount(String userId) async {
    return await count(
      where: 'receiver_id = ? AND status = ?',
      whereArgs: [userId, 'pending'],
    );
  }

  Future<int> getSentRequestCount(String userId) async {
    return await count(
      where: 'sender_id = ? AND status = ?',
      whereArgs: [userId, 'pending'],
    );
  }

  Future<Map<String, int>> getRequestStatistics() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM friend_requests
      GROUP BY status
      ORDER BY count DESC
    ''');

    final stats = <String, int>{};
    for (final map in maps) {
      stats[map['status'] as String] = map['count'] as int;
    }

    return stats;
  }

  Future<List<FriendRequest>> getRecentRequests({int days = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return await query(
      where: 'sent_at >= ?',
      whereArgs: [cutoffDate.toIso8601String()],
      orderBy: 'sent_at DESC',
    );
  }

  Future<void> cleanupOldRequests({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final db = await DatabaseHelper.instance.database;

    await db.delete(
      tableName,
      where: 'sent_at < ? AND status IN (?, ?)',
      whereArgs: [cutoffDate.toIso8601String(), 'declined', 'cancelled'],
    );
  }

  Future<bool> canSendRequestToUser(String senderId, String receiverId) async {
    // Check if there's already a pending request
    final hasPending = await hasPendingRequestBetweenUsers(senderId, receiverId);
    if (hasPending) return false;

    // Check if they're already friends (this would typically be checked in a higher service layer)
    // For now, we'll assume this check is done elsewhere

    return true;
  }
}
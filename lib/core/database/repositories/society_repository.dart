import '../../../shared/models/society.dart';
import '../base_repository.dart';
import '../database_helper.dart';

class SocietyRepository extends BaseRepository<Society> {
  @override
  String get tableName => 'societies';

  @override
  Society fromMap(Map<String, dynamic> map) {
    return Society(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String,
      memberCount: map['member_count'] as int,
      memberIds: [], // Will be populated separately from junction table
      logoUrl: map['image_url'] as String?,
      // Map database fields to model fields
      aboutUs: map['contact_email'] as String?, // Use contact_email as aboutUs
      tags: [], // Default empty tags
      isJoined: false, // Will be determined separately
      adminIds: [], // Default empty admin list
    );
  }

  @override
  Map<String, dynamic> toMap(Society society) {
    return {
      'id': society.id,
      'name': society.name,
      'description': society.description,
      'category': society.category,
      'member_count': society.memberCount,
      'is_featured': 0, // Default not featured
      'image_url': society.logoUrl,
      'contact_email': society.aboutUs, // Map aboutUs to contact_email
      'meeting_schedule': '', // Default empty
      'location': '', // Default empty
    };
  }

  Future<List<Society>> getFeaturedSocieties() async {
    return await query(
      where: 'is_featured = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  Future<List<Society>> getSocietiesByCategory(String category) async {
    return await query(
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'member_count DESC',
    );
  }

  Future<List<Society>> searchSocieties(String searchTerm) async {
    return await query(
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$searchTerm%', '%$searchTerm%'],
      orderBy: 'member_count DESC',
    );
  }

  Future<List<Society>> getPopularSocieties({int limit = 10}) async {
    return await query(
      orderBy: 'member_count DESC',
      limit: limit,
    );
  }

  Future<List<String>> getDistinctCategories() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT category
      FROM societies
      ORDER BY category ASC
    ''');

    return maps.map((map) => map['category'] as String).toList();
  }

  Future<Map<String, int>> getSocietyStatsByCategory() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM societies
      GROUP BY category
      ORDER BY count DESC
    ''');

    final stats = <String, int>{};
    for (final map in maps) {
      stats[map['category'] as String] = map['count'] as int;
    }

    return stats;
  }

  Future<void> updateMemberCount(String societyId, int newCount) async {
    final db = await DatabaseHelper.instance.database;

    await db.update(
      tableName,
      {
        'member_count': newCount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [societyId],
    );
  }

  Future<void> incrementMemberCount(String societyId) async {
    final db = await DatabaseHelper.instance.database;

    await db.rawUpdate('''
      UPDATE societies
      SET member_count = member_count + 1,
          updated_at = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), societyId]);
  }

  Future<void> decrementMemberCount(String societyId) async {
    final db = await DatabaseHelper.instance.database;

    await db.rawUpdate('''
      UPDATE societies
      SET member_count = CASE
        WHEN member_count > 0 THEN member_count - 1
        ELSE 0
      END,
      updated_at = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), societyId]);
  }
}
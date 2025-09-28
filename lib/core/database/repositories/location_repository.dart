import '../../../shared/models/location.dart';
import '../base_repository.dart';
import '../database_helper.dart';

class LocationRepository extends BaseRepository<Location> {
  @override
  String get tableName => 'locations';

  @override
  Location fromMap(Map<String, dynamic> map) {
    List<String> facilities = [];
    if (map['facilities'] != null && map['facilities'].isNotEmpty) {
      try {
        final facilitiesStr = map['facilities'] as String;
        facilities = facilitiesStr.split(',').where((facility) => facility.isNotEmpty).toList();
      } catch (e) {
        facilities = [];
      }
    }

    List<String> accessibilityFeatures = [];
    if (map['accessibility_features'] != null && map['accessibility_features'].isNotEmpty) {
      try {
        final featuresStr = map['accessibility_features'] as String;
        accessibilityFeatures = featuresStr.split(',').where((feature) => feature.isNotEmpty).toList();
      } catch (e) {
        accessibilityFeatures = [];
      }
    }

    return Location(
      id: map['id'] as String,
      name: map['name'] as String,
      building: map['building'] as String,
      room: map['room'] as String?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      type: LocationType.other, // Default type
      capacity: map['capacity'] as int?,
      amenities: facilities, // Map facilities to amenities
      description: '', // Default empty description
      isAccessible: accessibilityFeatures.isNotEmpty, // Has accessibility features
      createdAt: DateTime.now(), // Default creation time
      floor: map['floor_level']?.toString(), // Convert floor level to string
    );
  }

  @override
  Map<String, dynamic> toMap(Location location) {
    return {
      'id': location.id,
      'name': location.name,
      'building': location.building,
      'room': location.room,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'floor_level': location.floor != null ? int.tryParse(location.floor!) : null,
      'capacity': location.capacity,
      'facilities': location.amenities.join(','), // Map amenities to facilities
      'accessibility_features': location.isAccessible ? 'accessible' : '', // Basic accessibility
    };
  }

  Future<List<Location>> getLocationsByBuilding(String building) async {
    return await query(
      where: 'building = ?',
      whereArgs: [building],
      orderBy: 'name ASC',
    );
  }

  Future<List<String>> getDistinctBuildings() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT building
      FROM locations
      ORDER BY building ASC
    ''');

    return maps.map((map) => map['building'] as String).toList();
  }

  Future<List<Location>> getLocationsByCapacity({int? minCapacity, int? maxCapacity}) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (minCapacity != null && maxCapacity != null) {
      whereClause = 'capacity >= ? AND capacity <= ?';
      whereArgs = [minCapacity, maxCapacity];
    } else if (minCapacity != null) {
      whereClause = 'capacity >= ?';
      whereArgs = [minCapacity];
    } else if (maxCapacity != null) {
      whereClause = 'capacity <= ?';
      whereArgs = [maxCapacity];
    }

    return await query(
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'capacity ASC',
    );
  }

  Future<List<Location>> searchLocations(String searchTerm) async {
    return await query(
      where: 'name LIKE ? OR building LIKE ? OR room LIKE ?',
      whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
      orderBy: 'building ASC, name ASC',
    );
  }

  Future<List<Location>> getAccessibleLocations() async {
    return await query(
      where: 'accessibility_features IS NOT NULL AND accessibility_features != ""',
      orderBy: 'building ASC, name ASC',
    );
  }

  Future<List<Location>> getLocationsWithFacility(String facility) async {
    return await query(
      where: 'facilities LIKE ?',
      whereArgs: ['%$facility%'],
      orderBy: 'building ASC, name ASC',
    );
  }

  Future<List<Location>> getNearbyLocations(double latitude, double longitude, double radiusKm) async {
    final db = await DatabaseHelper.instance.database;

    // Using the haversine formula for distance calculation
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT *,
      (6371 * acos(cos(radians(?)) * cos(radians(latitude)) *
      cos(radians(longitude) - radians(?)) +
      sin(radians(?)) * sin(radians(latitude)))) AS distance
      FROM locations
      HAVING distance <= ?
      ORDER BY distance ASC
    ''', [latitude, longitude, latitude, radiusKm]);

    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  Future<Map<String, int>> getLocationStatsByBuilding() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT building, COUNT(*) as count
      FROM locations
      GROUP BY building
      ORDER BY count DESC
    ''');

    final stats = <String, int>{};
    for (final map in maps) {
      stats[map['building'] as String] = map['count'] as int;
    }

    return stats;
  }

  Future<List<String>> getAllFacilities() async {
    final locations = await getAll();
    final allFacilities = <String>{};

    for (final location in locations) {
      allFacilities.addAll(location.amenities); // Use amenities instead of facilities
    }

    return allFacilities.toList()..sort();
  }

  Future<List<String>> getAllAccessibilityFeatures() async {
    final locations = await getAll();
    final allFeatures = <String>{'accessible'}; // Basic accessibility feature

    // Add any specific accessibility features from database
    // For now, just return basic accessibility info
    return allFeatures.toList()..sort();
  }
}
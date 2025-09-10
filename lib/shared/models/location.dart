import 'dart:math';

enum LocationType { classroom, library, cafeteria, common, outdoor, study, lab, office, other }

class Location {
  final String id;
  final String name;
  final String building;
  final String? room;
  final String? floor;
  final LocationType type;
  final double latitude;
  final double longitude;
  final String? description;
  final bool isAccessible;
  final int? capacity;
  final List<String> amenities;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Location({
    required this.id,
    required this.name,
    required this.building,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.room,
    this.floor,
    this.description,
    this.isAccessible = true,
    this.capacity,
    this.amenities = const [],
    this.updatedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      name: json['name'] as String,
      building: json['building'] as String,
      room: json['room'] as String?,
      floor: json['floor'] as String?,
      type: LocationType.values.firstWhere(
        (e) => e.toString() == 'LocationType.${json['type']}',
        orElse: () => LocationType.other,
      ),
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      description: json['description'] as String?,
      isAccessible: json['isAccessible'] as bool? ?? true,
      capacity: json['capacity'] as int?,
      amenities: (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'building': building,
      'room': room,
      'floor': floor,
      'type': type.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'isAccessible': isAccessible,
      'capacity': capacity,
      'amenities': amenities,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Location copyWith({
    String? id,
    String? name,
    String? building,
    String? room,
    String? floor,
    LocationType? type,
    double? latitude,
    double? longitude,
    String? description,
    bool? isAccessible,
    int? capacity,
    List<String>? amenities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      building: building ?? this.building,
      room: room ?? this.room,
      floor: floor ?? this.floor,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      isAccessible: isAccessible ?? this.isAccessible,
      capacity: capacity ?? this.capacity,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Location(id: $id, name: $name, building: $building, room: $room)';
  }

  // Helper methods
  String get fullName {
    if (room != null) {
      return '$building $room';
    }
    return '$building - $name';
  }

  String get displayName {
    if (room != null && floor != null) {
      return '$name ($building $room, Floor $floor)';
    } else if (room != null) {
      return '$name ($building $room)';
    } else {
      return '$name ($building)';
    }
  }

  bool get hasCapacity => capacity != null && capacity! > 0;
  
  bool hasAmenity(String amenity) => amenities.contains(amenity);

  // Calculate distance to another location (simplified Haversine formula)
  double distanceTo(Location other) {
    const double earthRadius = 6371000; // meters
    
    final lat1Rad = latitude * (pi / 180);
    final lat2Rad = other.latitude * (pi / 180);
    final deltaLat = (other.latitude - latitude) * (pi / 180);
    final deltaLng = (other.longitude - longitude) * (pi / 180);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Check if location is within walking distance (default: 500m)
  bool isWithinWalkingDistance(Location other, {double maxDistance = 500}) {
    return distanceTo(other) <= maxDistance;
  }
}

// UTS-specific location extensions
extension UTSLocations on Location {
  // Common UTS buildings
  static const Map<String, String> utsBuildings = {
    'Building 1': 'CB01',
    'Building 2': 'CB02', 
    'Building 3': 'CB03',
    'Building 4': 'CB04',
    'Building 5': 'CB05',
    'Building 6': 'CB06',
    'Building 7': 'CB07',
    'Building 8': 'CB08',
    'Building 9': 'CB09',
    'Building 10': 'CB10',
    'Building 11': 'CB11',
    'Building 12': 'CB12',
    'Building 14': 'CB14',
    'Library': 'LIB',
    'Alumni Green': 'AG',
    'Tower': 'TOWER',
  };

  bool get isUTSBuilding => utsBuildings.containsKey(building);
  
  String? get utsBuildingCode => utsBuildings[building];
}
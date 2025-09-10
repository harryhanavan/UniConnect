class Society {
  final String id;
  final String name;
  final String description;
  final String? aboutUs;
  final String category;
  final String? logoUrl;
  final int memberCount;
  final List<String> memberIds;
  final List<String> tags;
  final bool isJoined;
  final List<String> adminIds;

  const Society({
    required this.id,
    required this.name,
    required this.description,
    this.aboutUs,
    required this.category,
    this.logoUrl,
    required this.memberCount,
    this.memberIds = const [],
    this.tags = const [],
    this.isJoined = false,
    this.adminIds = const [],
  });

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      aboutUs: json['aboutUs'] as String?,
      category: json['category'] as String,
      logoUrl: json['logoUrl'] as String?,
      memberCount: json['memberCount'] as int,
      memberIds: List<String>.from(json['memberIds'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      isJoined: json['isJoined'] as bool? ?? false,
      adminIds: List<String>.from(json['adminIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'aboutUs': aboutUs,
      'category': category,
      'logoUrl': logoUrl,
      'memberCount': memberCount,
      'memberIds': memberIds,
      'tags': tags,
      'isJoined': isJoined,
      'adminIds': adminIds,
    };
  }

  Society copyWith({
    String? id,
    String? name,
    String? description,
    String? aboutUs,
    String? category,
    String? logoUrl,
    int? memberCount,
    List<String>? memberIds,
    List<String>? tags,
    bool? isJoined,
    List<String>? adminIds,
  }) {
    return Society(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      aboutUs: aboutUs ?? this.aboutUs,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      memberCount: memberCount ?? this.memberCount,
      memberIds: memberIds ?? this.memberIds,
      tags: tags ?? this.tags,
      isJoined: isJoined ?? this.isJoined,
      adminIds: adminIds ?? this.adminIds,
    );
  }
}
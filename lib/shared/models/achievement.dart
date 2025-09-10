enum AchievementCategory {
  social,
  academic,
  engagement,
  exploration,
  leadership,
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int points;
  final Map<String, dynamic> requirements;
  final bool isHidden;
  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.rarity,
    required this.points,
    required this.requirements,
    this.isHidden = false,
    required this.createdAt,
  });

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    AchievementCategory? category,
    AchievementRarity? rarity,
    int? points,
    Map<String, dynamic>? requirements,
    bool? isHidden,
    DateTime? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      points: points ?? this.points,
      requirements: requirements ?? this.requirements,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get rarityDisplayName {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.academic:
        return 'Academic';
      case AchievementCategory.engagement:
        return 'Engagement';
      case AchievementCategory.exploration:
        return 'Exploration';
      case AchievementCategory.leadership:
        return 'Leadership';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final Map<String, dynamic> progress;
  final bool isDisplayed;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    required this.progress,
    this.isDisplayed = true,
  });

  UserAchievement copyWith({
    String? id,
    String? userId,
    String? achievementId,
    DateTime? unlockedAt,
    Map<String, dynamic>? progress,
    bool? isDisplayed,
  }) {
    return UserAchievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      isDisplayed: isDisplayed ?? this.isDisplayed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAchievement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final AchievementCategory category;
  final int requiredPoints;
  final List<String> requiredAchievementIds;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.requiredPoints,
    this.requiredAchievementIds = const [],
  });

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    AchievementCategory? category,
    int? requiredPoints,
    List<String>? requiredAchievementIds,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      category: category ?? this.category,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      requiredAchievementIds: requiredAchievementIds ?? this.requiredAchievementIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Badge &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final bool isDisplayed;

  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.isDisplayed = true,
  });

  UserBadge copyWith({
    String? id,
    String? userId,
    String? badgeId,
    DateTime? earnedAt,
    bool? isDisplayed,
  }) {
    return UserBadge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      badgeId: badgeId ?? this.badgeId,
      earnedAt: earnedAt ?? this.earnedAt,
      isDisplayed: isDisplayed ?? this.isDisplayed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBadge &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Leaderboard {
  final String userId;
  final String userName;
  final String profileImageUrl;
  final int totalPoints;
  final int rank;
  final Map<AchievementCategory, int> categoryPoints;
  final List<String> recentAchievements;

  const Leaderboard({
    required this.userId,
    required this.userName,
    required this.profileImageUrl,
    required this.totalPoints,
    required this.rank,
    required this.categoryPoints,
    required this.recentAchievements,
  });

  Leaderboard copyWith({
    String? userId,
    String? userName,
    String? profileImageUrl,
    int? totalPoints,
    int? rank,
    Map<AchievementCategory, int>? categoryPoints,
    List<String>? recentAchievements,
  }) {
    return Leaderboard(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      rank: rank ?? this.rank,
      categoryPoints: categoryPoints ?? this.categoryPoints,
      recentAchievements: recentAchievements ?? this.recentAchievements,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Leaderboard &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
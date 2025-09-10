import '../../shared/models/achievement.dart';
import '../demo_data/demo_data_manager.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;

  // Demo achievements data
  final List<Achievement> _achievements = [];
  final List<UserAchievement> _userAchievements = [];
  final List<Badge> _badges = [];
  final List<UserBadge> _userBadges = [];

  // User progress tracking
  final Map<String, Map<String, int>> _userProgress = {};

  void _initializeDemoData() {
    if (_achievements.isNotEmpty) return;

    final now = DateTime.now();

    // Initialize achievements
    _achievements.addAll([
      // Social Achievements
      Achievement(
        id: 'ach_001',
        name: 'First Friend',
        description: 'Make your first friend on UniConnect',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=friend',
        category: AchievementCategory.social,
        rarity: AchievementRarity.common,
        points: 10,
        requirements: {'friends_count': 1},
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'ach_002',
        name: 'Social Butterfly',
        description: 'Connect with 10 friends',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=butterfly',
        category: AchievementCategory.social,
        rarity: AchievementRarity.uncommon,
        points: 50,
        requirements: {'friends_count': 10},
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'ach_003',
        name: 'Popular',
        description: 'Have 25 friends in your network',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=popular',
        category: AchievementCategory.social,
        rarity: AchievementRarity.rare,
        points: 100,
        requirements: {'friends_count': 25},
        createdAt: now.subtract(const Duration(days: 30)),
      ),

      // Academic Achievements
      Achievement(
        id: 'ach_004',
        name: 'Studious',
        description: 'Join your first study group',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=study',
        category: AchievementCategory.academic,
        rarity: AchievementRarity.common,
        points: 15,
        requirements: {'study_groups_joined': 1},
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'ach_005',
        name: 'Group Leader',
        description: 'Create and manage a study group',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=leader',
        category: AchievementCategory.leadership,
        rarity: AchievementRarity.uncommon,
        points: 75,
        requirements: {'study_groups_created': 1},
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'ach_006',
        name: 'Study Marathon',
        description: 'Attend 20 study sessions',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=marathon',
        category: AchievementCategory.academic,
        rarity: AchievementRarity.rare,
        points: 150,
        requirements: {'study_sessions_attended': 20},
        createdAt: now.subtract(const Duration(days: 30)),
      ),

      // Engagement Achievements  
      Achievement(
        id: 'ach_007',
        name: 'Early Adopter',
        description: 'One of the first 100 users on UniConnect',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=early',
        category: AchievementCategory.engagement,
        rarity: AchievementRarity.legendary,
        points: 500,
        requirements: {'early_user': true},
        isHidden: true,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'ach_008',
        name: 'Daily User',
        description: 'Use UniConnect for 7 consecutive days',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=daily',
        category: AchievementCategory.engagement,
        rarity: AchievementRarity.common,
        points: 25,
        requirements: {'consecutive_days': 7},
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'ach_009',
        name: 'Week Warrior',
        description: 'Maintain a 30-day streak',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=warrior',
        category: AchievementCategory.engagement,
        rarity: AchievementRarity.epic,
        points: 200,
        requirements: {'consecutive_days': 30},
        createdAt: now.subtract(const Duration(days: 30)),
      ),

      // Exploration Achievements
      Achievement(
        id: 'ach_010',
        name: 'Explorer',
        description: 'Visit 5 different campus buildings',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=explore',
        category: AchievementCategory.exploration,
        rarity: AchievementRarity.uncommon,
        points: 30,
        requirements: {'buildings_visited': 5},
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'ach_011',
        name: 'Society Member',
        description: 'Join your first society',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=society',
        category: AchievementCategory.social,
        rarity: AchievementRarity.common,
        points: 20,
        requirements: {'societies_joined': 1},
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Achievement(
        id: 'ach_012',
        name: 'Event Enthusiast',
        description: 'Attend 10 society events',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=event',
        category: AchievementCategory.engagement,
        rarity: AchievementRarity.rare,
        points: 100,
        requirements: {'events_attended': 10},
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ]);

    // Initialize badges
    _badges.addAll([
      Badge(
        id: 'badge_001',
        name: 'Social Champion',
        description: 'Master of social connections',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=social_champion',
        category: AchievementCategory.social,
        requiredPoints: 200,
        requiredAchievementIds: ['ach_001', 'ach_002', 'ach_011'],
      ),
      Badge(
        id: 'badge_002',
        name: 'Academic Excellence',
        description: 'Dedicated to academic success',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=academic',
        category: AchievementCategory.academic,
        requiredPoints: 150,
        requiredAchievementIds: ['ach_004', 'ach_006'],
      ),
      Badge(
        id: 'badge_003',
        name: 'Campus Explorer',
        description: 'Knows every corner of the campus',
        iconUrl: 'https://api.dicebear.com/7.x/shapes/png?seed=explorer_badge',
        category: AchievementCategory.exploration,
        requiredPoints: 100,
        requiredAchievementIds: ['ach_010'],
      ),
    ]);

    // Initialize user achievements (for demo user)
    _userAchievements.addAll([
      UserAchievement(
        id: 'ua_001',
        userId: 'user_001',
        achievementId: 'ach_001',
        unlockedAt: now.subtract(const Duration(days: 15)),
        progress: {'friends_count': 2},
      ),
      UserAchievement(
        id: 'ua_002',
        userId: 'user_001',
        achievementId: 'ach_008',
        unlockedAt: now.subtract(const Duration(days: 7)),
        progress: {'consecutive_days': 7},
      ),
      UserAchievement(
        id: 'ua_003',
        userId: 'user_001',
        achievementId: 'ach_004',
        unlockedAt: now.subtract(const Duration(days: 10)),
        progress: {'study_groups_joined': 2},
      ),
    ]);

    // Initialize user progress
    _userProgress['user_001'] = {
      'friends_count': 2,
      'study_groups_joined': 2,
      'study_groups_created': 1,
      'consecutive_days': 12,
      'buildings_visited': 3,
      'societies_joined': 3,
      'events_attended': 4,
      'study_sessions_attended': 3,
    };
  }

  // Get all achievements
  List<Achievement> getAllAchievements() {
    _initializeDemoData();
    return List.unmodifiable(_achievements.where((a) => !a.isHidden));
  }

  // Get user's unlocked achievements
  List<UserAchievement> getUserAchievements(String userId) {
    _initializeDemoData();
    return _userAchievements.where((ua) => ua.userId == userId).toList();
  }

  // Get user's total points
  int getUserTotalPoints(String userId) {
    _initializeDemoData();
    final userAchievements = getUserAchievements(userId);
    int totalPoints = 0;
    
    for (final userAchievement in userAchievements) {
      final achievement = _achievements.firstWhere(
        (a) => a.id == userAchievement.achievementId,
        orElse: () => Achievement(
          id: '',
          name: '',
          description: '',
          iconUrl: '',
          category: AchievementCategory.social,
          rarity: AchievementRarity.common,
          points: 0,
          requirements: {},
          createdAt: DateTime.now(),
        ),
      );
      totalPoints += achievement.points;
    }
    
    return totalPoints;
  }

  // Get achievement progress for user
  Map<String, dynamic> getAchievementProgress(String userId, String achievementId) {
    _initializeDemoData();
    final achievement = _achievements.firstWhere((a) => a.id == achievementId);
    final userProgress = _userProgress[userId] ?? {};
    final progress = <String, dynamic>{};

    for (final requirement in achievement.requirements.entries) {
      final requiredValue = requirement.value;
      final currentValue = userProgress[requirement.key] ?? 0;
      
      progress[requirement.key] = {
        'current': currentValue,
        'required': requiredValue,
        'completed': currentValue >= requiredValue,
        'percentage': requiredValue is int 
          ? ((currentValue / requiredValue) * 100).clamp(0, 100).round()
          : (currentValue == requiredValue ? 100 : 0),
      };
    }

    return progress;
  }

  // Check and unlock achievements
  Future<List<Achievement>> checkAndUnlockAchievements(String userId) async {
    _initializeDemoData();
    final newlyUnlocked = <Achievement>[];
    final userAchievementIds = getUserAchievements(userId).map((ua) => ua.achievementId).toSet();

    for (final achievement in _achievements) {
      if (userAchievementIds.contains(achievement.id)) continue;

      final progress = getAchievementProgress(userId, achievement.id);
      bool canUnlock = true;

      for (final progressData in progress.values) {
        if (!(progressData['completed'] as bool)) {
          canUnlock = false;
          break;
        }
      }

      if (canUnlock) {
        final userAchievement = UserAchievement(
          id: 'ua_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          achievementId: achievement.id,
          unlockedAt: DateTime.now(),
          progress: Map<String, dynamic>.from(_userProgress[userId] ?? {}),
        );

        _userAchievements.add(userAchievement);
        newlyUnlocked.add(achievement);
      }
    }

    return newlyUnlocked;
  }

  // Update user progress
  Future<List<Achievement>> updateUserProgress(String userId, Map<String, dynamic> progressUpdates) async {
    _initializeDemoData();
    final currentProgress = _userProgress[userId] ?? <String, int>{};
    
    for (final update in progressUpdates.entries) {
      final key = update.key;
      final value = update.value;
      
      if (value is int) {
        currentProgress[key] = (currentProgress[key] ?? 0) + value;
      } else if (value is bool && value) {
        currentProgress[key] = 1;
      }
    }
    
    _userProgress[userId] = currentProgress;
    return await checkAndUnlockAchievements(userId);
  }

  // Get leaderboard
  List<Leaderboard> getLeaderboard({int limit = 20}) {
    _initializeDemoData();
    final users = _demoData.usersSync;
    final leaderboardEntries = <Leaderboard>[];

    for (final user in users) {
      final userAchievements = getUserAchievements(user.id);
      final totalPoints = getUserTotalPoints(user.id);
      final categoryPoints = <AchievementCategory, int>{};
      final recentAchievements = <String>[];

      // Calculate category points
      for (final userAchievement in userAchievements) {
        final achievement = _achievements.firstWhere(
          (a) => a.id == userAchievement.achievementId,
        );
        
        categoryPoints[achievement.category] = 
          (categoryPoints[achievement.category] ?? 0) + achievement.points;
        
        // Get recent achievements (last 7 days)
        if (userAchievement.unlockedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
          recentAchievements.add(userAchievement.achievementId);
        }
      }

      leaderboardEntries.add(Leaderboard(
        userId: user.id,
        userName: user.name,
        profileImageUrl: user.profileImageUrl ?? '',
        totalPoints: totalPoints,
        rank: 0, // Will be set after sorting
        categoryPoints: categoryPoints,
        recentAchievements: recentAchievements,
      ));
    }

    // Sort by points and assign ranks
    leaderboardEntries.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    for (int i = 0; i < leaderboardEntries.length; i++) {
      leaderboardEntries[i] = leaderboardEntries[i].copyWith(rank: i + 1);
    }

    return leaderboardEntries.take(limit).toList();
  }

  // Get user's badges
  List<UserBadge> getUserBadges(String userId) {
    _initializeDemoData();
    return _userBadges.where((ub) => ub.userId == userId).toList();
  }

  // Check and award badges
  Future<List<Badge>> checkAndAwardBadges(String userId) async {
    _initializeDemoData();
    final newlyAwarded = <Badge>[];
    final userBadgeIds = getUserBadges(userId).map((ub) => ub.badgeId).toSet();
    final userAchievementIds = getUserAchievements(userId).map((ua) => ua.achievementId).toSet();
    final userTotalPoints = getUserTotalPoints(userId);

    for (final badge in _badges) {
      if (userBadgeIds.contains(badge.id)) continue;

      bool canAward = true;

      // Check points requirement
      if (userTotalPoints < badge.requiredPoints) {
        canAward = false;
      }

      // Check required achievements
      for (final requiredAchievementId in badge.requiredAchievementIds) {
        if (!userAchievementIds.contains(requiredAchievementId)) {
          canAward = false;
          break;
        }
      }

      if (canAward) {
        final userBadge = UserBadge(
          id: 'ub_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          badgeId: badge.id,
          earnedAt: DateTime.now(),
        );

        _userBadges.add(userBadge);
        newlyAwarded.add(badge);
      }
    }

    return newlyAwarded;
  }

  // Get achievement statistics
  Map<String, dynamic> getAchievementStats(String userId) {
    _initializeDemoData();
    final userAchievements = getUserAchievements(userId);
    final userBadges = getUserBadges(userId);
    final totalPoints = getUserTotalPoints(userId);
    final categoryStats = <AchievementCategory, Map<String, int>>{};

    // Calculate category statistics
    for (final category in AchievementCategory.values) {
      final categoryAchievements = _achievements.where((a) => a.category == category);
      final unlockedInCategory = userAchievements.where((ua) {
        final achievement = _achievements.firstWhere((a) => a.id == ua.achievementId);
        return achievement.category == category;
      });

      categoryStats[category] = {
        'total': categoryAchievements.length,
        'unlocked': unlockedInCategory.length,
        'points': unlockedInCategory.fold(0, (sum, ua) {
          final achievement = _achievements.firstWhere((a) => a.id == ua.achievementId);
          return sum + achievement.points;
        }),
      };
    }

    return {
      'totalAchievements': _achievements.length,
      'unlockedAchievements': userAchievements.length,
      'totalPoints': totalPoints,
      'totalBadges': userBadges.length,
      'categoryStats': categoryStats,
      'completionPercentage': (userAchievements.length / _achievements.length * 100).round(),
    };
  }

  // Get recent activity
  List<Map<String, dynamic>> getRecentActivity(String userId, {int limit = 10}) {
    _initializeDemoData();
    final userAchievements = getUserAchievements(userId);
    final userBadges = getUserBadges(userId);
    final activities = <Map<String, dynamic>>[];

    // Add achievements
    for (final userAchievement in userAchievements) {
      final achievement = _achievements.firstWhere((a) => a.id == userAchievement.achievementId);
      activities.add({
        'type': 'achievement',
        'id': userAchievement.id,
        'title': achievement.name,
        'description': achievement.description,
        'points': achievement.points,
        'rarity': achievement.rarity,
        'timestamp': userAchievement.unlockedAt,
        'iconUrl': achievement.iconUrl,
      });
    }

    // Add badges
    for (final userBadge in userBadges) {
      final badge = _badges.firstWhere((b) => b.id == userBadge.badgeId);
      activities.add({
        'type': 'badge',
        'id': userBadge.id,
        'title': badge.name,
        'description': badge.description,
        'points': badge.requiredPoints,
        'timestamp': userBadge.earnedAt,
        'iconUrl': badge.iconUrl,
      });
    }

    // Sort by timestamp and limit
    activities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return activities.take(limit).toList();
  }
}
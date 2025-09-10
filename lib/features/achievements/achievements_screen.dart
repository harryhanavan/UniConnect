import 'package:flutter/material.dart';
import '../../shared/models/achievement.dart';
import '../../core/services/achievement_service.dart';
import '../../core/constants/app_colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with TickerProviderStateMixin {
  final AchievementService _achievementService = AchievementService();
  late TabController _tabController;

  List<Achievement> _allAchievements = [];
  List<UserAchievement> _userAchievements = [];
  List<UserBadge> _userBadges = [];
  List<Leaderboard> _leaderboard = [];
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAchievementData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievementData() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 700));

    final userId = 'user_001'; // Current user

    setState(() {
      _allAchievements = _achievementService.getAllAchievements();
      _userAchievements = _achievementService.getUserAchievements(userId);
      _userBadges = _achievementService.getUserBadges(userId);
      _leaderboard = _achievementService.getLeaderboard();
      _recentActivity = _achievementService.getRecentActivity(userId);
      _stats = _achievementService.getAchievementStats(userId);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Achievements'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAchievementsTab(),
                _buildLeaderboardTab(),
                _buildActivityTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final unlockedIds = _userAchievements.map((ua) => ua.achievementId).toSet();
    
    return RefreshIndicator(
      onRefresh: _loadAchievementData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsOverview(),
            const SizedBox(height: 24),
            _buildBadgesSection(),
            const SizedBox(height: 24),
            _buildRecentAchievements(),
            const SizedBox(height: 24),
            _buildProgressByCategory(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Your Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Points',
                    _stats['totalPoints']?.toString() ?? '0',
                    Icons.stars,
                    AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Achievements',
                    '${_stats['unlockedAchievements']}/${_stats['totalAchievements']}',
                    Icons.emoji_events,
                    AppColors.success,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Badges',
                    _stats['totalBadges']?.toString() ?? '0',
                    Icons.shield,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_stats['completionPercentage'] ?? 0) / 100.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${_stats['completionPercentage']}% Complete',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    if (_userBadges.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'No Badges Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Text(
                'Keep earning achievements to unlock badges!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield, color: AppColors.warning),
                SizedBox(width: 8),
                Text(
                  'Badges Earned',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _userBadges.map((userBadge) {
                // Find badge details (would be from service in real app)
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning, width: 2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, color: AppColors.warning, size: 32),
                      SizedBox(height: 4),
                      Text(
                        'Badge',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAchievements() {
    final recentAchievements = _recentActivity
        .where((activity) => activity['type'] == 'achievement')
        .take(3)
        .toList();

    if (recentAchievements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'Start Your Journey',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Text(
                'Complete activities to unlock achievements!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'Recent Achievements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recentAchievements.map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getRarityColor(activity['rarity']).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: _getRarityColor(activity['rarity']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '+${activity['points']} points',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTimeAgo(activity['timestamp']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressByCategory() {
    final categoryStats = _stats['categoryStats'] as Map<AchievementCategory, Map<String, int>>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Progress by Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AchievementCategory.values.map((category) {
              final stats = categoryStats[category] ?? {'total': 0, 'unlocked': 0, 'points': 0};
              final total = stats['total'] ?? 0;
              final unlocked = stats['unlocked'] ?? 0;
              final points = stats['points'] ?? 0;
              final progress = total > 0 ? unlocked / total : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getCategoryIcon(category), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _getCategoryName(category),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          '$unlocked/$total • $points pts',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final unlockedIds = _userAchievements.map((ua) => ua.achievementId).toSet();
    final achievementsByCategory = <AchievementCategory, List<Achievement>>{};

    for (final achievement in _allAchievements) {
      achievementsByCategory.putIfAbsent(achievement.category, () => []).add(achievement);
    }

    return RefreshIndicator(
      onRefresh: _loadAchievementData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: AchievementCategory.values.map((category) {
          final achievements = achievementsByCategory[category] ?? [];
          if (achievements.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(_getCategoryIcon(category), color: _getCategoryColor(category)),
                    const SizedBox(width: 8),
                    Text(
                      _getCategoryName(category),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...achievements.map((achievement) {
                final isUnlocked = unlockedIds.contains(achievement.id);
                final progress = _achievementService.getAchievementProgress('user_001', achievement.id);
                
                return _buildAchievementCard(achievement, isUnlocked, progress);
              }),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked, Map<String, dynamic> progress) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.7,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isUnlocked 
                  ? _getRarityColor(achievement.rarity).withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isUnlocked 
                    ? _getRarityColor(achievement.rarity)
                    : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                color: isUnlocked 
                  ? _getRarityColor(achievement.rarity)
                  : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? null : Colors.grey,
                          ),
                        ),
                      ),
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRarityColor(achievement.rarity).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${achievement.points}',
                            style: TextStyle(
                              color: _getRarityColor(achievement.rarity),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: isUnlocked ? Colors.grey.shade600 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  if (!isUnlocked && progress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...progress.entries.map((entry) {
                      final progressData = entry.value as Map<String, dynamic>;
                      final current = progressData['current'];
                      final required = progressData['required'];
                      final percentage = progressData['percentage'];
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_formatProgressKey(entry.key)}: $current/$required',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const Spacer(),
                              Text(
                                '$percentage%',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100.0,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(_getRarityColor(achievement.rarity)),
                          ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _loadAchievementData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final entry = _leaderboard[index];
          final isCurrentUser = entry.userId == 'user_001';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isCurrentUser ? AppColors.primary.withValues(alpha: 0.1) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getRankColor(entry.rank).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '#${entry.rank}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRankColor(entry.rank),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    backgroundImage: NetworkImage(entry.profileImageUrl),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              entry.userName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser ? AppColors.primary : null,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'YOU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${entry.totalPoints} points',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.recentAchievements.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.recentAchievements.length} new',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityTab() {
    if (_recentActivity.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Activity Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Text(
              'Your achievements and badge history will appear here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAchievementData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentActivity.length,
        itemBuilder: (context, index) {
          final activity = _recentActivity[index];
          final isAchievement = activity['type'] == 'achievement';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isAchievement 
                        ? _getRarityColor(activity['rarity']).withValues(alpha: 0.2)
                        : AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      isAchievement ? Icons.emoji_events : Icons.shield,
                      color: isAchievement 
                        ? _getRarityColor(activity['rarity'])
                        : AppColors.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activity['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+${activity['points']}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity['description'] ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimeAgo(activity['timestamp']),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey;
    if (rank == 3) return Colors.brown;
    return AppColors.primary;
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.social:
        return Icons.people;
      case AchievementCategory.academic:
        return Icons.school;
      case AchievementCategory.engagement:
        return Icons.favorite;
      case AchievementCategory.exploration:
        return Icons.explore;
      case AchievementCategory.leadership:
        return Icons.star;
    }
  }

  String _getCategoryName(AchievementCategory category) {
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

  Color _getCategoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.social:
        return Colors.blue;
      case AchievementCategory.academic:
        return Colors.green;
      case AchievementCategory.engagement:
        return Colors.red;
      case AchievementCategory.exploration:
        return Colors.orange;
      case AchievementCategory.leadership:
        return Colors.purple;
    }
  }

  String _formatProgressKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
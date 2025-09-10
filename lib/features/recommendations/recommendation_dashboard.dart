import 'package:flutter/material.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user.dart';
import '../../shared/models/event.dart';
import '../../shared/models/society.dart';

class RecommendationDashboard extends StatefulWidget {
  const RecommendationDashboard({super.key});

  @override
  State<RecommendationDashboard> createState() => _RecommendationDashboardState();
}

class _RecommendationDashboardState extends State<RecommendationDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final RecommendationService _recommendationService = RecommendationService();
  final DemoDataManager _demoData = DemoDataManager.instance;

  Map<RecommendationType, List<Recommendation>> _recommendations = {};
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadRecommendations();
  }

  void _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final allRecommendations = await _recommendationService.getRecommendations(
        userId: _demoData.currentUser.id,
        limit: 50,
      );

      final groupedRecommendations = <RecommendationType, List<Recommendation>>{};
      for (final rec in allRecommendations) {
        groupedRecommendations.putIfAbsent(rec.type, () => []);
        groupedRecommendations[rec.type]!.add(rec);
      }

      setState(() {
        _recommendations = groupedRecommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommendations: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('For You'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _loadRecommendations,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Recommendations')),
              const PopupMenuItem(value: 'high_confidence', child: Text('High Confidence Only')),
              const PopupMenuItem(value: 'recent', child: Text('Recent Additions')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Friends'),
            Tab(text: 'Events'),
            Tab(text: 'Societies'),
            Tab(text: 'Study'),
            Tab(text: 'Places'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllRecommendations(),
                _buildTypeRecommendations(RecommendationType.friends),
                _buildTypeRecommendations(RecommendationType.events),
                _buildTypeRecommendations(RecommendationType.societies),
                _buildStudyRecommendations(),
                _buildTypeRecommendations(RecommendationType.locations),
              ],
            ),
    );
  }

  Widget _buildAllRecommendations() {
    final allRecs = _recommendations.values.expand((list) => list).toList();
    allRecs.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    final filteredRecs = _applyFilter(allRecs);

    if (filteredRecs.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightCard(),
          const SizedBox(height: 24),
          _buildTopPicks(filteredRecs),
          const SizedBox(height: 24),
          _buildRecommendationsByType(),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    final totalRecs = _recommendations.values.fold<int>(0, (sum, list) => sum + list.length);
    final highConfidenceRecs = _recommendations.values
        .expand((list) => list)
        .where((rec) => rec.confidence > 0.7)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Your Personalized Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We found $totalRecs personalized recommendations for you, with $highConfidenceRecs high-confidence matches.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInsightStat('Friends', '${_recommendations[RecommendationType.friends]?.length ?? 0}', Icons.people),
              const SizedBox(width: 20),
              _buildInsightStat('Events', '${_recommendations[RecommendationType.events]?.length ?? 0}', Icons.event),
              const SizedBox(width: 20),
              _buildInsightStat('Societies', '${_recommendations[RecommendationType.societies]?.length ?? 0}', Icons.groups),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightStat(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTopPicks(List<Recommendation> recommendations) {
    final topPicks = recommendations.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Picks for You',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topPicks.length,
            itemBuilder: (context, index) {
              final rec = topPicks[index];
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 16),
                child: _buildRecommendationCard(rec, isTopPick: true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsByType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore by Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildCategorySection('New Connections', RecommendationType.friends, Icons.people, Colors.blue),
        const SizedBox(height: 20),
        _buildCategorySection('Upcoming Events', RecommendationType.events, Icons.event, Colors.green),
        const SizedBox(height: 20),
        _buildCategorySection('Societies to Join', RecommendationType.societies, Icons.groups, Colors.purple),
        const SizedBox(height: 20),
        _buildCategorySection('Study Partners', RecommendationType.studyPartners, Icons.school, Colors.orange),
      ],
    );
  }

  Widget _buildCategorySection(String title, RecommendationType type, IconData icon, Color color) {
    final recommendations = _recommendations[type] ?? [];
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                _tabController.animateTo(_getTabIndexForType(type));
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.take(5).length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: _buildCompactRecommendationCard(rec),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeRecommendations(RecommendationType type) {
    final recommendations = _applyFilter(_recommendations[type] ?? []);

    if (recommendations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${recommendations.length} recommendations found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          );
        }

        final rec = recommendations[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRecommendationCard(rec),
        );
      },
    );
  }

  Widget _buildStudyRecommendations() {
    final studyPartners = _recommendations[RecommendationType.studyPartners] ?? [];
    final studyLocations = _recommendations[RecommendationType.locations] ?? [];
    final studyCourses = _recommendations[RecommendationType.courses] ?? [];

    if (studyPartners.isEmpty && studyLocations.isEmpty && studyCourses.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (studyPartners.isNotEmpty) ...[
            const Text(
              'Study Partners',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...studyPartners.take(3).map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildRecommendationCard(rec),
            )),
            const SizedBox(height: 20),
          ],
          if (studyLocations.isNotEmpty) ...[
            const Text(
              'Study Locations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...studyLocations.take(3).map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildRecommendationCard(rec),
            )),
            const SizedBox(height: 20),
          ],
          if (studyCourses.isNotEmpty) ...[
            const Text(
              'Course Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...studyCourses.take(3).map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildRecommendationCard(rec),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Recommendation rec, {bool isTopPick = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isTopPick 
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isTopPick ? 0.1 : 0.05),
            blurRadius: isTopPick ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildRecommendationIcon(rec),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(rec.confidence).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(rec.confidence * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getConfidenceColor(rec.confidence),
                      ),
                    ),
                  ),
                  if (isTopPick) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TOP PICK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rec.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: rec.reasons.take(3).map((reason) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reason,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleRecommendationAction(rec),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_getActionButtonText(rec.type)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _dismissRecommendation(rec),
                icon: const Icon(Icons.close, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRecommendationCard(Recommendation rec) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRecommendationIcon(rec, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      rec.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${(rec.confidence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getConfidenceColor(rec.confidence),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rec.reasons.take(2).join(', '),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleRecommendationAction(rec),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                _getActionButtonText(rec.type),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationIcon(Recommendation rec, {double size = 40}) {
    Widget iconWidget;
    Color backgroundColor;

    switch (rec.type) {
      case RecommendationType.friends:
      case RecommendationType.studyPartners:
        if (rec.imageUrl != null) {
          return CircleAvatar(
            radius: size / 2,
            backgroundImage: NetworkImage(rec.imageUrl!),
          );
        } else {
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: AppColors.primary,
            child: Text(
              rec.title.isNotEmpty ? rec.title[0] : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          );
        }

      case RecommendationType.events:
        backgroundColor = Colors.green;
        iconWidget = Icon(Icons.event, color: Colors.white, size: size * 0.5);
        break;

      case RecommendationType.societies:
        if (rec.imageUrl != null) {
          return CircleAvatar(
            radius: size / 2,
            backgroundImage: NetworkImage(rec.imageUrl!),
          );
        }
        backgroundColor = Colors.purple;
        iconWidget = Icon(Icons.groups, color: Colors.white, size: size * 0.5);
        break;

      case RecommendationType.locations:
        backgroundColor = Colors.orange;
        iconWidget = Icon(Icons.location_on, color: Colors.white, size: size * 0.5);
        break;

      case RecommendationType.courses:
        backgroundColor = Colors.blue;
        iconWidget = Icon(Icons.school, color: Colors.white, size: size * 0.5);
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: iconWidget,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No recommendations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the app more to get personalized recommendations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadRecommendations,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<Recommendation> _applyFilter(List<Recommendation> recommendations) {
    switch (_selectedFilter) {
      case 'high_confidence':
        return recommendations.where((rec) => rec.confidence > 0.7).toList();
      case 'recent':
        return recommendations.where((rec) => 
          DateTime.now().difference(rec.timestamp).inHours < 24).toList();
      default:
        return recommendations;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.grey;
  }

  String _getActionButtonText(RecommendationType type) {
    switch (type) {
      case RecommendationType.friends:
        return 'Add Friend';
      case RecommendationType.events:
        return 'Join Event';
      case RecommendationType.societies:
        return 'Join Society';
      case RecommendationType.studyPartners:
        return 'Connect';
      case RecommendationType.locations:
        return 'Visit';
      case RecommendationType.courses:
        return 'Learn More';
    }
  }

  int _getTabIndexForType(RecommendationType type) {
    switch (type) {
      case RecommendationType.friends:
        return 1;
      case RecommendationType.events:
        return 2;
      case RecommendationType.societies:
        return 3;
      case RecommendationType.studyPartners:
        return 4;
      case RecommendationType.locations:
        return 5;
      case RecommendationType.courses:
        return 0; // Default to All
    }
  }

  void _handleRecommendationAction(Recommendation rec) {
    // Track interaction for learning
    _recommendationService.trackInteraction(
      _demoData.currentUser.id, 
      rec.id, 
      'accept'
    );

    // Handle the specific action based on recommendation type
    switch (rec.type) {
      case RecommendationType.friends:
      case RecommendationType.studyPartners:
        _handleFriendRecommendation(rec);
        break;
      case RecommendationType.events:
        _handleEventRecommendation(rec);
        break;
      case RecommendationType.societies:
        _handleSocietyRecommendation(rec);
        break;
      case RecommendationType.locations:
        _handleLocationRecommendation(rec);
        break;
      case RecommendationType.courses:
        _handleCourseRecommendation(rec);
        break;
    }
  }

  void _handleFriendRecommendation(Recommendation rec) {
    final user = rec.data['user'] as User;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(
                user.name[0],
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${user.course} • ${user.year}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recommended because: ${rec.reasons.join(", ")}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendFriendRequest(user);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Send Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleEventRecommendation(Recommendation rec) {
    final event = rec.data['event'] as Event;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${event.title}" to your calendar'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {},
        ),
      ),
    );
  }

  void _handleSocietyRecommendation(Recommendation rec) {
    final society = rec.data['society'] as Society;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined "${society.name}"'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {},
        ),
      ),
    );
  }

  void _handleLocationRecommendation(Recommendation rec) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${rec.title}" to your saved places'),
        action: SnackBarAction(
          label: 'Directions',
          onPressed: () {},
        ),
      ),
    );
  }

  void _handleCourseRecommendation(Recommendation rec) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Course "${rec.title}" saved to your wishlist'),
        action: SnackBarAction(
          label: 'Details',
          onPressed: () {},
        ),
      ),
    );
  }

  void _sendFriendRequest(User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend request sent to ${user.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _dismissRecommendation(Recommendation rec) {
    // Track dismissal for learning
    _recommendationService.trackInteraction(
      _demoData.currentUser.id, 
      rec.id, 
      'dismiss'
    );

    setState(() {
      _recommendations[rec.type]?.remove(rec);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recommendation dismissed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _recommendations[rec.type]?.add(rec);
            });
          },
        ),
      ),
    );
  }
}
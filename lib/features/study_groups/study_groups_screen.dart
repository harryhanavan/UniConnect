import 'package:flutter/material.dart';
import '../../shared/models/study_group.dart';
import '../../core/services/study_group_service.dart';
import '../../core/constants/app_colors.dart';
import 'study_group_detail_screen.dart';
import 'create_study_group_screen.dart';

class StudyGroupsScreen extends StatefulWidget {
  final TabController? tabController;

  const StudyGroupsScreen({super.key, this.tabController});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> with TickerProviderStateMixin {
  final StudyGroupService _studyGroupService = StudyGroupService();
  late TabController _tabController;

  List<StudyGroup> _myGroups = [];
  List<StudyGroup> _availableGroups = [];
  List<StudyGroup> _recommendedGroups = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = widget.tabController ?? TabController(length: 3, vsync: this);
    _loadStudyGroupData();
  }

  @override
  void dispose() {
    if (widget.tabController == null) {
      _tabController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudyGroupData() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _myGroups = _studyGroupService.getMyStudyGroups();
      _availableGroups = _studyGroupService.getAvailableStudyGroups();
      _recommendedGroups = _studyGroupService.getRecommendedStudyGroups();
      _stats = _studyGroupService.getStudyGroupStats();
      _isLoading = false;
    });
  }

  Future<void> _joinGroup(String groupId) async {
    final success = await _studyGroupService.joinStudyGroup(groupId);
    
    if (success) {
      await _loadStudyGroupData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined study group!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join group. It may be full or you may already be a member.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildStatsHeader(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyGroupsTab(),
                    _buildDiscoverTab(),
                    _buildRecommendedTab(),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.studyGroupColor.withValues(alpha: 0.1),
        border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Active Groups',
              _stats['activeGroups']?.toString() ?? '0',
              Icons.groups,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Upcoming Sessions',
              _stats['upcomingSessions']?.toString() ?? '0',
              Icons.event,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Study Hours/Week',
              _stats['studyHoursThisWeek']?.toString() ?? '0',
              Icons.schedule,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.studyGroupColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.studyGroupColor,
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

  Widget _buildMyGroupsTab() {
    if (_myGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Study Groups Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Text(
              'Join existing groups or create your own',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudyGroupData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myGroups.length,
        itemBuilder: (context, index) {
          return _buildStudyGroupCard(_myGroups[index], isMyGroup: true);
        },
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return RefreshIndicator(
      onRefresh: _loadStudyGroupData,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search study groups...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (query) {
                if (query.isEmpty) {
                  setState(() {
                    _availableGroups = _studyGroupService.getAvailableStudyGroups();
                  });
                } else {
                  setState(() {
                    _availableGroups = _studyGroupService.searchStudyGroups(query);
                  });
                }
              },
            ),
          ),
          Expanded(
            child: _availableGroups.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No Groups Found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Try adjusting your search or create a new group',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _availableGroups.length,
                    itemBuilder: (context, index) {
                      return _buildStudyGroupCard(_availableGroups[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedTab() {
    if (_recommendedGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Text(
              'Complete your profile and add more courses for better suggestions',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudyGroupData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recommendedGroups.length,
        itemBuilder: (context, index) {
          final group = _recommendedGroups[index];
          
          return _buildStudyGroupCard(group);
        },
      ),
    );
  }

  Widget _buildStudyGroupCard(StudyGroup group, {bool isMyGroup = false, int? recommendationScore}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyGroupDetailScreen(studyGroup: group),
            ),
          ).then((_) => _loadStudyGroupData());
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${group.courseCode} • ${group.courseName}',
                          style: const TextStyle(
                            color: AppColors.studyGroupColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recommendationScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            '$recommendationScore% match',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(group.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      group.typeDisplayName,
                      style: TextStyle(
                        color: _getTypeColor(group.type),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                group.description,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${group.memberIds.length}/${group.maxMembers} members',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (group.hasUpcomingMeeting) ...[
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Next: ${_formatDate(group.nextMeetingAt!)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (!isMyGroup)
                    ElevatedButton(
                      onPressed: group.isFull ? null : () => _joinGroup(group.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.studyGroupColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: Text(
                        group.isFull ? 'Full' : 'Join',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              if (group.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: group.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(StudyGroupType type) {
    switch (type) {
      case StudyGroupType.exam:
        return Colors.red;
      case StudyGroupType.assignment:
        return Colors.orange;
      case StudyGroupType.project:
        return Colors.blue;
      case StudyGroupType.general:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

/// StudyGroups screen with full Scaffold for normal navigation
/// This version is used when not preserving bottom navigation
class StudyGroupsFullScreen extends StatefulWidget {
  const StudyGroupsFullScreen({super.key});

  @override
  State<StudyGroupsFullScreen> createState() => _StudyGroupsFullScreenState();
}

class _StudyGroupsFullScreenState extends State<StudyGroupsFullScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onCreateStudyGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStudyGroupScreen(),
      ),
    ).then((_) {
      // Trigger refresh by incrementing counter
      setState(() {
        _refreshCounter++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Groups'),
        backgroundColor: AppColors.studyGroupColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Discover'),
            Tab(text: 'Recommended'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _onCreateStudyGroup,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StudyGroupsScreen(
        key: ValueKey(_refreshCounter),
        tabController: _tabController,
      ),
    );
  }
}
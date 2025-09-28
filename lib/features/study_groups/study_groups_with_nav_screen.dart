import 'package:flutter/material.dart';
import '../../shared/widgets/nav_wrapper.dart';
import '../../core/constants/app_colors.dart';
import 'study_groups_screen.dart';
import 'create_study_group_screen.dart';

/// StudyGroups screen wrapped with bottom navigation preservation
/// This version is used when navigating from quick actions to maintain bottom nav
class StudyGroupsWithNavScreen extends StatefulWidget {
  const StudyGroupsWithNavScreen({super.key});

  @override
  State<StudyGroupsWithNavScreen> createState() => _StudyGroupsWithNavScreenState();
}

class _StudyGroupsWithNavScreenState extends State<StudyGroupsWithNavScreen> with TickerProviderStateMixin {
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
    return NavWrapper(
      title: 'Study Groups',
      appBarColor: AppColors.studyGroupColor,
      appBarForegroundColor: Colors.white,
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
      child: StudyGroupsScreen(
        key: ValueKey(_refreshCounter),
        tabController: _tabController,
      ),
    );
  }
}
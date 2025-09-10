import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/society_card.dart';

class SocietiesScreen extends StatefulWidget {
  const SocietiesScreen({super.key});

  @override
  State<SocietiesScreen> createState() => _SocietiesScreenState();
}

class _SocietiesScreenState extends State<SocietiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Societies'),
            backgroundColor: AppColors.societyColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Discover'),
                Tab(text: 'My Societies'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search societies...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDiscoverTab(appState),
                    _buildMySocietiesTab(appState),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscoverTab(AppState appState) {
    final allSocieties = appState.societies
        .where((society) => 
            society.name.toLowerCase().contains(_searchQuery) ||
            society.description.toLowerCase().contains(_searchQuery) ||
            society.category.toLowerCase().contains(_searchQuery))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: allSocieties.length,
      itemBuilder: (context, index) {
        return SocietyCard(
          society: allSocieties[index],
          onJoinPressed: () {
            if (allSocieties[index].isJoined) {
              appState.leaveSociety(allSocieties[index].id);
            } else {
              appState.joinSociety(allSocieties[index].id);
            }
          },
        );
      },
    );
  }

  Widget _buildMySocietiesTab(AppState appState) {
    final joinedSocieties = appState.joinedSocieties
        .where((society) => 
            society.name.toLowerCase().contains(_searchQuery) ||
            society.description.toLowerCase().contains(_searchQuery) ||
            society.category.toLowerCase().contains(_searchQuery))
        .toList();

    if (joinedSocieties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? 'No societies joined yet'
                  : 'No joined societies match your search',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Explore the Discover tab to find societies',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: joinedSocieties.length,
      itemBuilder: (context, index) {
        return SocietyCard(
          society: joinedSocieties[index],
          onJoinPressed: () {
            appState.leaveSociety(joinedSocieties[index].id);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/search_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user.dart';
import '../../shared/models/event.dart';
import '../../shared/models/society.dart';
import '../../shared/models/location.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  final SearchService _searchService = SearchService();
  final DemoDataManager _demoData = DemoDataManager.instance;
  
  List<SearchResult> _searchResults = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  
  SearchCategory _selectedCategory = SearchCategory.all;
  final Set<SearchFilter> _activeFilters = {};
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    
    _loadInitialContent();
  }

  void _loadInitialContent() {
    setState(() {
      _suggestions = _searchService.getTrendingSearches();
    });
  }

  void _onTabChanged() {
    final categories = [
      SearchCategory.all,
      SearchCategory.people,
      SearchCategory.events,
      SearchCategory.societies,
      SearchCategory.locations,
      SearchCategory.courses,
    ];
    
    setState(() {
      _selectedCategory = categories[_tabController.index];
    });
    
    if (_searchController.text.isNotEmpty) {
      _performSearch();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() {
          _searchResults.clear();
          _suggestions = _searchService.getTrendingSearches();
          _showSuggestions = _searchFocusNode.hasFocus;
        });
      } else {
        _updateSuggestions(query);
        _performSearch();
      }
    });
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isEmpty;
      if (_showSuggestions) {
        _suggestions = _searchService.getTrendingSearches();
      }
    });
  }

  void _updateSuggestions(String query) {
    setState(() {
      _suggestions = _searchService.generateSearchSuggestions(query);
    });
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      final results = await _searchService.search(
        query: query,
        category: _selectedCategory,
        filters: _activeFilters.toList(),
        userId: _demoData.currentUser.id,
      );
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchFocusNode.unfocus();
    _performSearch();
  }

  void _toggleFilter(SearchFilter filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    });
    
    if (_searchController.text.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _showFilterBottomSheet,
            icon: Badge(
              isLabelVisible: _activeFilters.isNotEmpty,
              label: Text('${_activeFilters.length}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'People'),
            Tab(text: 'Events'),
            Tab(text: 'Societies'),
            Tab(text: 'Locations'),
            Tab(text: 'Courses'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showSuggestions) _buildSuggestionsList(),
          if (_activeFilters.isNotEmpty) _buildActiveFilters(),
          Expanded(
            child: _buildSearchContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search people, events, societies...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _searchController.text.isEmpty ? 'Trending Searches' : 'Suggestions',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ..._suggestions.map((suggestion) => ListTile(
            dense: true,
            leading: Icon(
              _searchController.text.isEmpty ? Icons.trending_up : Icons.search,
              color: Colors.grey[600],
              size: 20,
            ),
            title: Text(suggestion),
            onTap: () => _selectSuggestion(suggestion),
          )),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _activeFilters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(_getFilterLabel(filter)),
              onDeleted: () => _toggleFilter(filter),
              deleteIconColor: Colors.white,
              backgroundColor: AppColors.primary,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching...'),
          ],
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return _buildDiscoverContent();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  Widget _buildDiscoverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildQuickActionCard(
            'Find Study Partners',
            'Connect with classmates for collaborative learning',
            Icons.people,
            Colors.blue,
            () => _selectSuggestion('study group'),
          ),
          
          _buildQuickActionCard(
            'Upcoming Events',
            'Discover events happening on campus',
            Icons.event,
            Colors.green,
            () => _selectSuggestion('events this week'),
          ),
          
          _buildQuickActionCard(
            'Join Societies',
            'Find communities that match your interests',
            Icons.groups,
            Colors.purple,
            () => _selectSuggestion('programming society'),
          ),
          
          _buildQuickActionCard(
            'Campus Locations',
            'Explore study spaces and facilities',
            Icons.location_on,
            Colors.orange,
            () => _selectSuggestion('library study rooms'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Popular Right Now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...(_searchService.getTrendingSearches().take(5).map((trend) => 
            ListTile(
              leading: const Icon(Icons.trending_up, color: AppColors.primary),
              title: Text(trend),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectSuggestion(trend),
            )
          )),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term or adjust your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _activeFilters.clear();
                _selectedCategory = SearchCategory.all;
                _tabController.animateTo(0);
              });
              _performSearch();
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${_searchResults.length} results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          );
        }

        final result = _searchResults[index - 1];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildResultIcon(result),
        title: Text(
          result.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              result.subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (result.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                result.description,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(result.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getCategoryLabel(result.category),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getCategoryColor(result.category),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(result.relevanceScore).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        onTap: () => _handleResultTap(result),
      ),
    );
  }

  Widget _buildResultIcon(SearchResult result) {
    Widget iconWidget;
    Color backgroundColor;

    switch (result.category) {
      case SearchCategory.people:
        iconWidget = result.imageUrl != null
            ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(result.imageUrl!),
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  result.title.isNotEmpty ? result.title[0] : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              );
        return iconWidget;

      case SearchCategory.events:
        backgroundColor = Colors.green;
        iconWidget = const Icon(Icons.event, color: Colors.white);
        break;

      case SearchCategory.societies:
        backgroundColor = Colors.purple;
        iconWidget = result.imageUrl != null
            ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(result.imageUrl!),
              )
            : const Icon(Icons.groups, color: Colors.white);
        break;

      case SearchCategory.locations:
        backgroundColor = Colors.orange;
        iconWidget = const Icon(Icons.location_on, color: Colors.white);
        break;

      case SearchCategory.courses:
        backgroundColor = Colors.blue;
        iconWidget = const Icon(Icons.school, color: Colors.white);
        break;

      default:
        backgroundColor = Colors.grey;
        iconWidget = const Icon(Icons.search, color: Colors.white);
        break;
    }

    if (result.category != SearchCategory.people && result.category != SearchCategory.societies) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: iconWidget,
      );
    }

    return iconWidget;
  }

  void _handleResultTap(SearchResult result) {
    // Handle navigation based on result type
    switch (result.category) {
      case SearchCategory.people:
        final user = result.data['user'] as User;
        _showUserProfile(user);
        break;
      case SearchCategory.events:
        final event = result.data['event'] as Event;
        _showEventDetails(event);
        break;
      case SearchCategory.societies:
        final society = result.data['society'] as Society;
        _showSocietyDetails(society);
        break;
      case SearchCategory.locations:
        final location = result.data['location'] as Location;
        _showLocationDetails(location);
        break;
      case SearchCategory.courses:
        final courseCode = result.data['courseCode'] as String;
        _showCourseDetails(courseCode, result.data['courseData']);
        break;
      default:
        break;
    }
  }

  void _showUserProfile(User user) {
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Friend'),
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

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(_formatEventTime(event)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 8),
                Text(event.location),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add to Calendar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSocietyDetails(Society society) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              society.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${society.category} • ${society.memberCount} members',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(society.description),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: society.tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              )).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(_demoData.currentUser.societyIds.contains(society.id) ? 'View Society' : 'Join Society'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDetails(Location location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${location.building} • ${location.type.toString().split('.').last}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (location.description != null) ...[
              const SizedBox(height: 16),
              Text(location.description!),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.bookmark),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseDetails(String courseCode, Map<String, dynamic> courseData) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$courseCode - ${courseData['title']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(courseData['students'] as Set).length} students • ${(courseData['events'] as List).length} events',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.people),
                    label: const Text('Find Classmates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.event),
                    label: const Text('View Events'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Filters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SearchFilter.values.map((filter) {
                final isActive = _activeFilters.contains(filter);
                return FilterChip(
                  label: Text(_getFilterLabel(filter)),
                  selected: isActive,
                  onSelected: (selected) {
                    _toggleFilter(filter);
                    Navigator.pop(context);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(SearchFilter filter) {
    switch (filter) {
      case SearchFilter.recent:
        return 'Recent';
      case SearchFilter.popular:
        return 'Popular';
      case SearchFilter.nearby:
        return 'Nearby';
      case SearchFilter.friends:
        return 'Friends';
      case SearchFilter.trending:
        return 'Trending';
      case SearchFilter.recommended:
        return 'Recommended';
    }
  }

  String _getCategoryLabel(SearchCategory category) {
    switch (category) {
      case SearchCategory.all:
        return 'All';
      case SearchCategory.people:
        return 'People';
      case SearchCategory.events:
        return 'Events';
      case SearchCategory.societies:
        return 'Societies';
      case SearchCategory.locations:
        return 'Locations';
      case SearchCategory.courses:
        return 'Courses';
      case SearchCategory.studyGroups:
        return 'Study Groups';
    }
  }

  Color _getCategoryColor(SearchCategory category) {
    switch (category) {
      case SearchCategory.people:
        return Colors.blue;
      case SearchCategory.events:
        return Colors.green;
      case SearchCategory.societies:
        return Colors.purple;
      case SearchCategory.locations:
        return Colors.orange;
      case SearchCategory.courses:
        return Colors.indigo;
      case SearchCategory.studyGroups:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatEventTime(Event event) {
    final now = DateTime.now();
    final eventDate = event.startTime;
    final difference = eventDate.difference(now);
    
    if (difference.inDays > 0) {
      return 'In ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes';
    } else if (difference.inMinutes > -60) {
      return 'Just started';
    } else {
      return 'Ended';
    }
  }
}
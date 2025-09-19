import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/search_service.dart';
import '../../core/services/friendship_service.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user.dart';
import '../../shared/models/event.dart';
import '../../shared/models/society.dart';
import '../../shared/models/location.dart';
import '../../shared/widgets/user_profile_card.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final SearchCategory? initialTab;

  const AdvancedSearchScreen({super.key, this.initialTab});

  // Named constructors for convenience
  const AdvancedSearchScreen.people({super.key}) : initialTab = SearchCategory.people;
  const AdvancedSearchScreen.events({super.key}) : initialTab = SearchCategory.events;
  const AdvancedSearchScreen.societies({super.key}) : initialTab = SearchCategory.societies;

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  final SearchService _searchService = SearchService();
  final FriendshipService _friendshipService = FriendshipService();
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

    // Determine initial tab index
    int initialIndex = 0;
    if (widget.initialTab != null) {
      final categories = [
        SearchCategory.all,
        SearchCategory.people,
        SearchCategory.events,
        SearchCategory.societies,
        SearchCategory.locations,
        SearchCategory.courses,
      ];
      initialIndex = categories.indexOf(widget.initialTab!);
      if (initialIndex == -1) initialIndex = 0;
      _selectedCategory = widget.initialTab!;
    }

    _tabController = TabController(length: 6, vsync: this, initialIndex: initialIndex);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
    String placeholder = _getSearchPlaceholder();

    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: placeholder,
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
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  String _getSearchPlaceholder() {
    switch (_selectedCategory) {
      case SearchCategory.people:
        return 'Search for people...';
      case SearchCategory.events:
        return 'Search for events...';
      case SearchCategory.societies:
        return 'Search for societies...';
      case SearchCategory.locations:
        return 'Search for locations...';
      case SearchCategory.courses:
        return 'Search for courses...';
      case SearchCategory.all:
      default:
        return 'Search people, events, societies...';
    }
  }

  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ..._suggestions.map((suggestion) => ListTile(
            dense: true,
            leading: Icon(
              _searchController.text.isEmpty ? Icons.trending_up : Icons.search,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              deleteIconColor: Theme.of(context).colorScheme.surface,
              backgroundColor: AppColors.primary,
              labelStyle: TextStyle(color: Colors.white),
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
    switch (_selectedCategory) {
      case SearchCategory.people:
        return _buildPeopleDiscoverContent();
      case SearchCategory.events:
        return _buildEventsDiscoverContent();
      case SearchCategory.societies:
        return _buildSocietiesDiscoverContent();
      case SearchCategory.locations:
        return _buildLocationsDiscoverContent();
      case SearchCategory.courses:
        return _buildCoursesDiscoverContent();
      case SearchCategory.all:
      default:
        return _buildAllDiscoverContent();
    }
  }

  Widget _buildAllDiscoverContent() {
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

  Widget _buildPeopleDiscoverContent() {
    final currentUser = _demoData.currentUser;
    final friendSuggestions = _friendshipService.getFriendSuggestionsSync(currentUser.id).take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find People',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildQuickActionCard(
            'Find Classmates',
            'Connect with people from your courses',
            Icons.school,
            AppColors.personalColor,
            () => _selectSuggestion('${currentUser.course} students'),
          ),

          _buildQuickActionCard(
            'Study Partners',
            'Find study buddies for collaborative learning',
            Icons.groups,
            AppColors.studyGroupColor,
            () => _selectSuggestion('study partners'),
          ),

          _buildQuickActionCard(
            'Society Members',
            'Discover people from your joined societies',
            Icons.people_outline,
            AppColors.societyColor,
            () => _selectSuggestion('society members'),
          ),

          _buildQuickActionCard(
            'Friends Nearby',
            'Find friends currently on campus',
            Icons.location_on,
            AppColors.socialColor,
            () => _selectSuggestion('friends nearby'),
          ),

          if (friendSuggestions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Suggested for You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...friendSuggestions.map((user) => _buildSuggestedPersonCard(user)),
          ],

          const SizedBox(height: 24),
          const Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ..._getPeopleSearchTrends().map((trend) =>
            ListTile(
              leading: const Icon(Icons.trending_up, color: AppColors.primary),
              title: Text(trend),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectSuggestion(trend),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPersonCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ListTile(
        onTap: () => _showUserProfile(user),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            user.name[0],
            style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.name,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${user.course} • ${user.year}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  List<String> _getPeopleSearchTrends() {
    return [
      'Computer Science students',
      'Study groups',
      'Engineering majors',
      'International students',
      'Final year students',
    ];
  }

  Widget _buildEventsDiscoverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover Events',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildQuickActionCard(
            'This Week',
            'Events happening in the next 7 days',
            Icons.calendar_today,
            Colors.blue,
            () => _selectSuggestion('events this week'),
          ),

          _buildQuickActionCard(
            'Society Events',
            'Events from societies you\'ve joined',
            Icons.groups,
            AppColors.societyColor,
            () => _selectSuggestion('society events'),
          ),

          _buildQuickActionCard(
            'Academic Events',
            'Lectures, workshops, and study sessions',
            Icons.school,
            AppColors.personalColor,
            () => _selectSuggestion('academic events'),
          ),

          _buildQuickActionCard(
            'Social Events',
            'Parties, meetups, and social gatherings',
            Icons.celebration,
            AppColors.socialColor,
            () => _selectSuggestion('social events'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Popular Event Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...['Networking events', 'Tech talks', 'Study sessions', 'Sports events', 'Career fairs'].map((trend) =>
            ListTile(
              leading: const Icon(Icons.trending_up, color: AppColors.primary),
              title: Text(trend),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectSuggestion(trend),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSocietiesDiscoverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover Societies',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildQuickActionCard(
            'Recommended',
            'Societies based on your interests and courses',
            Icons.recommend,
            AppColors.societyColor,
            () => _selectSuggestion('recommended societies'),
          ),

          _buildQuickActionCard(
            'Most Active',
            'Societies with high engagement and events',
            Icons.trending_up,
            Colors.orange,
            () => _selectSuggestion('active societies'),
          ),

          _buildQuickActionCard(
            'Tech & Programming',
            'Technology and coding focused societies',
            Icons.computer,
            Colors.blue,
            () => _selectSuggestion('programming societies'),
          ),

          _buildQuickActionCard(
            'Sports & Fitness',
            'Athletic and recreational societies',
            Icons.sports,
            Colors.green,
            () => _selectSuggestion('sports societies'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Popular Society Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...['Programming Society', 'Student Government', 'Photography Club', 'Debate Society', 'Gaming Society'].map((trend) =>
            ListTile(
              leading: const Icon(Icons.trending_up, color: AppColors.primary),
              title: Text(trend),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectSuggestion(trend),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsDiscoverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover Locations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildQuickActionCard(
            'Study Spaces',
            'Libraries, quiet areas, and study rooms',
            Icons.menu_book,
            Colors.blue,
            () => _selectSuggestion('study spaces'),
          ),

          _buildQuickActionCard(
            'Food & Dining',
            'Cafeterias, cafes, and food courts',
            Icons.restaurant,
            Colors.orange,
            () => _selectSuggestion('dining options'),
          ),

          _buildQuickActionCard(
            'Recreation',
            'Gyms, sports facilities, and common areas',
            Icons.fitness_center,
            Colors.green,
            () => _selectSuggestion('recreation facilities'),
          ),

          _buildQuickActionCard(
            'Academic Buildings',
            'Lecture halls, labs, and department buildings',
            Icons.business,
            Colors.purple,
            () => _selectSuggestion('academic buildings'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Popular Location Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...['Main Library', 'Engineering Building', 'Student Center', 'Computer Labs', 'Study Rooms'].map((trend) =>
            ListTile(
              leading: const Icon(Icons.trending_up, color: AppColors.primary),
              title: Text(trend),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectSuggestion(trend),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesDiscoverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover Courses',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildQuickActionCard(
            'My Courses',
            'Courses you\'re currently enrolled in',
            Icons.book,
            AppColors.personalColor,
            () => _selectSuggestion('my courses'),
          ),

          _buildQuickActionCard(
            'Popular Electives',
            'Most enrolled elective courses',
            Icons.star,
            Colors.yellow[700]!,
            () => _selectSuggestion('popular electives'),
          ),

          _buildQuickActionCard(
            'Prerequisites',
            'Find prerequisite information for courses',
            Icons.arrow_forward,
            Colors.blue,
            () => _selectSuggestion('course prerequisites'),
          ),

          _buildQuickActionCard(
            'Course Reviews',
            'Student reviews and ratings for courses',
            Icons.rate_review,
            Colors.green,
            () => _selectSuggestion('course reviews'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Popular Course Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...['Computer Science', 'Mathematics', 'Engineering', 'Business', 'Design'].map((trend) =>
            ListTile(
              leading: const Icon(Icons.trending_up, color: AppColors.primary),
              title: Text(trend),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectSuggestion(trend),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
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
          style: TextStyle(fontWeight: FontWeight.bold),
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term or adjust your filters',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              foregroundColor: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          style: TextStyle(
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            if (result.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                result.description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        final user = result.data['user'] as User;
        final friendshipStatus = _getFriendshipStatus(user);

        Widget avatarWidget = result.imageUrl != null
            ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(result.imageUrl!),
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  result.title.isNotEmpty ? result.title[0] : '?',
                  style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold),
                ),
              );

        // Add friend status badge
        if (friendshipStatus != FriendshipStatus.self) {
          avatarWidget = Stack(
            children: [
              avatarWidget,
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _getFriendshipStatusColor(friendshipStatus),
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                  ),
                  child: Icon(
                    _getFriendshipStatusIcon(friendshipStatus),
                    size: 8,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ],
          );
        }

        return avatarWidget;

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
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: UserProfileCard(
            user: user,
            onClose: () => Navigator.pop(context),
          ),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  foregroundColor: Theme.of(context).colorScheme.surface,
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${society.category} • ${society.memberCount} members',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  foregroundColor: Theme.of(context).colorScheme.surface,
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${location.building} • ${location.type.toString().split('.').last}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      foregroundColor: Theme.of(context).colorScheme.surface,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(courseData['students'] as Set).length} students • ${(courseData['events'] as List).length} events',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      foregroundColor: Theme.of(context).colorScheme.surface,
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
                  foregroundColor: Theme.of(context).colorScheme.surface,
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

  FriendshipStatus _getFriendshipStatus(User user) {
    final currentUser = _demoData.currentUser;

    if (user.id == currentUser.id) {
      return FriendshipStatus.self;
    } else if (_demoData.areFriends(currentUser.id, user.id)) {
      return FriendshipStatus.friend;
    } else {
      // Check for pending requests
      final sentRequests = _demoData.getSentFriendRequests(currentUser.id);
      final receivedRequests = _demoData.getPendingFriendRequests(currentUser.id);

      if (sentRequests.any((r) => r.receiverId == user.id)) {
        return FriendshipStatus.requestSent;
      } else if (receivedRequests.any((r) => r.senderId == user.id)) {
        return FriendshipStatus.requestReceived;
      } else {
        return FriendshipStatus.notFriend;
      }
    }
  }

  Color _getFriendshipStatusColor(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.friend:
        return Colors.green;
      case FriendshipStatus.requestSent:
        return Colors.orange;
      case FriendshipStatus.requestReceived:
        return Colors.blue;
      case FriendshipStatus.notFriend:
        return Colors.grey;
      case FriendshipStatus.self:
        return Colors.purple;
    }
  }

  IconData _getFriendshipStatusIcon(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.friend:
        return Icons.check;
      case FriendshipStatus.requestSent:
        return Icons.schedule;
      case FriendshipStatus.requestReceived:
        return Icons.person_add;
      case FriendshipStatus.notFriend:
        return Icons.person_add_alt;
      case FriendshipStatus.self:
        return Icons.person;
    }
  }
}
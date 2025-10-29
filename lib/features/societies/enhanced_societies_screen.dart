import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/tour_flows.dart';
import '../../core/services/app_state.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/event_relationship_service.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/enhanced_event_card.dart';
import 'society_detail_screen.dart';

class EnhancedSocietiesScreen extends StatefulWidget {
  final int? initialTabIndex;

  const EnhancedSocietiesScreen({
    super.key,
    this.initialTabIndex,
  });

  @override
  State<EnhancedSocietiesScreen> createState() => _EnhancedSocietiesScreenState();
}

class _EnhancedSocietiesScreenState extends State<EnhancedSocietiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  EventTimeFilter _selectedEventTimeFilter = EventTimeFilter.upcoming;

  final DemoDataManager _demoData = DemoDataManager.instance;
  final CalendarService _calendarService = CalendarService();
  final EventRelationshipService _eventRelationshipService = EventRelationshipService();
  // Services are available but not directly used in this screen currently
  // final FriendshipService _friendshipService = FriendshipService();

  bool _isInitialized = false;

  final List<String> _categories = [
    'All', 'Technology', 'Creative', 'Sports', 'Cultural', 'Business', 'Academic'
  ];

  @override
  void initState() {
    super.initState();

    // Check for pending AppState parameters FIRST
    final appState = Provider.of<AppState>(context, listen: false);
    final pendingParams = appState.consumeSocietiesParams();

    int initialTabIndex;
    if (pendingParams?.initialTabIndex != null) {
      print('🏛️ Societies: Found pending params - tab: ${pendingParams!.initialTabIndex}');
      initialTabIndex = pendingParams.initialTabIndex!;
    } else {
      print('🏛️ Societies: No pending params, using widget param - tab: ${widget.initialTabIndex}');
      initialTabIndex = widget.initialTabIndex ?? 0;
    }

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialTabIndex,
    );
    _initializeData();

    // Listen for society membership changes
    _demoData.societyMembershipNotifier.addListener(_onMembershipChanged);

    // Listen for event relationship changes
    _eventRelationshipService.relationshipChangeNotifier.addListener(_onEventRelationshipGlobalChange);
  }
  
  void _onMembershipChanged() {
    if (mounted) {
      setState(() {}); // Refresh UI when membership changes
    }
  }
  
  void _onEventRelationshipGlobalChange() {
    if (mounted) {
      setState(() {}); // Refresh UI when event relationships change globally
    }
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _demoData.enhancedEvents; // Trigger EventV2 initialization
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for pending AppState parameters every time the widget builds
    final appState = Provider.of<AppState>(context, listen: false);
    final pendingParams = appState.consumeSocietiesParams();

    if (pendingParams?.initialTabIndex != null) {
      print('🏛️ Societies: Found pending params in build() - tab: ${pendingParams!.initialTabIndex}');

      // Update tab controller with the new tab index
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != pendingParams.initialTabIndex) {
          _tabController.animateTo(pendingParams.initialTabIndex!);
        }
      });
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          body: Column(
            children: [
              Container(
                key: TourKeys.societiesHeaderKey,
                child: _buildHeader(appState),
              ),
              Container(
                key: TourKeys.societiesSearchKey,
                child: _buildSearchAndFilter(appState),
              ),
              Container(
                key: TourKeys.societiesTabsKey,
                child: _buildTabBar(appState),
              ),
              Expanded(
                key: TourKeys.societiesCardsKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMySocietiesTab(appState),
                    _buildDiscoverTab(appState),
                    _buildEventsTab(appState),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppState appState) {
    final joinedSocieties = appState.joinedSocieties;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: appState.isTempStyleEnabled
              ? [AppColors.primaryDark, AppColors.primaryDark] // Option 3: Solid dark blue
              : [AppColors.societyColor, AppColors.societyColor.withValues(alpha: 0.8)], // Original green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Societies',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    joinedSocieties.isEmpty 
                        ? 'Discover your community at UTS'
                        : 'Your campus community awaits',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: () => _showQRScanner(),
              ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }


  Widget _buildSearchAndFilter(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search societies...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), // Match calendar cards
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppColors.getAdaptiveSocietyColor(appState.isTempStyleEnabled).withValues(alpha: 0.2),
                    checkmarkColor: AppColors.getAdaptiveSocietyColor(appState.isTempStyleEnabled),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppState appState) {
    // In temp style mode, use primary (lighter blue, same as create event button) for consistency
    final tabColor = appState.isTempStyleEnabled
        ? AppColors.primary
        : AppColors.societyColor;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: tabColor,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: tabColor,
        tabs: const [
          Tab(text: 'My Societies'),
          Tab(text: 'Discover'),
          Tab(text: 'Events'),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(AppState appState) {
    final filteredSocieties = _getFilteredSocieties();
    
    if (filteredSocieties.isEmpty) {
      return const Center(
        child: Text('No societies found matching your criteria'),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Browse All Societies Grid Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                // Section Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Browse All Societies',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Grid of Society Cards
                ...List.generate((filteredSocieties.length / 2).ceil(), (rowIndex) {
                  final startIndex = rowIndex * 2;
                  final endIndex = (startIndex + 2).clamp(0, filteredSocieties.length);
                  final rowSocieties = filteredSocieties.sublist(startIndex, endIndex);
                  
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ...rowSocieties.map((society) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: rowSocieties.indexOf(society) == 0 && rowSocieties.length > 1 ? 4 : 0,
                              left: rowSocieties.indexOf(society) == 1 ? 4 : 0,
                            ),
                            child: _buildFigmaDiscoverCard(society, appState),
                          ),
                        )),
                        // Add empty expanded widget if odd number of societies in last row
                        if (rowSocieties.length == 1) const Expanded(child: SizedBox()),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMySocietiesTab(AppState appState) {
    final allJoinedSocieties = appState.joinedSocieties;
    final filteredJoinedSocieties = _getFilteredJoinedSocieties();
    
    // Show empty state if no societies joined at all
    if (allJoinedSocieties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No societies joined yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore the Discover tab to find societies that match your interests!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getAdaptiveSocietyColor(appState.isTempStyleEnabled),
                foregroundColor: Colors.white,
              ),
              child: const Text('Discover Societies'),
            ),
          ],
        ),
      );
    }
    
    // Show "no results" if there are joined societies but none match the filter
    if (filteredJoinedSocieties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No societies in this category' : 'No societies found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Try selecting a different category or clear the filter.'
                  : 'Try adjusting your search terms or clear the filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16), // Match Discover tab padding
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _searchQuery.isEmpty && _selectedCategory == 'All'
                          ? 'Your Societies'
                          : 'Filtered Societies (${filteredJoinedSocieties.length})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        height: 1.33,
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 8),

            // Society List with proper spacing
            ...filteredJoinedSocieties.map((society) => Padding(
              padding: const EdgeInsets.only(bottom: 12), // Add spacing between cards
              child: _buildFigmaYourSocietyCard(society, appState),
            )).toList(),

            // Add bottom padding for last item
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab(AppState appState) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final currentUser = appState.currentUser;
    final filteredEvents = _getFilteredEvents();

    // Get all society events regardless of filters to check if user has any society events
    final allSocietyEvents = _demoData.enhancedEventsSync.where((event) =>
      event.societyId != null &&
      event.canUserView(
        currentUser.id,
        userSocietyIds: currentUser.societyIds,
      ) &&
      currentUser.societyIds.contains(event.societyId)
    ).toList();
    
    // Show empty state if no society events at all
    if (allSocietyEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No society events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Join societies to see their events here!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Show "no results" if there are events but none match the filter
    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No events in this category' : 'No events found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Try selecting a different category or clear the filter.'
                  : 'Try adjusting your search terms or clear the filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Time Filter Chips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getEventsHeaderText(filteredEvents.length),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: EventTimeFilter.values.map((filter) {
                  final isSelected = _selectedEventTimeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        EventTypeHelper.getEventTimeFilterDisplayName(filter),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedEventTimeFilter = filter;
                        });
                      },
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      selectedColor: const Color(0xFF4CAF50),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Events list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final event = filteredEvents[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: EnhancedEventCard(
                  event: event,
                  userId: _demoData.currentUser.id,
                  onEventTap: _onEventTap,
                  onRelationshipChanged: _onEventRelationshipChanged,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getEventsHeaderText(int count) {
    switch (_selectedEventTimeFilter) {
      case EventTimeFilter.upcoming:
        return count == 1 ? '1 upcoming event' : '$count upcoming events';
      case EventTimeFilter.past:
        return count == 1 ? '1 past event' : '$count past events';
      case EventTimeFilter.all:
        return count == 1 ? '1 event' : '$count events';
    }
  }

  Widget _buildFigmaDiscoverCard(Society society, AppState appState) {
    return GestureDetector(
      onTap: () => _showSocietyDetails(society),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Match calendar cards
          ),
          shadows: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              width: double.infinity,
              height: 164,
              child: Stack(
                children: [
                  // Background/Image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: society.logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: society.logoUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            errorWidget: (context, url, error) => 
                                _buildSocietyPlaceholder(society),
                          )
                        : _buildSocietyPlaceholder(society),
                  ),
                  
                  // Category Tag
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: ShapeDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                      ),
                      child: Text(
                        society.category,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    society.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Member count and friend info
                  _buildMembershipInfo(society, appState),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'Join now!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 1.50,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFigmaYourSocietyCard(Society society, AppState appState) {
    return InkWell(
      onTap: () => _showSocietyDetails(society),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Society Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: society.logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: society.logoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => 
                          _buildSocietyPlaceholder(society),
                    )
                  : _buildSocietyPlaceholder(society),
            ),
            
            const SizedBox(width: 12),
            
            // Society Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    society.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Member count and friend info
                  _buildMembershipInfo(society, appState),
                  
                  const SizedBox(height: 4),
                  
                  // Tags
                  if (society.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: society.tags.take(2).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: ShapeDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.50,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            height: 1.33,
                          ),
                        ),
                      )).toList(),
                    ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    society.description.length > 50 
                        ? '${society.description.substring(0, 50)}...'
                        : society.description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.67,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDateSection(DateTime date, List<Event> events, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '${date.day}/${date.month}/${date.year}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getAdaptiveSocietyColor(appState.isTempStyleEnabled),
            ),
          ),
        ),
        ...events.map((event) => _buildEventCard(event)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    final society = _demoData.getSocietyById(event.societyId!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: ShapeDecoration(
        color: AppTheme.getCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Match calendar cards
        ),
        shadows: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(8), // Match updated border radius
        child: Row(
          children: [
            // Society Logo with Gradient Overlay and Date
            Container(
              width: 80,
              height: 80,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Match calendar cards
                ),
              ),
              child: Stack(
                children: [
                  // Society Logo Background
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: society?.logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: society!.logoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            errorWidget: (context, url, error) => 
                                _buildSocietyPlaceholder(society),
                          )
                        : _buildSocietyPlaceholder(society ?? Society(
                            id: 'unknown',
                            name: 'Unknown Society',
                            description: '',
                            category: 'Academic',
                            logoUrl: null,
                            memberCount: 0,
                            tags: [],
                            isJoined: false,
                            adminIds: [],
                          )),
                  ),
                  
                  // Black/Grey Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  
                  // Date Details in White Text
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Day Number
                        Text(
                          '${event.startTime.day}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                        
                        // Month
                        Text(
                          _getShortMonthName(event.startTime.month),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        // Time
                        Text(
                          '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Event Details
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      society?.name ?? 'Society Event',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    Text(
                      event.location,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Attendee Count
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${event.attendeeIds.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'attending',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Widget _buildSocietyPlaceholder(Society society) {
    // Create a color based on society category
    final colors = {
      'Technology': Colors.blue,
      'Creative': Colors.purple,
      'Sports': Colors.green,
      'Cultural': Colors.orange,
      'Business': Colors.red,
      'Academic': Colors.indigo,
      'Entertainment': Colors.pink,
    };
    
    final color = colors[society.category] ?? Colors.grey;
    
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              color: color,
              size: 30,
            ),
            const SizedBox(height: 4),
            Text(
              society.name.split(' ').map((word) => word[0]).take(3).join(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getShortMonthName(int month) {
    const months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month];
  }

  List<Society> _getFilteredSocieties() {
    return _demoData.societiesSync.where((society) {
      if (_searchQuery.isNotEmpty && 
          !society.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !society.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      
      if (_selectedCategory != 'All' && society.category != _selectedCategory) {
        return false;
      }
      
      return true;
    }).toList();
  }

  List<Society> _getFilteredJoinedSocieties() {
    return _demoData.joinedSocieties.where((society) {
      if (_searchQuery.isNotEmpty && 
          !society.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !society.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      
      if (_selectedCategory != 'All' && society.category != _selectedCategory) {
        return false;
      }
      
      return true;
    }).toList();
  }

  List<EventV2> _getFilteredEvents() {
    if (!_isInitialized) return [];

    final now = DateTime.now();

    // Get all society events based on time filter
    final allSocietyEvents = _demoData.enhancedEventsSync.where((event) {
      if (event.societyId == null) return false;
      if (!_demoData.currentUser.societyIds.contains(event.societyId)) return false;
      if (!event.canUserView(
        _demoData.currentUser.id,
        userSocietyIds: _demoData.currentUser.societyIds,
      )) return false;

      // Apply time filter
      switch (_selectedEventTimeFilter) {
        case EventTimeFilter.upcoming:
          return event.startTime.isAfter(now);
        case EventTimeFilter.past:
          return event.startTime.isBefore(now);
        case EventTimeFilter.all:
          return true;
      }
    }).toList();
    
    return allSocietyEvents.where((event) {
      // Search in event title and description
      if (_searchQuery.isNotEmpty) {
        final matchesEvent = event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            event.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        // Also search in the society name that organized the event
        bool matchesSociety = false;
        if (event.societyId != null) {
          final society = _demoData.getSocietyById(event.societyId!);
          if (society != null) {
            matchesSociety = society.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }
        }
        
        if (!matchesEvent && !matchesSociety) {
          return false;
        }
      }
      
      // Filter by category if the event's organizing society matches the selected category
      if (_selectedCategory != 'All' && event.societyId != null) {
        final society = _demoData.getSocietyById(event.societyId!);
        if (society != null && society.category != _selectedCategory) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Sort events based on time filter
    if (_selectedEventTimeFilter == EventTimeFilter.past) {
      allSocietyEvents.sort((a, b) => b.startTime.compareTo(a.startTime)); // Most recent first
    } else {
      allSocietyEvents.sort((a, b) => a.startTime.compareTo(b.startTime)); // Soonest first
    }

    return allSocietyEvents;
  }

  void _onEventTap(EventV2 event) {
    // Show detailed event view modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                event.description,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${event.startTime.day}/${event.startTime.month}/${event.startTime.year} at ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              if (event.societyId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.groups, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _demoData.getSocietyById(event.societyId!)?.name ?? 'Unknown Society',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              EnhancedEventCard(
                event: event,
                userId: _demoData.currentUser.id,
                onRelationshipChanged: _onEventRelationshipChanged,
                showFullDetails: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onEventRelationshipChanged(EventV2 event, EventRelationship newRelationship) {
    // Refresh the UI to show updated relationship status
    setState(() {
      // The state will be automatically updated by the EnhancedEventCard
      // This setState triggers a rebuild to refresh any other UI elements
    });
  }


  Widget _buildMembershipInfo(Society society, AppState appState) {
    final currentUserFriends = _demoData.getFriendsForUser(_demoData.currentUser.id);
    final friendsInSociety = currentUserFriends.where((friend) => society.memberIds.contains(friend.id)).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${society.memberIds.length} members',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            height: 1.67,
          ),
        ),
        if (friendsInSociety.isNotEmpty)
          Text(
            '${friendsInSociety.length} friend${friendsInSociety.length > 1 ? 's' : ''} ${friendsInSociety.length > 1 ? 'are' : 'is'} a member',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 10,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              height: 1.67,
            ),
          ),
        const SizedBox(height: 4),
        // Membership fee badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: society.membershipFee == null
                ? Colors.green.withOpacity(0.1)
                : AppColors.getAdaptiveSocietyColor(appState.isTempStyleEnabled).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: society.membershipFee == null
                  ? Colors.green
                  : AppColors.getAdaptiveSocietyColor(appState.isTempStyleEnabled),
              width: 1,
            ),
          ),
          child: Text(
            society.membershipFee == null
                ? 'FREE'
                : '\$${society.membershipFee!.toStringAsFixed(0)}',
            style: TextStyle(
              color: society.membershipFee == null
                  ? Colors.green[700]
                  : AppColors.getAdaptiveSocietyColor(appState.isTempStyleEnabled),
              fontSize: 10,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<User> _getFriendsInSociety(Society society, List<User> friends) {
    // Updated to use actual memberIds
    return friends.where((friend) => society.memberIds.contains(friend.id)).toList();
  }

  List<User> _getFriendsAttendingEvent(Event event) {
    final friends = _demoData.getFriendsForUser(_demoData.currentUser.id);
    return friends.where((friend) => event.attendeeIds.contains(friend.id)).toList();
  }

  // Event Handlers
  void _showQRScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR scanner for society invites would open here')),
    );
  }

  void _joinSociety(Society society) async {
    // Show loading dialog
    UIHelpers.showLoadingDialog(context, message: 'Joining ${society.name}...');

    try {
      final success = await _calendarService.joinSocietyWithCalendarIntegration(
        _demoData.currentUser.id,
        society.id,
      );

      // Hide loading dialog
      Navigator.of(context).pop();

      if (success && mounted) {
        UIHelpers.showSnackBar(
          context,
          'Joined ${society.name}! Events added to your calendar.',
          type: SnackBarType.success,
        );
        setState(() {}); // Refresh UI
      }
    } catch (e) {
      // Hide loading dialog
      Navigator.of(context).pop();

      UIHelpers.showSnackBar(
        context,
        'Failed to join society: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  void _leaveSociety(Society society) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Society'),
        content: Text('Are you sure you want to leave ${society.name}? This will remove all society events from your calendar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      UIHelpers.showLoadingDialog(context, message: 'Leaving ${society.name}...');

      try {
        final success = await _calendarService.leaveSocietyWithCalendarCleanup(
          _demoData.currentUser.id,
          society.id,
        );

        // Hide loading dialog
        Navigator.of(context).pop();

        if (success && mounted) {
          UIHelpers.showSnackBar(
            context,
            'Left ${society.name}. Events removed from calendar.',
            type: SnackBarType.success,
          );
          setState(() {}); // Refresh UI
        }
      } catch (e) {
        // Hide loading dialog
        Navigator.of(context).pop();

        UIHelpers.showSnackBar(
          context,
          'Failed to leave society: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _showSocietyDetails(Society society) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SocietyDetailScreen(society: society),
      ),
    );
  }

  void _showSocietyEvents(Society society) {
    final societyEvents = _demoData.eventsSync.where((event) => event.societyId == society.id).toList();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${society.name} Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: societyEvents.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(societyEvents[index].title),
                      subtitle: Text('${societyEvents[index].startTime.day}/${societyEvents[index].startTime.month} at ${societyEvents[index].startTime.hour}:${societyEvents[index].startTime.minute.toString().padLeft(2, '0')}'),
                      trailing: Icon(
                        societyEvents[index].attendeeIds.contains(_demoData.currentUser.id) 
                          ? Icons.check_circle 
                          : Icons.circle_outlined,
                        color: Colors.green,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${event.title} details would open here')),
    );
  }

  void _showNotificationSettings(Society society) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${society.name} Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Notification preferences for this society:'),
            SizedBox(height: 12),
            Text('• Event announcements'),
            Text('• Meeting reminders'),
            Text('• Society updates'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _demoData.societyMembershipNotifier.removeListener(_onMembershipChanged);
    _eventRelationshipService.relationshipChangeNotifier.removeListener(_onEventRelationshipGlobalChange);
    super.dispose();
  }
}
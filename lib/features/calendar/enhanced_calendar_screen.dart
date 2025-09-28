import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/event_colors.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/friendship_service.dart';
import '../../core/services/event_relationship_service.dart';
import '../../core/utils/event_display_properties.dart';
import '../../shared/models/event.dart';
import '../../shared/models/event_v2.dart';
import '../../shared/models/event_enums.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/event_cards.dart';
import '../../shared/widgets/enhanced_event_card.dart';
import '../timetable/timetable_management_screen.dart';

class EnhancedCalendarScreen extends StatefulWidget {
  final CalendarFilter? initialFilter;
  final CalendarView? initialView;
  final bool? initialUseTimetableView;

  const EnhancedCalendarScreen({
    super.key,
    this.initialFilter,
    this.initialView,
    this.initialUseTimetableView,
  });

  @override
  State<EnhancedCalendarScreen> createState() => _EnhancedCalendarScreenState();
}

enum CalendarView { day, threeDays, week, month }

class _EnhancedCalendarScreenState extends State<EnhancedCalendarScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ScrollController _timetableScrollController;

  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();
  DateTime? _lastScrolledDate; // Track the last date we scrolled for
  late CalendarFilter selectedFilter;
  late CalendarView currentView;

  // Toggle states for UI elements - visible by default for easier access
  bool _showViewSelector = true;
  late bool _useTimetableView;
  bool _showFriendsSchedule = false; // Friends schedule collapsed by default

  // Advanced Filter states
  bool showAdvancedFilters = false;
  Map<String, bool> relationshipFilters = {
    'Attending': true,
    'Organizing': true,
    'Invited': false,
    'Interested': false,
  };
  bool includeDiscoverableEvents = true;
  bool showFriendOverlay = false;
  bool showConflictWarnings = true;
  
  final DemoDataManager _demoData = DemoDataManager.instance;
  final CalendarService _calendarService = CalendarService();
  final FriendshipService _friendshipService = FriendshipService();
  final EventRelationshipService _eventRelationshipService = EventRelationshipService();
  
  bool _isInitialized = false;

  // Initialize calendar data asynchronously
  Future<void> _initializeCalendarData() async {
    try {
      // Get current user from AppState
      final appState = context.read<AppState>();
      final currentUser = appState.currentUser;

      print('📅 Calendar: Initializing for user: ${currentUser.name} (${currentUser.id})');

      // Ensure demo data is loaded
      await _demoData.enhancedEvents;
      // Ensure calendar service is initialized with current user
      await _calendarService.getEnhancedUnifiedCalendar(currentUser.id);

      setState(() {
        _isInitialized = true;
      });
      print('📅 Calendar: Data initialization completed - ${_demoData.enhancedEventsSync.length} events loaded');

      // Force a rebuild and autoscroll recalculation now that data is fully loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // Trigger rebuild with fully loaded data
          });
        }
      });
    } catch (e) {
      print('📅 Calendar: Error during initialization: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize with widget parameters or defaults first
    selectedFilter = widget.initialFilter ?? CalendarFilter.mySchedule;
    currentView = widget.initialView ?? CalendarView.day;
    _useTimetableView = widget.initialUseTimetableView ?? false;

    print('📅 Calendar: initState - filter: $selectedFilter, view: $currentView, timetable: $_useTimetableView');

    // Ensure data is loaded asynchronously
    _initializeCalendarData();

    _tabController = TabController(length: 6, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _timetableScrollController = ScrollController();
    _initializeData();

    // Listen for event relationship changes to refresh calendar
    _eventRelationshipService.relationshipChangeNotifier.addListener(_onEventRelationshipChange);

    // Listen for society membership changes to refresh calendar
    _demoData.societyMembershipNotifier.addListener(_onSocietyMembershipChanged);
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _demoData.enhancedEvents; // Trigger EventV2 initialization
      // Initialize the calendar service with enhanced unified calendar
      await _calendarService.getEnhancedUnifiedCalendar(_demoData.currentUser.id);
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }
  
  void _onEventRelationshipChange() {
    if (mounted && _isInitialized) {
      _refreshCalendarData();
    }
  }
  
  void _onSocietyMembershipChanged() {
    if (mounted && _isInitialized) {
      _refreshCalendarData();
    }
  }
  
  void _refreshCalendarData({bool clearCache = true}) async {
    print('🎯 DEBUG (Calendar): Refreshing calendar data (clearCache: $clearCache)');
    
    if (clearCache) {
      // Clear calendar service cache to ensure fresh data from JSON
      await _calendarService.refreshCalendarData();
      print('🎯 DEBUG (Calendar): Cache cleared and data reloaded from JSON');
    }
    
    if (mounted) {
      setState(() {
        // Refresh the calendar when event relationships or society membership change
        // This will cause a rebuild and re-fetch events with updated data
      });
      print('🎯 DEBUG (Calendar): UI refreshed with setState');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for pending AppState parameters every time the widget builds
    // This handles navigation from quick actions when screen is already initialized
    final appState = Provider.of<AppState>(context, listen: false);
    final pendingParams = appState.consumeCalendarParams();

    if (pendingParams != null) {
      print('📅 Calendar: Found pending params in build() - filter: ${pendingParams.initialFilter}, view: ${pendingParams.initialView}, timetable: ${pendingParams.initialUseTimetableView}');

      // Update state with the new parameters
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedFilter = pendingParams.initialFilter ?? selectedFilter;
            currentView = pendingParams.initialView ?? currentView;
            _useTimetableView = pendingParams.initialUseTimetableView ?? _useTimetableView;
          });
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
        final currentUser = appState.currentUser;

        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          body: Column(
            children: [
              _buildHeader(),
              if (_showViewSelector) _buildViewSelector(),
              Expanded(child: _buildCalendarView(currentUser)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateEventDialog(currentUser),
            backgroundColor: AppColors.personalColor,
            foregroundColor: AppTheme.getButtonTextColor(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final appState = Provider.of<AppState>(context, listen: true);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: appState.isTempStyleEnabled
              ? [AppColors.primaryDark, AppColors.primaryDark] // Option 3: Solid dark blue
              : [AppColors.personalColor, AppColors.personalColor.withValues(alpha: 0.8)], // Original blue
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uni Life',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Stay organized with your academic schedule',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_calendar, 
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TimetableManagementScreen(initialTabIndex: 0),
                      ),
                    ),
                    tooltip: 'Manage Timetable',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: _showViewSelector ? Colors.yellow : Colors.white,
                    ),
                    onPressed: _toggleViewSelector,
                    tooltip: 'Filters & View Options',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _useTimetableView ? Icons.view_agenda : Icons.schedule, 
                      color: _useTimetableView ? Colors.yellow : Colors.white,
                    ),
                    onPressed: _toggleTimetableView,
                    tooltip: _useTimetableView ? 'Switch to Card View' : 'Switch to Timetable View',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Simplified View selector - only Day, Week, Month
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildViewButton('Day', CalendarView.day),
                _buildViewButton('Week', CalendarView.week),
                _buildViewButton('Month', CalendarView.month),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Simplified primary filters only
          _buildSimplifiedFilters(),
        ],
      ),
    );
  }

  Widget _buildViewButton(String title, CalendarView view) {
    final isSelected = currentView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentView = view;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.personalColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.getTextColor(context),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String title, CalendarFilter filter) {
    final isSelected = selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _getFilterColor(filter) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.getTextColor(context),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 10, // Slightly smaller font to fit 6 buttons
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryFilters() {
    final primaryFilters = [
      {'name': 'My Schedule', 'icon': '📅', 'filter': CalendarFilter.mySchedule},
      {'name': 'Academic', 'icon': '📚', 'filter': CalendarFilter.academic},
      {'name': 'Social', 'icon': '🎉', 'filter': CalendarFilter.social},
      {'name': 'Societies', 'icon': '🏛️', 'filter': CalendarFilter.societies},
      {'name': 'All', 'icon': '🌐', 'filter': CalendarFilter.allEvents},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Primary Filters',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: primaryFilters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = primaryFilters[index];
              final isSelected = selectedFilter == filter['filter'];
              return _buildPrimaryFilterChip(filter, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryFilterChip(Map<String, dynamic> filter, bool isSelected) {
    Color getColor() {
      switch (filter['filter'] as CalendarFilter) {
        case CalendarFilter.academic:
          return AppColors.personalColor;
        case CalendarFilter.mySchedule:
        case CalendarFilter.allEvents:
          return AppColors.homeColor;
        case CalendarFilter.societies:
          return AppColors.societyColor;
        case CalendarFilter.social:
          return AppColors.socialColor;
        default:
          return AppColors.homeColor;
      }
    }

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = filter['filter'] as CalendarFilter),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? getColor() : AppTheme.getInputBackgroundColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? getColor() : AppTheme.getBorderColor(context),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              filter['icon'] as String,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              filter['name'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.getTextColor(context),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedFilters() {
    final primaryFilters = [
      {'name': 'My Schedule', 'icon': '📅', 'filter': CalendarFilter.mySchedule},
      {'name': 'Academic', 'icon': '📚', 'filter': CalendarFilter.academic},
      {'name': 'Social', 'icon': '🎉', 'filter': CalendarFilter.social},
      {'name': 'Societies', 'icon': '🏛️', 'filter': CalendarFilter.societies},
      {'name': 'All', 'icon': '🌐', 'filter': CalendarFilter.allEvents},
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: primaryFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = primaryFilters[index];
          final isSelected = selectedFilter == filter['filter'];
          return _buildPrimaryFilterChip(filter, isSelected);
        },
      ),
    );
  }

  Widget _buildAdvancedFilterToggle() {
    final activeCount = _getActiveAdvancedFilterCount();
    final hasActiveFilters = activeCount > 0;

    return Row(
      children: [
        Text(
          'Advanced Filters',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hasActiveFilters && !showAdvancedFilters) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.homeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$activeCount active',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.homeColor,
              ),
            ),
          ),
        ],
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: hasActiveFilters
                ? AppColors.homeColor.withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasActiveFilters
                  ? AppColors.homeColor.withOpacity(0.3)
                  : Colors.grey[300]!,
            ),
          ),
          child: IconButton(
            icon: Icon(
              showAdvancedFilters ? Icons.remove : Icons.add,
              color: hasActiveFilters ? AppColors.homeColor : AppTheme.getSecondaryTextColor(context),
              size: 20,
            ),
            onPressed: () => setState(() => showAdvancedFilters = !showAdvancedFilters),
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  int _getActiveAdvancedFilterCount() {
    int count = 0;

    // Count active relationship filters (excluding defaults)
    final defaultRelationships = {
      'Attending': true,
      'Organizing': true,
      'Invited': false,
      'Interested': false
    };
    relationshipFilters.forEach((key, value) {
      if (value != defaultRelationships[key]) count++;
    });

    // Check discovery control (default is true)
    if (!includeDiscoverableEvents) count++;

    // Check visual enhancements (defaults: Friend Overlay false, Conflict Warnings true)
    if (showFriendOverlay) count++;
    if (!showConflictWarnings) count++;

    return count;
  }

  Widget _buildAdvancedFilterMenu() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.homeColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  color: AppColors.homeColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Advanced Options',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.homeColor,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetAdvancedFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Reset All',
                    style: TextStyle(
                      color: AppColors.homeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Relationship Filters
                _buildRelationshipFilters(),
                const SizedBox(height: 12),

                // Discovery Control
                _buildDiscoveryControl(),
                const SizedBox(height: 12),

                // Visual Enhancements
                _buildVisualEnhancements(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relationship Filters',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.homeColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select event relationships to include',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.getSecondaryTextColor(context),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        ...relationshipFilters.entries.map((entry) =>
          _buildCheckboxRow(
            entry.key,
            entry.value,
            (value) => setState(() => relationshipFilters[entry.key] = value ?? false),
          ),
        ).toList(),
      ],
    );
  }

  Widget _buildCheckboxRow(String title, bool value, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.homeColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discovery Control',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.homeColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Show discoverable events in Social & Societies',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.getSecondaryTextColor(context),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: includeDiscoverableEvents
                ? AppColors.socialColor.withOpacity(0.1)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: includeDiscoverableEvents
                  ? AppColors.socialColor
                  : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Switch(
                value: includeDiscoverableEvents,
                onChanged: (value) => setState(() => includeDiscoverableEvents = value),
                activeColor: AppColors.socialColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Include Discoverable Events',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: includeDiscoverableEvents
                        ? AppColors.socialColor
                        : Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualEnhancements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual Enhancements',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.homeColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Additional visual features for calendar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.getSecondaryTextColor(context),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),

        // Friend Overlay Toggle
        _buildVisualToggle(
          'Friend Overlay',
          'Show friend attendance indicators',
          showFriendOverlay,
          (value) => setState(() => showFriendOverlay = value),
          Icons.people,
          AppColors.socialColor,
        ),
        const SizedBox(height: 8),

        // Conflict Warnings Toggle
        _buildVisualToggle(
          'Conflict Warnings',
          'Highlight scheduling conflicts',
          showConflictWarnings,
          (value) => setState(() => showConflictWarnings = value),
          Icons.warning,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildVisualToggle(String title, String description, bool value,
      Function(bool) onChanged, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : AppTheme.getInputBackgroundColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value ? color : AppTheme.getBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? color : AppTheme.getSecondaryTextColor(context),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value ? color : AppTheme.getSecondaryTextColor(context),
                fontSize: 12,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  void _resetAdvancedFilters() {
    setState(() {
      // Reset relationship filters to defaults
      relationshipFilters = {
        'Attending': true,
        'Organizing': true,
        'Invited': false,
        'Interested': false,
      };

      // Reset discovery control to default
      includeDiscoverableEvents = true;

      // Reset visual enhancements to defaults
      showFriendOverlay = false;
      showConflictWarnings = true;
    });
  }

  Widget _buildDateCard(DateTime date) {
    final isSelected = date.day == selectedDate.day && 
                     date.month == selectedDate.month && 
                     date.year == selectedDate.year;
    final isToday = date.day == DateTime.now().day && 
                   date.month == DateTime.now().month && 
                   date.year == DateTime.now().year;
    
    // Get event count for this date
    final dayEvents = _calendarService.getEnhancedUnifiedCalendarSync(
      _demoData.currentUser.id,
      startDate: DateTime(date.year, date.month, date.day),
      endDate: DateTime(date.year, date.month, date.day + 1),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected ? AppColors.personalColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              selectedDate = date;
            });
          },
          child: Container(
            width: 70,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected 
                  ? Border.all(color: AppColors.personalColor, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(date),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                if (dayEvents.isNotEmpty)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.personalColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCalendarView(User currentUser) {
    switch (currentView) {
      case CalendarView.day:
        return _buildDayView(currentUser);
      case CalendarView.threeDays:
        return _buildThreeDaysView(currentUser);
      case CalendarView.week:
        return _buildWeekView(currentUser);
      case CalendarView.month:
        return _buildMonthView(currentUser);
    }
  }

  Widget _buildDayView(User currentUser) {
    return Column(
      children: [
        _buildDateNavigation(),
        Expanded(child: _useTimetableView ? _buildDayTimetable(currentUser) : _buildDayContent(currentUser)),
      ],
    );
  }

  Widget _buildThreeDaysView(User currentUser) {
    return Column(
      children: [
        _buildDateNavigation(),
        Expanded(child: _buildMultiDayContent(3, currentUser)),
      ],
    );
  }

  Widget _buildWeekView(User currentUser) {
    return Column(
      children: [
        _buildDateNavigation(),
        Expanded(child: _buildMultiDayContent(7, currentUser)),
      ],
    );
  }

  Widget _buildMonthView(User currentUser) {
    return Column(
      children: [
        _buildMonthNavigation(),
        Expanded(child: _buildMonthContent(currentUser)),
      ],
    );
  }

  Widget _buildDateNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateDate(-1),
          ),
          GestureDetector(
            onTap: () => _selectDate(),
            child: Text(
              DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateMonth(-1),
          ),
          GestureDetector(
            onTap: () => _selectMonth(),
            child: Text(
              DateFormat('MMMM yyyy').format(currentMonth),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContent(User currentUser) {
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get events based on selected filter using EventV2 with advanced filters
    List<EventV2> events = _calendarService.getEventsByCalendarFilterSync(
      currentUser.id,
      selectedFilter,
      startDate: startOfDay,
      endDate: endOfDay,
      relationshipFilters: relationshipFilters,
      includeDiscoverable: includeDiscoverableEvents,
    );

    if (events.isEmpty) {
      return _buildEmptyDay();
    }

    final overlayData = _calendarService.getEventsWithFriendOverlaySync(currentUser.id, selectedDate);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (selectedFilter == CalendarFilter.mySchedule || selectedFilter == CalendarFilter.academic)
          _buildFriendOverlaySection(overlayData),

        ...events.map((event) => _buildEnhancedEventCard(event, overlayData)).toList(),
      ],
    );
  }

  Widget _buildMultiDayContent(int days, User currentUser) {
    final startDate = days == 3 
        ? selectedDate.subtract(Duration(days: 1))  // Show day before, selected day, and day after
        : _getWeekStart(selectedDate);               // Show full week
    final displayDays = days;
    
    return Column(
      children: [
        // Day headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Spacer for time column alignment only in timetable view
              if (_useTimetableView) const SizedBox(width: 50),
              ...List.generate(displayDays, (index) {
              final date = startDate.add(Duration(days: index));
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              
              // Get event count for this date
              final dayEvents = _calendarService.getUnifiedCalendarSync(
                currentUser.id,
                startDate: DateTime(date.year, date.month, date.day),
                endDate: DateTime(date.year, date.month, date.day + 1),
              );
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.personalColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected 
                          ? Border.all(color: AppColors.personalColor, width: 1)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE').format(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.getSecondaryIconColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.getTextColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (dayEvents.isNotEmpty)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : AppColors.personalColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            })],
          ),
        ),
        
        // Multi-day events content
        Expanded(
          child: _useTimetableView
              ? _buildMultiDayTimetable(startDate, displayDays, currentUser)
              : _buildMultiDayEventsContent(startDate, displayDays, currentUser),
        ),
      ],
    );
  }

  Widget _buildDayTimetable(User currentUser) {
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    // Get events for the day using EventV2 with advanced filters
    List<EventV2> events = _calendarService.getEventsByCalendarFilterSync(
      currentUser.id,
      selectedFilter,
      startDate: startOfDay,
      endDate: endOfDay,
      relationshipFilters: relationshipFilters,
      includeDiscoverable: includeDiscoverableEvents,
    );

    return _buildTimetableGrid([selectedDate], events, 1, false);
  }

  Widget _buildMultiDayTimetable(DateTime startDate, int displayDays, User currentUser) {
    // Show loading indicator if data isn't ready
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading calendar data...'),
          ],
        ),
      );
    }

    // Use exact same event loading logic as _buildMultiDayEventsContent to ensure consistency
    final endDate = startDate.add(Duration(days: displayDays));

    List<EventV2> allEvents = _calendarService.getEventsByCalendarFilterSync(
      currentUser.id,
      selectedFilter,
      startDate: startDate,
      endDate: endDate,
      relationshipFilters: relationshipFilters,
      includeDiscoverable: includeDiscoverableEvents,
    );

    // Debug logging for event count verification
    print('🔍 Timetable view: Loaded ${allEvents.length} events for display and autoscroll');

    final dates = List.generate(displayDays, (index) => startDate.add(Duration(days: index)));
    return _buildTimetableGrid(dates, allEvents, displayDays, true);
  }

  Widget _buildTimetableGrid(List<DateTime> dates, List<EventV2> events, int dayCount, bool hasExternalHeaders) {
    const double hourHeight = 60.0;
    const int startHour = 0;  // Midnight (24-hour view)
    const int endHour = 24;   // End of day
    const int totalHours = endHour - startHour;

    // Check if date has changed
    final currentDateKey = dates.isNotEmpty ? DateFormat('yyyy-MM-dd').format(dates.first) : null;
    final bool dateChanged = _lastScrolledDate == null ||
        (currentDateKey != null && DateFormat('yyyy-MM-dd').format(_lastScrolledDate!) != currentDateKey);

    if (dateChanged && currentDateKey != null) {
      _lastScrolledDate = dates.first;
      print('🎯 Auto-scroll: Date changed to ${DateFormat('MMM dd').format(dates.first)}');

      // Reset scroll controller position immediately when date changes
      if (_timetableScrollController.hasClients) {
        _timetableScrollController.jumpTo(0);
      }
    }

    // Group events by date
    final Map<String, List<EventV2>> eventsByDate = {};
    for (final date in dates) {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      eventsByDate[dateKey] = [];
    }

    for (final event in events) {
      final dateKey = DateFormat('yyyy-MM-dd').format(event.startTime);
      if (eventsByDate.containsKey(dateKey)) {
        eventsByDate[dateKey]!.add(event);
      }
    }

    // Find the earliest event to auto-scroll to - context-aware for single vs multi-day views
    DateTime? earliestEventTime;
    final isMultiDayView = dates.length > 1;

    if (isMultiDayView) {
      // Multi-day view: Find earliest event across ALL visible dates
      if (events.isNotEmpty) {
        earliestEventTime = events
            .map((e) => e.startTime)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        print('🎯 Auto-scroll: Multi-day view (${dates.length} days) - Finding earliest across all dates');
        print('🎯 Auto-scroll: Date range: ${DateFormat('MMM dd').format(dates.first)} to ${DateFormat('MMM dd').format(dates.last)}');
        print('🎯 Auto-scroll: Found ${events.length} total events, earliest: ${DateFormat('MMM dd HH:mm').format(earliestEventTime!)}');

        // Show earliest events for debugging
        final sortedEvents = List<EventV2>.from(events)..sort((a, b) => a.startTime.compareTo(b.startTime));
        for (var i = 0; i < sortedEvents.length && i < 3; i++) {
          final e = sortedEvents[i];
          print('  - ${DateFormat('MMM dd HH:mm').format(e.startTime)}: ${e.title}');
        }
      }
    } else {
      // Single-day view: Use events from the specific selected date only
      final primaryDate = dates.first;
      final primaryDateKey = DateFormat('yyyy-MM-dd').format(primaryDate);
      final primaryDateEvents = eventsByDate[primaryDateKey] ?? [];

      if (primaryDateEvents.isNotEmpty) {
        earliestEventTime = primaryDateEvents
            .map((e) => e.startTime)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        print('🎯 Auto-scroll: Single-day view - Targeting earliest event on ${DateFormat('MMM dd').format(primaryDate)}');
        print('🎯 Auto-scroll: Found ${primaryDateEvents.length} events on selected date');
        final sortedEvents = List<EventV2>.from(primaryDateEvents)..sort((a, b) => a.startTime.compareTo(b.startTime));
        for (var i = 0; i < sortedEvents.length && i < 3; i++) {
          final e = sortedEvents[i];
          print('  - ${DateFormat('MMM dd HH:mm').format(e.startTime)}: ${e.title}');
        }
      } else {
        print('🎯 Auto-scroll: No events found on selected date ${DateFormat('MMM dd').format(primaryDate)}');
      }
    }

    // Schedule auto-scroll only if date changed, we're initializing, and we're in timetable view
    if (earliestEventTime != null && dateChanged && _useTimetableView) {
      // Use multiple frame callbacks to ensure all data is stable
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add a small delay to ensure all data loading is complete
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _useTimetableView) {
            _scrollToEarliestEvent(earliestEventTime!, hourHeight);
          }
        });
      });
    }

    return SingleChildScrollView(
      controller: _timetableScrollController,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Time column
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // Header space - smaller for multi-day views with external headers
                SizedBox(height: hasExternalHeaders ? 8 : 8),
                // Hour labels
                ...List.generate(totalHours, (index) {
                  final hour = startHour + index;
                  return Container(
                    height: hourHeight,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          
          // Day columns
          Expanded(
            child: Row(
              children: dates.map((date) {
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final dayEvents = eventsByDate[dateKey] ?? [];
                final isSelected = _isSameDay(date, selectedDate);
                
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.getSubtleBorderColor(context),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Only show header for single day view (which doesn't have external headers)
                        if (!hasExternalHeaders)
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppTheme.getSubtleBorderColor(context),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        
                        // Timetable grid
                        SizedBox(
                          height: hourHeight * totalHours,
                          child: Stack(
                            children: [
                              // Hour dividers
                              ...List.generate(totalHours, (index) {
                                return Positioned(
                                  top: index * hourHeight,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 1,
                                    color: AppTheme.getSubtleBorderColor(context),
                                  ),
                                );
                              }),
                              
                              // Events
                              ...(() {
                                // Calculate overlaps for this day's events
                                final overlapInfo = _calculateEventOverlaps(dayEvents);
                                return dayEvents.map((event) => _buildTimetableEvent(
                                  event, 
                                  hourHeight, 
                                  startHour, 
                                  dayCount == 1,
                                  overlapInfo[event]!,
                                ));
                              })(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Calculate overlap information for events in a day
  Map<EventV2, Map<String, dynamic>> _calculateEventOverlaps(List<EventV2> dayEvents) {
    final Map<EventV2, Map<String, dynamic>> overlapInfo = {};
    
    // Initialize each event with no overlap
    for (final event in dayEvents) {
      overlapInfo[event] = {
        'columnIndex': 0,
        'totalColumns': 1,
        'overlappingEvents': <EventV2>[],
      };
    }
    
    // Sort events by start time
    final sortedEvents = List<EventV2>.from(dayEvents);
    sortedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Find overlapping events
    for (int i = 0; i < sortedEvents.length; i++) {
      final eventA = sortedEvents[i];
      final overlappingEvents = <EventV2>[eventA];
      
      for (int j = i + 1; j < sortedEvents.length; j++) {
        final eventB = sortedEvents[j];
        
        if (_eventsOverlap(eventA, eventB)) {
          overlappingEvents.add(eventB);
        }
      }
      
      // If we found overlaps, assign column positions
      if (overlappingEvents.length > 1) {
        for (int k = 0; k < overlappingEvents.length; k++) {
          final event = overlappingEvents[k];
          overlapInfo[event] = {
            'columnIndex': k,
            'totalColumns': overlappingEvents.length,
            'overlappingEvents': List<EventV2>.from(overlappingEvents)..remove(event),
          };
        }
      }
    }
    
    return overlapInfo;
  }
  
  /// Check if two events overlap in time
  bool _eventsOverlap(EventV2 eventA, EventV2 eventB) {
    return eventA.startTime.isBefore(eventB.endTime) && eventB.startTime.isBefore(eventA.endTime);
  }

  Widget _buildTimetableEvent(EventV2 event, double hourHeight, int startHour, bool isDetailedView, Map<String, dynamic> overlapInfo) {
    final startTime = event.startTime;
    final endTime = event.endTime;
    final eventDisplayProperties = EventDisplayProperties.fromEventV2(event, _demoData.currentUser.id);
    final attendeeCount = event.attendeeIds.length;
    
    // Calculate position and height
    final startMinutes = (startTime.hour - startHour) * 60 + startTime.minute;
    final durationMinutes = endTime.difference(startTime).inMinutes;
    final top = (startMinutes / 60.0) * hourHeight;
    final height = (durationMinutes / 60.0) * hourHeight;
    
    
    // Create view-appropriate timetable chip
    Widget eventWidget;
    switch (currentView) {
      case CalendarView.day:
        eventWidget = _buildDayTimetableChip(
          event: event,
          height: height,
          isDetailedView: isDetailedView,
          onTap: () => _showEventDetails(event, []),
        );
        break;
      case CalendarView.threeDays:
        eventWidget = _build3DayTimetableChip(
          event: event,
          onTap: () => _showEventDetails(event, []),
        );
        break;
      case CalendarView.week:
        eventWidget = _buildWeekTimetableChip(
          event: event,
          onTap: () => _showEventDetails(event, []),
        );
        break;
      default:
        eventWidget = _buildDayTimetableChip(
          event: event,
          height: height,
          isDetailedView: isDetailedView,
          onTap: () => _showEventDetails(event, []),
        );
    }
    
    // Extract overlap information
    final columnIndex = overlapInfo['columnIndex'] as int;
    final totalColumns = overlapInfo['totalColumns'] as int;
    final hasOverlap = totalColumns > 1;
    
    // Position with appropriate dimensions for each view and handle overlaps
    switch (currentView) {
      case CalendarView.day:
        return Positioned(
          top: top,
          left: 1,
          right: 1,
          height: height.clamp(isDetailedView ? 60.0 : 40.0, double.infinity),
          child: eventWidget,
        );
        
      case CalendarView.threeDays:
        if (hasOverlap && totalColumns == 2) {
          // Side by side for 2 overlapping events - use LayoutBuilder to get available width
          return Positioned(
            top: top,
            left: 1,
            right: 1,
            height: height.clamp(40.0, double.infinity),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columnWidth = (constraints.maxWidth / 2) - 1;
                final leftPosition = columnIndex * (columnWidth + 2);
                return Positioned(
                  left: leftPosition,
                  width: columnWidth,
                  child: eventWidget,
                );
              },
            ),
          );
        } else if (hasOverlap) {
          // Stack with slight offset for 3+ overlapping events
          return Positioned(
            top: top + (columnIndex * 3.0), // 3px offset per overlap
            left: 1 + (columnIndex * 2.0), // 2px horizontal offset
            right: 1,
            height: height.clamp(40.0, double.infinity),
            child: eventWidget,
          );
        } else {
          // No overlap - full width
          return Positioned(
            top: top,
            left: 1,
            right: 1,
            height: height.clamp(40.0, double.infinity),
            child: eventWidget,
          );
        }
        
      case CalendarView.week:
        if (hasOverlap) {
          // Stack with transparency and slight offset
          return Positioned(
            top: top + (columnIndex * 5.0), // 5px offset per overlap
            left: 1,
            right: 1,
            height: height.clamp(40.0, double.infinity),
            child: Opacity(
              opacity: columnIndex == 0 ? 1.0 : 0.7 - (columnIndex * 0.1),
              child: eventWidget,
            ),
          );
        } else {
          // No overlap - full width
          return Positioned(
            top: top,
            left: 1,
            right: 1,
            height: height.clamp(40.0, double.infinity),
            child: eventWidget,
          );
        }
        
      default:
        return Positioned(
          top: top,
          left: 1,
          right: 1,
          height: height.clamp(isDetailedView ? 60.0 : 40.0, double.infinity),
          child: eventWidget,
        );
    }
  }

  Widget _buildMultiDayEventsContent(DateTime startDate, int displayDays, User currentUser) {
    // Get events for the entire date range using EventV2 with filtering
    final endDate = startDate.add(Duration(days: displayDays));
    
    List<EventV2> allEvents = _calendarService.getEventsByCalendarFilterSync(
      currentUser.id,
      selectedFilter,
      startDate: startDate,
      endDate: endDate,
      relationshipFilters: relationshipFilters,
      includeDiscoverable: includeDiscoverableEvents,
    );
    
    // Group events by date
    final Map<String, List<EventV2>> eventsByDate = {};
    for (int i = 0; i < displayDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      eventsByDate[dateKey] = [];
    }
    
    for (final event in allEvents) {
      final dateKey = DateFormat('yyyy-MM-dd').format(event.startTime);
      if (eventsByDate.containsKey(dateKey)) {
        eventsByDate[dateKey]!.add(event);
      }
    }
    
    // Sort events by start time for each day
    for (final dayEvents in eventsByDate.values) {
      dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    
    if (allEvents.isEmpty) {
      return _buildEmptyMultiDay(startDate, displayDays);
    }
    
    // Build horizontal scrollable layout for multi-day view
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(displayDays, (index) {
          final date = startDate.add(Duration(days: index));
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final dayEvents = eventsByDate[dateKey] ?? [];
          final isSelected = _isSameDay(date, selectedDate);
          
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  // Day column
                  Expanded(
                    child: dayEvents.isEmpty
                        ? _buildEmptyDayColumn(date)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: dayEvents.length,
                            itemBuilder: (context, eventIndex) {
                              return _buildCompactEventCard(
                                dayEvents[eventIndex], 
                                isSelected,
                                isMultiDay: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyMultiDay(DateTime startDate, int displayDays) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: AppTheme.getBorderColor(context),
          ),
          const SizedBox(height: 12),
          Text(
            displayDays == 3 
                ? 'No events for these 3 days'
                : 'No events this week',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Perfect time to plan ahead!',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayColumn(DateTime date) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          'Free',
          style: TextStyle(
            color: AppTheme.getBorderColor(context),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactEventCard(EventV2 event, bool isSelectedDay, {bool isMultiDay = false}) {
    final legacyEvent = event.toLegacyEvent();
    final eventDisplayProperties = EventDisplayProperties.fromEventV2(event, _demoData.currentUser.id);
    
    // Use different card types based on view
    if (isMultiDay) {
      // Multi-day views use week view cards
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: EventCards.buildWeekViewCard(
          context: context,
          event: legacyEvent,
          eventType: eventDisplayProperties.colorKey,
          attendeeCount: event.attendeeIds.length,
          onTap: () => _showEventDetails(event, []),
        ),
      );
    } else {
      // Day view uses full day view cards
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: EventCards.buildDayViewCard(
          context: context,
          event: legacyEvent,
          eventType: eventDisplayProperties.colorKey,
          attendeeCount: event.attendeeIds.length,
          suggestions: _getEventSuggestions(event, {}),
          onTap: () => _showEventDetails(event, []),
        ),
      );
    }
  }

  Widget _buildMonthContent(User currentUser) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    final totalDays = lastDayOfMonth.day;
    final totalCells = ((totalDays + firstDayOfWeek) / 7).ceil() * 7;
    
    return Column(
      children: [
        // Weekday headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              Expanded(child: Center(child: Text('Sun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              Expanded(child: Center(child: Text('Mon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              Expanded(child: Center(child: Text('Tue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              Expanded(child: Center(child: Text('Wed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              Expanded(child: Center(child: Text('Thu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              Expanded(child: Center(child: Text('Fri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              Expanded(child: Center(child: Text('Sat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
            ],
          ),
        ),
        
        // Calendar grid
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                final dayOffset = index - firstDayOfWeek + 1;
                
                if (dayOffset <= 0 || dayOffset > totalDays) {
                  return Container();
                }
                
                final date = DateTime(currentMonth.year, currentMonth.month, dayOffset);
                final isSelected = _isSameDay(date, selectedDate);
                final isToday = _isSameDay(date, DateTime.now());
                
                // Get events for this date
                final dayEvents = _calendarService.getUnifiedCalendarSync(
                  currentUser.id,
                  startDate: DateTime(date.year, date.month, date.day),
                  endDate: DateTime(date.year, date.month, date.day + 1),
                );
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                      currentView = CalendarView.day;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.personalColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected 
                          ? Border.all(color: AppColors.personalColor, width: 1)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayOffset.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.getTextColor(context),
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (dayEvents.isNotEmpty)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : AppColors.personalColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendOverlaySection(Map<String, dynamic> overlayData) {
    final friendsSchedules = overlayData['friendsSchedules'] as Map<String, List<Event>>;
    final overlaps = overlayData['overlaps'] as Map<String, List<Event>>;
    final commonFreeTimes = overlayData['commonFreeTimes'] as List<Map<String, dynamic>>;

    if (friendsSchedules.isEmpty && commonFreeTimes.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showFriendsSchedule = !_showFriendsSchedule;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Text(
                      'Friend Schedules',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _showFriendsSchedule ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.blue,
                ),
              ],
            ),
          ),

          if (_showFriendsSchedule || showFriendOverlay) ...[
            const SizedBox(height: 8),

            // Show friends with visible schedules
            ...friendsSchedules.entries.take(3).map((entry) {
              final friendId = entry.key;
              final friend = _demoData.getUserById(friendId);
              final friendEvents = entry.value;
              final hasOverlap = overlaps.containsKey(friendId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: hasOverlap ? Colors.orange : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${friend?.name}: ${friendEvents.length} events${hasOverlap ? ' (overlap!)' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Common free times
            if (commonFreeTimes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                '🕒 Common Free Time:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              ...commonFreeTimes.take(2).map((timeData) {
                final friend = timeData['friend'] as User;
                final timeSlot = timeData['timeSlot'] as Map<String, dynamic>;
                final startTime = timeSlot['startTime'] as DateTime;

                return Text(
                  '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} with ${friend.name}',
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedEventCard(EventV2 event, Map<String, dynamic> overlayData) {
    final suggestions = _getEventSuggestions(event, overlayData);
    final eventTypeStr = _getEventDisplayType(event);
    final attendeeCount = event.attendeeIds.length;
    
    // Format suggestions for the new card
    final formattedSuggestions = suggestions.map((s) => s.toString()).toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: EventCards.buildDayViewCard(
        context: context,
        event: event.toLegacyEvent(),
        eventType: eventTypeStr,
        attendeeCount: attendeeCount,
        suggestions: formattedSuggestions,
        onTap: () => _showEventDetails(event, suggestions),
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: AppTheme.getBorderColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No events for ${DateFormat('EEEE, MMM d').format(selectedDate)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Perfect time for a study session!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _suggestStudySession(),
            icon: const Icon(Icons.group_add),
            label: const Text('Find Study Buddies'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.personalColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getFilterColor(CalendarFilter filter) {
    switch (filter) {
      case CalendarFilter.allEvents:
        return AppColors.homeColor;      // Purple for all events
      case CalendarFilter.mySchedule:
        return AppColors.personalColor;  // Blue for my schedule
      case CalendarFilter.academic:
        return AppColors.personalColor;  // Blue for academic
      case CalendarFilter.social:
        return AppColors.socialColor;    // Bright green for social
      case CalendarFilter.societies:
        return AppColors.societyColor;   // Green for societies
      case CalendarFilter.discover:
        return AppColors.studyGroupColor; // Orange for discover
    }
  }

  Color _getEventColor(EventV2 event) {
    switch (event.category) {
      case EventCategory.academic:
        return AppColors.personalColor;  // Academic events use personal color
      case EventCategory.society:
        return AppColors.societyColor;   // Society events use society color
      case EventCategory.social:
        return AppColors.socialColor;    // Social events use social color
      case EventCategory.personal:
        return AppColors.personalColor;  // Personal events use personal color
      case EventCategory.university:
        return AppColors.personalColor;  // University events use personal color
    }
  }

  String _getEventDisplayType(EventV2 event) {
    // Get the display type based on actual event type
    final displayProps = EventDisplayProperties.fromEventV2(event, _demoData.currentUser.id);
    return displayProps.colorKey;
  }

  // Overloaded version for legacy Event types
  String _getEventDisplayTypeLegacy(Event event) {
    // Get the display type based on actual event type
    final displayProps = EventDisplayProperties.fromEvent(event);
    return displayProps.colorKey;
  }

  void _showEventDetailsLegacy(Event event, List<String> suggestions) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('${DateFormat('MMM d, HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}'),
              if (event.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('📍 ${event.location}'),
              ],
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(event.description),
              ],
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Smart Suggestions:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...suggestions.map((s) => Text('• $s')),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  if (event.type != EventType.class_)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event editing would open here')),
                        );
                      },
                      child: const Text('Edit'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getEventSuggestions(EventV2 event, Map<String, dynamic> overlayData) {
    final suggestions = <String>[];
    
    // Add friend-related suggestions
    final friendsSchedules = overlayData['friendsSchedules'] as Map<String, List<Event>>;
    for (final friendId in friendsSchedules.keys) {
      final friend = _demoData.getUserById(friendId);
      final friendEvents = friendsSchedules[friendId]!;
      
      // Check if friend has events at same time
      for (final friendEvent in friendEvents) {
        if (_eventsOverlapMixed(event, friendEvent)) {
          suggestions.add('${friend?.name} also has ${friendEvent.title} at this time');
          break;
        }
      }
    }
    
    // Add location-based suggestions
    if (event.location.isNotEmpty) {
      final friendsOnCampus = _demoData.getFriendsForUser(_demoData.currentUser.id)
          .where((friend) => friend.isOnline && friend.currentBuilding != null)
          .toList();
      
      for (final friend in friendsOnCampus.take(2)) {
        if (event.location.contains(friend.currentBuilding!)) {
          suggestions.add('${friend.name} is currently in ${friend.currentBuilding}');
        }
      }
    }
    
    return suggestions;
  }

  // Overloaded version to handle EventV2 and legacy Event
  bool _eventsOverlapMixed(EventV2 eventV2, Event legacyEvent) {
    return eventV2.startTime.isBefore(legacyEvent.endTime) && 
           legacyEvent.startTime.isBefore(eventV2.endTime);
  }

  // Navigation helpers
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _navigateDate(int direction) {
    setState(() {
      switch (currentView) {
        case CalendarView.day:
          selectedDate = selectedDate.add(Duration(days: direction));
          break;
        case CalendarView.threeDays:
          selectedDate = selectedDate.add(Duration(days: direction * 3));
          break;
        case CalendarView.week:
          selectedDate = selectedDate.add(Duration(days: direction * 7));
          break;
        case CalendarView.month:
          _navigateMonth(direction);
          break;
      }
    });
  }

  void _navigateMonth(int direction) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + direction, 1);
      // Keep selected date in the same relative position if possible
      final newSelectedDate = DateTime(currentMonth.year, currentMonth.month, selectedDate.day);
      final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
      
      if (newSelectedDate.day <= lastDayOfMonth) {
        selectedDate = newSelectedDate;
      } else {
        selectedDate = DateTime(currentMonth.year, currentMonth.month, lastDayOfMonth);
      }
    });
  }

  void _selectDate() {
    showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        setState(() {
          selectedDate = date;
          currentMonth = DateTime(date.year, date.month, 1);
        });
      }
    });
  }

  void _selectMonth() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Select Month', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = DateTime(currentMonth.year, index + 1, 1);
                    final isSelected = month.month == currentMonth.month;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          currentMonth = month;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.personalColor : AppTheme.getInputBackgroundColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('MMM').format(month),
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.getTextColor(context),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Event Handlers
  void _toggleViewSelector() {
    setState(() {
      _showViewSelector = !_showViewSelector;
    });
  }

  void _scrollToEarliestEvent(DateTime earliestEventTime, double hourHeight) {
    // Calculate the hour of the earliest event
    final hour = earliestEventTime.hour;
    final minute = earliestEventTime.minute;

    // Debug logging
    print('🎯 Auto-scroll: Scrolling to earliest event at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');

    // Calculate scroll position (hour * hourHeight + proportion of minutes)
    // Subtract a small buffer (30 pixels) so the event isn't right at the top
    final scrollPosition = (hour * hourHeight + (minute / 60) * hourHeight) - 30;

    // Wait for next frame then check if controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_timetableScrollController.hasClients) {
        print('🎯 Auto-scroll: ScrollController not ready, retrying...');
        // Try again after a delay if controller isn't ready
        Future.delayed(const Duration(milliseconds: 100), () {
          _performScroll(scrollPosition, hourHeight);
        });
      } else {
        _performScroll(scrollPosition, hourHeight);
      }
    });
  }

  void _performScroll(double scrollPosition, double hourHeight) {
    if (!_timetableScrollController.hasClients) {
      print('🎯 Auto-scroll: ScrollController still not ready, aborting');
      return;
    }

    // Ensure we don't scroll beyond bounds
    final clampedPosition = scrollPosition.clamp(
      0.0,
      _timetableScrollController.position.maxScrollExtent,
    );

    print('🎯 Auto-scroll: Scrolling to position = $clampedPosition (max: ${_timetableScrollController.position.maxScrollExtent})');

    // Perform the animated scroll
    _timetableScrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleTimetableView() {
    setState(() {
      _useTimetableView = !_useTimetableView;
      if (_useTimetableView) {
        // Reset last scrolled date when enabling timetable view
        _lastScrolledDate = null;
      }
    });
  }

  void _showAdvancedFilters() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advanced filters would open here')),
    );
  }

// Removed _showTimetableManagementDialog - Edit Timetable button now navigates directly to Import tab

  void _showImportDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TimetableManagementScreen(initialTabIndex: 0),
      ),
    );
  }
  
  void _showManualEntryDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TimetableManagementScreen(initialTabIndex: 1),
      ),
    );
  }
  
  void _showCurrentTimetable() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TimetableManagementScreen(initialTabIndex: 2),
      ),
    );
  }

  void _showCreateEventDialog(User currentUser) {
    showDialog(
      context: context,
      builder: (context) => _EventCreationDialog(
        currentUser: currentUser,
        onEventCreated: (newEvent) {
          print('🎯 DEBUG (Calendar): Event created callback received for "${newEvent.title}"');
          
          // Refresh calendar view WITHOUT clearing cache (since we just added to in-memory data)
          _refreshCalendarData(clearCache: false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${newEvent.title}" created successfully!'),
              backgroundColor: AppColors.socialColor,
              duration: const Duration(seconds: 3),
            ),
          );
          
          print('🎯 DEBUG (Calendar): Event creation flow completed');
        },
      ),
    );
  }

  void _showEventDetails(EventV2 event, List<String> suggestions) {
    final currentUserId = _demoData.currentUser.id;
    final userRelationship = event.getUserRelationship(currentUserId);
    final canEdit = event.canUserEdit(currentUserId);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 500,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and relationship badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildRelationshipBadge(userRelationship),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Time and location
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: AppTheme.getSecondaryIconColor(context)),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('EEEE, MMM d, HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppTheme.getSecondaryIconColor(context)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(event.location, style: const TextStyle(fontSize: 16))),
                      ],
                    ),
                  ],
                  
                  // Privacy level and category
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildInfoChip(event.privacyLevel.toString().split('.').last, Icons.visibility),
                      _buildInfoChip('${event.category.toString().split('.').last} • ${event.subType.toString().split('.').last}', Icons.category),
                    ],
                  ),
                  
                  // Description
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(event.description),
                  ],
                  
                  // Attendees section
                  const SizedBox(height: 16),
                  _buildAttendeesSection(event),
                  
                  // Smart suggestions
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Smart Suggestions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
                          Expanded(child: Text(s)),
                        ],
                      ),
                    )),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  _buildActionButtons(event, userRelationship, canEdit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _suggestStudySession() {
    final friends = _demoData.getFriendsForUser(_demoData.currentUser.id);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Study Session Suggestion'),
        content: Text(
          friends.isEmpty 
            ? 'Add some friends first to organize study sessions!'
            : 'Study session planning with ${friends.length} friends would be implemented here.',
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


  // Helper methods for enhanced event details modal
  Widget _buildRelationshipBadge(EventRelationship relationship) {
    Color badgeColor;
    String label;
    
    switch (relationship) {
      case EventRelationship.owner:
        badgeColor = Colors.purple;
        label = 'Owner';
        break;
      case EventRelationship.organizer:
        badgeColor = Colors.blue;
        label = 'Organizer';
        break;
      case EventRelationship.attendee:
        badgeColor = Colors.green;
        label = 'Attending';
        break;
      case EventRelationship.interested:
        badgeColor = Colors.orange;
        label = 'Interested';
        break;
      case EventRelationship.invited:
        badgeColor = Colors.amber;
        label = 'Invited';
        break;
      case EventRelationship.observer:
        badgeColor = AppTheme.getSecondaryIconColor(context);
        label = 'Observer';
        break;
      default:
        badgeColor = AppTheme.getSecondaryIconColor(context);
        label = 'Not Participating';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.getSecondaryIconColor(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeesSection(EventV2 event) {
    final attendeeCount = event.attendeeIds.length;
    final interestedCount = event.interestedIds.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildParticipantChip('$attendeeCount Attending', Icons.check_circle, Colors.green),
            const SizedBox(width: 8),
            _buildParticipantChip('$interestedCount Interested', Icons.star, Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(EventV2 event, EventRelationship userRelationship, bool canEdit) {
    final currentUserId = _demoData.currentUser.id;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 12),
            if (canEdit) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _editEvent(event),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.personalColor,
                    foregroundColor: AppTheme.getButtonTextColor(context),
                  ),
                ),
              ),
            ] else if (userRelationship == EventRelationship.none) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _joinEvent(event),
                  icon: const Icon(Icons.add),
                  label: const Text('Join'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: AppTheme.getButtonTextColor(context),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _changeAttendanceStatus(event, userRelationship),
                  icon: Icon(userRelationship == EventRelationship.attendee 
                      ? Icons.star_outline : Icons.check_circle_outline),
                  label: Text(userRelationship == EventRelationship.attendee 
                      ? 'Mark Interested' : 'Mark Attending'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: userRelationship == EventRelationship.attendee 
                        ? Colors.orange : Colors.green,
                    foregroundColor: AppTheme.getButtonTextColor(context),
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Secondary actions
        if (userRelationship != EventRelationship.none && userRelationship != EventRelationship.owner) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _removeFromCalendar(event),
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            label: const Text('Remove from Calendar', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
        
        if (userRelationship == EventRelationship.owner && _hasOtherParticipants(event)) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _deleteEventOptions(event),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete Event', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ] else if (userRelationship == EventRelationship.owner) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _deleteEvent(event),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete Event', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  bool _hasOtherParticipants(EventV2 event) {
    return event.attendeeIds.isNotEmpty || 
           event.interestedIds.isNotEmpty || 
           event.invitedIds.isNotEmpty ||
           event.organizerIds.isNotEmpty;
  }

  // Action methods for event management
  void _editEvent(EventV2 event) async {
    Navigator.pop(context);
    
    final result = await showDialog<EventV2>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EventEditingDialog(event: event),
    );

    if (result != null) {
      // Update the event in the system
      final success = await _eventRelationshipService.updateEventDetails(result);
      
      if (success && mounted) {
        setState(() {
          // Refresh the calendar view by triggering setState
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${result.title}" updated successfully'),
            backgroundColor: AppColors.socialColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update event. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _joinEvent(EventV2 event) async {
    Navigator.pop(context);
    
    // Show dialog to choose how to join
    final result = await showDialog<EventRelationship>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Event'),
        content: const Text('How would you like to participate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, EventRelationship.interested),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Interested'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, EventRelationship.attendee),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Attending'),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await _eventRelationshipService.updateEventRelationship(
        _demoData.currentUser.id, 
        event.id, 
        result
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined as ${result.toString().split('.').last}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join event'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeAttendanceStatus(EventV2 event, EventRelationship currentRelationship) async {
    Navigator.pop(context);
    
    final newRelationship = currentRelationship == EventRelationship.attendee 
        ? EventRelationship.interested 
        : EventRelationship.attendee;
    
    final success = await _eventRelationshipService.updateEventRelationship(
      _demoData.currentUser.id, 
      event.id, 
      newRelationship
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Changed to ${newRelationship.toString().split('.').last}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update attendance'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFromCalendar(EventV2 event) async {
    Navigator.pop(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Event'),
        content: Text('Remove "${event.title}" from your calendar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _eventRelationshipService.updateEventRelationship(
        _demoData.currentUser.id, 
        event.id, 
        EventRelationship.none
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event removed from calendar'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove event'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteEvent(EventV2 event) async {
    Navigator.pop(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Permanently delete "${event.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deletion will be implemented in Phase 6')),
      );
    }
  }

  void _deleteEventOptions(EventV2 event) async {
    Navigator.pop(context);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What would you like to do with "${event.title}"?'),
            const SizedBox(height: 12),
            const Text('This event has other participants:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${event.attendeeIds.length} attending, ${event.interestedIds.length} interested'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'transfer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Transfer & Leave'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'delete_all'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete for Everyone'),
          ),
        ],
      ),
    );

    if (result == 'transfer') {
      await _showOwnershipTransferDialog(event);
    } else if (result == 'delete_all') {
      await _confirmDeleteEventForEveryone(event);
    }
  }

  /// Show ownership transfer dialog with list of eligible users
  Future<void> _showOwnershipTransferDialog(EventV2 event) async {
    // Get eligible users for ownership transfer (organizers and attendees)
    final eligibleUsers = <User>[];
    
    // Add organizers
    for (final organizerId in event.organizerIds) {
      final user = _demoData.getUserById(organizerId);
      if (user != null && user.id != _demoData.currentUser.id) {
        eligibleUsers.add(user);
      }
    }
    
    // Add attendees who aren't already organizers
    for (final attendeeId in event.attendeeIds) {
      final user = _demoData.getUserById(attendeeId);
      if (user != null && 
          user.id != _demoData.currentUser.id && 
          !eligibleUsers.any((u) => u.id == user.id)) {
        eligibleUsers.add(user);
      }
    }
    
    if (eligibleUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No eligible users to transfer ownership to. Add organizers or attendees first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedUser = await showDialog<User>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.homeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.transfer_within_a_station, color: AppTheme.getButtonTextColor(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Transfer Ownership',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getButtonTextColor(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppTheme.getButtonTextColor(context)),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a new owner for "${event.title}"',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will be removed from the event after transfer.',
                      style: TextStyle(fontSize: 14, color: AppTheme.getSecondaryTextColor(context)),
                    ),
                    const SizedBox(height: 20),
                    
                    // User selection list
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          children: eligibleUsers.map((user) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.personalColor,
                              child: Text(
                                user.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(color: AppTheme.getButtonTextColor(context), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email ?? 'No email'),
                                Text(
                                  event.organizerIds.contains(user.id) ? 'Organizer' : 'Attendee',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: event.organizerIds.contains(user.id) 
                                        ? AppColors.studyGroupColor 
                                        : AppColors.socialColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pop(context, user),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          )).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedUser != null) {
      await _transferOwnership(event, selectedUser);
    }
  }

  /// Transfer event ownership to another user
  Future<void> _transferOwnership(EventV2 event, User newOwner) async {
    try {
      // Create updated event with new owner
      // First, ensure new owner is in organizers list and remove current user
      final updatedOrganizerIds = [...event.organizerIds, newOwner.id]
          .toSet()
          .where((id) => id != _demoData.currentUser.id)
          .toList();
      
      final updatedEvent = event.copyWith(
        creatorId: newOwner.id,
        organizerIds: updatedOrganizerIds,
        // Remove current user from all participant lists
        attendeeIds: event.attendeeIds.where((id) => id != _demoData.currentUser.id).toList(),
        invitedIds: event.invitedIds.where((id) => id != _demoData.currentUser.id).toList(),
        interestedIds: event.interestedIds.where((id) => id != _demoData.currentUser.id).toList(),
      );

      // Update event in data manager
      final success = await _eventRelationshipService.updateEventDetails(updatedEvent);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event ownership transferred to ${newOwner.name}. You have been removed from the event.'),
            backgroundColor: AppColors.socialColor,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Refresh calendar view
        _onEventRelationshipChange();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to transfer ownership. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error transferring ownership: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during ownership transfer.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Confirm deletion of event for everyone
  Future<void> _confirmDeleteEventForEveryone(EventV2 event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Event'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to permanently delete "${event.title}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ This action cannot be undone',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text('• The event will be removed from everyone\'s calendar'),
                  Text('• ${event.attendeeIds.length + event.interestedIds.length} participants will be affected'),
                  const Text('• All event data will be permanently lost'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete Permanently', style: TextStyle(color: AppTheme.getButtonTextColor(context))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteEventPermanently(event);
    }
  }

  /// Permanently delete event for everyone
  Future<void> _deleteEventPermanently(EventV2 event) async {
    try {
      // Remove event from data manager
      final events = _demoData.enhancedEventsSync;
      events.removeWhere((e) => e.id == event.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event "${event.title}" has been deleted permanently.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Refresh calendar view
      _onEventRelationshipChange();
      
    } catch (e) {
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete event. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Build day view timetable chip with responsive content based on height
  Widget _buildDayTimetableChip({
    required EventV2 event,
    required double height,
    required bool isDetailedView,
    required VoidCallback onTap,
  }) {
    final eventDisplayProperties = EventDisplayProperties.fromEventV2(event, _demoData.currentUser.id);
    final eventColor = EventColors.getEventColor(eventDisplayProperties.colorKey);
    final eventBgColor = EventColors.getEventBackgroundColor(eventDisplayProperties.colorKey);
    final eventLabel = EventColors.getEventTypeLabel(eventDisplayProperties.colorKey);
    
    // Ensure minimum height for readability
    final safeHeight = height.clamp(40.0, double.infinity);
    
    // Determine what content to show based on height
    final showCourseCode = safeHeight >= 60.0;
    final showLocation = safeHeight >= 80.0;
    final showAttendees = safeHeight >= 100.0 && isDetailedView;
    final showTypeLabel = safeHeight >= 50.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: safeHeight,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: EventColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: [
            BoxShadow(
              color: EventColors.getShadowColor(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // Left color bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 4,
                height: safeHeight,
                decoration: ShapeDecoration(
                  color: eventColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Event title (always shown)
            Positioned(
              left: isDetailedView ? 20 : 12,
              top: 8,
              right: showTypeLabel ? 60 : 12,
              child: Text(
                event.title,
                style: TextStyle(
                  color: EventColors.getPrimaryTextColor(context),
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  height: 1.20,
                ),
                maxLines: safeHeight < 60 ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Course code (shown if height >= 60px)
            if (showCourseCode && event.courseCode != null)
              Positioned(
                left: isDetailedView ? 20 : 12,
                top: 28,
                child: Text(
                  event.courseCode!,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 10,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    height: 1.20,
                  ),
                ),
              ),

            // Event type badge (shown if height >= 50px)
            if (showTypeLabel)
              Positioned(
                right: isDetailedView ? 20 : 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: ShapeDecoration(
                    color: eventBgColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    eventLabel,
                    style: TextStyle(
                      color: eventColor,
                      fontSize: 8,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              ),

            // Location (shown if height >= 80px)
            if (showLocation)
              Positioned(
                left: isDetailedView ? 20 : 12,
                top: safeHeight - (showAttendees ? 40 : 24),
                right: 12,
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 10, color: EventColors.getSecondaryTextColor(context)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          color: EventColors.getSecondaryTextColor(context),
                          fontSize: 9,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Attendee count (shown if height >= 100px and detailed view)
            if (showAttendees)
              Positioned(
                left: isDetailedView ? 20 : 12,
                top: safeHeight - 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 10, color: EventColors.getSecondaryTextColor(context)),
                    const SizedBox(width: 2),
                    Text(
                      event.attendeeIds.length.toString(),
                      style: TextStyle(
                        color: EventColors.getSecondaryTextColor(context),
                        fontSize: 9,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
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

  /// Build 3-day view timetable chip with fixed 61x123 dimensions
  Widget _build3DayTimetableChip({
    required EventV2 event,
    required VoidCallback onTap,
  }) {
    final eventDisplayProperties = EventDisplayProperties.fromEventV2(event, _demoData.currentUser.id);
    final eventColor = EventColors.getEventColor(eventDisplayProperties.colorKey);
    final eventBgColor = EventColors.getEventBackgroundColor(eventDisplayProperties.colorKey);
    final eventLabel = EventColors.getEventTypeLabel(eventDisplayProperties.colorKey);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 123,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: EventColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: [
            BoxShadow(
              color: EventColors.getShadowColor(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // Left color bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 4,
                height: 122.58,
                decoration: ShapeDecoration(
                  color: eventColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Event title
            Positioned(
              left: 6,
              top: 4,
              right: 6,
              child: SizedBox(
                height: 48,
                child: Text(
                  event.title,
                  style: TextStyle(
                    color: EventColors.getPrimaryTextColor(context),
                    fontSize: 10,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Course code
            if (event.courseCode != null)
              Positioned(
                left: 6,
                top: 58,
                child: Text(
                  event.courseCode!,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    height: 1.20,
                  ),
                ),
              ),

            // Time
            Positioned(
              left: 6,
              top: 72,
              child: Text(
                '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: EventColors.getSecondaryTextColor(context),
                  fontSize: 8,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Event type badge
            Positioned(
              left: 6,
              top: 90,
              child: Container(
                height: 14,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: ShapeDecoration(
                  color: eventBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Center(
                  child: Text(
                    eventLabel,
                    style: TextStyle(
                      color: eventColor,
                      fontSize: 7,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.30,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build week view timetable chip with ultra-narrow 43x111 dimensions
  Widget _buildWeekTimetableChip({
    required EventV2 event,
    required VoidCallback onTap,
  }) {
    final eventDisplayProperties = EventDisplayProperties.fromEventV2(event, _demoData.currentUser.id);
    final eventColor = EventColors.getEventColor(eventDisplayProperties.colorKey);
    final eventBgColor = EventColors.getEventBackgroundColor(eventDisplayProperties.colorKey);
    final eventLabel = EventColors.getEventTypeLabel(eventDisplayProperties.colorKey);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 111,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: EventColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: [
            BoxShadow(
              color: EventColors.getShadowColor(context),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            )
          ],
        ),
        child: Stack(
          children: [
            // Left color bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 4,
                height: 110.58,
                decoration: ShapeDecoration(
                  color: eventColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Event title
            Positioned(
              left: 6,
              top: 4,
              right: 6,
              child: SizedBox(
                height: 32,
                child: Text(
                  event.title,
                  style: TextStyle(
                    color: EventColors.getPrimaryTextColor(context),
                    fontSize: 7,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    height: 1.43,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Course code
            if (event.courseCode != null)
              Positioned(
                left: 6,
                top: 52,
                child: Text(
                  event.courseCode!,
                  style: TextStyle(
                    color: eventColor,
                    fontSize: 8,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    height: 1.80,
                  ),
                ),
              ),

            // Event type badge
            Positioned(
              left: 6,
              top: 64,
              child: Container(
                width: 23,
                height: 12,
                decoration: ShapeDecoration(
                  color: eventBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Center(
                  child: Text(
                    eventLabel,
                    style: TextStyle(
                      color: eventColor,
                      fontSize: 3,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.50,
                    ),
                  ),
                ),
              ),
            ),

            // Attendee count (ultra compact)
            Positioned(
              left: 6,
              top: 76,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people, size: 12, color: EventColors.getSecondaryTextColor(context)),
                  const SizedBox(width: 2),
                  Text(
                    event.attendeeIds.length.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EventColors.getSecondaryTextColor(context),
                      fontSize: 8,
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

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _timetableScrollController.dispose();
    _eventRelationshipService.relationshipChangeNotifier.removeListener(_onEventRelationshipChange);
    _demoData.societyMembershipNotifier.removeListener(_onSocietyMembershipChanged);
    super.dispose();
  }
}

// Event Editing Dialog Widget
class _EventEditingDialog extends StatefulWidget {
  final EventV2 event;

  const _EventEditingDialog({required this.event});

  @override
  State<_EventEditingDialog> createState() => _EventEditingDialogState();
}

class _EventEditingDialogState extends State<_EventEditingDialog> {
  final _formKey = GlobalKey<FormState>();
  final DemoDataManager _demoData = DemoDataManager.instance;
  
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _startTime;
  late DateTime _endTime;
  late EventCategory _selectedCategory;
  late EventSubType _selectedSubType;
  late EventPrivacyLevel _selectedPrivacy;
  late EventSharingPermission _selectedSharingPermission;
  late bool _isAllDay;
  String? _selectedSocietyId;

  // State management
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _selectedCategory = widget.event.category;
    _selectedSubType = widget.event.subType;
    _selectedPrivacy = widget.event.privacyLevel;
    _selectedSharingPermission = widget.event.sharingPermission;
    _isAllDay = widget.event.isAllDay;
    _selectedSocietyId = widget.event.societyId;
    
    // Validate that the subType is compatible with the category
    final compatibleSubTypes = _getValidSubTypesForCategory(_selectedCategory);
    if (!compatibleSubTypes.contains(_selectedSubType)) {
      print('Warning: Event subType ${_selectedSubType} is not compatible with category ${_selectedCategory}');
      print('Compatible types: $compatibleSubTypes');
      
      // Try to fix the category first by using EventTypeHelper
      final correctCategory = EventTypeHelper.getCategoryForSubType(_selectedSubType);
      print('EventTypeHelper suggests category: $correctCategory for subType: $_selectedSubType');
      
      if (correctCategory != _selectedCategory) {
        // Use the correct category according to EventTypeHelper
        _selectedCategory = correctCategory;
        print('Corrected category to: $_selectedCategory');
      } else if (compatibleSubTypes.isNotEmpty) {
        // If that doesn't work, fall back to first compatible subtype
        _selectedSubType = compatibleSubTypes.first;
        print('Fallback to subType: $_selectedSubType');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Event'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isLoading)
              const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator()))
            else
              TextButton(
                onPressed: _saveEvent,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information', Icons.event),
              const SizedBox(height: 16),
              
              // Event Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 24),

              // Time and Date Section
              _buildSectionHeader('Time & Date', Icons.access_time),
              const SizedBox(height: 16),
              
              // All Day Toggle
              SwitchListTile(
                title: const Text('All Day Event'),
                subtitle: const Text('Event runs for the entire day'),
                value: _isAllDay,
                onChanged: (value) => setState(() => _isAllDay = value),
                secondary: const Icon(Icons.schedule),
              ),
              const SizedBox(height: 16),

              // Start Time
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Start Time'),
                subtitle: Text(_formatDateTime(_startTime)),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDateTime(true),
              ),
              
              // End Time
              ListTile(
                leading: const Icon(Icons.stop),
                title: const Text('End Time'),
                subtitle: Text(_formatDateTime(_endTime)),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDateTime(false),
              ),
              const SizedBox(height: 24),

              // Location Section
              _buildSectionHeader('Location', Icons.location_on),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 24),

              // Categorization Section
              _buildSectionHeader('Categorization', Icons.category),
              const SizedBox(height: 16),
              
              // Category Dropdown
              DropdownButtonFormField<EventCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: EventCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryDisplayName(category)),
                  );
                }).toList(),
                onChanged: (category) {
                  if (category != null) {
                    setState(() {
                      _selectedCategory = category;
                      // Reset subtype to compatible one
                      _selectedSubType = _getValidSubTypesForCategory(category).first;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // SubType Dropdown
              DropdownButtonFormField<EventSubType>(
                value: _selectedSubType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subdirectory_arrow_right),
                ),
                items: _getValidSubTypesForCategory(_selectedCategory).map((subType) {
                  return DropdownMenuItem(
                    value: subType,
                    child: Text(_getSubTypeDisplayName(subType)),
                  );
                }).toList(),
                onChanged: (subType) {
                  if (subType != null) {
                    setState(() => _selectedSubType = subType);
                  }
                },
                validator: (value) {
                  if (value == null) return 'Please select an event type';
                  
                  // Validate that the selected subtype is compatible with the category
                  final validSubTypes = _getValidSubTypesForCategory(_selectedCategory);
                  if (!validSubTypes.contains(value)) {
                    return 'Selected type is incompatible with category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Society Association (if applicable)
              if (_selectedCategory == EventCategory.society) ...[
                _buildSectionHeader('Society Association', Icons.groups),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String?>(
                  value: _selectedSocietyId,
                  decoration: const InputDecoration(
                    labelText: 'Associated Society',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.groups),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No Society'),
                    ),
                    ..._demoData.joinedSocieties.map((society) {
                      return DropdownMenuItem<String?>(
                        value: society.id,
                        child: Text(society.name),
                      );
                    }),
                  ],
                  onChanged: (societyId) => setState(() => _selectedSocietyId = societyId),
                ),
                const SizedBox(height: 24),
              ],

              // Privacy and Sharing Section
              _buildSectionHeader('Privacy & Sharing', Icons.privacy_tip),
              const SizedBox(height: 16),
              
              // Privacy Level
              DropdownButtonFormField<EventPrivacyLevel>(
                value: _selectedPrivacy,
                decoration: const InputDecoration(
                  labelText: 'Privacy Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.privacy_tip),
                ),
                items: EventPrivacyLevel.values.map((privacy) {
                  return DropdownMenuItem(
                    value: privacy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getPrivacyDisplayName(privacy)),
                        Text(
                          _getPrivacyDescription(privacy),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (privacy) {
                  if (privacy != null) {
                    setState(() => _selectedPrivacy = privacy);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Sharing Permission
              DropdownButtonFormField<EventSharingPermission>(
                value: _selectedSharingPermission,
                decoration: const InputDecoration(
                  labelText: 'Sharing Permission',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.share),
                ),
                items: EventSharingPermission.values.map((permission) {
                  return DropdownMenuItem(
                    value: permission,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getSharingDisplayName(permission)),
                        Text(
                          _getSharingDescription(permission),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (permission) {
                  if (permission != null) {
                    setState(() => _selectedSharingPermission = permission);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveEvent,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                          : const Text('Save Event'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.homeColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.homeColor,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    if (_isAllDay) {
      return DateFormat('EEEE, MMM d, y').format(dateTime);
    } else {
      return DateFormat('EEEE, MMM d, y • h:mm a').format(dateTime);
    }
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final DateTime initialDate = isStartTime ? _startTime : _endTime;
    
    // Select Date
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate == null) return;

    if (_isAllDay) {
      setState(() {
        if (isStartTime) {
          _startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          // Ensure end time is not before start time
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(days: 1));
          }
        } else {
          _endTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          // Ensure end time is not before start time
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(days: 1));
          }
        }
      });
    } else {
      // Select Time
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (selectedTime == null) return;

      final DateTime newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      setState(() {
        if (isStartTime) {
          _startTime = newDateTime;
          // Ensure end time is at least 30 minutes after start time
          if (_endTime.isBefore(_startTime.add(const Duration(minutes: 30)))) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = newDateTime;
          // Ensure end time is at least 30 minutes after start time
          if (_endTime.isBefore(_startTime.add(const Duration(minutes: 30)))) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        }
      });
    }
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate time logic
    if (!_isAllDay && _endTime.isBefore(_startTime.add(const Duration(minutes: 30)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be at least 30 minutes after start time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedEvent = widget.event.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        category: _selectedCategory,
        subType: _selectedSubType,
        privacyLevel: _selectedPrivacy,
        sharingPermission: _selectedSharingPermission,
        isAllDay: _isAllDay,
        societyId: _selectedSocietyId,
      );

      Navigator.pop(context, updatedEvent);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  // Helper methods for display names and validation
  List<EventSubType> _getValidSubTypesForCategory(EventCategory category) {
    // Use EventTypeHelper logic to ensure consistency
    return EventSubType.values.where((subType) {
      return EventTypeHelper.getCategoryForSubType(subType) == category;
    }).toList();
  }

  String _getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.social:
        return 'Social';
      case EventCategory.society:
        return 'Society';
      case EventCategory.personal:
        return 'Personal';
      case EventCategory.university:
        return 'University';
    }
  }

  String _getSubTypeDisplayName(EventSubType subType) {
    switch (subType) {
      case EventSubType.lecture:
        return 'Lecture';
      case EventSubType.tutorial:
        return 'Tutorial';
      case EventSubType.lab:
        return 'Lab';
      case EventSubType.assignment:
        return 'Assignment';
      case EventSubType.exam:
        return 'Exam';
      case EventSubType.meeting:
        return 'Meeting';
      case EventSubType.meetup:
        return 'Meetup';
      case EventSubType.party:
        return 'Party';
      case EventSubType.casualHangout:
        return 'Casual Hangout';
      case EventSubType.gameNight:
        return 'Game Night';
      case EventSubType.networking:
        return 'Networking';
      case EventSubType.societyEvent:
        return 'Society Event';
      case EventSubType.societyWorkshop:
        return 'Society Workshop';
      case EventSubType.competition:
        return 'Competition';
      case EventSubType.fundraiser:
        return 'Fundraiser';
      case EventSubType.studySession:
        return 'Study Session';
      case EventSubType.task:
        return 'Task';
      case EventSubType.break_:
        return 'Break';
      case EventSubType.appointment:
        return 'Appointment';
      case EventSubType.personalGoal:
        return 'Personal Goal';
      case EventSubType.orientation:
        return 'Orientation';
      case EventSubType.ceremony:
        return 'Ceremony';
      case EventSubType.careerFair:
        return 'Career Fair';
      case EventSubType.guestLecture:
        return 'Guest Lecture';
      case EventSubType.administrative:
        return 'Administrative';
      case EventSubType.workshop:
        return 'Workshop';
      case EventSubType.presentation:
        return 'Presentation';
      case EventSubType.other:
        return 'Other';
    }
  }

  String _getPrivacyDisplayName(EventPrivacyLevel privacy) {
    switch (privacy) {
      case EventPrivacyLevel.public:
        return 'Public';
      case EventPrivacyLevel.university:
        return 'University';
      case EventPrivacyLevel.faculty:
        return 'Faculty';
      case EventPrivacyLevel.societyOnly:
        return 'Society Only';
      case EventPrivacyLevel.friendsOnly:
        return 'Friends Only';
      case EventPrivacyLevel.friendsOfFriends:
        return 'Friends of Friends';
      case EventPrivacyLevel.inviteOnly:
        return 'Invite Only';
      case EventPrivacyLevel.private:
        return 'Private';
    }
  }

  String _getPrivacyDescription(EventPrivacyLevel privacy) {
    switch (privacy) {
      case EventPrivacyLevel.public:
        return 'Anyone can see and join this event';
      case EventPrivacyLevel.university:
        return 'All university students can see this event';
      case EventPrivacyLevel.faculty:
        return 'Students in the same faculty can see this event';
      case EventPrivacyLevel.societyOnly:
        return 'Only society members can see this event';
      case EventPrivacyLevel.friendsOnly:
        return 'Only your friends can see this event';
      case EventPrivacyLevel.friendsOfFriends:
        return 'Friends and their friends can see this event';
      case EventPrivacyLevel.inviteOnly:
        return 'Only invited people can see this event';
      case EventPrivacyLevel.private:
        return 'Only you can see this event';
    }
  }

  String _getSharingDisplayName(EventSharingPermission permission) {
    switch (permission) {
      case EventSharingPermission.canShare:
        return 'Can Share';
      case EventSharingPermission.canSuggest:
        return 'Can Suggest';
      case EventSharingPermission.noShare:
        return 'No Sharing';
      case EventSharingPermission.hidden:
        return 'Hidden';
    }
  }

  String _getSharingDescription(EventSharingPermission permission) {
    switch (permission) {
      case EventSharingPermission.canShare:
        return 'Others can freely share this event';
      case EventSharingPermission.canSuggest:
        return 'Others can suggest this event to friends';
      case EventSharingPermission.noShare:
        return 'Only organizers can share this event';
      case EventSharingPermission.hidden:
        return 'Event is hidden from sharing and suggestions';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

/// Dialog for creating new events with comprehensive form fields and validation
class _EventCreationDialog extends StatefulWidget {
  final User currentUser;
  final Function(EventV2) onEventCreated;

  const _EventCreationDialog({
    required this.currentUser,
    required this.onEventCreated,
  });

  @override
  State<_EventCreationDialog> createState() => _EventCreationDialogState();
}

class _EventCreationDialogState extends State<_EventCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final DemoDataManager _demoData = DemoDataManager.instance;
  final EventRelationshipService _eventRelationshipService = EventRelationshipService();
  
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  
  // Form state
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  EventCategory _selectedCategory = EventCategory.personal;
  EventSubType _selectedSubType = EventSubType.task;
  EventPrivacyLevel _selectedPrivacy = EventPrivacyLevel.friendsOnly;
  EventSharingPermission _selectedSharingPermission = EventSharingPermission.canSuggest;
  bool _isAllDay = false;
  String? _selectedSocietyId;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    
    // Set default start time to next hour, end time to hour after that
    final now = DateTime.now();
    _startTime = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    _endTime = _startTime.add(const Duration(hours: 1));
    
    // Ensure subtype matches category
    final compatibleSubTypes = _getValidSubTypesForCategory(_selectedCategory);
    if (compatibleSubTypes.isNotEmpty) {
      _selectedSubType = compatibleSubTypes.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Event'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: AppColors.homeColor,
          foregroundColor: Colors.white,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                _buildSectionHeader('Event Details'),
                const SizedBox(height: 16),
                
                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Event title is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Title must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty && value.trim().length < 5) {
                      return 'Description must be at least 5 characters if provided';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Location Field
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Location is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Category & Type Section
                _buildSectionHeader('Event Category'),
                const SizedBox(height: 16),
                
                // Category Dropdown
                DropdownButtonFormField<EventCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: EventCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_getCategoryDisplayName(category)),
                    );
                  }).toList(),
                  onChanged: (category) {
                    if (category != null) {
                      setState(() {
                        _selectedCategory = category;
                        // Auto-select first compatible subtype
                        final compatibleSubTypes = _getValidSubTypesForCategory(category);
                        if (compatibleSubTypes.isNotEmpty) {
                          _selectedSubType = compatibleSubTypes.first;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // SubType Dropdown
                DropdownButtonFormField<EventSubType>(
                  value: _selectedSubType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.subdirectory_arrow_right),
                  ),
                  items: _getValidSubTypesForCategory(_selectedCategory).map((subType) {
                    return DropdownMenuItem(
                      value: subType,
                      child: Text(_getSubTypeDisplayName(subType)),
                    );
                  }).toList(),
                  onChanged: (subType) {
                    if (subType != null) {
                      setState(() => _selectedSubType = subType);
                    }
                  },
                  validator: (value) {
                    if (value == null) return 'Please select an event type';
                    
                    // Validate that the selected subtype is compatible with the category
                    final validSubTypes = _getValidSubTypesForCategory(_selectedCategory);
                    if (!validSubTypes.contains(value)) {
                      return 'Selected type is incompatible with category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Society Association (if applicable)
                if (_selectedCategory == EventCategory.society) ...[
                  _buildSectionHeader('Society Association'),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedSocietyId,
                    decoration: const InputDecoration(
                      labelText: 'Associated Society',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.groups),
                    ),
                    items: _demoData.joinedSocieties.map((society) {
                      return DropdownMenuItem(
                        value: society.id,
                        child: Text(society.name),
                      );
                    }).toList(),
                    onChanged: (societyId) {
                      setState(() => _selectedSocietyId = societyId);
                    },
                    validator: (value) {
                      if (_selectedCategory == EventCategory.society && value == null) {
                        return 'Please select a society for society events';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Time & Duration Section
                _buildSectionHeader('Schedule'),
                const SizedBox(height: 16),
                
                // All Day Toggle
                Row(
                  children: [
                    Switch(
                      value: _isAllDay,
                      onChanged: (value) {
                        setState(() {
                          _isAllDay = value;
                          if (_isAllDay) {
                            // Set to start and end of day
                            final date = DateTime(_startTime.year, _startTime.month, _startTime.day);
                            _startTime = date;
                            _endTime = date.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text('All Day Event'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Start Time
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Start Time'),
                  subtitle: Text(_formatDateTime(_startTime, _isAllDay)),
                  onTap: () => _selectDateTime(context, true),
                  contentPadding: EdgeInsets.zero,
                ),
                
                // End Time
                ListTile(
                  leading: const Icon(Icons.schedule_send),
                  title: const Text('End Time'),
                  subtitle: Text(_formatDateTime(_endTime, _isAllDay)),
                  onTap: () => _selectDateTime(context, false),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Privacy & Sharing Section
                _buildSectionHeader('Privacy & Sharing'),
                const SizedBox(height: 16),
                
                // Privacy Level
                DropdownButtonFormField<EventPrivacyLevel>(
                  value: _selectedPrivacy,
                  decoration: const InputDecoration(
                    labelText: 'Privacy Level',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.privacy_tip),
                  ),
                  items: EventPrivacyLevel.values.map((privacy) {
                    return DropdownMenuItem(
                      value: privacy,
                      child: Text(_getPrivacyDisplayName(privacy)),
                    );
                  }).toList(),
                  onChanged: (privacy) {
                    if (privacy != null) {
                      setState(() => _selectedPrivacy = privacy);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Sharing Permission
                DropdownButtonFormField<EventSharingPermission>(
                  value: _selectedSharingPermission,
                  decoration: const InputDecoration(
                    labelText: 'Sharing Permission',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.share),
                  ),
                  items: EventSharingPermission.values.map((permission) {
                    return DropdownMenuItem(
                      value: permission,
                      child: Text(_getSharingPermissionDisplayName(permission)),
                    );
                  }).toList(),
                  onChanged: (permission) {
                    if (permission != null) {
                      setState(() => _selectedSharingPermission = permission);
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.socialColor,
                          foregroundColor: AppTheme.getButtonTextColor(context),
                        ),
                        child: const Text('Create Event'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.getTextColor(context),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime, bool isAllDay) {
    if (isAllDay) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final initialDate = isStartTime ? _startTime : _endTime;
    
    if (_isAllDay) {
      // Select Date only for all-day events
      final DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (selectedDate == null) return;

      setState(() {
        if (isStartTime) {
          _startTime = selectedDate;
          // Ensure end time is not before start time
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          }
        } else {
          _endTime = selectedDate.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          // Ensure end time is not before start time
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          }
        }
      });
    } else {
      // Select Date and Time for regular events
      final DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (selectedDate == null) return;

      // Select Time
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (selectedTime == null) return;

      final DateTime newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      setState(() {
        if (isStartTime) {
          _startTime = newDateTime;
          // Ensure end time is at least 30 minutes after start time
          if (_endTime.isBefore(_startTime.add(const Duration(minutes: 30)))) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = newDateTime;
          // Ensure end time is at least 30 minutes after start time
          if (_endTime.isBefore(_startTime.add(const Duration(minutes: 30)))) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        }
      });
    }
  }

  void _createEvent() async {
    print('🎯 DEBUG (Calendar): Starting event creation from dialog form');
    
    if (!_formKey.currentState!.validate()) return;

    // Validate time logic
    if (!_isAllDay && _endTime.isBefore(_startTime.add(const Duration(minutes: 30)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be at least 30 minutes after start time')),
      );
      return;
    }

    // Generate unique event ID
    final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';

    print('🎯 DEBUG (Calendar): Creating event with ID: $eventId, Title: "${_titleController.text.trim()}"');

    // Create new EventV2
    final newEvent = EventV2(
      id: eventId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      location: _locationController.text.trim(),
      category: _selectedCategory,
      subType: _selectedSubType,
      origin: EventOrigin.user,
      creatorId: widget.currentUser.id,
      privacyLevel: _selectedPrivacy,
      sharingPermission: _selectedSharingPermission,
      societyId: _selectedSocietyId,
      isAllDay: _isAllDay,
    );

    print('🎯 DEBUG (Calendar): Event object created, calling _addEventToDataManager...');

    // Add event to data manager (in a real app, this would be an API call)
    bool success = await _addEventToDataManager(newEvent);
    
    if (success) {
      print('🎯 DEBUG (Calendar): Event added successfully, closing dialog and calling callback');
      Navigator.pop(context);
      widget.onEventCreated(newEvent);
    } else {
      print('🎯 DEBUG (Calendar): Event creation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create event. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Add event to data manager (demo implementation)
  Future<bool> _addEventToDataManager(EventV2 newEvent) async {
    try {
      print('🎯 DEBUG (Calendar): Adding new event "${newEvent.title}" to data manager');
      
      // For demo purposes, we'll add the event to the in-memory data
      // In a real app, this would be an API call followed by local data refresh
      
      final events = _demoData.enhancedEventsSync;
      events.add(newEvent);
      
      print('🎯 DEBUG (Calendar): Event added to in-memory list. Total events: ${events.length}');
      print('🎯 DEBUG (Calendar): New event details - Start: ${newEvent.startTime}, Category: ${newEvent.category}');
      
      return true;
    } catch (e) {
      print('🎯 DEBUG (Calendar): Error creating event: $e');
      return false;
    }
  }

  List<EventSubType> _getValidSubTypesForCategory(EventCategory category) {
    return EventSubType.values.where((subType) {
      return EventTypeHelper.getCategoryForSubType(subType) == category;
    }).toList();
  }

  String _getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.social:
        return 'Social';
      case EventCategory.society:
        return 'Society';
      case EventCategory.personal:
        return 'Personal';
      case EventCategory.university:
        return 'University';
    }
  }

  String _getSubTypeDisplayName(EventSubType subType) {
    return EventTypeHelper.getSubTypeDisplayName(subType);
  }

  String _getPrivacyDisplayName(EventPrivacyLevel privacy) {
    switch (privacy) {
      case EventPrivacyLevel.public:
        return 'Public - Anyone can see';
      case EventPrivacyLevel.university:
        return 'University - Any student';
      case EventPrivacyLevel.faculty:
        return 'Faculty - Same faculty only';
      case EventPrivacyLevel.societyOnly:
        return 'Society - Members only';
      case EventPrivacyLevel.friendsOnly:
        return 'Friends - Friends only';
      case EventPrivacyLevel.friendsOfFriends:
        return 'Friends of Friends';
      case EventPrivacyLevel.inviteOnly:
        return 'Invite Only';
      case EventPrivacyLevel.private:
        return 'Private - Only me';
    }
  }

  String _getSharingPermissionDisplayName(EventSharingPermission permission) {
    switch (permission) {
      case EventSharingPermission.canShare:
        return 'Can Share - Others can invite';
      case EventSharingPermission.canSuggest:
        return 'Can Suggest - Friends can suggest';
      case EventSharingPermission.noShare:
        return 'No Sharing - Locked audience';
      case EventSharingPermission.hidden:
        return 'Hidden - No feed visibility';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

// Removed _TimetableManagementDialog - navigation now goes directly to TimetableManagementScreen tabs
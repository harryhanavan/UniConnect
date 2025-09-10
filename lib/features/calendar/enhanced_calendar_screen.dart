import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/event_colors.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/friendship_service.dart';
import '../../shared/models/event.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/event_cards.dart';

class EnhancedCalendarScreen extends StatefulWidget {
  const EnhancedCalendarScreen({super.key});

  @override
  State<EnhancedCalendarScreen> createState() => _EnhancedCalendarScreenState();
}

enum CalendarView { day, threeDays, week, month }

class _EnhancedCalendarScreenState extends State<EnhancedCalendarScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();
  EventSource selectedSource = EventSource.personal;
  CalendarView currentView = CalendarView.day;
  
  // Toggle states for UI elements - hidden by default
  bool _showViewSelector = false;
  bool _useTimetableView = false;
  
  final DemoDataManager _demoData = DemoDataManager.instance;
  final CalendarService _calendarService = CalendarService();
  final FriendshipService _friendshipService = FriendshipService();
  
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _demoData.users; // Trigger initialization
      // Initialize the calendar service by calling an async method
      await _calendarService.getUnifiedCalendar(_demoData.currentUser.id);
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _showViewSelector 
                  ? _buildViewSelector()
                  : const SizedBox(height: 0),
            ),
            Expanded(child: _buildCalendarView()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEventDialog(),
        backgroundColor: AppColors.personalColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.personalColor, AppColors.personalColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
                    icon: Icon(
                      Icons.calendar_view_week, 
                      color: _showViewSelector ? Colors.yellow : Colors.white,
                    ),
                    onPressed: _toggleViewSelector,
                    tooltip: 'View & Filter Options',
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
    );
  }

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // View selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildViewButton('Day', CalendarView.day),
                _buildViewButton('3 Days', CalendarView.threeDays),
                _buildViewButton('Week', CalendarView.week),
                _buildViewButton('Month', CalendarView.month),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Event source filter
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildSourceButton('Personal', EventSource.personal),
                _buildSourceButton('Friends', EventSource.friends),
                _buildSourceButton('Societies', EventSource.societies),
                _buildSourceButton('Shared', EventSource.shared),
              ],
            ),
          ),
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
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(String title, EventSource source) {
    final isSelected = selectedSource == source;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedSource = source;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.personalColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard(DateTime date) {
    final isSelected = date.day == selectedDate.day && 
                     date.month == selectedDate.month && 
                     date.year == selectedDate.year;
    final isToday = date.day == DateTime.now().day && 
                   date.month == DateTime.now().month && 
                   date.year == DateTime.now().year;
    
    // Get event count for this date
    final dayEvents = _calendarService.getUnifiedCalendarSync(
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


  Widget _buildCalendarView() {
    switch (currentView) {
      case CalendarView.day:
        return _buildDayView();
      case CalendarView.threeDays:
        return _buildThreeDaysView();
      case CalendarView.week:
        return _buildWeekView();
      case CalendarView.month:
        return _buildMonthView();
    }
  }

  Widget _buildDayView() {
    return Column(
      children: [
        _buildDateNavigation(),
        Expanded(child: _useTimetableView ? _buildDayTimetable() : _buildDayContent()),
      ],
    );
  }

  Widget _buildThreeDaysView() {
    return Column(
      children: [
        _buildDateNavigation(),
        Expanded(child: _buildMultiDayContent(3)),
      ],
    );
  }

  Widget _buildWeekView() {
    return Column(
      children: [
        _buildDateNavigation(),
        Expanded(child: _buildMultiDayContent(7)),
      ],
    );
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        _buildMonthNavigation(),
        Expanded(child: _buildMonthContent()),
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

  Widget _buildDayContent() {
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    // Get events based on selected source - maintain demo data persistence
    List<Event> events;
    
    switch (selectedSource) {
      case EventSource.shared:
        events = _calendarService.getUnifiedCalendarSync(_demoData.currentUser.id, startDate: startOfDay, endDate: endOfDay);
        break;
      case EventSource.personal:
        events = _calendarService.getUnifiedCalendarSync(_demoData.currentUser.id, startDate: startOfDay, endDate: endOfDay);
        break;
      default:
        events = _calendarService.getEventsBySourceSync(_demoData.currentUser.id, selectedSource, startDate: startOfDay, endDate: endOfDay);
        break;
    }

    if (events.isEmpty) {
      return _buildEmptyDay();
    }

    final overlayData = _calendarService.getEventsWithFriendOverlaySync(_demoData.currentUser.id, selectedDate);
    
    return Column(
      children: [
        if (selectedSource == EventSource.personal)
          _buildFriendOverlaySection(overlayData),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEnhancedEventCard(events[index], overlayData);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMultiDayContent(int days) {
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
                _demoData.currentUser.id,
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
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
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
              ? _buildMultiDayTimetable(startDate, displayDays)
              : _buildMultiDayEventsContent(startDate, displayDays),
        ),
      ],
    );
  }

  Widget _buildDayTimetable() {
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    // Get events for the day
    List<Event> events;
    switch (selectedSource) {
      case EventSource.shared:
        events = _calendarService.getUnifiedCalendarSync(_demoData.currentUser.id, startDate: startOfDay, endDate: endOfDay);
        break;
      case EventSource.personal:
        events = _calendarService.getUnifiedCalendarSync(_demoData.currentUser.id, startDate: startOfDay, endDate: endOfDay);
        break;
      default:
        events = _calendarService.getEventsBySourceSync(_demoData.currentUser.id, selectedSource, startDate: startOfDay, endDate: endOfDay);
        break;
    }

    return _buildTimetableGrid([selectedDate], events, 1, false);
  }

  Widget _buildMultiDayTimetable(DateTime startDate, int displayDays) {
    final endDate = startDate.add(Duration(days: displayDays));
    final allEvents = _calendarService.getUnifiedCalendarSync(
      _demoData.currentUser.id,
      startDate: startDate,
      endDate: endDate,
    );
    
    final dates = List.generate(displayDays, (index) => startDate.add(Duration(days: index)));
    return _buildTimetableGrid(dates, allEvents, displayDays, true);
  }

  Widget _buildTimetableGrid(List<DateTime> dates, List<Event> events, int dayCount, bool hasExternalHeaders) {
    const double hourHeight = 60.0;
    const int startHour = 6;  // 6 AM
    const int endHour = 22;   // 10 PM
    const int totalHours = endHour - startHour;
    
    // Group events by date
    final Map<String, List<Event>> eventsByDate = {};
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
    
    return SingleChildScrollView(
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
                        color: Colors.grey.shade600,
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
                        color: Colors.grey.shade200,
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
                                  color: Colors.grey.shade200,
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
                                    color: Colors.grey.shade100,
                                  ),
                                );
                              }),
                              
                              // Events
                              ...dayEvents.map((event) => _buildTimetableEvent(
                                event, 
                                hourHeight, 
                                startHour, 
                                dayCount == 1,
                              )),
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

  Widget _buildTimetableEvent(Event event, double hourHeight, int startHour, bool isDetailedView) {
    final startTime = event.startTime;
    final endTime = event.endTime;
    final source = _determineEventSource(event);
    final eventTypeStr = _getSourceLabel(source).toLowerCase();
    final attendeeCount = event.attendeeIds.length;
    
    // Calculate position and height
    final startMinutes = (startTime.hour - startHour) * 60 + startTime.minute;
    final durationMinutes = endTime.difference(startTime).inMinutes;
    final top = (startMinutes / 60.0) * hourHeight;
    final height = (durationMinutes / 60.0) * hourHeight;
    
    // Don't show events outside the visible time range
    if (startTime.hour < startHour || startTime.hour >= (startHour + 16)) {
      return const SizedBox();
    }
    
    // Use appropriate card based on size and detail level
    Widget eventWidget;
    if (isDetailedView) {
      // Day view timetable chip
      eventWidget = EventCards.buildDayTimetableChip(
        event: event,
        eventType: eventTypeStr,
        attendeeCount: attendeeCount,
        onTap: () => _showEventDetails(event, []),
      );
    } else {
      // Week view timetable chip
      eventWidget = EventCards.buildWeekTimetableChip(
        event: event,
        eventType: eventTypeStr,
        attendeeCount: attendeeCount,
        onTap: () => _showEventDetails(event, []),
      );
    }
    
    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: height.clamp(isDetailedView ? 128.0 : 111.0, double.infinity),
      child: eventWidget,
    );
  }

  Widget _buildMultiDayEventsContent(DateTime startDate, int displayDays) {
    // Get events for the entire date range
    final endDate = startDate.add(Duration(days: displayDays));
    final allEvents = _calendarService.getUnifiedCalendarSync(
      _demoData.currentUser.id,
      startDate: startDate,
      endDate: endDate,
    );
    
    // Group events by date
    final Map<String, List<Event>> eventsByDate = {};
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            displayDays == 3 
                ? 'No events for these 3 days'
                : 'No events this week',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Perfect time to plan ahead!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
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
            color: Colors.grey.shade400,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactEventCard(Event event, bool isSelectedDay, {bool isMultiDay = false}) {
    final source = _determineEventSource(event);
    final eventTypeStr = _getSourceLabel(source).toLowerCase();
    final attendeeCount = event.attendeeIds.length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: EventCards.buildWeekViewCard(
        event: event,
        eventType: eventTypeStr,
        attendeeCount: attendeeCount,
        onTap: () => _showEventDetails(event, []),
      ),
    );
  }

  Widget _buildMonthContent() {
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
                  _demoData.currentUser.id,
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
                            color: isSelected ? Colors.white : Colors.black,
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
      ),
    );
  }

  Widget _buildEnhancedEventCard(Event event, Map<String, dynamic> overlayData) {
    final source = _determineEventSource(event);
    final suggestions = _getEventSuggestions(event, overlayData);
    final eventTypeStr = _getSourceLabel(source).toLowerCase();
    final attendeeCount = event.attendeeIds.length;
    
    // Format suggestions for the new card
    final formattedSuggestions = suggestions.map((s) => s.toString()).toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: EventCards.buildDayViewCard(
        event: event,
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No events for ${DateFormat('EEEE, MMM d').format(selectedDate)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Perfect time for a study session!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
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
  Color _getSourceColor(EventSource source) {
    switch (source) {
      case EventSource.personal:
        return AppColors.personalColor;  // Personal events use personal color
      case EventSource.friends:
        return AppColors.socialColor;  // Friends events use social color
      case EventSource.societies:
        return AppColors.societyColor;
      case EventSource.shared:
        return AppColors.personalColor;
    }
  }

  String _getSourceLabel(EventSource source) {
    switch (source) {
      case EventSource.personal:
        return 'Personal';
      case EventSource.friends:
        return 'Friends';
      case EventSource.societies:
        return 'Societies';
      case EventSource.shared:
        return 'Shared';
    }
  }

  Color _getEventColor(Event event) {
    switch (event.type) {
      case EventType.class_:
        return AppColors.personalColor;  // Classes are personal schedule
      case EventType.society:
        return AppColors.societyColor;
      case EventType.personal:
        return AppColors.personalColor;
      case EventType.assignment:
        return AppColors.personalColor;  // Assignments are personal academic
    }
  }

  EventSource _determineEventSource(Event event) {
    if (event.creatorId == _demoData.currentUser.id) return EventSource.personal;
    if (event.societyId != null) return EventSource.societies;
    if (event.attendeeIds.contains(_demoData.currentUser.id)) return EventSource.shared;
    return EventSource.friends;
  }

  List<String> _getEventSuggestions(Event event, Map<String, dynamic> overlayData) {
    final suggestions = <String>[];
    
    // Add friend-related suggestions
    final friendsSchedules = overlayData['friendsSchedules'] as Map<String, List<Event>>;
    for (final friendId in friendsSchedules.keys) {
      final friend = _demoData.getUserById(friendId);
      final friendEvents = friendsSchedules[friendId]!;
      
      // Check if friend has events at same time
      for (final friendEvent in friendEvents) {
        if (_eventsOverlap(event, friendEvent)) {
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

  bool _eventsOverlap(Event event1, Event event2) {
    return event1.startTime.isBefore(event2.endTime) && 
           event2.startTime.isBefore(event1.endTime);
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
                          color: isSelected ? AppColors.personalColor : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('MMM').format(month),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
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


  void _toggleTimetableView() {
    setState(() {
      _useTimetableView = !_useTimetableView;
    });
  }

  void _showAdvancedFilters() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advanced filters would open here')),
    );
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Event'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create shared event functionality would be implemented here.'),
            SizedBox(height: 12),
            Text('This would include:'),
            Text('• Event details form'),
            Text('• Friend invitation system'),
            Text('• Location selection'),
            Text('• Privacy settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event creation would be processed here')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(Event event, List<String> suggestions) {
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
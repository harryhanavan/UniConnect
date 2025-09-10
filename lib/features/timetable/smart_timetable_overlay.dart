import 'package:flutter/material.dart';
import '../../core/demo_data/demo_data_manager.dart';
import '../../core/services/friendship_service.dart';
import '../../core/services/calendar_service.dart';
import '../../shared/models/user.dart';
import '../../shared/models/event.dart';
import '../../core/constants/app_colors.dart';

class SmartTimetableOverlay extends StatefulWidget {
  const SmartTimetableOverlay({super.key});

  @override
  State<SmartTimetableOverlay> createState() => _SmartTimetableOverlayState();
}

class _SmartTimetableOverlayState extends State<SmartTimetableOverlay> {
  late FriendshipService _friendshipService;
  late CalendarService _calendarService;
  late DemoDataManager _demoData;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedView = 'personal';
  List<String> _selectedFriendIds = [];
  bool _showConflicts = true;
  bool _showFreeTime = true;
  bool _isInitialized = false;
  
  final List<String> _timeSlots = [
    '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    _demoData = DemoDataManager.instance;
    _friendshipService = FriendshipService();
    _calendarService = CalendarService();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _demoData.users; // Trigger initialization
      final friends = _friendshipService.getUserFriends(_demoData.currentUser.id);
      _selectedFriendIds = friends.take(3).map((f) => f.id).toList();
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
      appBar: AppBar(
        title: const Text('Smart Timetable'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_module),
            onSelected: (value) {
              setState(() {
                _selectedView = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'personal', child: Text('Personal View')),
              const PopupMenuItem(value: 'overlay', child: Text('Friend Overlay')),
              const PopupMenuItem(value: 'comparison', child: Text('Side Comparison')),
              const PopupMenuItem(value: 'availability', child: Text('Availability Matrix')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildViewControls(),
          Expanded(
            child: _buildTimetableView(),
          ),
          _buildSmartSuggestions(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    _formatDateHeader(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatWeekday(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildViewControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Text('View: '),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildViewChip('personal', 'Personal'),
                      const SizedBox(width: 8),
                      _buildViewChip('overlay', 'Overlay'),
                      const SizedBox(width: 8),
                      _buildViewChip('comparison', 'Compare'),
                      const SizedBox(width: 8),
                      _buildViewChip('availability', 'Free Time'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: _showConflicts,
                      onChanged: (value) {
                        setState(() {
                          _showConflicts = value;
                        });
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                    const Text('Show Conflicts'),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Switch(
                      value: _showFreeTime,
                      onChanged: (value) {
                        setState(() {
                          _showFreeTime = value;
                        });
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                    const Text('Show Free Time'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewChip(String value, String label) {
    final isSelected = _selectedView == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedView = value;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildTimetableView() {
    switch (_selectedView) {
      case 'personal':
        return _buildPersonalTimetable();
      case 'overlay':
        return _buildOverlayTimetable();
      case 'comparison':
        return _buildComparisonTimetable();
      case 'availability':
        return _buildAvailabilityMatrix();
      default:
        return _buildPersonalTimetable();
    }
  }

  Widget _buildPersonalTimetable() {
    final events = _calendarService.getUserEventsForDateSync(_demoData.currentUser.id, _selectedDate);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimetableHeader(['You']),
          Expanded(
            child: ListView.builder(
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = _timeSlots[index];
                final hourEvents = _getEventsForHour(events, index + 8);
                
                return Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          timeSlot,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          child: hourEvents.isNotEmpty
                              ? _buildEventCard(hourEvents.first, Colors.blue)
                              : _showFreeTime
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green[200]!),
                                      ),
                                      child: const Text(
                                        'Free',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayTimetable() {
    final friends = _friendshipService.getUserFriends(_demoData.currentUser.id)
        .where((f) => _selectedFriendIds.contains(f.id))
        .toList();
    
    final userEvents = _calendarService.getUserEventsForDateSync(_demoData.currentUser.id, _selectedDate);
    final friendEvents = <String, List<Event>>{};
    
    for (final friend in friends) {
      friendEvents[friend.id] = _calendarService.getUserEventsForDateSync(friend.id, _selectedDate);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimetableHeader(['You', ...friends.map((f) => f.name.split(' ')[0])]),
          Expanded(
            child: ListView.builder(
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = _timeSlots[index];
                final userHourEvents = _getEventsForHour(userEvents, index + 8);
                
                return Container(
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          timeSlot,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          child: userHourEvents.isNotEmpty
                              ? _buildEventCard(userHourEvents.first, AppColors.primary)
                              : _buildFreeTimeSlot(index + 8, friends, friendEvents),
                        ),
                      ),
                      ...friends.asMap().entries.map((entry) {
                        final friend = entry.value;
                        final events = friendEvents[friend.id] ?? [];
                        final hourEvents = _getEventsForHour(events, index + 8);
                        
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            child: hourEvents.isNotEmpty
                                ? _buildEventCard(hourEvents.first, _getFriendColor(entry.key))
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTimetable() {
    final friends = _friendshipService.getUserFriends(_demoData.currentUser.id).take(2).toList();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _demoData.currentUser.name[0],
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Your Schedule',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildPersonalTimetable(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (friends.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.orange,
                          child: Text(
                            friends.first.name[0],
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${friends.first.name.split(' ')[0]}\'s Schedule',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildFriendTimetable(friends.first),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityMatrix() {
    final friends = _friendshipService.getUserFriends(_demoData.currentUser.id);
    final commonFreeSlots = _friendshipService.findCommonFreeTime(
      _demoData.currentUser.id,
      friends.map((f) => f.id).toList(),
      date: _selectedDate,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common Free Time Slots',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final hour = index + 8;
                final isCommonFree = commonFreeSlots.any((slot) {
                  final startHour = slot['start'].hour;
                  final endHour = slot['end'].hour;
                  return hour >= startHour && hour < endHour;
                });

                return Container(
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCommonFree ? Colors.green[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCommonFree ? Colors.green[300]! : Colors.grey[200]!,
                    ),
                  ),
                  child: ListTile(
                    leading: Text(
                      _timeSlots[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    title: isCommonFree
                        ? const Text(
                            'Available for meetup',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : const Text(
                            'Someone is busy',
                            style: TextStyle(color: Colors.grey),
                          ),
                    trailing: isCommonFree
                        ? IconButton(
                            onPressed: () => _suggestMeetup(hour),
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableHeader(List<String> columns) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.all(8),
            child: const Text(
              'Time',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          ...columns.map((column) => Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                column,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            event.title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (event.location.isNotEmpty)
            Text(
              event.location,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildFreeTimeSlot(int hour, List<User> friends, Map<String, List<Event>> friendEvents) {
    final anyFriendFree = friends.any((friend) {
      final events = friendEvents[friend.id] ?? [];
      return _getEventsForHour(events, hour).isEmpty;
    });

    if (!anyFriendFree || !_showFreeTime) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Free with ${friends.where((f) => _getEventsForHour(friendEvents[f.id] ?? [], hour).isEmpty).length} friends',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTimetable(User friend) {
    final events = _calendarService.getUserEventsForDateSync(friend.id, _selectedDate);
    
    return ListView.builder(
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = _timeSlots[index];
        final hourEvents = _getEventsForHour(events, index + 8);
        
        return Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.all(8),
                child: Text(
                  timeSlot,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  child: hourEvents.isNotEmpty
                      ? _buildEventCard(hourEvents.first, Colors.orange)
                      : _showFreeTime
                          ? Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: const Text(
                                'Free',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartSuggestions() {
    final suggestions = _generateSmartSuggestions();
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Smart Suggestions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.take(2).map((suggestion) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(suggestion['icon'], color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion['text'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: suggestion['action'],
                  child: const Text('Act', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<Event> _getEventsForHour(List<Event> events, int hour) {
    return events.where((event) {
      return event.startTime.hour <= hour && event.endTime.hour > hour;
    }).toList();
  }

  Color _getFriendColor(int index) {
    final colors = [Colors.orange, Colors.purple, Colors.teal, Colors.red];
    return colors[index % colors.length];
  }

  List<Map<String, dynamic>> _generateSmartSuggestions() {
    final suggestions = <Map<String, dynamic>>[];
    final friends = _friendshipService.getUserFriends(_demoData.currentUser.id);
    
    final commonFreeSlots = _friendshipService.findCommonFreeTime(
      _demoData.currentUser.id,
      friends.take(3).map((f) => f.id).toList(),
      date: _selectedDate,
    );

    if (commonFreeSlots.isNotEmpty) {
      suggestions.add({
        'icon': Icons.coffee,
        'text': 'You have ${commonFreeSlots.length} free slots with friends today. Perfect for a study break!',
        'action': () => _suggestMeetup(commonFreeSlots.first['start'].hour),
      });
    }

    final userEvents = _calendarService.getUserEventsForDateSync(_demoData.currentUser.id, _selectedDate);
    final studyEvents = userEvents.where((e) => e.title.toLowerCase().contains('study')).toList();
    
    if (studyEvents.isNotEmpty && friends.isNotEmpty) {
      suggestions.add({
        'icon': Icons.group,
        'text': 'Invite friends to your study session for better motivation',
        'action': () => _inviteToStudySession(studyEvents.first),
      });
    }

    return suggestions;
  }

  void _suggestMeetup(int hour) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggest Meetup'),
        content: Text('Would you like to suggest meeting friends at ${_timeSlots[hour - 8]}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meetup suggestion sent to friends!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _inviteToStudySession(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invite to ${event.title}'),
        content: const Text('Select friends to invite to this study session:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Study session invites sent!')),
              );
            },
            child: const Text('Send Invites'),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatWeekday(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 
                     'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }
}
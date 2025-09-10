import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../core/demo_data/demo_data_manager.dart';

class SocietyDetailScreen extends StatefulWidget {
  final Society society;

  const SocietyDetailScreen({
    super.key,
    required this.society,
  });

  @override
  State<SocietyDetailScreen> createState() => _SocietyDetailScreenState();
}

class _SocietyDetailScreenState extends State<SocietyDetailScreen> {
  late Society currentSociety;
  List<Event> upcomingEvents = [];
  bool notificationsEnabled = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    currentSociety = widget.society;
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await DemoDataManager.instance.events; // Trigger initialization
      _loadUpcomingEvents();
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }

  void _loadUpcomingEvents() {
    final allEvents = DemoDataManager.instance.eventsSync;
    upcomingEvents = allEvents
        .where((event) => 
            event.source == EventSource.societies && 
            event.societyId == widget.society.id &&
            event.startTime.isAfter(DateTime.now()))
        .take(3)
        .toList();
  }

  void _toggleJoinSociety() {
    setState(() {
      if (currentSociety.isJoined) {
        currentSociety = currentSociety.copyWith(
          isJoined: false,
          memberCount: currentSociety.memberCount - 1,
        );
      } else {
        currentSociety = currentSociety.copyWith(
          isJoined: true,
          memberCount: currentSociety.memberCount + 1,
        );
      }
    });
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  // Society Header Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Society Image/Logo Section  
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Logo/Image
                              Center(
                                child: currentSociety.logoUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: currentSociety.logoUrl!,
                                        fit: BoxFit.contain,
                                        height: 120,
                                        placeholder: (context, url) => SizedBox(
                                          height: 120,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => 
                                            _buildSocietyPlaceholder(),
                                      )
                                    : _buildSocietyPlaceholder(),
                              ),
                              
                              // Category Tag
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: ShapeDecoration(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        bottomRight: Radius.circular(6),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    currentSociety.category,
                                    style: const TextStyle(
                                      color: Colors.black,
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
                        
                        // Society Info Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Society Name
                              Text(
                                currentSociety.name,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Member Count
                              Text(
                                '${currentSociety.memberCount} members',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.50),
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.67,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Tags
                              if (currentSociety.tags.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: currentSociety.tags.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: ShapeDecoration(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          width: 0.50,
                                          color: Colors.black.withValues(alpha: 0.10),
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w400,
                                        height: 1.33,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              
                              const SizedBox(height: 16),
                              
                              // Join Society Button
                              Container(
                                width: double.infinity,
                                height: 48,
                                decoration: ShapeDecoration(
                                  color: currentSociety.isJoined 
                                      ? const Color(0xFF34C759) 
                                      : const Color(0xFF0D99FF),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: Colors.black.withValues(alpha: 0.1),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: _toggleJoinSociety,
                                  child: Text(
                                    currentSociety.isJoined ? 'Joined' : 'Join Society',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Short Description and Contact Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSociety.description,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Contact email
                          if (currentSociety.id == 'soc_001') ...
                          [
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening email client...')),
                                );
                              },
                              child: Text(
                                'uxidsoc@activateuts.com.au',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // About Us Section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About Us',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentSociety.aboutUs ?? currentSociety.description,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Website link for UXID Society
                          if (currentSociety.id == 'soc_001') ...
                          [
                            GestureDetector(
                              onTap: () {
                                // Website link functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening UXID Society website...')),
                                );
                              },
                              child: Text(
                                'Check out our Website!',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Upcoming Events Section
                  if (upcomingEvents.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: Colors.black.withValues(alpha: 0.10),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '${upcomingEvents.length} upcoming events',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    // Event Cards
                    ...upcomingEvents.map((event) => _buildEventCard(event)),
                  ],

                  // Sample Announcement
                  _buildAnnouncementCard(),

                  // Notifications Section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Notification toggles
                          _buildNotificationToggle('Event Reminders', notificationsEnabled),
                          const SizedBox(height: 16),
                          _buildNotificationToggle('New announcements', true),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      width: double.infinity,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              event.description,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.67,
              ),
            ),
            const SizedBox(height: 30),
            
            // When and Where info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // When
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'When\n',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '\n${_formatEventTime(event)}',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            height: 1.33,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Where
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Where\n',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '\n${event.location}',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            height: 1.33,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Add to calendar button
            Center(
              child: Container(
                width: 196,
                height: 42,
                decoration: ShapeDecoration(
                  color: const Color(0xFF0D99FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(34),
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    // Add to calendar functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${event.title} added to calendar')),
                    );
                  },
                  child: const Text(
                    'Add to calendar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      width: double.infinity,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Welcome New Members!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '2 days ago',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'Welcome to all our new members! We\'re excited to have you join our community. Don\'t forget to introduce yourself in our Discord channel.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.67,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(String title, bool isEnabled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 0.5,
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            width: 64,
            height: 28,
            decoration: ShapeDecoration(
              color: isEnabled 
                  ? const Color(0xFF34C759) 
                  : Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: isEnabled ? 23 : 2,
                  top: 2,
                  child: Container(
                    width: 39,
                    height: 24,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventTime(Event event) {
    final day = event.startTime.day;
    final month = _getMonthName(event.startTime.month);
    final startHour = event.startTime.hour;
    final endHour = event.endTime.hour;
    
    return '$day $month ${event.startTime.year}, ${startHour}:00 - ${endHour}:00';
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
  
  Widget _buildSocietyPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.group,
        size: 40,
        color: Colors.grey[600],
      ),
    );
  }
}
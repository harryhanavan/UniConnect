import '../../shared/models/study_group.dart';
import '../demo_data/demo_data_manager.dart';
import 'friendship_service.dart';
import 'calendar_service.dart';

class StudyGroupService {
  static final StudyGroupService _instance = StudyGroupService._internal();
  factory StudyGroupService() => _instance;
  StudyGroupService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  final FriendshipService _friendshipService = FriendshipService();
  final CalendarService _calendarService = CalendarService();
  
  bool _isInitialized = false;

  // Demo study groups data
  final List<StudyGroup> _studyGroups = [];
  final List<StudySession> _studySessions = [];
  
  // Ensure data is loaded before using any methods
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _demoData.users; // This triggers async initialization
      _isInitialized = true;
    }
  }

  // Initialize demo data
  void _initializeDemoData() {
    if (_studyGroups.isNotEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _studyGroups.addAll([
      StudyGroup(
        id: 'sg_001',
        name: 'Database Systems Study Group',
        description: 'Preparing for the final exam together. Focus on SQL, normalization, and transaction management.',
        courseCode: '31244',
        courseName: 'Database Systems',
        type: StudyGroupType.exam,
        creatorId: 'user_002',
        memberIds: ['user_001', 'user_002', 'user_005'],
        invitedUserIds: ['user_003'],
        maxMembers: 6,
        createdAt: now.subtract(const Duration(days: 10)),
        nextMeetingAt: today.add(const Duration(days: 2, hours: 14)),
        nextMeetingLocation: 'Library Study Room 3A',
        tags: ['SQL', 'Database Design', 'Final Exam'],
      ),
      StudyGroup(
        id: 'sg_002',
        name: 'Interactive Design Portfolio',
        description: 'Working together on our final portfolio submissions. Peer review and feedback sessions.',
        courseCode: '41021',
        courseName: 'Interactive Design Studio',
        type: StudyGroupType.project,
        creatorId: 'user_001',
        memberIds: ['user_001', 'user_002'],
        maxMembers: 4,
        createdAt: now.subtract(const Duration(days: 5)),
        nextMeetingAt: today.add(const Duration(days: 1, hours: 16)),
        nextMeetingLocation: 'Design Studio B',
        tags: ['Portfolio', 'Peer Review', 'Design'],
      ),
      StudyGroup(
        id: 'sg_003',
        name: 'Engineering Mathematics Cramming',
        description: 'Last-minute exam preparation for calculus and linear algebra. Problem-solving focused.',
        courseCode: 'MATH101',
        courseName: 'Engineering Mathematics',
        type: StudyGroupType.exam,
        creatorId: 'user_003',
        memberIds: ['user_003'],
        invitedUserIds: [],
        maxMembers: 8,
        createdAt: now.subtract(const Duration(days: 2)),
        tags: ['Mathematics', 'Problem Solving', 'Exam Prep'],
      ),
      StudyGroup(
        id: 'sg_004',
        name: 'Business Plan Development',
        description: 'Collaborative work on startup business plans for entrepreneurship course.',
        courseCode: 'BUS301',
        courseName: 'Entrepreneurship',
        type: StudyGroupType.assignment,
        creatorId: 'user_004',
        memberIds: ['user_004'],
        maxMembers: 5,
        createdAt: now.subtract(const Duration(days: 1)),
        tags: ['Business Plan', 'Entrepreneurship', 'Startups'],
      ),
    ]);

    _studySessions.addAll([
      StudySession(
        id: 'ss_001',
        studyGroupId: 'sg_001',
        title: 'SQL Practice Session',
        description: 'Working through complex SQL queries and joins',
        startTime: today.subtract(const Duration(days: 3, hours: -14)),
        endTime: today.subtract(const Duration(days: 3, hours: -16)),
        location: 'Library Study Room 3A',
        attendeeIds: ['user_001', 'user_002', 'user_005'],
        materials: ['SQL Practice Problems.pdf', 'Database Schema Examples'],
        notes: 'Covered complex joins and subqueries. Need more practice with window functions.',
        createdAt: now.subtract(const Duration(days: 4)),
        creatorId: 'user_002',
      ),
      StudySession(
        id: 'ss_002',
        studyGroupId: 'sg_002',
        title: 'Portfolio Review Session',
        description: 'Peer feedback on portfolio draft submissions',
        startTime: today.add(const Duration(days: 1, hours: 16)),
        endTime: today.add(const Duration(days: 1, hours: 18)),
        location: 'Design Studio B',
        attendeeIds: ['user_001', 'user_002'],
        materials: ['Portfolio Guidelines.pdf', 'Evaluation Criteria'],
        createdAt: now.subtract(const Duration(days: 1)),
        creatorId: 'user_001',
      ),
    ]);
  }

  // Get all study groups
  List<StudyGroup> getAllStudyGroups() {
    _initializeDemoData();
    return List.unmodifiable(_studyGroups);
  }

  // Get study groups for current user
  List<StudyGroup> getMyStudyGroups() {
    _initializeDemoData();
    final userId = _demoData.currentUser.id;
    return _studyGroups
        .where((group) => group.memberIds.contains(userId))
        .toList();
  }

  // Get available study groups to join
  List<StudyGroup> getAvailableStudyGroups() {
    _initializeDemoData();
    final userId = _demoData.currentUser.id;
    return _studyGroups
        .where((group) =>
            !group.memberIds.contains(userId) &&
            !group.isFull &&
            group.isActive)
        .toList();
  }

  // Get study groups by course
  List<StudyGroup> getStudyGroupsByCourse(String courseCode) {
    _initializeDemoData();
    return _studyGroups
        .where((group) => group.courseCode == courseCode && group.isActive)
        .toList();
  }

  // Search study groups
  List<StudyGroup> searchStudyGroups(String query) {
    _initializeDemoData();
    final lowerQuery = query.toLowerCase();
    return _studyGroups
        .where((group) =>
            group.name.toLowerCase().contains(lowerQuery) ||
            group.description.toLowerCase().contains(lowerQuery) ||
            group.courseCode.toLowerCase().contains(lowerQuery) ||
            group.courseName.toLowerCase().contains(lowerQuery) ||
            group.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  // Create new study group
  Future<StudyGroup> createStudyGroup({
    required String name,
    required String description,
    required String courseCode,
    required String courseName,
    required StudyGroupType type,
    int maxMembers = 8,
    DateTime? nextMeetingAt,
    String? nextMeetingLocation,
    List<String> tags = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newGroup = StudyGroup(
      id: 'sg_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      courseCode: courseCode,
      courseName: courseName,
      type: type,
      creatorId: _demoData.currentUser.id,
      memberIds: [_demoData.currentUser.id],
      maxMembers: maxMembers,
      createdAt: DateTime.now(),
      nextMeetingAt: nextMeetingAt,
      nextMeetingLocation: nextMeetingLocation,
      tags: tags,
    );

    _studyGroups.add(newGroup);
    return newGroup;
  }

  // Join study group
  Future<bool> joinStudyGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final groupIndex = _studyGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return false;

    final group = _studyGroups[groupIndex];
    final userId = _demoData.currentUser.id;

    if (group.memberIds.contains(userId) || group.isFull) {
      return false;
    }

    final updatedGroup = group.copyWith(
      memberIds: [...group.memberIds, userId],
    );

    _studyGroups[groupIndex] = updatedGroup;
    return true;
  }

  // Leave study group
  Future<bool> leaveStudyGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final groupIndex = _studyGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex == -1) return false;

    final group = _studyGroups[groupIndex];
    final userId = _demoData.currentUser.id;

    if (!group.memberIds.contains(userId)) return false;

    final updatedMembers = group.memberIds.where((id) => id != userId).toList();
    
    if (updatedMembers.isEmpty) {
      // Archive group if no members left
      final updatedGroup = group.copyWith(
        memberIds: updatedMembers,
        status: StudyGroupStatus.archived,
      );
      _studyGroups[groupIndex] = updatedGroup;
    } else {
      final updatedGroup = group.copyWith(memberIds: updatedMembers);
      _studyGroups[groupIndex] = updatedGroup;
    }

    return true;
  }

  // Get study group by ID
  StudyGroup? getStudyGroupById(String id) {
    _initializeDemoData();
    try {
      return _studyGroups.firstWhere((group) => group.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update study group
  Future<bool> updateStudyGroup(StudyGroup updatedGroup) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _studyGroups.indexWhere((g) => g.id == updatedGroup.id);
    if (index == -1) return false;

    _studyGroups[index] = updatedGroup;
    return true;
  }

  // Schedule study session
  Future<StudySession> scheduleStudySession({
    required String studyGroupId,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    String? locationId,
    List<String> materials = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final session = StudySession(
      id: 'ss_${DateTime.now().millisecondsSinceEpoch}',
      studyGroupId: studyGroupId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      locationId: locationId,
      attendeeIds: [], // Will be populated as members RSVP
      materials: materials,
      createdAt: DateTime.now(),
      creatorId: _demoData.currentUser.id,
    );

    _studySessions.add(session);

    // Update group's next meeting info
    final group = getStudyGroupById(studyGroupId);
    if (group != null) {
      final updatedGroup = group.copyWith(
        nextMeetingAt: startTime,
        nextMeetingLocation: location,
      );
      await updateStudyGroup(updatedGroup);
    }

    return session;
  }

  // Get study sessions for a group
  List<StudySession> getStudySessionsForGroup(String groupId) {
    _initializeDemoData();
    return _studySessions
        .where((session) => session.studyGroupId == groupId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Get upcoming study sessions for user
  List<StudySession> getUpcomingStudySessionsForUser() {
    _initializeDemoData();
    final userGroups = getMyStudyGroups();
    final userGroupIds = userGroups.map((g) => g.id).toSet();

    return _studySessions
        .where((session) =>
            userGroupIds.contains(session.studyGroupId) &&
            session.isUpcoming)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // RSVP to study session
  Future<bool> rsvpToStudySession(String sessionId, bool attending) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final sessionIndex = _studySessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return false;

    final session = _studySessions[sessionIndex];
    final userId = _demoData.currentUser.id;
    final currentAttendees = List<String>.from(session.attendeeIds);

    if (attending && !currentAttendees.contains(userId)) {
      currentAttendees.add(userId);
    } else if (!attending && currentAttendees.contains(userId)) {
      currentAttendees.remove(userId);
    }

    _studySessions[sessionIndex] = session.copyWith(attendeeIds: currentAttendees);
    return true;
  }

  // Get study group recommendations based on user's courses and friends
  List<StudyGroup> getRecommendedStudyGroups() {
    if (!_isInitialized) {
      throw StateError('StudyGroupService not initialized. Call await _ensureInitialized() first.');
    }
    
    _initializeDemoData();
    final currentUser = _demoData.currentUser;
    final friends = _demoData.getFriendsForUser(currentUser.id);
    final friendIds = friends.map((f) => f.id).toSet();

    // Get user's enrolled courses from their events
    final userEvents = _calendarService.getUnifiedCalendarSync(currentUser.id);
    final userCourses = userEvents
        .where((event) => event.courseCode != null)
        .map((event) => event.courseCode!)
        .toSet();

    final sortedItems = _studyGroups
        .where((group) =>
            !group.memberIds.contains(currentUser.id) &&
            group.isActive &&
            !group.isFull)
        .map((group) {
          int score = 0;

          // Boost score if it's for user's course
          if (userCourses.contains(group.courseCode)) {
            score += 10;
          }

          // Boost score if friends are in the group
          final friendsInGroup = group.memberIds.where((id) => friendIds.contains(id)).length;
          score += friendsInGroup * 5;

          // Boost score based on group activity
          if (group.hasUpcomingMeeting) {
            score += 3;
          }

          return {'group': group, 'score': score};
        })
        .where((item) => (item['score'] as int) > 0)
        .toList();
    
    sortedItems.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return sortedItems.map((item) => item['group'] as StudyGroup).toList();
  }

  // Find optimal study times for group members
  Map<String, dynamic> findOptimalStudyTimes(String groupId, DateTime date) {
    final group = getStudyGroupById(groupId);
    if (group == null) return {};

    final commonTimes = _friendshipService.findCommonFreeTime(
      _demoData.currentUser.id,
      group.memberIds.where((id) => id != _demoData.currentUser.id).toList(),
      date: date,
    );

    return {
      'date': date,
      'groupId': groupId,
      'memberCount': group.memberIds.length,
      'availableSlots': commonTimes,
    };
  }

  // Get study group statistics
  Map<String, dynamic> getStudyGroupStats() {
    _initializeDemoData();
    final userId = _demoData.currentUser.id;
    final myGroups = getMyStudyGroups();
    final upcomingSessions = getUpcomingStudySessionsForUser();

    return {
      'totalGroups': myGroups.length,
      'activeGroups': myGroups.where((g) => g.isActive).length,
      'upcomingSessions': upcomingSessions.length,
      'completedSessions': _studySessions
          .where((s) =>
              myGroups.map((g) => g.id).contains(s.studyGroupId) &&
              s.isCompleted)
          .length,
      'studyHoursThisWeek': _calculateStudyHoursThisWeek(userId),
    };
  }

  int _calculateStudyHoursThisWeek(String userId) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final userGroups = getMyStudyGroups();
    final userGroupIds = userGroups.map((g) => g.id).toSet();

    final weekSessions = _studySessions
        .where((session) =>
            userGroupIds.contains(session.studyGroupId) &&
            session.attendeeIds.contains(userId) &&
            session.startTime.isAfter(weekStart) &&
            session.startTime.isBefore(weekEnd))
        .toList();

    return weekSessions.fold(0, (total, session) => total + session.duration.inHours);
  }
}
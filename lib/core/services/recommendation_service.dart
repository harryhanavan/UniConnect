import 'dart:math';
import '../../shared/models/user.dart';
import '../../shared/models/event.dart';
import '../demo_data/demo_data_manager.dart';
import 'friendship_service.dart';
import 'location_service.dart';

enum RecommendationType {
  friends,
  events,
  societies,
  studyPartners,
  locations,
  courses,
}

class Recommendation {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final RecommendationType type;
  final double confidence;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final List<String> reasons;
  final DateTime timestamp;

  Recommendation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.type,
    required this.confidence,
    required this.data,
    this.imageUrl,
    required this.reasons,
    required this.timestamp,
  });
}

class UserProfile {
  final String userId;
  final Map<String, double> interestScores;
  final Map<String, int> activityCounts;
  final Set<String> preferredLocations;
  final Set<String> activeTimeSlots;
  final Map<String, double> socialConnections;
  
  UserProfile({
    required this.userId,
    required this.interestScores,
    required this.activityCounts,
    required this.preferredLocations,
    required this.activeTimeSlots,
    required this.socialConnections,
  });
}

class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  final FriendshipService _friendshipService = FriendshipService();
  final LocationService _locationService = LocationService();

  // Cache for user profiles
  final Map<String, UserProfile> _userProfiles = {};
  
  // Interaction tracking
  final Map<String, Map<String, int>> _userInteractions = {};
  
  // Content-based similarity cache
  final Map<String, Map<String, double>> _similarityCache = {};

  // Generate comprehensive recommendations for a user
  Future<List<Recommendation>> getRecommendations({
    required String userId,
    List<RecommendationType>? types,
    int limit = 20,
  }) async {
    final targetTypes = types ?? RecommendationType.values;
    final allRecommendations = <Recommendation>[];

    // Build or update user profile
    final userProfile = await _buildUserProfile(userId);

    // Generate recommendations by type
    for (final type in targetTypes) {
      switch (type) {
        case RecommendationType.friends:
          allRecommendations.addAll(await _recommendFriends(userId, userProfile));
          break;
        case RecommendationType.events:
          allRecommendations.addAll(await _recommendEvents(userId, userProfile));
          break;
        case RecommendationType.societies:
          allRecommendations.addAll(await _recommendSocieties(userId, userProfile));
          break;
        case RecommendationType.studyPartners:
          allRecommendations.addAll(await _recommendStudyPartners(userId, userProfile));
          break;
        case RecommendationType.locations:
          allRecommendations.addAll(await _recommendLocations(userId, userProfile));
          break;
        case RecommendationType.courses:
          allRecommendations.addAll(await _recommendCourses(userId, userProfile));
          break;
      }
    }

    // Sort by confidence score and apply diversity
    allRecommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
    final diversifiedRecs = _applyDiversification(allRecommendations, limit);
    
    return diversifiedRecs.take(limit).toList();
  }

  // Build comprehensive user profile
  Future<UserProfile> _buildUserProfile(String userId) async {
    if (_userProfiles.containsKey(userId)) {
      return _userProfiles[userId]!;
    }

    final user = _demoData.getUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    // Calculate interest scores based on multiple factors
    final interestScores = <String, double>{};
    final activityCounts = <String, int>{};
    final preferredLocations = <String>{};
    final activeTimeSlots = <String>{};
    final socialConnections = <String, double>{};

    // Analyze user's society memberships
    final joinedSocieties = _demoData.joinedSocieties;
    for (final society in joinedSocieties) {
      // Category interest
      interestScores[society.category] = (interestScores[society.category] ?? 0) + 1.0;
      
      // Tag interests
      for (final tag in society.tags) {
        interestScores[tag] = (interestScores[tag] ?? 0) + 0.5;
      }
      
      activityCounts['societies'] = (activityCounts['societies'] ?? 0) + 1;
    }

    // Analyze event attendance patterns
    final userEvents = _demoData.eventsSync.where((event) => 
      event.creatorId == userId || event.attendeeIds.contains(userId));
    
    for (final event in userEvents) {
      // Event type preferences
      final eventType = event.type.toString().split('.').last;
      interestScores[eventType] = (interestScores[eventType] ?? 0) + 0.8;
      
      // Location preferences
      preferredLocations.add(event.location);
      
      // Time slot preferences
      final timeSlot = '${event.startTime.hour}:00';
      activeTimeSlots.add(timeSlot);
      
      // Course interests
      if (event.courseCode != null) {
        interestScores[event.courseCode!] = (interestScores[event.courseCode!] ?? 0) + 1.2;
      }
      
      activityCounts['events'] = (activityCounts['events'] ?? 0) + 1;
    }

    // Analyze social connections strength
    final friends = _friendshipService.getUserFriends(userId);
    for (final friend in friends) {
      // Calculate connection strength based on mutual friends and common activities
      final mutualFriends = _friendshipService.getMutualFriendsSync(userId, friend.id);
      final connectionStrength = 1.0 + (mutualFriends.length * 0.2);
      socialConnections[friend.id] = connectionStrength;
    }

    // Course-based interests
    final courseInterests = _extractCourseInterests(user.course);
    for (final entry in courseInterests.entries) {
      interestScores[entry.key] = (interestScores[entry.key] ?? 0) + entry.value;
    }

    final profile = UserProfile(
      userId: userId,
      interestScores: interestScores,
      activityCounts: activityCounts,
      preferredLocations: preferredLocations,
      activeTimeSlots: activeTimeSlots,
      socialConnections: socialConnections,
    );

    _userProfiles[userId] = profile;
    return profile;
  }

  // Recommend friends using collaborative filtering
  Future<List<Recommendation>> _recommendFriends(String userId, UserProfile profile) async {
    final recommendations = <Recommendation>[];
    final user = _demoData.getUserById(userId)!;
    final currentFriends = _friendshipService.getUserFriends(userId).map((f) => f.id).toSet();
    
    for (final candidate in _demoData.usersSync) {
      if (candidate.id == userId || currentFriends.contains(candidate.id)) continue;
      
      double score = 0.0;
      final reasons = <String>[];

      // Course similarity
      if (candidate.course.contains(_extractMainCourse(user.course))) {
        score += 0.4;
        reasons.add('Same course');
      }

      // Year similarity
      if (candidate.year == user.year) {
        score += 0.3;
        reasons.add('Same year');
      }

      // Mutual friends boost
      final mutualFriends = _friendshipService.getMutualFriendsSync(userId, candidate.id);
      if (mutualFriends.isNotEmpty) {
        score += mutualFriends.length * 0.2;
        reasons.add('${mutualFriends.length} mutual friends');
      }

      // Society overlap
      final candidateSocieties = _demoData.societiesSync.where((s) => s.memberIds.contains(candidate.id));
      final userSocieties = _demoData.joinedSocieties.map((s) => s.id).toSet();
      final commonSocieties = candidateSocieties.where((s) => userSocieties.contains(s.id)).length;
      
      if (commonSocieties > 0) {
        score += commonSocieties * 0.25;
        reasons.add('$commonSocieties shared societies');
      }

      // Location proximity
      if (candidate.latitude != null && candidate.longitude != null && 
          user.latitude != null && user.longitude != null) {
        final distance = _locationService.calculateDistance(
          user.latitude!,
          user.longitude!,
          candidate.latitude!,
          candidate.longitude!,
        );
        if (distance < 1000) {
          score += 0.2;
          reasons.add('Currently nearby');
        }
      }

      // Interest similarity based on profile
      final interestSimilarity = _calculateInterestSimilarity(profile, candidate);
      score += interestSimilarity * 0.3;
      if (interestSimilarity > 0.5) {
        reasons.add('Similar interests');
      }

      // Activity level similarity
      if (candidate.isOnline) {
        score += 0.1;
        reasons.add('Currently active');
      }

      if (score > 0.3 && reasons.isNotEmpty) { // Threshold for recommendation
        recommendations.add(Recommendation(
          id: candidate.id,
          title: candidate.name,
          subtitle: '${candidate.course} • ${candidate.year}',
          description: 'Recommended based on ${reasons.join(", ")}',
          type: RecommendationType.friends,
          confidence: min(score, 1.0),
          data: {'user': candidate},
          imageUrl: candidate.profileImageUrl,
          reasons: reasons,
          timestamp: DateTime.now(),
        ));
      }
    }

    return recommendations;
  }

  // Recommend events using hybrid filtering
  Future<List<Recommendation>> _recommendEvents(String userId, UserProfile profile) async {
    final recommendations = <Recommendation>[];
    final user = _demoData.getUserById(userId)!;
    final now = DateTime.now();
    
    for (final event in _demoData.eventsSync) {
      if (event.startTime.isBefore(now) || event.attendeeIds.contains(userId)) continue;
      
      double score = 0.0;
      final reasons = <String>[];

      // Course relevance
      if (event.courseCode != null && user.course.contains(event.courseCode!)) {
        score += 0.5;
        reasons.add('Your course');
      }

      // Event type preference
      final eventType = event.type.toString().split('.').last;
      if (profile.interestScores.containsKey(eventType)) {
        score += profile.interestScores[eventType]! * 0.1;
        reasons.add('You attend $eventType events');
      }

      // Location preference
      if (profile.preferredLocations.contains(event.location)) {
        score += 0.2;
        reasons.add('Familiar location');
      }

      // Time slot preference
      final eventTimeSlot = '${event.startTime.hour}:00';
      if (profile.activeTimeSlots.contains(eventTimeSlot)) {
        score += 0.15;
        reasons.add('Your preferred time');
      }

      // Friend attendance
      final friendsAttending = event.attendeeIds
          .where((id) => profile.socialConnections.containsKey(id))
          .length;
      if (friendsAttending > 0) {
        score += friendsAttending * 0.2;
        reasons.add('$friendsAttending friends attending');
      }

      // Society relevance
      if (event.societyId != null) {
        final society = _demoData.societiesSync.firstWhere((s) => s.id == event.societyId);
        if (profile.interestScores.containsKey(society.category)) {
          score += profile.interestScores[society.category]! * 0.1;
          reasons.add('${society.category} interest');
        }
      }

      // Recency boost (upcoming events)
      final hoursUntilEvent = event.startTime.difference(now).inHours;
      if (hoursUntilEvent <= 24) {
        score += 0.3;
        reasons.add('Happening soon');
      } else if (hoursUntilEvent <= 168) {
        score += 0.2;
        reasons.add('This week');
      }

      if (score > 0.2 && reasons.isNotEmpty) {
        recommendations.add(Recommendation(
          id: event.id,
          title: event.title,
          subtitle: _formatEventTime(event),
          description: 'Recommended because: ${reasons.join(", ")}',
          type: RecommendationType.events,
          confidence: min(score, 1.0),
          data: {'event': event},
          reasons: reasons,
          timestamp: DateTime.now(),
        ));
      }
    }

    return recommendations;
  }

  // Recommend societies using content-based filtering
  Future<List<Recommendation>> _recommendSocieties(String userId, UserProfile profile) async {
    final recommendations = <Recommendation>[];
    final joinedSocietyIds = _demoData.joinedSocieties.map((s) => s.id).toSet();
    
    for (final society in _demoData.societiesSync) {
      if (joinedSocietyIds.contains(society.id)) continue;
      
      double score = 0.0;
      final reasons = <String>[];

      // Category interest
      if (profile.interestScores.containsKey(society.category)) {
        score += profile.interestScores[society.category]! * 0.2;
        reasons.add('${society.category} interest');
      }

      // Tag matching
      double tagScore = 0.0;
      final matchedTags = <String>[];
      for (final tag in society.tags) {
        if (profile.interestScores.containsKey(tag)) {
          tagScore += profile.interestScores[tag]! * 0.15;
          matchedTags.add(tag);
        }
      }
      score += tagScore;
      if (matchedTags.isNotEmpty) {
        reasons.add('Tags: ${matchedTags.join(", ")}');
      }

      // Friend membership
      final friendsInSociety = society.memberIds
          .where((memberId) => profile.socialConnections.containsKey(memberId))
          .length;
      if (friendsInSociety > 0) {
        score += friendsInSociety * 0.25;
        reasons.add('$friendsInSociety friends are members');
      }

      // Size preference (not too small, not too big)
      if (society.memberCount >= 50 && society.memberCount <= 500) {
        score += 0.1;
        reasons.add('Good size community');
      }

      // Course alignment
      final user = _demoData.getUserById(userId)!;
      final mainCourse = _extractMainCourse(user.course);
      if (society.name.toLowerCase().contains(mainCourse.toLowerCase()) ||
          society.description.toLowerCase().contains(mainCourse.toLowerCase())) {
        score += 0.3;
        reasons.add('Course relevance');
      }

      if (score > 0.25 && reasons.isNotEmpty) {
        recommendations.add(Recommendation(
          id: society.id,
          title: society.name,
          subtitle: '${society.category} • ${society.memberCount} members',
          description: 'Recommended because: ${reasons.join(", ")}',
          type: RecommendationType.societies,
          confidence: min(score, 1.0),
          data: {'society': society},
          imageUrl: society.logoUrl,
          reasons: reasons,
          timestamp: DateTime.now(),
        ));
      }
    }

    return recommendations;
  }

  // Recommend study partners
  Future<List<Recommendation>> _recommendStudyPartners(String userId, UserProfile profile) async {
    final recommendations = <Recommendation>[];
    final user = _demoData.getUserById(userId)!;
    final currentFriends = _friendshipService.getUserFriends(userId).map((f) => f.id).toSet();
    
    // Find users in same courses with complementary study schedules
    for (final candidate in _demoData.usersSync) {
      if (candidate.id == userId || currentFriends.contains(candidate.id)) continue;
      
      double score = 0.0;
      final reasons = <String>[];

      // Course overlap (essential for study partners)
      final courseOverlap = _calculateCourseOverlap(user.course, candidate.course);
      if (courseOverlap > 0.3) {
        score += courseOverlap * 0.6;
        reasons.add('Same courses');
      } else {
        continue; // Skip if no significant course overlap
      }

      // Study schedule compatibility
      final scheduleCompatibility = _calculateScheduleCompatibility(userId, candidate.id);
      if (scheduleCompatibility > 0.2) {
        score += scheduleCompatibility * 0.3;
        reasons.add('Compatible study times');
      }

      // Academic performance indication (simulated)
      if (candidate.year == user.year) {
        score += 0.2;
        reasons.add('Same academic level');
      }

      // Location compatibility
      if (candidate.latitude != null && candidate.longitude != null && 
          user.latitude != null && user.longitude != null) {
        final distance = _locationService.calculateDistance(
          user.latitude!,
          user.longitude!,
          candidate.latitude!,
          candidate.longitude!,
        );
        if (distance < 2000) {
          score += 0.15;
          reasons.add('Study locations nearby');
        }
      }

      // Mutual connections (trust factor)
      final mutualFriends = _friendshipService.getMutualFriendsSync(userId, candidate.id);
      if (mutualFriends.isNotEmpty) {
        score += mutualFriends.length * 0.1;
        reasons.add('${mutualFriends.length} mutual connections');
      }

      if (score > 0.4 && reasons.isNotEmpty) {
        recommendations.add(Recommendation(
          id: candidate.id,
          title: '${candidate.name} (Study Partner)',
          subtitle: '${candidate.course} • ${candidate.year}',
          description: 'Great study partner because: ${reasons.join(", ")}',
          type: RecommendationType.studyPartners,
          confidence: min(score, 1.0),
          data: {'user': candidate, 'studyPartner': true},
          imageUrl: candidate.profileImageUrl,
          reasons: reasons,
          timestamp: DateTime.now(),
        ));
      }
    }

    return recommendations;
  }

  // Recommend locations based on usage patterns
  Future<List<Recommendation>> _recommendLocations(String userId, UserProfile profile) async {
    final recommendations = <Recommendation>[];
    final user = _demoData.getUserById(userId)!;
    
    for (final location in _demoData.locationsSync) {
      double score = 0.0;
      final reasons = <String>[];

      // Location type preference
      final locationType = location.type.toString().split('.').last;
      if (profile.interestScores.containsKey(locationType)) {
        score += profile.interestScores[locationType]! * 0.1;
        reasons.add('You use ${locationType}s');
      }

      // Friends at location
      final friendsAtLocation = _demoData.usersSync
          .where((u) => profile.socialConnections.containsKey(u.id) && 
                       u.currentLocationId == location.id)
          .length;
      if (friendsAtLocation > 0) {
        score += friendsAtLocation * 0.3;
        reasons.add('$friendsAtLocation friends here');
      }

      // Proximity to current location
      if (user.latitude != null && user.longitude != null) {
        final distance = _locationService.calculateDistance(
          user.latitude!,
          user.longitude!,
          location.latitude,
          location.longitude,
        );
        
        if (distance < 500) {
          score += 0.4;
          reasons.add('Very close (${distance.toInt()}m)');
        } else if (distance < 1000) {
          score += 0.2;
          reasons.add('Nearby (${distance.toInt()}m)');
        }
      }

      // Study-friendly locations for students
      if (location.type.toString().contains('library') || 
          location.type.toString().contains('study')) {
        score += 0.3;
        reasons.add('Great for studying');
      }

      // Building familiarity
      if (profile.preferredLocations.any((loc) => loc.contains(location.building))) {
        score += 0.2;
        reasons.add('Familiar building');
      }

      if (score > 0.2 && reasons.isNotEmpty) {
        recommendations.add(Recommendation(
          id: location.id,
          title: location.name,
          subtitle: '${location.building} • $locationType',
          description: 'Recommended because: ${reasons.join(", ")}',
          type: RecommendationType.locations,
          confidence: min(score, 1.0),
          data: {'location': location},
          reasons: reasons,
          timestamp: DateTime.now(),
        ));
      }
    }

    return recommendations;
  }

  // Recommend courses based on academic path
  Future<List<Recommendation>> _recommendCourses(String userId, UserProfile profile) async {
    final recommendations = <Recommendation>[];
    final user = _demoData.getUserById(userId)!;
    
    // Course recommendation based on academic progression and interests
    final courseRecommendations = {
      'Advanced Database Systems': {
        'code': '32557',
        'reason': 'Next level after Database Systems',
        'prerequisites': ['31244'],
      },
      'Machine Learning': {
        'code': '42809',
        'reason': 'Popular among programming students',
        'prerequisites': ['31251'],
      },
      'Web Development': {
        'code': '48430',
        'reason': 'Practical programming skills',
        'prerequisites': ['48024'],
      },
      'User Experience Design': {
        'code': '42810',
        'reason': 'Complements interaction design',
        'prerequisites': ['41021'],
      },
    };

    for (final entry in courseRecommendations.entries) {
      final courseTitle = entry.key;
      final courseData = entry.value;
      
      double score = 0.0;
      final reasons = <String>[];

      // Check if prerequisites are met
      final prerequisites = courseData['prerequisites'] as List<String>;
      bool hasPrerequisites = prerequisites.any((prereq) => user.course.contains(prereq));
      
      if (hasPrerequisites) {
        score += 0.5;
        reasons.add('Prerequisites met');
      }

      // Interest alignment
      final courseKeywords = courseTitle.toLowerCase().split(' ');
      for (final keyword in courseKeywords) {
        if (profile.interestScores.containsKey(keyword)) {
          score += profile.interestScores[keyword]! * 0.1;
          reasons.add('${keyword.capitalize()} interest');
        }
      }

      // Friend enrollment (simulated)
      final friendsInCourse = profile.socialConnections.keys
          .where((friendId) => Random().nextDouble() < 0.2) // Simulate 20% chance
          .length;
      
      if (friendsInCourse > 0) {
        score += friendsInCourse * 0.2;
        reasons.add('$friendsInCourse friends taking this');
      }

      // Academic path relevance
      if (courseData['reason'] != null) {
        score += 0.3;
        reasons.add(courseData['reason'] as String);
      }

      if (score > 0.3 && reasons.isNotEmpty) {
        recommendations.add(Recommendation(
          id: courseData['code'] as String,
          title: courseTitle,
          subtitle: 'Course ${courseData['code']}',
          description: 'Recommended because: ${reasons.join(", ")}',
          type: RecommendationType.courses,
          confidence: min(score, 1.0),
          data: {
            'courseCode': courseData['code'],
            'courseTitle': courseTitle,
            'prerequisites': prerequisites,
          },
          reasons: reasons,
          timestamp: DateTime.now(),
        ));
      }
    }

    return recommendations;
  }

  // Apply diversification to avoid over-concentration in one type
  List<Recommendation> _applyDiversification(List<Recommendation> recommendations, int limit) {
    final diversified = <Recommendation>[];
    final typeCount = <RecommendationType, int>{};
    
    // First pass: Add top recommendations while maintaining diversity
    for (final rec in recommendations) {
      final currentTypeCount = typeCount[rec.type] ?? 0;
      final maxPerType = (limit / RecommendationType.values.length).ceil() + 1;
      
      if (currentTypeCount < maxPerType || diversified.length < limit * 0.7) {
        diversified.add(rec);
        typeCount[rec.type] = currentTypeCount + 1;
      }
      
      if (diversified.length >= limit) break;
    }
    
    return diversified;
  }

  // Utility methods
  double _calculateInterestSimilarity(UserProfile profile, User candidate) {
    // Simplified interest similarity calculation
    // In a real app, this would use more sophisticated algorithms
    final userInterests = profile.interestScores.keys.toSet();
    final candidateInterests = _getCandidateInterests(candidate);
    
    if (userInterests.isEmpty || candidateInterests.isEmpty) return 0.0;
    
    final intersection = userInterests.intersection(candidateInterests);
    final union = userInterests.union(candidateInterests);
    
    return intersection.length / union.length;
  }

  Set<String> _getCandidateInterests(User candidate) {
    final interests = <String>{};
    
    // Extract from course
    final courseInterests = _extractCourseInterests(candidate.course);
    interests.addAll(courseInterests.keys);
    
    // Add simulated interests based on user patterns
    if (candidate.course.contains('Computer Science')) {
      interests.addAll(['programming', 'technology', 'software']);
    }
    if (candidate.course.contains('Design')) {
      interests.addAll(['design', 'creative', 'visual']);
    }
    
    return interests;
  }

  Map<String, double> _extractCourseInterests(String course) {
    final interests = <String, double>{};
    final courseWords = course.toLowerCase().split(' ');
    
    for (final word in courseWords) {
      switch (word) {
        case 'computer':
        case 'programming':
        case 'software':
          interests['technology'] = 1.0;
          break;
        case 'design':
        case 'interaction':
          interests['design'] = 1.0;
          break;
        case 'engineering':
          interests['engineering'] = 1.0;
          break;
        case 'business':
          interests['business'] = 1.0;
          break;
      }
    }
    
    return interests;
  }

  String _extractMainCourse(String course) {
    // Extract the main course identifier
    final match = RegExp(r'([A-Za-z\s]+)').firstMatch(course);
    return match?.group(0)?.trim() ?? course;
  }

  double _calculateCourseOverlap(String course1, String course2) {
    final words1 = course1.toLowerCase().split(' ').toSet();
    final words2 = course2.toLowerCase().split(' ').toSet();
    
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    
    return intersection.length / union.length;
  }

  double _calculateScheduleCompatibility(String userId1, String userId2) {
    // Calculate how compatible two users' schedules are for studying together
    final user1Events = _demoData.eventsSync.where((e) => 
      e.creatorId == userId1 || e.attendeeIds.contains(userId1));
    final user2Events = _demoData.eventsSync.where((e) => 
      e.creatorId == userId2 || e.attendeeIds.contains(userId2));
    
    // Find overlapping free time slots (simplified)
    final user1BusySlots = user1Events.map((e) => '${e.startTime.hour}:00').toSet();
    final user2BusySlots = user2Events.map((e) => '${e.startTime.hour}:00').toSet();
    
    final allSlots = {'9:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'};
    final user1FreeSlots = allSlots.difference(user1BusySlots);
    final user2FreeSlots = allSlots.difference(user2BusySlots);
    
    final commonFreeSlots = user1FreeSlots.intersection(user2FreeSlots);
    
    return commonFreeSlots.length / allSlots.length;
  }

  String _formatEventTime(Event event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
    
    if (eventDate == today) {
      return 'Today ${_formatTime(event.startTime)}';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow ${_formatTime(event.startTime)}';
    } else {
      return '${event.startTime.day}/${event.startTime.month} ${_formatTime(event.startTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // Track user interactions for learning
  void trackInteraction(String userId, String itemId, String interactionType) {
    _userInteractions.putIfAbsent(userId, () => {});
    _userInteractions[userId]!.putIfAbsent(itemId, () => 0);
    _userInteractions[userId]![itemId] = _userInteractions[userId]![itemId]! + 1;
  }

  // Clear cache when user profile changes significantly
  void invalidateUserProfile(String userId) {
    _userProfiles.remove(userId);
    _similarityCache.remove(userId);
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
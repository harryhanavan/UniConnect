import '../../shared/models/user.dart';
import '../../shared/models/event.dart';
import '../../shared/models/society.dart';
import '../../shared/models/location.dart';
import '../demo_data/demo_data_manager.dart';
import 'friendship_service.dart';
import 'location_service.dart';

enum SearchCategory {
  all,
  people,
  events,
  societies,
  locations,
  courses,
  studyGroups,
}

enum SearchFilter {
  recent,
  popular,
  nearby,
  friends,
  trending,
  recommended,
}

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final SearchCategory category;
  final double relevanceScore;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final DateTime? timestamp;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.relevanceScore,
    required this.data,
    this.imageUrl,
    this.timestamp,
  });
}

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final DemoDataManager _demoData = DemoDataManager.instance;
  final FriendshipService _friendshipService = FriendshipService();
  final LocationService _locationService = LocationService();

  // Recent search history
  final List<String> _recentSearches = [];
  
  // Trending searches (simulated)
  final List<String> _trendingSearches = [
    'study group database',
    'design workshop',
    'hackathon team',
    'assignment help',
    'programming society',
    'library study rooms',
    'project collaboration',
  ];

  // Advanced search with intelligent ranking and filtering
  Future<List<SearchResult>> search({
    required String query,
    SearchCategory category = SearchCategory.all,
    List<SearchFilter> filters = const [],
    String? userId,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    // Add to recent searches
    _addToRecentSearches(query);

    // Simulate search delay
    await Future.delayed(const Duration(milliseconds: 300));

    final results = <SearchResult>[];
    final normalizedQuery = query.toLowerCase().trim();

    // Search across different categories
    if (category == SearchCategory.all || category == SearchCategory.people) {
      results.addAll(await _searchPeople(normalizedQuery, userId));
    }
    
    if (category == SearchCategory.all || category == SearchCategory.events) {
      results.addAll(await _searchEvents(normalizedQuery, userId));
    }
    
    if (category == SearchCategory.all || category == SearchCategory.societies) {
      results.addAll(await _searchSocieties(normalizedQuery, userId));
    }
    
    if (category == SearchCategory.all || category == SearchCategory.locations) {
      results.addAll(await _searchLocations(normalizedQuery, userId));
    }

    if (category == SearchCategory.all || category == SearchCategory.courses) {
      results.addAll(await _searchCourses(normalizedQuery, userId));
    }

    // Apply filters
    final filteredResults = _applyFilters(results, filters, userId);

    // Sort by relevance score (descending)
    filteredResults.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return filteredResults.take(limit).toList();
  }

  // Search people with intelligent matching
  Future<List<SearchResult>> _searchPeople(String query, String? userId) async {
    final results = <SearchResult>[];
    final currentUser = userId != null ? _demoData.getUserById(userId) : null;

    for (final user in _demoData.usersSync) {
      if (userId != null && user.id == userId) continue; // Skip self

      double score = 0.0;
      final matchReasons = <String>[];

      // Name matching (highest priority)
      if (user.name.toLowerCase().contains(query)) {
        score += 100;
        matchReasons.add('Name match');
      }

      // Course matching
      if (user.course.toLowerCase().contains(query)) {
        score += 80;
        matchReasons.add('Same course');
      }

      // Year matching
      if (user.year.toLowerCase().contains(query)) {
        score += 60;
        matchReasons.add('Same year');
      }

      // Email matching (partial)
      if (user.email.toLowerCase().contains(query)) {
        score += 40;
        matchReasons.add('Email match');
      }

      // Friend network boost
      if (currentUser != null && _friendshipService.getMutualFriendsSync(currentUser.id, user.id).isNotEmpty) {
        score += 30;
        final mutualCount = _friendshipService.getMutualFriendsSync(currentUser.id, user.id).length;
        matchReasons.add('$mutualCount mutual friends');
      }

      // Online status boost
      if (user.isOnline) {
        score += 10;
        matchReasons.add('Currently online');
      }

      // Location proximity boost
      if (currentUser != null && user.latitude != null && user.longitude != null &&
          currentUser.latitude != null && currentUser.longitude != null) {
        final proximity = _locationService.calculateDistance(
          currentUser.latitude!,
          currentUser.longitude!,
          user.latitude!,
          user.longitude!,
        );
        if (proximity < 500) { // Within 500m
          score += 20;
          matchReasons.add('Nearby (${proximity.toInt()}m)');
        }
      }

      if (score > 0) {
        results.add(SearchResult(
          id: user.id,
          title: user.name,
          subtitle: '${user.course} • ${user.year}',
          description: matchReasons.join(' • '),
          category: SearchCategory.people,
          relevanceScore: score,
          data: {'user': user, 'matchReasons': matchReasons},
          imageUrl: user.profileImageUrl,
        ));
      }
    }

    return results;
  }

  // Search events with context awareness
  Future<List<SearchResult>> _searchEvents(String query, String? userId) async {
    final results = <SearchResult>[];
    final events = _demoData.eventsSync;
    final currentUser = userId != null ? _demoData.getUserById(userId) : null;

    for (final event in events) {
      double score = 0.0;
      final matchReasons = <String>[];

      // Title matching
      if (event.title.toLowerCase().contains(query)) {
        score += 100;
        matchReasons.add('Title match');
      }

      // Description matching
      if (event.description.toLowerCase().contains(query)) {
        score += 80;
        matchReasons.add('Description match');
      }

      // Location matching
      if (event.location.toLowerCase().contains(query)) {
        score += 70;
        matchReasons.add('Location match');
      }

      // Course code matching
      if (event.courseCode != null && event.courseCode!.toLowerCase().contains(query)) {
        score += 90;
        matchReasons.add('Course match');
      }

      // Friend attendance boost
      if (currentUser != null) {
        final friendsAttending = event.attendeeIds
            .where((id) => _demoData.areFriends(currentUser.id, id))
            .length;
        if (friendsAttending > 0) {
          score += 25;
          matchReasons.add('$friendsAttending friends attending');
        }
      }

      // Time relevance (upcoming events get priority)
      final now = DateTime.now();
      if (event.startTime.isAfter(now)) {
        final hoursUntil = event.startTime.difference(now).inHours;
        if (hoursUntil < 24) {
          score += 30; // Today
          matchReasons.add('Today');
        } else if (hoursUntil < 168) {
          score += 15; // This week
          matchReasons.add('This week');
        }
      }

      // Event type relevance
      if (query.contains('class') && event.type == EventType.class_) {
        score += 50;
      } else if (query.contains('society') && event.type == EventType.society) {
        score += 50;
      } else if (query.contains('assignment') && event.type == EventType.assignment) {
        score += 50;
      }

      if (score > 0) {
        results.add(SearchResult(
          id: event.id,
          title: event.title,
          subtitle: '${_formatEventTime(event)} • ${event.location}',
          description: matchReasons.join(' • '),
          category: SearchCategory.events,
          relevanceScore: score,
          data: {'event': event, 'matchReasons': matchReasons},
          timestamp: event.startTime,
        ));
      }
    }

    return results;
  }

  // Search societies with engagement metrics
  Future<List<SearchResult>> _searchSocieties(String query, String? userId) async {
    final results = <SearchResult>[];
    final currentUser = userId != null ? _demoData.getUserById(userId) : null;

    for (final society in _demoData.societiesSync) {
      double score = 0.0;
      final matchReasons = <String>[];

      // Name matching
      if (society.name.toLowerCase().contains(query)) {
        score += 100;
        matchReasons.add('Name match');
      }

      // Description matching
      if (society.description.toLowerCase().contains(query)) {
        score += 80;
        matchReasons.add('Description match');
      }

      // Category matching
      if (society.category.toLowerCase().contains(query)) {
        score += 70;
        matchReasons.add('Category match');
      }

      // Tags matching
      for (final tag in society.tags) {
        if (tag.toLowerCase().contains(query)) {
          score += 60;
          matchReasons.add('Tag: $tag');
          break; // Only count one tag match
        }
      }

      // Member count boost (popular societies)
      if (society.memberCount > 200) {
        score += 20;
        matchReasons.add('Popular (${society.memberCount} members)');
      }

      // Already joined boost
      if (society.isJoined) {
        score += 15;
        matchReasons.add('Already joined');
      }

      // Friend membership boost
      if (currentUser != null) {
        final friendsInSociety = _demoData.usersSync
            .where((user) => 
              _demoData.areFriends(currentUser.id, user.id) &&
              society.memberIds.contains(user.id))
            .length;
        
        if (friendsInSociety > 0) {
          score += 25;
          matchReasons.add('$friendsInSociety friends are members');
        }
      }

      if (score > 0) {
        results.add(SearchResult(
          id: society.id,
          title: society.name,
          subtitle: '${society.category} • ${society.memberCount} members',
          description: matchReasons.join(' • '),
          category: SearchCategory.societies,
          relevanceScore: score,
          data: {'society': society, 'matchReasons': matchReasons},
          imageUrl: society.logoUrl,
        ));
      }
    }

    return results;
  }

  // Search locations with context awareness
  Future<List<SearchResult>> _searchLocations(String query, String? userId) async {
    final results = <SearchResult>[];
    final currentUser = userId != null ? _demoData.getUserById(userId) : null;

    for (final location in _demoData.locationsSync) {
      double score = 0.0;
      final matchReasons = <String>[];

      // Name matching
      if (location.name.toLowerCase().contains(query)) {
        score += 100;
        matchReasons.add('Name match');
      }

      // Building matching
      if (location.building.toLowerCase().contains(query)) {
        score += 90;
        matchReasons.add('Building match');
      }

      // Description matching
      if (location.description?.toLowerCase().contains(query) == true) {
        score += 70;
        matchReasons.add('Description match');
      }

      // Location type matching
      final typeString = location.type.toString().split('.').last;
      if (typeString.toLowerCase().contains(query)) {
        score += 80;
        matchReasons.add('Type: $typeString');
      }

      // Proximity boost
      if (currentUser?.latitude != null && currentUser?.longitude != null) {
        final distance = _locationService.calculateDistance(
          currentUser!.latitude!,
          currentUser.longitude!,
          location.latitude,
          location.longitude,
        );
        if (distance < 1000) { // Within 1km
          score += 30;
          matchReasons.add('${distance.toInt()}m away');
        }
      }

      // Friends at location boost
      if (currentUser != null) {
        final friendsHere = _demoData.usersSync
            .where((user) => 
              _demoData.areFriends(currentUser.id, user.id) &&
              user.currentLocationId == location.id)
            .length;
        
        if (friendsHere > 0) {
          score += 40;
          matchReasons.add('$friendsHere friends here');
        }
      }

      if (score > 0) {
        results.add(SearchResult(
          id: location.id,
          title: location.name,
          subtitle: '${location.building} • ${location.type.toString().split('.').last}',
          description: matchReasons.join(' • '),
          category: SearchCategory.locations,
          relevanceScore: score,
          data: {'location': location, 'matchReasons': matchReasons},
        ));
      }
    }

    return results;
  }

  // Search courses with academic context
  Future<List<SearchResult>> _searchCourses(String query, String? userId) async {
    final results = <SearchResult>[];
    final currentUser = userId != null ? _demoData.getUserById(userId) : null;

    // Extract unique courses from events and users
    final courses = <String, Map<String, dynamic>>{};
    
    // From events
    for (final event in _demoData.eventsSync.where((e) => e.courseCode != null)) {
      final code = event.courseCode!;
      if (courses.containsKey(code)) {
        courses[code]!['events'] = (courses[code]!['events'] as List)..add(event);
      } else {
        courses[code] = {
          'code': code,
          'title': _getCourseTitle(code),
          'events': [event],
          'students': <String>{},
        };
      }
    }

    // From users (infer from their course string)
    for (final user in _demoData.usersSync) {
      // Simple pattern matching for course codes in user.course
      final courseMatches = RegExp(r'\b\d{5}\b').allMatches(user.course);
      for (final match in courseMatches) {
        final code = match.group(0)!;
        if (courses.containsKey(code)) {
          (courses[code]!['students'] as Set<String>).add(user.id);
        }
      }
    }

    // Search through courses
    for (final entry in courses.entries) {
      final code = entry.key;
      final courseData = entry.value;
      double score = 0.0;
      final matchReasons = <String>[];

      // Course code matching
      if (code.toLowerCase().contains(query)) {
        score += 100;
        matchReasons.add('Course code match');
      }

      // Course title matching
      final title = courseData['title'] as String;
      if (title.toLowerCase().contains(query)) {
        score += 90;
        matchReasons.add('Title match');
      }

      // Current user enrolled boost
      if (currentUser?.course.contains(code) == true) {
        score += 50;
        matchReasons.add('You are enrolled');
      }

      // Friends enrolled boost
      if (currentUser != null) {
        final friendsEnrolled = (courseData['students'] as Set<String>)
            .where((studentId) => _demoData.areFriends(currentUser.id, studentId))
            .length;
        
        if (friendsEnrolled > 0) {
          score += 30;
          matchReasons.add('$friendsEnrolled friends enrolled');
        }
      }

      // Upcoming events boost
      final upcomingEvents = (courseData['events'] as List<Event>)
          .where((e) => e.startTime.isAfter(DateTime.now()))
          .length;
      
      if (upcomingEvents > 0) {
        score += 20;
        matchReasons.add('$upcomingEvents upcoming events');
      }

      if (score > 0) {
        results.add(SearchResult(
          id: code,
          title: '$code - $title',
          subtitle: '${(courseData['students'] as Set).length} students • ${(courseData['events'] as List).length} events',
          description: matchReasons.join(' • '),
          category: SearchCategory.courses,
          relevanceScore: score,
          data: {'courseCode': code, 'courseData': courseData, 'matchReasons': matchReasons},
        ));
      }
    }

    return results;
  }

  // Apply advanced filters
  List<SearchResult> _applyFilters(List<SearchResult> results, List<SearchFilter> filters, String? userId) {
    var filteredResults = List<SearchResult>.from(results);

    for (final filter in filters) {
      switch (filter) {
        case SearchFilter.recent:
          // Prioritize recent/upcoming items
          filteredResults = filteredResults.where((result) {
            if (result.category == SearchCategory.events) {
              final event = result.data['event'] as Event;
              return event.startTime.isAfter(DateTime.now().subtract(const Duration(days: 7)));
            }
            return true;
          }).toList();
          break;

        case SearchFilter.popular:
          // Prioritize high-engagement items
          filteredResults.sort((a, b) {
            double aPopularity = 0;
            double bPopularity = 0;

            if (a.category == SearchCategory.societies) {
              aPopularity = (a.data['society'] as Society).memberCount.toDouble();
            } else if (a.category == SearchCategory.events) {
              aPopularity = (a.data['event'] as Event).attendeeIds.length.toDouble();
            }

            if (b.category == SearchCategory.societies) {
              bPopularity = (b.data['society'] as Society).memberCount.toDouble();
            } else if (b.category == SearchCategory.events) {
              bPopularity = (b.data['event'] as Event).attendeeIds.length.toDouble();
            }

            return bPopularity.compareTo(aPopularity);
          });
          break;

        case SearchFilter.nearby:
          // Filter by proximity if user location available
          if (userId != null) {
            final currentUser = _demoData.getUserById(userId);
            if (currentUser?.latitude != null && currentUser?.longitude != null) {
              filteredResults = filteredResults.where((result) {
                if (result.category == SearchCategory.locations) {
                  final location = result.data['location'] as Location;
                  final distance = _locationService.calculateDistance(
                    currentUser!.latitude!,
                    currentUser.longitude!,
                    location.latitude,
                    location.longitude,
                  );
                  return distance < 2000; // Within 2km
                }
                return true;
              }).toList();
            }
          }
          break;

        case SearchFilter.friends:
          // Prioritize friend-related content
          if (userId != null) {
            filteredResults = filteredResults.where((result) {
              if (result.category == SearchCategory.people) {
                final user = result.data['user'] as User;
                return _demoData.areFriends(userId, user.id) || 
                       _friendshipService.getMutualFriendsSync(userId, user.id).isNotEmpty;
              } else if (result.category == SearchCategory.events) {
                final event = result.data['event'] as Event;
                return event.attendeeIds.any((id) => _demoData.areFriends(userId, id));
              }
              return true;
            }).toList();
          }
          break;

        case SearchFilter.trending:
          // Boost results that match trending searches
          for (final result in filteredResults) {
            if (_trendingSearches.any((trend) => 
              result.title.toLowerCase().contains(trend.toLowerCase()) ||
              result.description.toLowerCase().contains(trend.toLowerCase()))) {
              result.data['trendingBoost'] = true;
            }
          }
          break;

        case SearchFilter.recommended:
          // Apply recommendation algorithm boost
          _applyRecommendationBoost(filteredResults, userId);
          break;
      }
    }

    return filteredResults;
  }

  // Apply AI-like recommendation boost
  void _applyRecommendationBoost(List<SearchResult> results, String? userId) {
    if (userId == null) return;

    final currentUser = _demoData.getUserById(userId);
    if (currentUser == null) return;

    for (final result in results) {
      double boost = 0;

      // Course affinity
      if (result.category == SearchCategory.people) {
        final user = result.data['user'] as User;
        if (user.course == currentUser.course) boost += 20;
        if (user.year == currentUser.year) boost += 15;
      }

      // Interest alignment (based on societies)
      if (result.category == SearchCategory.societies) {
        final society = result.data['society'] as Society;
        final userSocieties = _demoData.joinedSocieties;
        
        // Check category overlap
        for (final userSociety in userSocieties) {
          if (userSociety.category == society.category) {
            boost += 25;
            break;
          }
        }

        // Check tag overlap
        final userTags = userSocieties.expand((s) => s.tags).toSet();
        final overlapCount = society.tags.where((tag) => userTags.contains(tag)).length;
        boost += overlapCount * 10;
      }

      // Temporal relevance for events
      if (result.category == SearchCategory.events) {
        final event = result.data['event'] as Event;
        // Prefer events in user's typical active hours
        final eventHour = event.startTime.hour;
        if (eventHour >= 9 && eventHour <= 17) { // Business hours
          boost += 10;
        }
        
        // Prefer weekday events for classes
        if (event.type == EventType.class_ && event.startTime.weekday <= 5) {
          boost += 15;
        }
      }

      result.data['recommendationBoost'] = boost;
    }
  }

  // Utility methods
  void _addToRecentSearches(String query) {
    _recentSearches.remove(query); // Remove if exists
    _recentSearches.insert(0, query); // Add to front
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
  }

  List<String> getRecentSearches() => List.from(_recentSearches);
  List<String> getTrendingSearches() => List.from(_trendingSearches);

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

  String _getCourseTitle(String courseCode) {
    // Mock course titles - in real app would come from course catalog
    final courseTitles = {
      '41021': 'Interaction Design Studio',
      '31244': 'Database Design',
      '48024': 'Applications Programming',
      '42889': 'Computer Graphics',
      '31251': 'Data Structures and Algorithms',
    };
    return courseTitles[courseCode] ?? 'Course Title';
  }

  // Advanced search suggestions
  List<String> generateSearchSuggestions(String partial) {
    if (partial.length < 2) return getTrendingSearches().take(5).toList();

    final suggestions = <String>[];
    final normalizedPartial = partial.toLowerCase();

    // Add matching recent searches
    suggestions.addAll(
      _recentSearches
          .where((search) => search.toLowerCase().contains(normalizedPartial))
          .take(3)
    );

    // Add matching trending searches
    suggestions.addAll(
      _trendingSearches
          .where((trend) => trend.toLowerCase().contains(normalizedPartial))
          .take(3)
    );

    // Add user names
    final userMatches = _demoData.usersSync
        .where((user) => user.name.toLowerCase().contains(normalizedPartial))
        .map((user) => user.name)
        .take(3);
    suggestions.addAll(userMatches);

    // Add society names
    final societyMatches = _demoData.societiesSync
        .where((society) => society.name.toLowerCase().contains(normalizedPartial))
        .map((society) => society.name)
        .take(2);
    suggestions.addAll(societyMatches);

    // Remove duplicates and limit
    return suggestions.toSet().take(8).toList();
  }
}
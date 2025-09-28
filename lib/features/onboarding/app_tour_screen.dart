import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/uniconnect_logo.dart';
import 'welcome_complete_screen.dart';

class AppTourScreen extends StatefulWidget {
  const AppTourScreen({super.key});

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TourPage> _tourPages = [
    TourPage(
      title: "Home Dashboard",
      description: "Your personalized hub with quick access to upcoming classes, events, and friend activity. See what's happening right now on campus.",
      features: [
        "Today's schedule overview",
        "Friend activity feed",
        "Quick actions",
        "Campus hotspots",
      ],
      mockupWidget: _buildHomeMockup(),
      color: AppColors.homeColor,
    ),
    TourPage(
      title: "Smart Calendar",
      description: "Never miss a class or event! Your intelligent calendar syncs with your timetable and shows events from friends and societies.",
      features: [
        "University timetable sync",
        "Society events",
        "Study group meetings",
        "Assignment deadlines",
      ],
      mockupWidget: _buildCalendarMockup(),
      color: AppColors.personalColor,
    ),
    TourPage(
      title: "Find Friends",
      description: "Connect with classmates in your courses, join study groups, and build your university social network.",
      features: [
        "Find classmates",
        "Course-based matching",
        "Friend recommendations",
        "Direct messaging",
      ],
      mockupWidget: _buildFriendsMockup(),
      color: AppColors.socialColor,
    ),
    TourPage(
      title: "Societies & Clubs",
      description: "Discover and join societies that match your interests. See events, connect with members, and get involved in campus life.",
      features: [
        "Browse all societies",
        "Interest-based discovery",
        "Society events",
        "Member connections",
      ],
      mockupWidget: _buildSocietiesMockup(),
      color: AppColors.societyColor,
    ),
    TourPage(
      title: "Study Groups",
      description: "Collaborate with peers in your courses. Create study sessions, share resources, and achieve better academic outcomes together.",
      features: [
        "Course-specific groups",
        "Study session planning",
        "Resource sharing",
        "Peer collaboration",
      ],
      mockupWidget: _buildStudyGroupMockup(),
      color: AppColors.studyGroupColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const UniConnectLogoSmall(showShadow: false),
                      const SizedBox(width: 8),
                      Text(
                        'App Tour',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _tourPages[_currentPage].color,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _skipTour,
                    child: const Text(
                      'Skip Tour',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildProgressIndicator(),
            ),

            const SizedBox(height: 24),

            // Tour content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _tourPages.length,
                itemBuilder: (context, index) {
                  return _buildTourPage(_tourPages[index]);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _tourPages[_currentPage].color),
                          foregroundColor: _tourPages[_currentPage].color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),

                  const SizedBox(width: 16),

                  // Next/Finish button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _currentPage == _tourPages.length - 1
                          ? _finishTour
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tourPages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage == _tourPages.length - 1
                            ? 'Finish Tour'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(
        _tourPages.length,
        (index) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < _tourPages.length - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: index <= _currentPage
                  ? _tourPages[_currentPage].color
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTourPage(TourPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Mockup section
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: page.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: page.color.withValues(alpha: 0.3)),
              ),
              child: page.mockupWidget,
            ),
          ),

          const SizedBox(height: 32),

          // Content section
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Title
                Text(
                  page.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: page.color,
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),

                const SizedBox(height: 24),

                // Features list
                Column(
                  children: page.features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: page.color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _tourPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipTour() {
    _finishTour();
  }

  void _finishTour() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomeCompleteScreen(),
      ),
    );
  }

  // Static mockup builders
  static Widget _buildHomeMockup() {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.homeColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Welcome back, Alex!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.personalColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('Next Class\n10:00 AM')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.socialColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('3 Friends\nOnline')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildCalendarMockup() {
    return Column(
      children: [
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.personalColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(child: Text('Today - March 15')),
        ),
        const SizedBox(height: 12),
        ...List.generate(3, (index) {
          final colors = [AppColors.personalColor, AppColors.societyColor, AppColors.studyGroupColor];
          final events = ['Database Systems Lecture', 'Photography Society Meet', 'Study Group - Algorithms'];
          return Container(
            height: 35,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colors[index].withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text(events[index], style: const TextStyle(fontSize: 12))),
          );
        }),
      ],
    );
  }

  static Widget _buildFriendsMockup() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: 50,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.socialColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.socialColor.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sarah Chen', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    Text('IT Student, 2nd Year', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  static Widget _buildSocietiesMockup() {
    return Column(
      children: List.generate(2, (index) {
        final societies = ['Photography Society', 'Tech Innovation Club'];
        return Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.societyColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  societies[index],
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  '142 members • Weekly events',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  static Widget _buildStudyGroupMockup() {
    return Column(
      children: List.generate(2, (index) {
        final groups = ['Database Systems Study Group', 'Web Development Workshop'];
        return Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.studyGroupColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groups[index],
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  '8 members • Next: Tomorrow 2PM',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class TourPage {
  final String title;
  final String description;
  final List<String> features;
  final Widget mockupWidget;
  final Color color;

  TourPage({
    required this.title,
    required this.description,
    required this.features,
    required this.mockupWidget,
    required this.color,
  });
}
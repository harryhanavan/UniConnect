import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../constants/tour_flows.dart';
import '../constants/app_colors.dart';
import '../../core/utils/navigation_helper.dart';
import '../../main.dart';

enum TourType {
  mainOnboarding,
  homeSection,
  calendarSection,
  societiesSection,
  friendsSection,
  messagesSection,
}

class TourManager {
  static final TourManager _instance = TourManager._internal();
  static TourManager get instance => _instance;
  TourManager._internal();

  // Persistence keys
  static const String _mainTourCompletedKey = 'main_tour_completed';
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _tourVersionKey = 'tour_version';
  static const int _currentTourVersion = 1;

  TutorialCoachMark? _currentTutorial;
  int _currentTourStep = 0;
  TourType? _currentTourType;
  bool _isTourActive = false;

  // Tour request queue system
  TourType? _pendingTourRequest;
  bool _isProcessingTourRequest = false;

  // Public getter to check if tour is currently active
  bool get isTourActive => _isTourActive;

  // Validation method to check if context is safe for tours
  bool _isContextValid(BuildContext context, {bool requireScaffold = false}) {
    if (!context.mounted) {
      print('❌ Tour Error: Context is not mounted');
      return false;
    }

    // Only check for Scaffold if explicitly required (for screen-level contexts)
    if (requireScaffold) {
      try {
        Scaffold.of(context);
        return true;
      } catch (e) {
        print('❌ Tour Error: Context has no Scaffold: $e');
        return false;
      }
    }

    return true;
  }

  // Get stable app context that won't be invalidated by dialog transitions
  BuildContext? _getStableContext() {
    final context = UniConnectApp.currentContext;
    if (context == null) {
      print('❌ Tour Error: No stable app context available');
      return null;
    }

    if (!_isContextValid(context, requireScaffold: false)) {
      print('❌ Tour Error: Stable context is not valid');
      return null;
    }

    print('✅ Tour: Stable context obtained successfully');
    return context;
  }

  // Find the current screen's context that has a Scaffold
  BuildContext? _findScreenContext() {
    final appContext = _getStableContext();
    if (appContext == null) return null;

    // Navigate down the widget tree to find a context with a Scaffold
    BuildContext? screenContext;

    // Use the global navigator to find the current route's context
    final navigator = UniConnectApp.navigatorKey.currentState;
    if (navigator != null) {
      final overlay = navigator.overlay;
      if (overlay != null && overlay.context.mounted) {
        try {
          // Try to find a Scaffold in the current route
          Scaffold.of(overlay.context);
          screenContext = overlay.context;
          print('✅ Tour: Found screen context with Scaffold');
        } catch (e) {
          print('⚠️ Tour: Overlay context has no Scaffold, will try alternative approach');
        }
      }
    }

    return screenContext;
  }

  // Queue a tour request instead of starting immediately
  void queueTourRequest(TourType tourType) {
    print('📥 Tour: Queueing tour request for $tourType');
    _pendingTourRequest = tourType;
    _processPendingTourRequest();
  }

  // Process pending tour request when context is stable
  void _processPendingTourRequest() {
    if (_isProcessingTourRequest || _pendingTourRequest == null) {
      return;
    }

    _isProcessingTourRequest = true;
    print('🔄 Tour: Processing pending tour request for $_pendingTourRequest');

    // Use PostFrameCallback to ensure UI is stable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        // Try to find a screen context first, fall back to stable context
        final context = _findScreenContext() ?? _getStableContext();
        if (context != null && _pendingTourRequest != null) {
          final tourType = _pendingTourRequest!;
          _pendingTourRequest = null;
          _isProcessingTourRequest = false;

          print('🎯 Tour: Starting queued tour: $tourType');
          startSectionTour(context, tourType);
        } else {
          print('❌ Tour Error: Cannot process pending tour - context unavailable');
          _pendingTourRequest = null;
          _isProcessingTourRequest = false;
        }
      });
    });
  }

  // Check if there's a pending tour request (for widgets to query)
  bool hasPendingTour() {
    return _pendingTourRequest != null && !_isProcessingTourRequest;
  }

  // Get the type of pending tour (for widgets to query)
  TourType? getPendingTourType() {
    return _pendingTourRequest;
  }

  // Start a pending tour with a specific screen context when widgets are ready
  void startPendingTourWithContext(BuildContext screenContext) {
    if (_pendingTourRequest == null || _isProcessingTourRequest) {
      print('🔍 Tour: No pending tour to start or already processing');
      return;
    }

    print('🔍 Tour: Starting pending tour with ready screen context...');
    _processWithScreenContext(screenContext);
  }

  // Check for and process any pending tour requests (call from widgets) - DEPRECATED
  @deprecated
  void checkForPendingTours([BuildContext? screenContext]) {
    if (_pendingTourRequest != null && !_isProcessingTourRequest) {
      print('🔍 Tour: Checking for pending tours... (DEPRECATED - use startPendingTourWithContext)');
      if (screenContext != null) {
        // Process immediately with the provided screen context
        _processWithScreenContext(screenContext);
      } else {
        _processPendingTourRequest();
      }
    }
  }

  // Process pending tour with provided screen context (widgets should already be ready)
  void _processWithScreenContext(BuildContext screenContext) {
    if (_pendingTourRequest == null || _isProcessingTourRequest) return;

    _isProcessingTourRequest = true;
    print('🔄 Tour: Processing pending tour with screen context for $_pendingTourRequest');

    // Validate the screen context
    if (!_isContextValid(screenContext, requireScaffold: true)) {
      print('❌ Tour Error: Provided screen context is not valid');
      _pendingTourRequest = null;
      _isProcessingTourRequest = false;
      return;
    }

    // No delay needed since widgets should already be ready when this is called
    final tourType = _pendingTourRequest!;
    _pendingTourRequest = null;
    _isProcessingTourRequest = false;

    print('🎯 Tour: Starting queued tour with ready screen context: $tourType');
    startSectionTour(screenContext, tourType);
  }

  // Method to safely navigate with error handling
  Future<bool> _safeNavigateToTab(BuildContext context, int tabIndex) async {
    try {
      if (!_isContextValid(context, requireScaffold: false)) return false;

      print('🧭 Tour: Navigating to tab $tabIndex');
      NavigationHelper.navigateToTab(context, tabIndex);

      // Wait and verify navigation completed
      await Future.delayed(const Duration(milliseconds: 500));
      return _isContextValid(context, requireScaffold: false);
    } catch (e) {
      print('❌ Tour Error: Navigation failed: $e');
      return false;
    }
  }

  // Check if this is the first time the user opens the app
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_firstLaunchKey) ?? true;
    if (isFirst) {
      await prefs.setBool(_firstLaunchKey, false);
    }
    return isFirst;
  }

  // Check if the main tour has been completed
  Future<bool> isMainTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool(_mainTourCompletedKey) ?? false;
    final tourVersion = prefs.getInt(_tourVersionKey) ?? 0;

    // If tour version is outdated, show tour again
    return isCompleted && tourVersion >= _currentTourVersion;
  }

  // Mark main tour as completed
  Future<void> markMainTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mainTourCompletedKey, true);
    await prefs.setInt(_tourVersionKey, _currentTourVersion);
  }

  // Reset all tour progress (for testing or user preference)
  Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mainTourCompletedKey, false);
    await prefs.setInt(_tourVersionKey, 0);
    // Also reset first launch to trigger welcome dialog
    await prefs.setBool(_firstLaunchKey, true);
  }

  // Check if user should see tour prompt on app launch
  Future<bool> shouldShowTourPrompt() async {
    final isFirst = await isFirstLaunch();
    final isCompleted = await isMainTourCompleted();
    return isFirst && !isCompleted;
  }

  // Show welcome tour prompt for first-time users
  Future<void> showWelcomeTourPrompt(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Image.asset(
                'assets/Logos/UniConnect Logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              const Text('Welcome to UniConnect!'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Would you like an interactive tour to discover all the features that will help you connect with your university community?',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                '🎯 Interactive highlights\n'
                '📱 Step-by-step guidance\n'
                '🔄 Navigate through app features\n'
                '⏱️ Takes about 2 minutes',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                markMainTourCompleted(); // Skip tour
              },
              child: const Text('Skip for now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                // Queue the main tour request instead of starting directly
                print('📥 Tour: Queueing main onboarding tour from welcome dialog');
                queueTourRequest(TourType.mainOnboarding);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.homeColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Interactive Tour'),
            ),
          ],
        );
      },
    );
  }

  // Start the main comprehensive onboarding tour
  Future<void> startMainOnboardingTour(BuildContext context) async {
    print('🎯 Tour: Starting main onboarding tour...');

    if (!context.mounted) {
      print('❌ Tour Error: Context not mounted when starting main tour');
      return;
    }

    if (!_isContextValid(context)) {
      print('❌ Tour Error: Context not valid when starting main tour');
      return;
    }

    _currentTourType = TourType.mainOnboarding;
    _currentTourStep = 0;

    print('🎯 Tour: Context validated, starting home screen tour...');
    // Start with home screen tour (it will queue if widgets not ready)
    _startHomeScreenTour(context, isPartOfMainTour: true);
  }

  // Start a specific section tour
  Future<void> startSectionTour(BuildContext context, TourType tourType) async {
    if (!context.mounted) return;

    _currentTourType = tourType;
    _currentTourStep = 0;

    switch (tourType) {
      case TourType.homeSection:
        _startHomeScreenTour(context, isPartOfMainTour: false);
        break;
      case TourType.calendarSection:
        _startCalendarTour(context, isPartOfMainTour: false);
        break;
      case TourType.societiesSection:
        _startSocietiesScreenTour(context, isPartOfMainTour: false);
        break;
      case TourType.friendsSection:
        _startFriendsScreenTour(context, isPartOfMainTour: false);
        break;
      case TourType.messagesSection:
        _startMessagesScreenTour(context, isPartOfMainTour: false);
        break;
      case TourType.mainOnboarding:
        startMainOnboardingTour(context);
        break;
    }
  }

  // Show tour menu dialog
  Future<void> showTourMenu(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.tour, color: AppColors.homeColor),
              const SizedBox(width: 8),
              const Text('Interactive Tours'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose a tour to get visual, step-by-step guidance:'),
              const SizedBox(height: 16),
              _buildTourMenuButton(
                context,
                'Complete App Tour',
                'Full interactive walkthrough',
                Icons.tour,
                AppColors.homeColor,
                () => queueTourRequest(TourType.mainOnboarding),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Home Screen',
                'Quick actions and overview',
                Icons.home,
                AppColors.homeColor,
                () => queueTourRequest(TourType.homeSection),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Calendar & Timetable',
                'Events and scheduling',
                Icons.calendar_today,
                AppColors.personalColor,
                () => queueTourRequest(TourType.calendarSection),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Societies & Events',
                'Clubs and activities',
                Icons.groups,
                AppColors.societyColor,
                () => queueTourRequest(TourType.societiesSection),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Friends & Social',
                'Connect with classmates',
                Icons.people,
                AppColors.socialColor,
                () => queueTourRequest(TourType.friendsSection),
              ),
              const SizedBox(height: 8),
              _buildTourMenuButton(
                context,
                'Messages & Chat',
                'Communication features',
                Icons.message,
                AppColors.socialColor,
                () => queueTourRequest(TourType.messagesSection),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await resetAllTours();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tour progress reset. Restart app to see welcome prompt.')),
                );
              },
              child: const Text('Reset Tours'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTourMenuButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop(); // Close dialog
          onTap(); // Queue the tour request
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          foregroundColor: color,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w500, color: color),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Private methods for starting specific screen tours
  void _startHomeScreenTour(BuildContext context, {required bool isPartOfMainTour}) {
    try {
      _isTourActive = true;
      TourKeys.setTourActive(true);
      print('🔑 Tour: Tour keys activated');
      print('🎯 Tour: Starting Home screen tour...');

      // Force the entire app to rebuild by invalidating the current context
      if (context.mounted) {
        // Get the root widget and force a rebuild
        final navigator = Navigator.of(context, rootNavigator: true);
        final overlayState = Overlay.of(context, rootOverlay: true);

        // Force a rebuild by marking the overlay as needing to rebuild
        WidgetsBinding.instance.addPostFrameCallback((_) {
          overlayState.setState(() {});
        });
      }

      // Try starting the tour with retry logic
      _attemptTourStart(context, isPartOfMainTour, 0);
    } catch (e, stackTrace) {
      print('❌ Tour Error: Failed to start home screen tour: $e');
      print('📍 Stack trace: $stackTrace');
      _isTourActive = false;
      TourKeys.setTourActive(false);
      // Show fallback message to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to start tour. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Attempt to start tour with retry logic for widget readiness
  void _attemptTourStart(BuildContext context, bool isPartOfMainTour, int attempt) {
    const maxAttempts = 10;
    const delayMs = 1000;

    if (attempt >= maxAttempts) {
      print('❌ Tour Error: Failed to start tour after $maxAttempts attempts');
      _isTourActive = false;
      TourKeys.setTourActive(false);
      return;
    }

    Future.delayed(Duration(milliseconds: delayMs + (attempt * 500)), () {
      if (!_isContextValid(context)) {
        print('❌ Tour Error: Context no longer valid');
        _isTourActive = false;
        TourKeys.setTourActive(false);
        return;
      }

      // Check if key widgets are actually ready
      final homeWelcomeKey = TourKeys.homeWelcomeKey;
      final homeHelpIconKey = TourKeys.homeHelpIconKey;

      if (homeWelcomeKey?.currentContext == null || homeHelpIconKey?.currentContext == null) {
        print('⏳ Tour: Widgets not ready (attempt ${attempt + 1}/$maxAttempts), retrying...');
        _attemptTourStart(context, isPartOfMainTour, attempt + 1);
        return;
      }

      print('✅ Tour: Widgets ready, starting tour...');

      final targets = TourFlows.getHomeScreenTargets();
      print('🎯 Tour: Found ${targets.length} targets for Home screen');

      if (targets.isEmpty) {
        print('❌ Tour Error: No targets found for Home tour');
        _isTourActive = false;
        TourKeys.setTourActive(false);
        return;
      }

      // Create and show the tutorial
      _currentTutorial = TutorialCoachMark(
        targets: targets,
        colorShadow: AppColors.homeColor,
        paddingFocus: 10,
        hideSkip: false,
        opacityShadow: 0.8,
        textSkip: isPartOfMainTour ? "Skip Tour" : "Close",
        onFinish: () {
          if (isPartOfMainTour) {
            _handleTourFinish(context, 'Home');
          } else {
            _isTourActive = false;
            TourKeys.setTourActive(false);
          }
        },
        onSkip: () {
          _isTourActive = false;
          TourKeys.setTourActive(false);
          if (isPartOfMainTour) {
            markMainTourCompleted();
          }
          return true;
        },
      );

      _currentTutorial!.show(context: context);
    });
  }

  // Helper method to wait for targets and start tour with retry logic
  void _waitForTargetsAndStartTour(
    BuildContext context,
    bool isPartOfMainTour,
    String tourName,
    List<TargetFocus> Function() getTargets,
    Color shadowColor, {
    int attemptCount = 0,
    int maxAttempts = 5,
  }) {
    const baseDelay = 800; // Increased base delay for better stability
    final delay = baseDelay + (attemptCount * 300); // Increase delay with each attempt

    Future.delayed(Duration(milliseconds: delay), () {
      if (!_isContextValid(context)) {
        print('❌ Tour Error: Context no longer valid for $tourName tour');
        _isTourActive = false;
        TourKeys.setTourActive(false);
        return;
      }

      // Debug key status before trying to get targets
      print('🔍 Tour: Checking key status before creating targets for $tourName...');
      TourKeys.debugKeyStatus();

      final targets = getTargets();
      print('🎯 Tour: Found ${targets.length} targets for $tourName screen');

      if (targets.isEmpty && attemptCount < maxAttempts) {
        print('⏳ Tour: No valid targets found for $tourName, retrying (attempt ${attemptCount + 1}/$maxAttempts)...');

        // Force a UI rebuild to ensure widgets are rendered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Add longer delay for each retry to give widgets more time to render
          Future.delayed(Duration(milliseconds: 1000 + (attemptCount * 500)), () {
            _waitForTargetsAndStartTour(context, isPartOfMainTour, tourName, getTargets, shadowColor,
              attemptCount: attemptCount + 1, maxAttempts: maxAttempts);
          });
        });
        return;
      }

      if (targets.isEmpty) {
        print('❌ Tour Error: No valid targets found for $tourName tour after $maxAttempts attempts');
        _isTourActive = false;
        TourKeys.setTourActive(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to start $tourName tour - please try again'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Final validation: ensure we have at least one target
      if (targets.isEmpty) {
        print('❌ Tour Error: Cannot create tour with zero targets for $tourName');
        _isTourActive = false;
        TourKeys.setTourActive(false);
        return;
      }

      print('✅ Tour: Creating tutorial with ${targets.length} valid targets for $tourName');

      // Create and show the tutorial
      _currentTutorial = TutorialCoachMark(
        targets: targets,
        colorShadow: shadowColor,
        paddingFocus: 10,
        hideSkip: false,
        opacityShadow: 0.8,
        textSkip: isPartOfMainTour ? "Skip Tour" : "Close",
        onFinish: () {
          if (isPartOfMainTour) {
            _handleTourFinish(context, tourName);
          } else {
            _isTourActive = false;
            TourKeys.setTourActive(false); // Deactivate tour keys
          }
        },
        onSkip: () {
          _isTourActive = false;
          TourKeys.setTourActive(false); // Deactivate tour keys
          if (isPartOfMainTour) {
            markMainTourCompleted();
          }
          return true;
        },
      );

      try {
        _currentTutorial!.show(context: context);
        print('🎯 Tour: $tourName screen tour started successfully');
      } catch (e) {
        print('❌ Tour Error: Failed to show $tourName tour: $e');
        _isTourActive = false;
        TourKeys.setTourActive(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to display $tourName tour'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  // Handle tour finish and navigation to next section
  void _handleTourFinish(BuildContext context, String tourName) {
    print('🎯 Tour: $tourName tour finished');

    switch (tourName) {
      case 'Home':
        print('🎯 Tour: Navigating to Calendar...');
        Future.delayed(const Duration(milliseconds: 300), () async {
          final navigationSuccess = await _safeNavigateToTab(context, 1);
          if (navigationSuccess) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (_isContextValid(context)) {
                _startCalendarTour(context, isPartOfMainTour: true);
              } else {
                print('❌ Tour Error: Context invalid for Calendar tour');
                _isTourActive = false;
                TourKeys.setTourActive(false);
              }
            });
          } else {
            print('❌ Tour Error: Failed to navigate to Calendar');
            _isTourActive = false;
            TourKeys.setTourActive(false);
          }
        });
        break;

      case 'Calendar':
        print('🎯 Tour: Navigating to Societies...');
        Future.delayed(const Duration(milliseconds: 300), () async {
          final navigationSuccess = await _safeNavigateToTab(context, 2);
          if (navigationSuccess) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (_isContextValid(context)) {
                _startSocietiesScreenTour(context, isPartOfMainTour: true);
              } else {
                print('❌ Tour Error: Context invalid for Societies tour');
                _isTourActive = false;
                TourKeys.setTourActive(false);
              }
            });
          } else {
            print('❌ Tour Error: Failed to navigate to Societies');
            _isTourActive = false;
            TourKeys.setTourActive(false);
          }
        });
        break;

      case 'Societies':
        print('🎯 Tour: Navigating to Friends...');
        Future.delayed(const Duration(milliseconds: 300), () async {
          final navigationSuccess = await _safeNavigateToTab(context, 3);
          if (navigationSuccess) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (_isContextValid(context)) {
                _startFriendsScreenTour(context, isPartOfMainTour: true);
              } else {
                print('❌ Tour Error: Context invalid for Friends tour');
                _isTourActive = false;
                TourKeys.setTourActive(false);
              }
            });
          } else {
            print('❌ Tour Error: Failed to navigate to Friends');
            _isTourActive = false;
            TourKeys.setTourActive(false);
          }
        });
        break;

      case 'Friends':
        print('🎯 Tour: Navigating to Messages...');
        Future.delayed(const Duration(milliseconds: 300), () async {
          final navigationSuccess = await _safeNavigateToTab(context, 4);
          if (navigationSuccess) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (_isContextValid(context)) {
                _startMessagesScreenTour(context, isPartOfMainTour: true);
              } else {
                print('❌ Tour Error: Context invalid for Messages tour');
                _isTourActive = false;
                TourKeys.setTourActive(false);
              }
            });
          } else {
            print('❌ Tour Error: Failed to navigate to Messages');
            _isTourActive = false;
            TourKeys.setTourActive(false);
          }
        });
        break;

      case 'Messages':
        print('🎯 Tour: All tours completed!');
        _isTourActive = false;
        TourKeys.setTourActive(false);
        _showTourCompletionDialog(context);
        markMainTourCompleted();
        break;

      default:
        print('❌ Tour Error: Unknown tour name: $tourName');
        _isTourActive = false;
        TourKeys.setTourActive(false);
        break;
    }
  }

  void _startCalendarTour(BuildContext context, {required bool isPartOfMainTour}) {
    print('🎯 Tour: Starting Calendar screen tour...');

    _waitForTargetsAndStartTour(context, isPartOfMainTour, 'Calendar', () {
      return TourFlows.getCalendarScreenTargets();
    }, AppColors.personalColor);
  }

  void _startSocietiesScreenTour(BuildContext context, {required bool isPartOfMainTour}) {
    print('🎯 Tour: Starting Societies screen tour...');

    _waitForTargetsAndStartTour(context, isPartOfMainTour, 'Societies', () {
      return TourFlows.getSocietiesScreenTargets();
    }, AppColors.societyColor);
  }

  void _startFriendsScreenTour(BuildContext context, {required bool isPartOfMainTour}) {
    print('🎯 Tour: Starting Friends screen tour...');

    _waitForTargetsAndStartTour(context, isPartOfMainTour, 'Friends', () {
      return TourFlows.getFriendsScreenTargets();
    }, AppColors.socialColor);
  }

  void _startMessagesScreenTour(BuildContext context, {required bool isPartOfMainTour}) {
    print('🎯 Tour: Starting Messages screen tour...');

    _waitForTargetsAndStartTour(context, isPartOfMainTour, 'Messages', () {
      return TourFlows.getMessagesScreenTargets();
    }, AppColors.socialColor);
  }

  void _showTourCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.celebration, color: AppColors.homeColor),
              const SizedBox(width: 8),
              const Text('Tour Complete!'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎉 Congratulations! You\'ve completed the UniConnect tour.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'You can now explore the app and connect with your university community. The help icon (?) is always available if you need guidance.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to home
                NavigationHelper.navigateToTab(context, 0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.homeColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Exploring!'),
            ),
          ],
        );
      },
    );
  }

  // Clean up method
  void dispose() {
    _currentTutorial = null;
    _currentTourStep = 0;
    _currentTourType = null;
    _isTourActive = false;
    // Reset all GlobalKeys to prevent conflicts
    TourKeys.resetAllKeys(); // This will call setTourActive(false)
  }
}
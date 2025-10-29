import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_state.dart';
import '../../shared/widgets/main_navigation.dart';
import '../../shared/widgets/uniconnect_logo.dart';

class WelcomeCompleteScreen extends StatefulWidget {
  const WelcomeCompleteScreen({super.key});

  @override
  State<WelcomeCompleteScreen> createState() => _WelcomeCompleteScreenState();
}

class _WelcomeCompleteScreenState extends State<WelcomeCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _celebrationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              Colors.white,
              AppColors.socialColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Animated celebration with logo
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.1),
                                  AppColors.socialColor.withValues(alpha: 0.1),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                          ),
                          const UniConnectLogo(size: 100, showShadow: false),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Icon(
                              Icons.celebration,
                              size: 30,
                              color: AppColors.socialColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Animated welcome text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'Welcome to UniConnect!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You\'re all set up and ready to connect with your university community!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Quick tips
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Quick Tips to Get Started',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTip(
                          icon: Icons.schedule,
                          color: AppColors.personalColor,
                          text: 'Check your calendar for today\'s classes',
                        ),
                        const SizedBox(height: 16),
                        _buildTip(
                          icon: Icons.people,
                          color: AppColors.socialColor,
                          text: 'Find friends in your courses',
                        ),
                        const SizedBox(height: 16),
                        _buildTip(
                          icon: Icons.groups,
                          color: AppColors.societyColor,
                          text: 'Explore societies that match your interests',
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Action buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _enterApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Let\'s Go!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _showHelpOptions,
                        child: const Text(
                          'Need help getting started?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _enterApp() async {
    // Mark onboarding as complete and authenticate user
    final appState = Provider.of<AppState>(context, listen: false);

    print('WelcomeCompleteScreen._enterApp: Checking onboarding state');
    print('WelcomeCompleteScreen._enterApp: newUserData != null: ${appState.newUserData != null}');
    print('WelcomeCompleteScreen._enterApp: activeUserId: ${appState.activeUserId}');
    print('WelcomeCompleteScreen._enterApp: isNewUser: ${appState.isNewUser}');

    // Debug the current state before completion
    print('WelcomeCompleteScreen._enterApp: BEFORE completion state check:');
    print('  - newUserData != null: ${appState.newUserData != null}');
    print('  - activeUserId: ${appState.activeUserId}');
    print('  - isNewUser: ${appState.isNewUser}');

    // Check if we have new user data from the onboarding flow
    if (appState.newUserData != null && appState.activeUserId != null) {
      print('WelcomeCompleteScreen._enterApp: Completing onboarding with new user ID: ${appState.activeUserId}');
      // Complete onboarding with new user using the generated user ID
      appState.completeOnboarding(newUserId: appState.activeUserId!);
    } else {
      print('WelcomeCompleteScreen._enterApp: Completing onboarding with demo user (Andrea)');
      // Complete onboarding with existing demo user (Andrea)
      appState.completeOnboarding();
    }

    // Ensure AppState updates have propagated
    await Future.delayed(const Duration(milliseconds: 50));

    // Verify the state is correctly set
    print('WelcomeCompleteScreen._enterApp: AFTER completion:');
    print('  - isAuthenticated: ${appState.isAuthenticated}');
    print('  - shouldShowOnboarding: ${appState.shouldShowOnboarding}');
    print('  - isInitialized: ${appState.isInitialized}');

    // Set navigation index to home
    appState.setNavIndex(0);

    // CRITICAL: Prevent MaterialApp from auto-routing during manual navigation
    // This prevents duplicate MainNavigation instances that cause GlobalKey conflicts
    appState.startManualNavigation();

    // Clear the entire navigation stack and go to MainNavigation
    if (mounted) {
      print('WelcomeCompleteScreen._enterApp: Manually navigating to MainNavigation (MaterialApp auto-routing disabled)');

      // Use pushAndRemoveUntil to completely replace the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false, // Remove all previous routes
      ).then((_) {
        // Re-enable MaterialApp auto-routing after navigation completes
        if (mounted) {
          appState.endManualNavigation();
          print('WelcomeCompleteScreen._enterApp: Navigation complete, MaterialApp auto-routing re-enabled');
        }
      });
    }
  }

  void _showHelpOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Need Help?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.replay, color: AppColors.primary),
                title: const Text('Replay App Tour'),
                onTap: () {
                  Navigator.pop(context);
                  // Could navigate back to app tour
                },
              ),
              ListTile(
                leading: const Icon(Icons.help, color: AppColors.primary),
                title: const Text('View Help Center'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to help center
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback, color: AppColors.primary),
                title: const Text('Send Feedback'),
                onTap: () {
                  Navigator.pop(context);
                  // Open feedback form
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
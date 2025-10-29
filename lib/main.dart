import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/app_state.dart';
import 'core/services/simple_reminder_service.dart';
import 'shared/widgets/main_navigation.dart';
import 'features/onboarding/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize reminder service in background
  SimpleReminderService().initialize().catchError((error) {
    print('Reminder service initialization failed: $error');
  });

  runApp(const UniConnectApp());
}

class UniConnectApp extends StatelessWidget {
  const UniConnectApp({super.key});

  // Global navigator key for accessing app context from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Get the current app context that won't be invalidated by dialog transitions
  static BuildContext? get currentContext => navigatorKey.currentContext;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'UniConnect',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: !appState.isInitialized
                ? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : appState.shouldShowOnboarding
                    ? const WelcomeScreen()
                    : appState.isAuthenticated
                        ? const MainNavigation()
                        : const WelcomeScreen(), // Fallback to welcome if not authenticated
          );
        },
      ),
    );
  }
}
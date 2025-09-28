import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/app_state.dart';
import 'shared/widgets/main_navigation.dart';
import 'features/onboarding/welcome_screen.dart';

void main() {
  runApp(const UniConnectApp());
}

class UniConnectApp extends StatelessWidget {
  const UniConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'UniConnect',
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
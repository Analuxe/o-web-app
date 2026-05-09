import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/app_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:o_web/screens/discovery_screen.dart';
import 'package:o_web/screens/messaging_screen.dart';
import 'package:o_web/screens/admin_screen.dart';
import 'package:o_web/screens/profile_screen.dart';
import 'package:o_web/screens/auth_screen.dart';
import 'package:o_web/screens/matchmaker_screen.dart';

import 'package:o_web/screens/onboarding_screen.dart';
import 'package:o_web/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const OApp());
}

final _router = GoRouter(
  initialLocation: '/discovery',
  redirect: (context, state) async {
    final session = SupabaseService.client.auth.currentSession;
    final bool isLoggingIn = state.matchedLocation == '/auth';

    if (session == null) {
      return isLoggingIn ? null : '/auth';
    }

    // Check if profile is complete
    final profile = await SupabaseService.getMyProfile();
    final bool isOnboarding = state.matchedLocation == '/onboarding';

    if (profile == null || !profile.isComplete) {
      return isOnboarding ? null : '/onboarding';
    }

    if (isLoggingIn || isOnboarding) return '/discovery';

    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/discovery',
          builder: (context, state) => const DiscoveryScreen(),
        ),
        GoRoute(
          path: '/messaging',
          builder: (context, state) => const MessagingScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/matchmaker',
          builder: (context, state) => const MatchmakerScreen(),
        ),
      ],
    ),
  ],
);

class OApp extends StatelessWidget {
  const OApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'O',
      theme: OTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

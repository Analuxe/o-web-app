import 'package:o_web/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/app_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:o_web/screens/discovery_screen.dart';
import 'package:o_web/screens/messaging_screen.dart';
import 'package:o_web/screens/admin_screen.dart';
import 'package:o_web/screens/profile_screen.dart';
import 'package:o_web/screens/auth_screen.dart';
import 'package:o_web/screens/forgot_password_screen.dart';
import 'package:o_web/screens/reset_password_screen.dart';
import 'package:o_web/screens/matchmaker_screen.dart';

import 'package:o_web/screens/onboarding_screen.dart';
import 'package:o_web/screens/settings_screen.dart';
import 'package:o_web/screens/hub_screen.dart';
import 'package:o_web/screens/legal_screen.dart';
import 'package:o_web/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const OApp());
}

final _router = GoRouter(
  initialLocation: '/hub',
  redirect: (context, state) async {
    final session = SupabaseService.client.auth.currentSession;
    final bool isLoggingIn = state.matchedLocation == '/auth';
    final bool isForgotPassword = state.matchedLocation == '/forgot-password';
    final bool isResetPassword = state.matchedLocation == '/reset-password';

    if (session == null) {
      if (isLoggingIn || isForgotPassword || isResetPassword) return null;
      return '/auth';
    }

    // Check if profile is complete
    Profile? profile;
    safeLog('NAV: Checking profile for user: ${SupabaseService.client.auth.currentUser?.id}');
    try {
      profile = await SupabaseService.getMyProfile().timeout(const Duration(seconds: 3));
      safeLog('NAV: Profile fetch success: ${profile != null}');
    } catch (e) {
      safeLog('NAV: Profile fetch FAILED: $e');
    }

    final bool isOnboarding = state.matchedLocation == '/onboarding';

    // Simple, non-blocking check: if no username, go to onboarding
    if (profile == null || profile.username == null || profile.username!.isEmpty) {
      if (isOnboarding || isResetPassword) return null;
      return '/onboarding';
    }

    // Admin Protection
    if (state.matchedLocation == '/admin' && !profile.isAdmin) {
      return '/hub';
    }

    if (isLoggingIn || isOnboarding) return '/hub';

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/hub',
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/hub',
          builder: (context, state) => const HubScreen(),
        ),
        GoRoute(
          path: '/discovery',
          builder: (context, state) => const DiscoveryScreen(),
        ),
        GoRoute(
          path: '/messaging',
          builder: (context, state) {
            final id = state.uri.queryParameters['id'];
            return MessagingScreen(
              key: ValueKey(id),
              initialProfileId: id,
            );
          },
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            final id = state.uri.queryParameters['id'];
            return ProfileScreen(
              key: id != null ? ValueKey(id) : null,
              userId: id,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/legal/terms',
          builder: (context, state) => const LegalScreen(doc: LegalDoc.termsOfService),
        ),
        GoRoute(
          path: '/legal/privacy',
          builder: (context, state) => const LegalScreen(doc: LegalDoc.privacyPolicy),
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

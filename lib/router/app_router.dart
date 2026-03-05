import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/setup_profile_screen.dart';

// Placeholder — replace with real dashboard once built
class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Dashboard — coming soon')),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthPage = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/verify-email') ||
          state.matchedLocation.startsWith('/setup-profile') ||
          state.matchedLocation.startsWith('/forgot-password');

      // Not logged in → send to login
      if (!isLoggedIn && !isOnAuthPage) return '/login';

      // Logged in but on login/register → send to dashboard
      if (isLoggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/setup-profile',
        builder: (context, state) => const SetupProfileScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPlaceholder(),
      ),
    ],
  );
});

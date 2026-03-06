import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

// Auth screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/setup_profile_screen.dart';

// App screens
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/gigs/gig_browse_screen.dart';
import '../screens/gigs/post_gig_screen.dart';
import '../screens/rentals/rental_browse_screen.dart';
import '../screens/rentals/list_rental_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/reports_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthPage =
          state.matchedLocation.startsWith('/login') ||
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
      // ── Auth ──────────────────────────────────
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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

      // ── Main app (shell with bottom nav) ──────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/gigs',
            builder: (context, state) => const GigBrowseScreen(),
          ),
          GoRoute(
            path: '/gigs/post',
            builder: (context, state) => const PostGigScreen(),
          ),
          GoRoute(
            path: '/rentals',
            builder: (context, state) => const RentalBrowseScreen(),
          ),
          GoRoute(
            path: '/rentals/list',
            builder: (context, state) => const ListRentalScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),

      // ── Admin (no bottom nav) ────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
    ],
  );
});

// ─────────────────────────────────────────────
//  APP SHELL  — persistent bottom nav bar
// ─────────────────────────────────────────────
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(path: '/dashboard', icon: Icons.home_rounded, label: 'Home'),
    _TabItem(path: '/gigs', icon: Icons.flash_on_rounded, label: 'Gigs'),
    _TabItem(
      path: '/rentals',
      icon: Icons.inventory_2_rounded,
      label: 'Rentals',
    ),
    _TabItem(path: '/profile', icon: Icons.person_rounded, label: 'Profile'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080E),
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex(context),
        onTap: (i) => context.go(_tabs[i].path),
        tabs: _tabs,
      ),
    );
  }
}

class _TabItem {
  final String path, label;
  final IconData icon;
  const _TabItem({required this.path, required this.icon, required this.label});
}

// ─────────────────────────────────────────────
//  BOTTOM NAV BAR  (custom styled)
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> tabs;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        border: Border(top: BorderSide(color: Color(0xFF222235))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF7B2FFF).withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[i].icon,
                        size: 22,
                        color: selected
                            ? const Color(0xFF7B2FFF)
                            : const Color(0xFF8888AA),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? const Color(0xFF7B2FFF)
                              : const Color(0xFF8888AA),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

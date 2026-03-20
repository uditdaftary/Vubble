import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

// Auth screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/setup_profile_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

// App screens
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/gigs/gig_browse_screen.dart';
import '../screens/gigs/my_gigs_screen.dart';
import '../screens/gigs/post_gig_screen.dart';
import '../screens/rentals/my_rentals_screen.dart';
import '../screens/rentals/rental_browse_screen.dart';
import '../screens/rentals/list_rental_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/reports_screen.dart';

// ── Transition helper ────────────────────────
CustomTransitionPage<void> _tp(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileState = ref.watch(currentUserProfileProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final profile = profileState.valueOrNull;
      final profileLoading = profileState.isLoading;
      final loc = state.matchedLocation;

      final isOnAuthPage =
          loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/verify-email') ||
          loc.startsWith('/setup-profile') ||
          loc.startsWith('/forgot-password');

      // Not logged in → send to login
      if (!isLoggedIn && !isOnAuthPage) return '/login';

      // Logged in but profile still loading → stay put to avoid flicker
      if (isLoggedIn && profileLoading) return null;

      // Logged in but no Firestore profile yet → must complete setup
      if (isLoggedIn && profile == null && !isOnAuthPage) {
        return '/setup-profile';
      }

      // Logged in with profile, on login/register/setup → go to app
      if (isLoggedIn &&
          profile != null &&
          (loc == '/login' || loc == '/register' || loc == '/setup-profile')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────
      GoRoute(path: '/login', pageBuilder: (_, s) => _tp(s, const LoginScreen())),
      GoRoute(path: '/register', pageBuilder: (_, s) => _tp(s, const RegisterScreen())),
      GoRoute(path: '/verify-email', pageBuilder: (_, s) => _tp(s, const VerifyEmailScreen())),
      GoRoute(path: '/setup-profile', pageBuilder: (_, s) => _tp(s, const SetupProfileScreen())),
      GoRoute(path: '/forgot-password', pageBuilder: (_, s) => _tp(s, const ForgotPasswordScreen())),

      // ── Main app (shell with bottom nav) ──────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', pageBuilder: (_, s) => _tp(s, const DashboardScreen())),
          GoRoute(path: '/gigs', pageBuilder: (_, s) => _tp(s, const GigBrowseScreen())),
          GoRoute(path: '/gigs/post', pageBuilder: (_, s) => _tp(s, const PostGigScreen())),
          GoRoute(path: '/rentals', pageBuilder: (_, s) => _tp(s, const RentalBrowseScreen())),
          GoRoute(path: '/rentals/list', pageBuilder: (_, s) => _tp(s, const ListRentalScreen())),
          GoRoute(path: '/profile', pageBuilder: (_, s) => _tp(s, const ProfileScreen())),
          GoRoute(path: '/notifications', pageBuilder: (_, s) => _tp(s, const NotificationsScreen())),
          GoRoute(path: '/my-gigs', pageBuilder: (_, s) => _tp(s, const MyGigsScreen())),
          GoRoute(path: '/my-rentals', pageBuilder: (_, s) => _tp(s, const MyRentalsScreen())),
        ],
      ),

      // ── Admin (no bottom nav) ────────────────
      GoRoute(path: '/admin', pageBuilder: (_, s) => _tp(s, const AdminDashboardScreen())),
      GoRoute(path: '/admin/users', pageBuilder: (_, s) => _tp(s, const UserManagementScreen())),
      GoRoute(path: '/admin/reports', pageBuilder: (_, s) => _tp(s, const ReportsScreen())),
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
      icon: Icons.swap_horiz_rounded,
      label: 'Lend & Borrow',
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

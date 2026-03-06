import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';

// ─────────────────────────────────────────────
//  USER MANAGEMENT SCREEN
// ─────────────────────────────────────────────
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});
  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _showActionDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── User avatar ─────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.violet, AppColors.cyan],
                  ),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: AppText.display(size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(user.name, style: AppText.heading(size: 18)),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: AppText.body(size: 13, color: AppColors.textMuted),
              ),
              Text(
                user.department,
                style: AppText.body(size: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StarRating(rating: user.rating, count: user.totalRatings),
                  const SizedBox(width: 10),
                  if (user.isSuspended)
                    _StatusBadge(label: 'SUSPENDED', color: AppColors.amber),
                  if (user.isBanned)
                    _StatusBadge(label: 'BANNED', color: AppColors.coral),
                  if (!user.isSuspended && !user.isBanned)
                    _StatusBadge(label: 'ACTIVE', color: AppColors.lime),
                ],
              ),
              const SizedBox(height: 8),
              // ── Stats row ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MiniStat(label: 'Gigs', value: '${user.completedGigs}'),
                  _MiniStat(
                    label: 'Rentals',
                    value: '${user.completedRentals}',
                  ),
                  _MiniStat(label: 'Reports', value: '${user.reportCount}'),
                  _MiniStat(label: 'Cancels', value: '${user.cancellations}'),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),
              Text('ACTIONS', style: AppText.label()),
              const SizedBox(height: 12),
              // ── Action buttons ──────────────────
              Row(
                children: [
                  if (!user.isSuspended && !user.isBanned)
                    Expanded(
                      child: _ActionButton(
                        label: 'Suspend',
                        color: AppColors.amber,
                        icon: Icons.pause_circle_rounded,
                        onTap: () {
                          ref
                              .read(adminServiceProvider)
                              .suspendUser(user.userId);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  if (!user.isSuspended && !user.isBanned)
                    const SizedBox(width: 8),
                  if (!user.isBanned)
                    Expanded(
                      child: _ActionButton(
                        label: 'Ban',
                        color: AppColors.coral,
                        icon: Icons.block_rounded,
                        onTap: () {
                          ref.read(adminServiceProvider).banUser(user.userId);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  if (user.isSuspended || user.isBanned)
                    Expanded(
                      child: _ActionButton(
                        label: 'Lift Restriction',
                        color: AppColors.lime,
                        icon: Icons.check_circle_rounded,
                        onTap: () {
                          ref
                              .read(adminServiceProvider)
                              .liftRestriction(user.userId);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/admin'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'User Management',
                        style: AppText.display(size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: TextFormField(
                  style: AppText.input(),
                  decoration: const InputDecoration(
                    hintText: 'Search users…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
            ),

            // ── Users list ──────────────────────
            usersAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.violet),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Failed to load users',
                    style: AppText.body(color: AppColors.coral),
                  ),
                ),
              ),
              data: (users) {
                final filtered = users
                    .where(
                      (u) =>
                          u.name.toLowerCase().contains(_search) ||
                          u.email.toLowerCase().contains(_search) ||
                          u.department.toLowerCase().contains(_search),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No users found',
                        style: AppText.body(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _UserTile(
                        user: filtered[i],
                        onTap: () => _showActionDialog(filtered[i]),
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                );
              },
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.violet, AppColors.cyan],
                ),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: AppText.heading(size: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: AppText.body(
                      size: 14,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.department,
                    style: AppText.body(size: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StarRating(rating: user.rating),
                const SizedBox(height: 4),
                if (user.isBanned)
                  _StatusBadge(label: 'BANNED', color: AppColors.coral)
                else if (user.isSuspended)
                  _StatusBadge(label: 'SUSPENDED', color: AppColors.amber)
                else
                  _StatusBadge(label: 'ACTIVE', color: AppColors.lime),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: AppText.label(size: 9, color: color)),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: AppText.label(size: 10, color: color)),
        ],
      ),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppText.heading(size: 16)),
      const SizedBox(height: 2),
      Text(label, style: AppText.body(size: 10, color: AppColors.textMuted)),
    ],
  );
}

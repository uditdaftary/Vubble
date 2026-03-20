import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/gig_model.dart';
import '../../models/rental_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_rental_providers.dart';
import '../../theme/app_theme.dart' hide GigCategory, RentalCategory;

// ─────────────────────────────────────────────
//  DASHBOARD SCREEN
// ─────────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

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

  // ── build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: userAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.violet,
              strokeWidth: 2,
            ),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: AppText.body(color: AppColors.coral),
            ),
          ),
          data: (user) {
            if (user == null) {
              return Center(
                child: Text(
                  'Not logged in',
                  style: AppText.body(color: AppColors.coral),
                ),
              );
            }
            return CustomScrollView(
              slivers: [
                _header(user),
                _statsRow(user),
                _quickActions(),
                _sectionTitle('🏆 Leaderboard'),
                _leaderboardSection(),
                _sectionTitle(
                  'Active Gigs',
                  onSeeAll: () => context.push('/my-gigs'),
                ),
                _activeGigRow(),
                _sectionTitle('Recent Activity', onSeeAll: () {}),
                _activityFeed(),
                const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────
  Widget _header(user) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, ${user.name.isNotEmpty ? user.name.split(' ').first : 'there'} 👋',
                  style: AppText.display(size: 26),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (user.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.violet.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '✓ Verified',
                          style: AppText.label(
                            size: 10,
                            color: AppColors.violet,
                          ),
                        ),
                      ),
                    if (user.isVerified) const SizedBox(width: 8),
                    Text(
                      user.department,
                      style: AppText.body(size: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _NotifButton(count: 0, onTap: () => context.push('/notifications')),
          const SizedBox(width: 10),
          _AvatarCircle(
            initial: user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          ),
        ],
      ),
    ),
  );

  // ── stats row ─────────────────────────────────
  Widget _statsRow(user) {
    final activeGigs = ref.watch(activeGigCountProvider);
    final activeRentals = ref.watch(activeRentalCountProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Active Gigs',
                value: '$activeGigs',
                color: AppColors.cyan,
                emoji: '⚡',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Active Rentals',
                value: '$activeRentals',
                color: AppColors.lime,
                emoji: '📦',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Rating',
                value: '${user.rating}★',
                color: AppColors.amber,
                emoji: '🏆',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── quick actions ─────────────────────────────
  Widget _quickActions() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUICK ACTIONS', style: AppText.label()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  emoji: '🔍',
                  label: 'Browse\nGigs',
                  grad: [AppColors.violet, const Color(0xFF5000EE)],
                  onTap: () => context.push('/gigs'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  emoji: '✏️',
                  label: 'Post\nGig',
                  grad: [const Color(0xFF0099BB), AppColors.cyan],
                  onTap: () => context.push('/gigs/post'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  emoji: '📦',
                  label: 'Browse\nRentals',
                  grad: [const Color(0xFF885000), AppColors.amber],
                  onTap: () => context.push('/rentals'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  emoji: '➕',
                  label: 'List\nItem',
                  grad: [const Color(0xFF4A6000), AppColors.lime],
                  onTap: () => context.push('/rentals/list'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ── leaderboard ────────────────────────────────
  Widget _leaderboardSection() {
    final lbAsync = ref.watch(leaderboardProvider);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: lbAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
          ),
          error: (e, _) => Text('Error: $e', style: AppText.body(color: AppColors.coral)),
          data: (users) {
            if (users.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No data yet', style: AppText.body(size: 13, color: AppColors.textMuted)),
                ),
              );
            }
            final top5 = users.take(5).toList();
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: top5.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final user = entry.value;
                  final rankColors = [AppColors.amber, const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];
                  final rankColor = rank <= 3 ? rankColors[rank - 1] : AppColors.textMuted;
                  final rankEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: rank <= 3
                              ? Text(rankEmoji, style: const TextStyle(fontSize: 18))
                              : Text('#$rank', style: AppText.label(size: 13, color: rankColor)),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: rankColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: rankColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(user.name, style: AppText.body(size: 13).copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rankColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${user.totalCompleted}',
                            style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: rankColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── section title ─────────────────────────────
  Widget _sectionTitle(String title, {VoidCallback? onSeeAll}) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppText.heading(size: 18)),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'See all →',
                  style: AppText.body(size: 13, color: AppColors.violet),
                ),
              ),
            ],
          ),
        ),
      );

  // ── active gig horizontal scroll ──────────────
  Widget _activeGigRow() {
    final postedAsync = ref.watch(myPostedGigsProvider);
    final acceptedAsync = ref.watch(myAcceptedGigsProvider);

    final posted = postedAsync.valueOrNull ?? [];
    final accepted = acceptedAsync.valueOrNull ?? [];

    final activeStatuses = {
      GigStatus.open,
      GigStatus.accepted,
      GigStatus.inProgress,
      GigStatus.completedPendingReview,
    };

    final activeGigs = [
      ...posted.where((g) => activeStatuses.contains(g.status)),
      ...accepted.where((g) => activeStatuses.contains(g.status)),
    ];
    // Deduplicate by gigId
    final seen = <String>{};
    final dedupedGigs = activeGigs.where((g) => seen.add(g.gigId)).toList();
    dedupedGigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayGigs = dedupedGigs.take(5).toList();

    if (postedAsync.isLoading || acceptedAsync.isLoading) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 156,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.violet,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (displayGigs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('📋', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text('No active gigs', style: AppText.heading(size: 14)),
                const SizedBox(height: 4),
                Text(
                  'Post a gig or browse open ones to get started.',
                  style: AppText.body(size: 13, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 156,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemCount: displayGigs.length,
          itemBuilder: (_, i) => _ActiveGigCard(gig: displayGigs[i]),
        ),
      ),
    );
  }

  // ── activity feed ─────────────────────────────
  Widget _activityFeed() {
    final gigsAsync = ref.watch(myPostedGigsProvider);
    final rentalsAsync = ref.watch(myOwnedRentalsProvider);

    final gigs = gigsAsync.valueOrNull ?? [];
    final rentals = rentalsAsync.valueOrNull ?? [];

    // Build feed items from real data
    final feedItems = <_FeedItem>[];
    for (final gig in gigs) {
      feedItems.add(
        _FeedItem(
          emoji: gig.category.emoji,
          title: '${gig.status.label} — ${gig.title}',
          sub: '₹${gig.price} · ${gig.category.label}',
          time: gig.timeAgo,
          createdAt: gig.createdAt,
        ),
      );
    }
    for (final rental in rentals) {
      feedItems.add(
        _FeedItem(
          emoji: rental.category.emoji,
          title: '${rental.status.label} — ${rental.itemName}',
          sub: '₹${rental.dailyRate}/day',
          time: _timeAgo(rental.createdAt),
          createdAt: rental.createdAt,
        ),
      );
    }

    feedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayItems = feedItems.take(5).toList();

    if (displayItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('📭', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text('No recent activity', style: AppText.heading(size: 14)),
                const SizedBox(height: 4),
                Text(
                  'Your gig and rental activity will show up here.',
                  style: AppText.body(size: 13, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _FeedTile(item: displayItems[i]),
        ),
        childCount: displayItems.length,
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

class _NotifButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _NotifButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String initial;
  const _AvatarCircle({required this.initial});

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [AppColors.violet, AppColors.cyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        initial,
        style: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String emoji;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text(value, style: AppText.price(size: 15, color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppText.body(size: 11, color: AppColors.textMuted)),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final List<Color> grad;
  final VoidCallback onTap;

  const _ActionTile({
    required this.emoji,
    required this.label,
    required this.grad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── data class for feed ──────────────────────
class _FeedItem {
  final String emoji, title, sub, time;
  final DateTime createdAt;
  const _FeedItem({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.time,
    required this.createdAt,
  });
}

// ── active gig card ───────────────────────────
class _ActiveGigCard extends StatelessWidget {
  final GigModel gig;
  const _ActiveGigCard({required this.gig});

  Color get _statusColor {
    switch (gig.status) {
      case GigStatus.inProgress:
        return AppColors.lime;
      case GigStatus.accepted:
        return AppColors.cyan;
      case GigStatus.completedPendingReview:
        return AppColors.violet;
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catLabel = gig.category.label;
    final catColor = _catColor(gig.category);
    return GestureDetector(
      onTap: () => _openGigDetail(context),
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 210,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryBadge(
                    label: catLabel,
                    color: catColor,
                    emoji: gig.category.emoji,
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                gig.title,
                style: AppText.heading(size: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹${gig.price}', style: AppText.price(size: 16)),
                  Text(
                    gig.isOverdue ? 'OVERDUE' : 'Due ${gig.deadlineFormatted}',
                    style: AppText.body(
                      size: 11,
                      color: gig.isOverdue
                          ? AppColors.coral
                          : AppColors.textMuted,
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

  Color _catColor(GigCategory cat) {
    switch (cat) {
      case GigCategory.tutoring:
        return AppColors.violet;
      case GigCategory.delivery:
        return AppColors.cyan;
      case GigCategory.writing:
        return AppColors.lime;
      case GigCategory.coding:
        return AppColors.amber;
      case GigCategory.errands:
        return AppColors.coral;
      case GigCategory.other:
        return const Color(0xFF7777AA);
    }
  }

  void _openGigDetail(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      expand: false,
      builder: (_, sc) => SingleChildScrollView(
        controller: sc,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                CategoryBadge(
                  label: gig.category.label,
                  color: _catColor(gig.category),
                  emoji: gig.category.emoji,
                ),
                const Spacer(),
                Text('₹${gig.price}', style: AppText.price(size: 26)),
              ],
            ),
            const SizedBox(height: 14),
            Text(gig.title, style: AppText.heading(size: 20)),
            const SizedBox(height: 10),
            Text(
              gig.description,
              style: AppText.body(
                size: 14,
                color: AppColors.textMuted,
              ).copyWith(height: 1.6),
            ),
            const SizedBox(height: 20),
            _DashDetailRow(
              icon: Icons.schedule_rounded,
              label: 'Deadline',
              value: gig.deadlineFormatted,
            ),
            const SizedBox(height: 8),
            _DashDetailRow(
              icon: Icons.person_rounded,
              label: 'Posted by',
              value: '${gig.creatorName}  ★ ${gig.creatorRating}',
            ),
            const SizedBox(height: 8),
            _DashDetailRow(
              icon: Icons.info_outline_rounded,
              label: 'Status',
              value: gig.status.label,
            ),
            const SizedBox(height: 8),
            _DashDetailRow(
              icon: Icons.access_time_rounded,
              label: 'Posted',
              value: gig.timeAgo,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

// ── feed tile ─────────────────────────────────
class _FeedTile extends StatelessWidget {
  final _FeedItem item;
  const _FeedTile({required this.item});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    radius: 14,
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.sub,
                style: AppText.body(size: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Text(
          item.time,
          style: AppText.body(size: 11, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

// ── detail row for gig bottom sheet ───────────
class _DashDetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DashDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: AppColors.textMuted),
      const SizedBox(width: 8),
      Text(
        '$label: ',
        style: AppText.body(size: 13, color: AppColors.textMuted),
      ),
      Flexible(
        child: Text(
          value,
          style: AppText.body(size: 13).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

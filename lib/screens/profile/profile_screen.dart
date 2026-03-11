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
//  PROFILE SCREEN
// ─────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.violet,
            strokeWidth: 2,
          ),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: AppText.body(color: AppColors.coral)),
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
          return NestedScrollView(
            headerSliverBuilder: (_, _) => [
              _profileHeader(user),
              _statsRow(user),
              _tabBar(),
            ],
            body: TabBarView(
              controller: _tabs,
              children: [_reviewsTab(user), _listingsTab(), _activityTab()],
            ),
          );
        },
      ),
    );
  }

  // ── profile header ────────────────────────────
  Widget _profileHeader(user) => SliverToBoxAdapter(
    child: Stack(
      children: [
        // gradient banner
        Container(
          height: 160,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF180840), Color(0xFF0A1840)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // action buttons
        Positioned(
          top: 52,
          right: 16,
          child: Row(
            children: [
              _IconBtn(icon: Icons.share_rounded, onTap: () {}),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.settings_rounded, onTap: () {}),
            ],
          ),
        ),
        // avatar + info
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // avatar
                  Container(
                    width: 76,
                    height: 76,
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
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: GoogleFonts.syne(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: AppText.heading(size: 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (user.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.violet.withOpacity(0.2),
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
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.department,
                          style: AppText.body(
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // bio
              if (user.bio.isNotEmpty)
                Text(
                  user.bio,
                  style: AppText.body(
                    size: 14,
                    color: AppColors.textMuted,
                  ).copyWith(height: 1.4),
                ),
              if (user.bio.isNotEmpty) const SizedBox(height: 12),
              // registration number + email
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (user.registrationNumber.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.cyan.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: AppColors.cyan,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.registrationNumber,
                            style: GoogleFonts.syne(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyan,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.alternate_email_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          user.email,
                          style: AppText.body(
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    ),
  );

  // ── stats row ─────────────────────────────────
  Widget _statsRow(user) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: _StatBlock(
              value: '${user.rating}★',
              label: 'Rating',
              color: AppColors.amber,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _StatBlock(
              value: '${user.totalRatings}',
              label: 'Reviews',
              color: AppColors.violet,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _StatBlock(
              value: '${user.completedGigs}',
              label: 'Gigs Done',
              color: AppColors.lime,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _StatBlock(
              value: '${user.completedRentals}',
              label: 'Rentals',
              color: AppColors.cyan,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: AppColors.border);

  // ── tab bar ───────────────────────────────────
  Widget _tabBar() => SliverPersistentHeader(
    pinned: true,
    delegate: _StickyTabBarDelegate(
      tabBar: TabBar(
        controller: _tabs,
        indicatorColor: AppColors.violet,
        indicatorWeight: 2,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        tabs: const [
          Tab(text: 'Reviews'),
          Tab(text: 'Listings'),
          Tab(text: 'Activity'),
        ],
      ),
    ),
  );

  // ── reviews tab ───────────────────────────────
  Widget _reviewsTab(user) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
    children: [
      _ratingBreakdown(user),
      const SizedBox(height: 20),
      // Empty state — reviews collection not wired yet
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            const Text('📝', style: TextStyle(fontSize: 42)),
            const SizedBox(height: 12),
            Text('No reviews yet', style: AppText.heading(size: 16)),
            const SizedBox(height: 6),
            Text(
              'Reviews from gig and rental completions will appear here.',
              textAlign: TextAlign.center,
              style: AppText.body(size: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _ratingBreakdown(user) => SurfaceCard(
    child: Column(
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.rating}',
                  style: GoogleFonts.syne(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber,
                  ),
                ),
                Text(
                  'out of 5.0',
                  style: AppText.body(size: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on ${user.totalRatings} review${user.totalRatings == 1 ? '' : 's'}',
                  style: AppText.body(size: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: AppColors.border),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                emoji: '✅',
                label: 'Completion',
                value: '${user.completionRate.toStringAsFixed(0)}%',
              ),
            ),
            Expanded(
              child: _MiniStat(
                emoji: '❌',
                label: 'Cancellations',
                value: '${user.cancellations}',
              ),
            ),
            Expanded(
              child: _MiniStat(
                emoji: '📅',
                label: 'Member Since',
                value: '${user.createdAt.year}',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // ── listings tab ──────────────────────────────
  Widget _listingsTab() {
    final gigsAsync = ref.watch(myPostedGigsProvider);
    final rentalsAsync = ref.watch(myOwnedRentalsProvider);

    return gigsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.violet,
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: AppText.body(color: AppColors.coral)),
      ),
      data: (gigs) {
        final rentals = rentalsAsync.valueOrNull ?? [];

        // Active gigs
        final activeGigs = gigs
            .where(
              (g) =>
                  g.status != GigStatus.closed &&
                  g.status != GigStatus.cancelled,
            )
            .toList();

        // Active rentals
        final activeRentals = rentals
            .where(
              (r) =>
                  r.status != RentalStatus.completed &&
                  r.status != RentalStatus.cancelled,
            )
            .toList();

        final hasActive = activeGigs.isNotEmpty || activeRentals.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            if (hasActive) ...[
              Text(
                'ACTIVE (${activeGigs.length + activeRentals.length})',
                style: AppText.label(),
              ),
              const SizedBox(height: 12),
              ...activeGigs.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GigListingTile(gig: g),
                ),
              ),
              ...activeRentals.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RentalListingTile(rental: r),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (!hasActive)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 12),
                    Text(
                      'No active listings',
                      style: AppText.heading(size: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Post a gig or list an item to get started.',
                      textAlign: TextAlign.center,
                      style: AppText.body(size: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            GradientButton(
              label: '+ Post New Gig',
              width: double.infinity,
              onTap: () => context.push('/gigs/post'),
            ),
            const SizedBox(height: 10),
            GradientButton(
              label: '+ List New Item',
              width: double.infinity,
              colors: [const Color(0xFF0099BB), AppColors.cyan],
              onTap: () => context.push('/rentals/list'),
            ),
          ],
        );
      },
    );
  }

  // ── activity tab ──────────────────────────────
  Widget _activityTab() {
    final gigsAsync = ref.watch(myPostedGigsProvider);
    final rentalsAsync = ref.watch(myOwnedRentalsProvider);

    final gigs = gigsAsync.valueOrNull ?? [];
    final rentals = rentalsAsync.valueOrNull ?? [];

    // Combine closed gigs and completed rentals as activity history
    final activityItems = <_ActivityItem>[];

    for (final g in gigs) {
      activityItems.add(
        _ActivityItem(
          emoji: g.category.emoji,
          title: '${g.status.label} — ${g.title}',
          sub: '₹${g.price} · ${g.category.label}',
          time: _timeAgo(g.createdAt),
          color: _gigStatusColor(g.status),
          createdAt: g.createdAt,
        ),
      );
    }

    for (final r in rentals) {
      activityItems.add(
        _ActivityItem(
          emoji: r.category.emoji,
          title: '${r.status.label} — ${r.itemName}',
          sub: '₹${r.dailyRate}/day',
          time: _timeAgo(r.createdAt),
          color: _rentalStatusColor(r.status),
          createdAt: r.createdAt,
        ),
      );
    }

    activityItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayItems = activityItems.take(15).toList();

    if (displayItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📭', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('No activity yet', style: AppText.heading(size: 18)),
              const SizedBox(height: 8),
              Text(
                'Your gig and rental history will show up here.',
                textAlign: TextAlign.center,
                style: AppText.body(size: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      separatorBuilder: (_, _) => const SizedBox(height: 1),
      itemCount: displayItems.length,
      itemBuilder: (_, i) => _ActivityRow(
        data: displayItems[i],
        isLast: i == displayItems.length - 1,
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _gigStatusColor(GigStatus status) {
    switch (status) {
      case GigStatus.open:
        return AppColors.cyan;
      case GigStatus.accepted:
        return AppColors.amber;
      case GigStatus.inProgress:
        return AppColors.violet;
      case GigStatus.completedPendingReview:
        return AppColors.lime;
      case GigStatus.closed:
        return AppColors.textMuted;
      case GigStatus.cancelled:
        return AppColors.coral;
      case GigStatus.reported:
        return AppColors.coral;
    }
  }

  Color _rentalStatusColor(RentalStatus status) {
    switch (status) {
      case RentalStatus.available:
        return AppColors.lime;
      case RentalStatus.requested:
        return AppColors.amber;
      case RentalStatus.active:
        return AppColors.cyan;
      case RentalStatus.returnPending:
        return AppColors.violet;
      case RentalStatus.completed:
        return AppColors.textMuted;
      case RentalStatus.disputed:
        return AppColors.coral;
      case RentalStatus.cancelled:
        return AppColors.coral;
    }
  }
}

// ─────────────────────────────────────────────
//  STICKY TAB BAR DELEGATE
// ─────────────────────────────────────────────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate({required this.tabBar});
  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(
    color: AppColors.bg,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tabBar,
        Divider(height: 1, color: AppColors.border),
      ],
    ),
  );
  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => false;
}

// ─────────────────────────────────────────────
//  DATA CLASSES
// ─────────────────────────────────────────────
class _ActivityItem {
  final String emoji, title, sub, time;
  final Color color;
  final DateTime createdAt;
  const _ActivityItem({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.time,
    required this.color,
    required this.createdAt,
  });
}

// ─────────────────────────────────────────────
//  SUB WIDGETS
// ─────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Icon(icon, size: 18, color: AppColors.textPrimary),
    ),
  );
}

class _StatBlock extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBlock({
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: GoogleFonts.syne(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      const SizedBox(height: 3),
      Text(label, style: AppText.body(size: 11, color: AppColors.textMuted)),
    ],
  );
}

class _MiniStat extends StatelessWidget {
  final String emoji, label, value;
  const _MiniStat({
    required this.emoji,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(value, style: AppText.heading(size: 14)),
      Text(label, style: AppText.body(size: 11, color: AppColors.textMuted)),
    ],
  );
}

// ── Listing tiles ─────────────────────────────
class _GigListingTile extends StatelessWidget {
  final GigModel gig;
  const _GigListingTile({required this.gig});

  Color get _statusColor {
    switch (gig.status) {
      case GigStatus.open:
        return AppColors.cyan;
      case GigStatus.accepted:
        return AppColors.amber;
      case GigStatus.inProgress:
        return AppColors.violet;
      case GigStatus.completedPendingReview:
        return AppColors.lime;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 12,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              gig.category.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gig.title,
                style: AppText.body(
                  size: 13,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    gig.status.label,
                    style: AppText.label(size: 10, color: _statusColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· Gig',
                    style: AppText.body(size: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text('₹${gig.price}', style: AppText.price(size: 14)),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
          size: 18,
        ),
      ],
    ),
  );
}

class _RentalListingTile extends StatelessWidget {
  final RentalModel rental;
  const _RentalListingTile({required this.rental});

  Color get _statusColor {
    switch (rental.status) {
      case RentalStatus.available:
        return AppColors.lime;
      case RentalStatus.requested:
        return AppColors.amber;
      case RentalStatus.active:
        return AppColors.cyan;
      case RentalStatus.returnPending:
        return AppColors.violet;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 12,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              rental.category.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rental.itemName,
                style: AppText.body(
                  size: 13,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    rental.status.label,
                    style: AppText.label(size: 10, color: _statusColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· Rental',
                    style: AppText.body(size: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text('₹${rental.dailyRate}/d', style: AppText.price(size: 14)),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
          size: 18,
        ),
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem data;
  final bool isLast;
  const _ActivityRow({required this.data, required this.isLast});
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: data.color.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(data.emoji, style: const TextStyle(fontSize: 16)),
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 1.5,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: AppText.body(
                    size: 13,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  data.sub,
                  style: AppText.body(size: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  data.time,
                  style: AppText.body(
                    size: 11,
                    color: AppColors.textMuted.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

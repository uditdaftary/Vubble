import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/gig_model.dart';
import '../../providers/gig_rental_providers.dart';
import '../../providers/auth_provider.dart';
import '../../services/gig_service.dart';
import '../../theme/app_theme.dart' hide GigCategory;

// ─────────────────────────────────────────────
//  MY GIGS SCREEN
// ─────────────────────────────────────────────
class MyGigsScreen extends ConsumerStatefulWidget {
  const MyGigsScreen({super.key});
  @override
  ConsumerState<MyGigsScreen> createState() => _MyGigsScreenState();
}

class _MyGigsScreenState extends ConsumerState<MyGigsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posted   = ref.watch(myPostedGigsProvider);
    final accepted = ref.watch(myAcceptedGigsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [_appBar(), _tabBar()],
          body: TabBarView(
            controller: _tabs,
            children: [
              // ── Tab 1: Gigs I Posted ─────────────
              posted.when(
                loading: () => _LoadingState(),
                error:   (e, _) => _ErrorState(message: e.toString()),
                data:    (gigs) => gigs.isEmpty
                  ? _EmptyState(
                      emoji: '📋',
                      title: 'No gigs posted yet',
                      sub: 'Post your first gig to get help from campus.',
                      actionLabel: 'Post a Gig',
                      onAction: () => Navigator.pushNamed(context, '/gigs/post'),
                    )
                  : _GigList(gigs: gigs, role: _GigRole.creator),
              ),

              // ── Tab 2: Gigs I'm Executing ────────
              accepted.when(
                loading: () => _LoadingState(),
                error:   (e, _) => _ErrorState(message: e.toString()),
                data:    (gigs) => gigs.isEmpty
                  ? _EmptyState(
                      emoji: '🔍',
                      title: 'No gigs accepted yet',
                      sub: 'Browse open gigs and start earning.',
                      actionLabel: 'Browse Gigs',
                      onAction: () => Navigator.pushNamed(context, '/gigs'),
                    )
                  : _GigList(gigs: gigs, role: _GigRole.executor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── app bar ───────────────────────────────────
  Widget _appBar() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My Gigs', style: AppText.display(size: 28)),
        const SizedBox(height: 4),
        Text('Track everything you\'ve posted or accepted.',
          style: AppText.body(size: 14, color: AppColors.textMuted)),
      ]),
    ),
  );

  // ── tab bar ───────────────────────────────────
  Widget _tabBar() => SliverPersistentHeader(
    pinned: true,
    delegate: _StickyTab(
      TabBar(
        controller: _tabs,
        indicatorColor: AppColors.violet,
        indicatorWeight: 2,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:          GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        tabs: [
          _tabItem('Posted', ref.watch(myPostedGigsProvider).valueOrNull?.length),
          _tabItem('Executing', ref.watch(myAcceptedGigsProvider).valueOrNull?.length),
        ],
      ),
    ),
  );

  Tab _tabItem(String label, int? count) => Tab(
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label),
      if (count != null && count > 0) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.violet.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
            style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.violet)),
        ),
      ],
    ]),
  );
}

// ─────────────────────────────────────────────
//  GIG LIST
// ─────────────────────────────────────────────
enum _GigRole { creator, executor }

class _GigList extends StatelessWidget {
  final List<GigModel> gigs;
  final _GigRole role;
  const _GigList({required this.gigs, required this.role});

  @override
  Widget build(BuildContext context) {
    // Group by active vs closed
    final active = gigs.where((g) =>
      g.status != GigStatus.closed &&
      g.status != GigStatus.cancelled).toList();
    final done = gigs.where((g) =>
      g.status == GigStatus.closed ||
      g.status == GigStatus.cancelled).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (active.isNotEmpty) ...[
          _sectionLabel('ACTIVE  (${active.length})'),
          const SizedBox(height: 10),
          ...active.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GigCard(gig: g, role: role),
          )),
          const SizedBox(height: 20),
        ],
        if (done.isNotEmpty) ...[
          _sectionLabel('HISTORY  (${done.length})'),
          const SizedBox(height: 10),
          ...done.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GigCard(gig: g, role: role),
          )),
        ],
      ],
    );
  }

  Widget _sectionLabel(String t) => Text(t, style: AppText.label());
}

// ─────────────────────────────────────────────
//  GIG CARD  — state-aware
// ─────────────────────────────────────────────
class _GigCard extends ConsumerWidget {
  final GigModel gig;
  final _GigRole role;
  const _GigCard({required this.gig, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = _catColor(gig.category);

    return SurfaceCard(
      borderColor: gig.isOverdue ? AppColors.coral.withOpacity(0.5) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── header ──────────────────────────────
        Row(children: [
          CategoryBadge(
            label: gig.category.label,
            color: cc,
            emoji: gig.category.emoji,
          ),
          const Spacer(),
          _StatusPill(status: gig.status),
        ]),
        const SizedBox(height: 10),

        // ── title ────────────────────────────────
        Text(gig.title, style: AppText.heading(size: 15)),
        const SizedBox(height: 4),

        // ── meta row ─────────────────────────────
        Row(children: [
          const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            gig.isOverdue ? 'OVERDUE' : 'Due ${gig.deadlineFormatted}',
            style: AppText.body(size: 12,
              color: gig.isOverdue ? AppColors.coral : AppColors.textMuted),
          ),
          const Spacer(),
          Text('₹${gig.price}', style: AppText.price(size: 16)),
        ]),

        // ── executor/creator info ─────────────────
        if (gig.acceptedById != null) ...[
          const SizedBox(height: 10),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.person_rounded, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              role == _GigRole.creator
                ? 'Executor: ${gig.acceptedByName}'
                : 'Posted by: ${gig.creatorName}',
              style: AppText.body(size: 12, color: AppColors.textMuted),
            ),
            const Spacer(),
            StarRating(rating: role == _GigRole.creator
              ? 0 : gig.creatorRating),
          ]),
        ],

        // ── action buttons ────────────────────────
        ..._buildActions(context, ref),
      ]),
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    final service = ref.read(gigServiceProvider);
    final userId  = ref.read(authStateProvider).valueOrNull?.uid ?? '';

    // Creator actions
    if (role == _GigRole.creator) {
      if (gig.isOpen) {
        return [
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Cancel Gig',
            color: AppColors.coral,
            icon: Icons.close_rounded,
            onTap: () => _confirm(context, 'Cancel this gig?', () async {
              await service.cancelGig(gig.gigId, userId);
            }),
          ),
        ];
      }
      if (gig.isPending) {
        return [
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Approve & Close Gig',
            color: AppColors.lime,
            icon: Icons.check_circle_rounded,
            onTap: () => _confirm(context, 'Mark this gig as complete?', () async {
              await service.closeGig(gig.gigId);
            }),
          ),
        ];
      }
    }

    // Executor actions
    if (role == _GigRole.executor) {
      if (gig.isAccepted) {
        return [
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Mark as Started',
            color: AppColors.cyan,
            icon: Icons.play_arrow_rounded,
            onTap: () async {
              await service.markStarted(gig.gigId);
              _snack(context, 'Gig started! ⚡', AppColors.cyan);
            },
          ),
        ];
      }
      if (gig.isInProgress) {
        return [
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Mark as Complete',
            color: AppColors.violet,
            icon: Icons.check_rounded,
            onTap: () => _confirm(context, 'Submit for creator review?', () async {
              await service.markComplete(gig.gigId);
            }),
          ),
        ];
      }
    }

    return [];
  }

  Color _catColor(GigCategory cat) {
    switch (cat) {
      case GigCategory.tutoring: return AppColors.violet;
      case GigCategory.delivery: return AppColors.cyan;
      case GigCategory.writing:  return AppColors.lime;
      case GigCategory.coding:   return AppColors.amber;
      case GigCategory.errands:  return AppColors.coral;
      case GigCategory.other:    return const Color(0xFF7777AA);
    }
  }

  Future<void> _confirm(BuildContext context, String message, Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(message: message),
    );
    if (ok == true && context.mounted) {
      await action();
      _snack(context, 'Done ✅', AppColors.violet);
    }
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ─────────────────────────────────────────────
//  SHARED SMALL WIDGETS
// ─────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final GigStatus status;
  const _StatusPill({required this.status});

  Color get _color {
    switch (status) {
      case GigStatus.open:                   return AppColors.cyan;
      case GigStatus.accepted:               return AppColors.amber;
      case GigStatus.inProgress:             return AppColors.violet;
      case GigStatus.completedPendingReview: return AppColors.lime;
      case GigStatus.closed:                 return AppColors.textMuted;
      case GigStatus.cancelled:              return AppColors.coral;
      case GigStatus.reported:               return AppColors.coral;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _color.withOpacity(0.35)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
        decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(status.label,
        style: AppText.label(size: 10, color: _color)),
    ]),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label,
          style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String message;
  const _ConfirmDialog({required this.message});

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text('Confirm', style: AppText.heading(size: 16)),
    content: Text(message, style: AppText.body(size: 14, color: AppColors.textMuted)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('Cancel', style: AppText.body(size: 14, color: AppColors.textMuted)),
      ),
      GestureDetector(
        onTap: () => Navigator.pop(context, true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.violet,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Confirm', style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    ],
  );
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.violet, strokeWidth: 2),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Text('Error: $message', style: AppText.body(color: AppColors.coral)),
  );
}

class _EmptyState extends StatelessWidget {
  final String emoji, title, sub, actionLabel;
  final VoidCallback onAction;
  const _EmptyState({required this.emoji, required this.title, required this.sub, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 52)),
      const SizedBox(height: 20),
      Text(title, style: AppText.heading(size: 18), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(sub, style: AppText.body(size: 14, color: AppColors.textMuted), textAlign: TextAlign.center),
      const SizedBox(height: 28),
      GradientButton(label: actionLabel, onTap: onAction, width: 220),
    ]),
  );
}

// ─────────────────────────────────────────────
//  STICKY TAB DELEGATE
// ─────────────────────────────────────────────
class _StickyTab extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTab(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height + 1;
  @override double get maxExtent => tabBar.preferredSize.height + 1;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
    Container(
      color: AppColors.bg,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        tabBar,
        Divider(height: 1, color: AppColors.border),
      ]),
    );
  @override
  bool shouldRebuild(_StickyTab old) => false;
}
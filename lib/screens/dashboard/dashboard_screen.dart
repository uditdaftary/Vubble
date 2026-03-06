import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  DASHBOARD SCREEN
// ─────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── mock data ────────────────────────────────
  static const _user = (
    name: 'Alex Kumar',
    dept: 'Computer Science',
    initial: 'A',
    notifCount: 3,
    balance: '₹2,450',
    activeGigs: '3',
    rating: '4.8',
  );

  final _activeGigs = const [
    _ActiveGigData(
      title: 'Calculus Tutoring',
      category: 'Tutoring',
      price: '₹300',
      deadline: 'Due tomorrow',
      status: 'IN PROGRESS',
    ),
    _ActiveGigData(
      title: 'Build Login UI',
      category: 'Coding',
      price: '₹500',
      deadline: 'Due in 3 days',
      status: 'OPEN',
    ),
    _ActiveGigData(
      title: 'Deliver Lab Notes',
      category: 'Delivery',
      price: '₹80',
      deadline: 'Today, 6 PM',
      status: 'ACCEPTED',
    ),
  ];

  final _feed = const [
    _FeedItem(
      emoji: '🏃',
      title: 'Errand accepted',
      sub: 'by Priya S.',
      time: '2m ago',
    ),
    _FeedItem(
      emoji: '📸',
      title: 'DSLR returned & confirmed',
      sub: 'Deposit refunded',
      time: '1h ago',
    ),
    _FeedItem(
      emoji: '⭐',
      title: 'You received a 5★ review!',
      sub: '"Super fast delivery"',
      time: '3h ago',
    ),
    _FeedItem(
      emoji: '✍️',
      title: 'New writing gig posted',
      sub: 'Writing · ₹200',
      time: '5h ago',
    ),
    _FeedItem(
      emoji: '📦',
      title: 'Rental request from Rahul',
      sub: 'Canon DSLR · 3 days',
      time: '6h ago',
    ),
  ];

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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _header(),
            _statsRow(),
            _quickActions(),
            _sectionTitle('Active Gigs'),
            _activeGigRow(),
            _sectionTitle('Recent Activity'),
            _activityFeed(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
          ],
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────
  Widget _header() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, ${_user.name.split(' ').first} 👋',
                  style: AppText.display(size: 26),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
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
                        style: AppText.label(size: 10, color: AppColors.violet),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _user.dept,
                      style: AppText.body(size: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _NotifButton(
            count: _user.notifCount,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(width: 10),
          _AvatarCircle(initial: _user.initial),
        ],
      ),
    ),
  );

  // ── stats row ─────────────────────────────────
  Widget _statsRow() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Balance',
              value: _user.balance,
              color: AppColors.lime,
              emoji: '💰',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Active Gigs',
              value: _user.activeGigs,
              color: AppColors.cyan,
              emoji: '⚡',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Rating',
              value: '${_user.rating}★',
              color: AppColors.amber,
              emoji: '🏆',
            ),
          ),
        ],
      ),
    ),
  );

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
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  emoji: '✏️',
                  label: 'Post\nGig',
                  grad: [const Color(0xFF0099BB), AppColors.cyan],
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  emoji: '📦',
                  label: 'Browse\nRentals',
                  grad: [const Color(0xFF885000), AppColors.amber],
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  emoji: '➕',
                  label: 'List\nItem',
                  grad: [const Color(0xFF4A6000), AppColors.lime],
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ── section title ─────────────────────────────
  Widget _sectionTitle(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.heading(size: 18)),
          Text(
            'See all →',
            style: AppText.body(size: 13, color: AppColors.violet),
          ),
        ],
      ),
    ),
  );

  // ── active gig horizontal scroll ──────────────
  Widget _activeGigRow() => SliverToBoxAdapter(
    child: SizedBox(
      height: 156,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _activeGigs.length,
        itemBuilder: (_, i) => _ActiveGigCard(data: _activeGigs[i]),
      ),
    ),
  );

  // ── activity feed ─────────────────────────────
  Widget _activityFeed() => SliverList(
    delegate: SliverChildBuilderDelegate(
      (_, i) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: _FeedTile(item: _feed[i]),
      ),
      childCount: _feed.length,
    ),
  );
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

// ── data classes ──────────────────────────────
class _ActiveGigData {
  final String title, category, price, deadline, status;
  const _ActiveGigData({
    required this.title,
    required this.category,
    required this.price,
    required this.deadline,
    required this.status,
  });
}

class _FeedItem {
  final String emoji, title, sub, time;
  const _FeedItem({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.time,
  });
}

// ── active gig card ───────────────────────────
class _ActiveGigCard extends StatelessWidget {
  final _ActiveGigData data;
  const _ActiveGigCard({required this.data});

  Color get _statusColor {
    switch (data.status) {
      case 'IN PROGRESS':
        return AppColors.lime;
      case 'ACCEPTED':
        return AppColors.cyan;
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = GigCategory.colorOf(data.category);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryBadge(
                  label: data.category,
                  color: catColor,
                  emoji: GigCategory.emojiOf(data.category),
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
              data.title,
              style: AppText.heading(size: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.price, style: AppText.price(size: 16)),
                Text(
                  data.deadline,
                  style: AppText.body(size: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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

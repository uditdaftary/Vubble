import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ── mock data ────────────────────────────────
  static const _profile = (
    name:        'Alex Kumar',
    dept:        'Computer Science · 3rd Year',
    email:       'alex.kumar@univ.edu',
    bio:         'Flutter dev | Calculus tutor | Always up for a good side gig 🚀',
    rating:      4.8,
    totalReviews: 47,
    gigsCompleted: 31,
    rentalsCompleted: 16,
    earnings:    '₹14,350',
    cancelRate:  '2%',
    initial:     'A',
    joinedYear:  '2023',
    skills:      ['Flutter', 'Python', 'Calculus', 'ML', 'Writing'],
  );

  final _reviews = const [
    _ReviewData(reviewer: 'Rahul K.', rating: 5, text: 'Super fast delivery — dropped it exactly on time. Highly recommend!', type: 'Gig', ago: '2 days ago'),
    _ReviewData(reviewer: 'Meena R.', rating: 5, text: 'Alex tutored me for my calc exam. Explained derivatives so clearly! Got an A.', type: 'Gig', ago: '1 week ago'),
    _ReviewData(reviewer: 'Siya T.',  rating: 4, text: 'Good experience renting the DSLR. Returned clean and on time.', type: 'Rental', ago: '2 weeks ago'),
    _ReviewData(reviewer: 'Dev P.',   rating: 5, text: 'Wrote the blog exactly as asked. APA citations were perfect too.', type: 'Gig', ago: '3 weeks ago'),
    _ReviewData(reviewer: 'Priya S.', rating: 4, text: 'Decent tutoring. Could have been more patient during explanations.', type: 'Gig', ago: '1 month ago'),
  ];

  final _activeListings = const [
    _ListingData(title: 'Canon EOS 1500D DSLR', type: 'Rental', status: 'AVAILABLE', badge: '📷', rate: '₹200/day'),
    _ListingData(title: 'Build Login UI in Flutter', type: 'Gig',    status: 'OPEN',      badge: '💻', rate: '₹500'),
    _ListingData(title: 'Calculus Exam Prep',         type: 'Gig',    status: 'IN PROGRESS', badge: '📚', rate: '₹300'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: NestedScrollView(
      headerSliverBuilder: (_, __) => [
        _profileHeader(),
        _statsRow(),
        _tabBar(),
      ],
      body: TabBarView(
        controller: _tabs,
        children: [
          _reviewsTab(),
          _listingsTab(),
          _activityTab(),
        ],
      ),
    ),
  );

  // ── profile header ────────────────────────────
  Widget _profileHeader() => SliverToBoxAdapter(
    child: Stack(children: [
      // gradient banner
      Container(
        height: 160,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF180840), Color(0xFF0A1840)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      ),
      // settings + menu
      Positioned(top: 52, right: 16, child: Row(children: [
        _IconBtn(icon: Icons.share_rounded, onTap: () {}),
        const SizedBox(width: 8),
        _IconBtn(icon: Icons.settings_rounded, onTap: () {}),
      ])),
      // avatar + info
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            // avatar
            Container(
              width: 76, height: 76,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.violet, AppColors.cyan],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(_profile.initial,
                  style: GoogleFonts.syne(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),
              Row(children: [
                Text(_profile.name, style: AppText.heading(size: 20)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('✓ Verified', style: AppText.label(size: 10, color: AppColors.violet)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(_profile.dept, style: AppText.body(size: 13, color: AppColors.textMuted)),
            ])),
          ]),
          const SizedBox(height: 14),
          // bio
          Text(_profile.bio, style: AppText.body(size: 14, color: AppColors.textMuted).copyWith(height: 1.4)),
          const SizedBox(height: 14),
          // skills
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _profile.skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(s, style: AppText.body(size: 12)),
            )).toList(),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    ]),
  );

  // ── stats row ─────────────────────────────────
  Widget _statsRow() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(children: [
        Expanded(child: _StatBlock(value: '${_profile.rating}★', label: 'Rating', color: AppColors.amber)),
        _vDivider(),
        Expanded(child: _StatBlock(value: '${_profile.totalReviews}', label: 'Reviews', color: AppColors.violet)),
        _vDivider(),
        Expanded(child: _StatBlock(value: '${_profile.gigsCompleted}', label: 'Gigs Done', color: AppColors.lime)),
        _vDivider(),
        Expanded(child: _StatBlock(value: '${_profile.rentalsCompleted}', label: 'Rentals', color: AppColors.cyan)),
      ]),
    ),
  );

  Widget _vDivider() => Container(width: 1, height: 36, color: AppColors.border);

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
  Widget _reviewsTab() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
    children: [
      _ratingBreakdown(),
      const SizedBox(height: 20),
      ..._reviews.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ReviewCard(data: r),
      )),
    ],
  );

  Widget _ratingBreakdown() => SurfaceCard(
    child: Column(children: [
      Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_profile.rating}', style: GoogleFonts.syne(
            fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.amber)),
          Text('out of 5.0', style: AppText.body(size: 13, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('Based on ${_profile.totalReviews} reviews',
            style: AppText.body(size: 12, color: AppColors.textMuted)),
        ]),
        const SizedBox(width: 20),
        Expanded(child: Column(children: [
          _RatingBar(stars: 5, count: 31, total: _profile.totalReviews),
          _RatingBar(stars: 4, count: 12, total: _profile.totalReviews),
          _RatingBar(stars: 3, count: 3,  total: _profile.totalReviews),
          _RatingBar(stars: 2, count: 1,  total: _profile.totalReviews),
          _RatingBar(stars: 1, count: 0,  total: _profile.totalReviews),
        ])),
      ]),
      const SizedBox(height: 16),
      Divider(color: AppColors.border),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _MiniStat(emoji: '💰', label: 'Total Earned', value: _profile.earnings)),
        Expanded(child: _MiniStat(emoji: '❌', label: 'Cancel Rate', value: _profile.cancelRate)),
        Expanded(child: _MiniStat(emoji: '📅', label: 'Member Since', value: _profile.joinedYear)),
      ]),
    ]),
  );

  // ── listings tab ──────────────────────────────
  Widget _listingsTab() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
    children: [
      Text('ACTIVE (${_activeListings.length})', style: AppText.label()),
      const SizedBox(height: 12),
      ..._activeListings.map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ListingTile(data: l),
      )),
      const SizedBox(height: 20),
      GradientButton(
        label: '+ Post New Gig',
        width: double.infinity,
        onTap: () {},
      ),
      const SizedBox(height: 10),
      GradientButton(
        label: '+ List New Item',
        width: double.infinity,
        colors: [const Color(0xFF0099BB), AppColors.cyan],
        onTap: () {},
      ),
    ],
  );

  // ── activity tab ──────────────────────────────
  Widget _activityTab() {
    final items = const [
      _ActivityItem(emoji: '✅', title: 'Gig completed', sub: 'Calculus Tutoring · ₹300', time: '2 days ago', color: AppColors.lime),
      _ActivityItem(emoji: '📦', title: 'Rental ended', sub: 'DSLR · 3 days · ₹600', time: '1 week ago', color: AppColors.cyan),
      _ActivityItem(emoji: '⭐', title: 'Review received', sub: '5★ from Meena R.', time: '1 week ago', color: AppColors.amber),
      _ActivityItem(emoji: '✏️', title: 'Gig posted', sub: 'Build Login UI · ₹500', time: '2 weeks ago', color: AppColors.violet),
      _ActivityItem(emoji: '📦', title: 'Item listed', sub: 'Canon DSLR · ₹200/day', time: '1 month ago', color: AppColors.cyan),
      _ActivityItem(emoji: '🎉', title: 'Joined campus platform', sub: 'Welcome to the ecosystem!', time: 'Aug 2023', color: AppColors.violet),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemCount: items.length,
      itemBuilder: (_, i) => _ActivityRow(data: items[i], isLast: i == items.length - 1),
    );
  }
}

// ─────────────────────────────────────────────
//  STICKY TAB BAR DELEGATE
// ─────────────────────────────────────────────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate({required this.tabBar});

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
  bool shouldRebuild(_StickyTabBarDelegate old) => false;
}

// ─────────────────────────────────────────────
//  DATA CLASSES
// ─────────────────────────────────────────────
class _ReviewData {
  final String reviewer, text, type, ago;
  final int rating;
  const _ReviewData({required this.reviewer, required this.rating, required this.text, required this.type, required this.ago});
}

class _ListingData {
  final String title, type, status, badge, rate;
  const _ListingData({required this.title, required this.type, required this.status, required this.badge, required this.rate});
}

class _ActivityItem {
  final String emoji, title, sub, time;
  final Color color;
  const _ActivityItem({required this.emoji, required this.title, required this.sub, required this.time, required this.color});
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
      width: 38, height: 38,
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
  const _StatBlock({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 3),
    Text(label, style: AppText.body(size: 11, color: AppColors.textMuted)),
  ]);
}

class _RatingBar extends StatelessWidget {
  final int stars, count, total;
  const _RatingBar({required this.stars, required this.count, required this.total});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text('$stars', style: AppText.body(size: 11, color: AppColors.textMuted)),
      const SizedBox(width: 4),
      const Icon(Icons.star_rounded, size: 10, color: AppColors.amber),
      const SizedBox(width: 6),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: total > 0 ? count / total : 0,
          backgroundColor: AppColors.surfaceHigh,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
          minHeight: 6,
        ),
      )),
      const SizedBox(width: 6),
      Text('$count', style: AppText.body(size: 11, color: AppColors.textMuted)),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  final String emoji, label, value;
  const _MiniStat({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(height: 4),
    Text(value, style: AppText.heading(size: 14)),
    Text(label, style: AppText.body(size: 11, color: AppColors.textMuted)),
  ]);
}

class _ReviewCard extends StatelessWidget {
  final _ReviewData data;
  const _ReviewCard({required this.data});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 14,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        // avatar
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.violet, AppColors.cyan]),
          ),
          child: Center(child: Text(data.reviewer[0],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.reviewer, style: AppText.body(size: 13).copyWith(fontWeight: FontWeight.w600)),
          Text(data.ago, style: AppText.body(size: 11, color: AppColors.textMuted)),
        ])),
        // stars
        Row(children: List.generate(data.rating, (_) =>
          const Icon(Icons.star_rounded, size: 14, color: AppColors.amber))),
        const SizedBox(width: 8),
        // type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: (data.type == 'Gig' ? AppColors.violet : AppColors.cyan).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(data.type,
            style: AppText.label(size: 10, color: data.type == 'Gig' ? AppColors.violet : AppColors.cyan)),
        ),
      ]),
      const SizedBox(height: 10),
      Text('"${data.text}"',
        style: AppText.body(size: 13, color: AppColors.textMuted).copyWith(
          fontStyle: FontStyle.italic, height: 1.45)),
    ]),
  );
}

class _ListingTile extends StatelessWidget {
  final _ListingData data;
  const _ListingTile({required this.data});

  Color get _statusColor {
    switch (data.status) {
      case 'AVAILABLE':   return AppColors.lime;
      case 'OPEN':        return AppColors.cyan;
      case 'IN PROGRESS': return AppColors.amber;
      default:            return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 12,
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(data.badge, style: const TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data.title, style: AppText.body(size: 13).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Row(children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(data.status, style: AppText.label(size: 10, color: _statusColor)),
          const SizedBox(width: 8),
          Text('· ${data.type}', style: AppText.body(size: 12, color: AppColors.textMuted)),
        ]),
      ])),
      Text(data.rate, style: AppText.price(size: 14)),
      const SizedBox(width: 8),
      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
    ]),
  );
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem data;
  final bool isLast;
  const _ActivityRow({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // timeline
      Column(mainAxisSize: MainAxisSize.max, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: data.color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: data.color.withOpacity(0.3)),
          ),
          child: Center(child: Text(data.emoji, style: const TextStyle(fontSize: 16))),
        ),
        if (!isLast) Expanded(
          child: Container(width: 1.5, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 4)),
        ),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.title, style: AppText.body(size: 13).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(data.sub, style: AppText.body(size: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(data.time, style: AppText.body(size: 11, color: AppColors.textMuted.withOpacity(0.7))),
        ]),
      )),
    ]),
  );
}

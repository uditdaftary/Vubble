import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'post_gig_screen.dart';        // same folder, no change

// ─────────────────────────────────────────────
//  GIG BROWSE SCREEN
// ─────────────────────────────────────────────
class GigBrowseScreen extends StatefulWidget {
  const GigBrowseScreen({super.key});
  @override
  State<GigBrowseScreen> createState() => _GigBrowseScreenState();
}

class _GigBrowseScreenState extends State<GigBrowseScreen> {
  String _selectedCat = 'All';
  String _sortBy = 'Newest';
  final _search = TextEditingController();

  static const _cats = ['All', 'Tutoring', 'Delivery', 'Writing', 'Coding', 'Errands', 'Other'];

  final _gigs = <_GigData>[
    _GigData(id: '1', title: 'Calculus Exam Prep — 2 hr Session',
      desc: 'Need help with derivatives and integrals before Friday exam. Must know Spivak level.',
      category: 'Tutoring', price: 300, deadline: 'Thu, 5 Dec',
      posterName: 'Rohan M.', posterRating: 4.7, postedAgo: '5 min ago'),
    _GigData(id: '2', title: 'Build Login + Auth UI in Flutter',
      desc: 'Firebase auth flow with Google sign-in for a side project. Clean material 3 look.',
      category: 'Coding', price: 500, deadline: 'Sat, 7 Dec',
      posterName: 'Aisha K.', posterRating: 4.9, postedAgo: '12 min ago'),
    _GigData(id: '3', title: 'Deliver Notes from Library to Hostel A',
      desc: 'Printed notes at circulation desk. Need by 6 PM today. Room 214.',
      category: 'Delivery', price: 80, deadline: 'Today, 6 PM',
      posterName: 'Siya R.', posterRating: 4.5, postedAgo: '25 min ago'),
    _GigData(id: '4', title: 'Write 500-word Blog on AI Ethics',
      desc: 'For my personal website. Needs citations. APA format. SEO-friendly title.',
      category: 'Writing', price: 200, deadline: 'Fri, 6 Dec',
      posterName: 'Dev P.', posterRating: 4.2, postedAgo: '1h ago'),
    _GigData(id: '5', title: 'Collect ID Card from Admin Office',
      desc: 'Pick up new ID card and drop to Room 214, Block B. Ask for Neel.',
      category: 'Errands', price: 60, deadline: 'Tomorrow',
      posterName: 'Neel S.', posterRating: 4.8, postedAgo: '2h ago'),
    _GigData(id: '6', title: 'Proofread 3000-word Research Paper',
      desc: 'Economics paper on micro-lending. Grammar + flow corrections only.',
      category: 'Writing', price: 350, deadline: 'Mon, 9 Dec',
      posterName: 'Priya T.', posterRating: 4.6, postedAgo: '3h ago'),
    _GigData(id: '7', title: 'Python Script for Data Scraping',
      desc: 'Scrape a public university notice board and email results daily.',
      category: 'Coding', price: 700, deadline: 'Wed, 11 Dec',
      posterName: 'Arjun L.', posterRating: 4.3, postedAgo: '4h ago'),
  ];

  List<_GigData> get _filtered {
    return _gigs.where((g) {
      final catOk  = _selectedCat == 'All' || g.category == _selectedCat;
      final q      = _search.text.toLowerCase();
      final textOk = q.isEmpty || g.title.toLowerCase().contains(q) || g.desc.toLowerCase().contains(q);
      return catOk && textOk;
    }).toList();
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: CustomScrollView(slivers: [
      _appBar(),
      _searchBar(),
      _categoryChips(),
      _countRow(),
      _gigList(),
      const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
    ]),
    floatingActionButton: _fab(),
  );

  // ── app bar ───────────────────────────────────
  Widget _appBar() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Row(children: [
        Expanded(child: Text('Browse Gigs', style: AppText.display(size: 26))),
        GestureDetector(
          onTap: _showSortSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.tune_rounded, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(_sortBy, style: AppText.body(size: 13, color: AppColors.textMuted)),
            ]),
          ),
        ),
      ]),
    ),
  );

  // ── search ────────────────────────────────────
  Widget _searchBar() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        style: AppText.body(),
        decoration: InputDecoration(
          hintText: 'Search gigs…',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          suffixIcon: _search.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                onPressed: () { _search.clear(); setState(() {}); })
            : null,
        ),
      ),
    ),
  );

  // ── category chips ────────────────────────────
  Widget _categoryChips() => SliverToBoxAdapter(
    child: SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _cats.length,
        itemBuilder: (_, i) {
          final cat = _cats[i];
          final sel = cat == _selectedCat;
          final color = cat == 'All' ? AppColors.violet : GigCategory.colorOf(cat);
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? color : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? color : AppColors.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (cat != 'All') ...[
                  Text(GigCategory.emojiOf(cat), style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                ],
                Text(cat,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppColors.textMuted,
                  )),
              ]),
            ),
          );
        },
      ),
    ),
  );

  // ── count row ─────────────────────────────────
  Widget _countRow() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Text(
        '${_filtered.length} gig${_filtered.length == 1 ? '' : 's'} available',
        style: AppText.body(size: 13, color: AppColors.textMuted),
      ),
    ),
  );

  // ── gig list ──────────────────────────────────
  Widget _gigList() {
    final list = _filtered;
    if (list.isEmpty) return SliverToBoxAdapter(child: _EmptyState(label: 'No gigs found', sub: 'Try a different filter'));
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _GigCard(data: list[i]),
        ),
        childCount: list.length,
      ),
    );
  }

  // ── FAB ───────────────────────────────────────
  Widget _fab() => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostGigScreen())),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.violet, Color(0xFF5000EE)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text('Post Gig', style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    ),
  );

  // ── sort sheet ────────────────────────────────
  void _showSortSheet() => showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('Sort By', style: AppText.heading(size: 18)),
        const SizedBox(height: 16),
        ...['Newest', 'Price: Low → High', 'Price: High → Low', 'Deadline Soon'].map((s) => ListTile(
          title: Text(s, style: AppText.body()),
          trailing: _sortBy == s ? const Icon(Icons.check_rounded, color: AppColors.violet) : null,
          onTap: () { setState(() => _sortBy = s); Navigator.pop(context); },
        )),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────
//  GIG DATA MODEL
// ─────────────────────────────────────────────
class _GigData {
  final String id, title, desc, category, posterName, postedAgo, deadline;
  final int price;
  final double posterRating;

  const _GigData({
    required this.id,
    required this.title,
    required this.desc,
    required this.category,
    required this.price,
    required this.posterName,
    required this.posterRating,
    required this.postedAgo,
    required this.deadline,
  });
}

// ─────────────────────────────────────────────
//  GIG CARD
// ─────────────────────────────────────────────
class _GigCard extends StatelessWidget {
  final _GigData data;
  const _GigCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cc = GigCategory.colorOf(data.category);
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: SurfaceCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // top row
          Row(children: [
            CategoryBadge(label: data.category, color: cc, emoji: GigCategory.emojiOf(data.category)),
            const Spacer(),
            Text(data.postedAgo, style: AppText.body(size: 11, color: AppColors.textMuted)),
          ]),
          const SizedBox(height: 10),
          // title
          Text(data.title, style: AppText.heading(size: 15)),
          const SizedBox(height: 6),
          // description
          Text(data.desc,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: AppText.body(size: 13, color: AppColors.textMuted).copyWith(height: 1.45)),
          const SizedBox(height: 14),
          // bottom row
          Row(children: [
            _MiniAvatar(name: data.posterName, color: cc),
            const SizedBox(width: 8),
            Text(data.posterName, style: AppText.body(size: 12, color: AppColors.textMuted)),
            const SizedBox(width: 4),
            StarRating(rating: data.posterRating),
            const Spacer(),
            const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(data.deadline, style: AppText.body(size: 12, color: AppColors.textMuted)),
            const SizedBox(width: 12),
            Text('₹${data.price}', style: AppText.price(size: 18)),
          ]),
        ]),
      ),
    );
  }

  void _openDetail(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.72, maxChildSize: 0.95, minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => _GigDetailSheet(data: data, sc: sc),
    ),
  );
}

// ─────────────────────────────────────────────
//  GIG DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────
class _GigDetailSheet extends StatelessWidget {
  final _GigData data;
  final ScrollController sc;
  const _GigDetailSheet({required this.data, required this.sc});

  @override
  Widget build(BuildContext context) {
    final cc = GigCategory.colorOf(data.category);
    return SingleChildScrollView(
      controller: sc,
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // handle
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 22),
        // category + price
        Row(children: [
          CategoryBadge(label: data.category, color: cc, emoji: GigCategory.emojiOf(data.category)),
          const Spacer(),
          Text('₹${data.price}', style: AppText.price(size: 26)),
        ]),
        const SizedBox(height: 14),
        // title
        Text(data.title, style: AppText.heading(size: 20)),
        const SizedBox(height: 10),
        // description
        Text(data.desc, style: AppText.body(size: 14, color: AppColors.textMuted).copyWith(height: 1.6)),
        const SizedBox(height: 20),
        // details
        _InfoRow(icon: Icons.schedule_rounded, label: 'Deadline', value: data.deadline),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.person_rounded, label: 'Posted by', value: '${data.posterName}  ★ ${data.posterRating}'),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.access_time_rounded, label: 'Posted', value: data.postedAgo),
        const SizedBox(height: 28),
        // divider
        Divider(color: AppColors.border),
        const SizedBox(height: 20),
        // poster card
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            _MiniAvatar(name: data.posterName, color: cc, size: 44),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.posterName, style: AppText.heading(size: 14)),
              StarRating(rating: data.posterRating, count: 12),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('View Profile', style: AppText.label(size: 11, color: AppColors.textPrimary)),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        // CTA
        GradientButton(
          label: 'Accept This Gig  →',
          width: double.infinity,
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gig accepted! 🎉', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
              backgroundColor: AppColors.violet,
            ));
          },
        ),
        const SizedBox(height: 12),
        // Report
        Center(
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.flag_rounded, size: 14, color: AppColors.textMuted),
            label: Text('Report this gig', style: AppText.body(size: 13, color: AppColors.textMuted)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────
class _MiniAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const _MiniAvatar({required this.name, required this.color, this.size = 28});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(name[0],
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w800, color: Colors.white)),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: AppColors.textMuted),
    const SizedBox(width: 8),
    Text('$label: ', style: AppText.body(size: 13, color: AppColors.textMuted)),
    Flexible(child: Text(value, style: AppText.body(size: 13).copyWith(fontWeight: FontWeight.w600))),
  ]);
}

class _EmptyState extends StatelessWidget {
  final String label, sub;
  const _EmptyState({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 80),
    child: Column(children: [
      const Text('🔍', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text(label, style: AppText.heading(size: 18)),
      const SizedBox(height: 6),
      Text(sub, style: AppText.body(size: 14, color: AppColors.textMuted)),
    ]),
  );
}

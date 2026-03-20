import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/gig_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_rental_providers.dart';
import '../../theme/app_theme.dart' hide GigCategory;

// ─────────────────────────────────────────────
//  GIG BROWSE SCREEN
// ─────────────────────────────────────────────
class GigBrowseScreen extends ConsumerStatefulWidget {
  const GigBrowseScreen({super.key});
  @override
  ConsumerState<GigBrowseScreen> createState() => _GigBrowseScreenState();
}

class _GigBrowseScreenState extends ConsumerState<GigBrowseScreen> {
  String _selectedCat = 'All';
  String _sortBy = 'Newest';
  final _search = TextEditingController();

  static const _cats = [
    'All',
    'Tutoring',
    'Delivery',
    'Writing',
    'Coding',
    'Errands',
    'Other',
  ];

  /// Map UI string to model enum (null = all)
  GigCategory? get _categoryEnum {
    if (_selectedCat == 'All') return null;
    return GigCategory.values.firstWhere(
      (c) => c.label == _selectedCat,
      orElse: () => GigCategory.other,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: CustomScrollView(
      slivers: [
        _appBar(),
        _searchBar(),
        _categoryChips(),
        _gigContent(),
        const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
      ],
    ),
    floatingActionButton: _fab(),
  );

  // ── app bar ───────────────────────────────────
  Widget _appBar() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text('Browse Gigs', style: AppText.display(size: 26)),
          ),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _sortBy,
                    style: AppText.body(size: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: _search.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                )
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: _cats.length,
        itemBuilder: (_, i) {
          final cat = _cats[i];
          final sel = cat == _selectedCat;
          final color = cat == 'All' ? AppColors.violet : _themeGigColor(cat);
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat != 'All') ...[
                    Text(
                      _themeGigEmoji(cat),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    cat,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  // ── gig content (AsyncValue) ──────────────────
  Widget _gigContent() {
    final gigsAsync = ref.watch(gigsByCategoryProvider(_categoryEnum));
    final userAsync = ref.watch(currentUserProfileProvider);
    final currentUserId = userAsync.valueOrNull?.userId;

    return gigsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.violet,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Text(
              'Error: $e',
              style: AppText.body(color: AppColors.coral),
            ),
          ),
        ),
      ),
      data: (gigs) {
        // Filter out own gigs and already-accepted gigs
        var filtered = gigs.where((g) {
          if (currentUserId != null && g.creatorId == currentUserId) {
            return false;
          }
          if (currentUserId != null && g.acceptedById == currentUserId) {
            return false;
          }
          return true;
        }).toList();

        // Apply search filter
        final q = _search.text.toLowerCase();
        if (q.isNotEmpty) {
          filtered = filtered
              .where(
                (g) =>
                    g.title.toLowerCase().contains(q) ||
                    g.description.toLowerCase().contains(q),
              )
              .toList();
        }

        // Apply sort
        switch (_sortBy) {
          case 'Price: Low → High':
            filtered.sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'Price: High → Low':
            filtered.sort((a, b) => b.price.compareTo(a.price));
            break;
          case 'Deadline Soon':
            filtered.sort((a, b) => a.deadline.compareTo(b.deadline));
            break;
          default: // Newest
            filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        // Count row + list
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  '${filtered.length} gig${filtered.length == 1 ? '' : 's'} available',
                  style: AppText.body(size: 13, color: AppColors.textMuted),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(
                  label: 'No gigs found',
                  sub: 'Try a different filter',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _GigCard(gig: filtered[i]),
                  ),
                  childCount: filtered.length,
                ),
              ),
          ],
        );
      },
    );
  }

  // ── FAB ───────────────────────────────────────
  Widget _fab() => GestureDetector(
    onTap: () => context.push('/gigs/post'),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.violet, Color(0xFF5000EE)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'Post Gig',
            style: GoogleFonts.syne(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  // ── sort sheet ────────────────────────────────
  void _showSortSheet() => showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),
          Text('Sort By', style: AppText.heading(size: 18)),
          const SizedBox(height: 16),
          ...[
            'Newest',
            'Price: Low → High',
            'Price: High → Low',
            'Deadline Soon',
          ].map(
            (s) => ListTile(
              title: Text(s, style: AppText.body()),
              trailing: _sortBy == s
                  ? const Icon(Icons.check_rounded, color: AppColors.violet)
                  : null,
              onTap: () {
                setState(() => _sortBy = s);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    ),
  );

  // ── theme helpers ────────────────────────────
  Color _themeGigColor(String cat) {
    const m = {
      'Tutoring': AppColors.violet,
      'Delivery': AppColors.cyan,
      'Writing': AppColors.lime,
      'Coding': AppColors.amber,
      'Errands': AppColors.coral,
    };
    return m[cat] ?? const Color(0xFF7777AA);
  }

  String _themeGigEmoji(String cat) {
    const m = {
      'Tutoring': '📚',
      'Delivery': '🚚',
      'Writing': '✍️',
      'Coding': '💻',
      'Errands': '🏃',
      'Other': '⚡',
    };
    return m[cat] ?? '⚡';
  }
}

// ─────────────────────────────────────────────
//  GIG CARD
// ─────────────────────────────────────────────
class _GigCard extends StatelessWidget {
  final GigModel gig;
  const _GigCard({required this.gig});

  @override
  Widget build(BuildContext context) {
    final cc = _catColor(gig.category);
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row
            Row(
              children: [
                CategoryBadge(
                  label: gig.category.label,
                  color: cc,
                  emoji: gig.category.emoji,
                ),
                const Spacer(),
                Text(
                  gig.timeAgo,
                  style: AppText.body(size: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // title
            Text(gig.title, style: AppText.heading(size: 15)),
            const SizedBox(height: 6),
            // description
            Text(
              gig.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                size: 13,
                color: AppColors.textMuted,
              ).copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            // bottom row
            Row(
              children: [
                _MiniAvatar(name: gig.creatorName, color: cc),
                const SizedBox(width: 8),
                Text(
                  gig.creatorName,
                  style: AppText.body(size: 12, color: AppColors.textMuted),
                ),
                const SizedBox(width: 4),
                StarRating(rating: gig.creatorRating),
                const Spacer(),
                const Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 3),
                Text(
                  gig.deadlineFormatted,
                  style: AppText.body(size: 12, color: AppColors.textMuted),
                ),
                const SizedBox(width: 12),
                Text('₹${gig.price}', style: AppText.price(size: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => _GigDetailSheet(gig: gig, sc: sc),
    ),
  );

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
}

// ─────────────────────────────────────────────
//  GIG DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────
class _GigDetailSheet extends ConsumerStatefulWidget {
  final GigModel gig;
  final ScrollController sc;
  const _GigDetailSheet({required this.gig, required this.sc});
  @override
  ConsumerState<_GigDetailSheet> createState() => _GigDetailSheetState();
}

class _GigDetailSheetState extends ConsumerState<_GigDetailSheet> {
  bool _isApplying = false;
  bool _hasApplied = false;
  final _messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfApplied();
  }

  Future<void> _checkIfApplied() async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return;
    final applied = await ref
        .read(gigServiceProvider)
        .hasUserApplied(widget.gig.gigId, user.userId);
    if (mounted) setState(() => _hasApplied = applied);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gig = widget.gig;
    final cc = _catColor(gig.category);
    return SingleChildScrollView(
      controller: widget.sc,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // handle
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
          // category + price
          Row(
            children: [
              CategoryBadge(
                label: gig.category.label,
                color: cc,
                emoji: gig.category.emoji,
              ),
              const Spacer(),
              Text('₹${gig.price}', style: AppText.price(size: 26)),
            ],
          ),
          const SizedBox(height: 14),
          // title
          Text(gig.title, style: AppText.heading(size: 20)),
          const SizedBox(height: 10),
          // description
          Text(
            gig.description,
            style: AppText.body(
              size: 14,
              color: AppColors.textMuted,
            ).copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          // details
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Deadline',
            value: gig.deadlineFormatted,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_rounded,
            label: 'Posted by',
            value: '${gig.creatorName}  ★ ${gig.creatorRating}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Posted',
            value: gig.timeAgo,
          ),
          const SizedBox(height: 28),
          // divider
          Divider(color: AppColors.border),
          const SizedBox(height: 20),
          // poster card
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _MiniAvatar(name: gig.creatorName, color: cc, size: 44),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gig.creatorName, style: AppText.heading(size: 14)),
                    StarRating(rating: gig.creatorRating),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'View Profile',
                    style: AppText.label(
                      size: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── Application message field ──
          if (!_hasApplied) ...[
            Text('Your Application', style: AppText.heading(size: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              style: AppText.input(),
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Why are you the best fit? (10-300 chars)',
              ),
            ),
            const SizedBox(height: 16),
          ],
          // CTA
          if (_hasApplied)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  '✅ Already Applied',
                  style: AppText.label(size: 14, color: AppColors.textMuted),
                ),
              ),
            )
          else
            GradientButton(
              label: 'Apply to This Gig  →',
              width: double.infinity,
              isLoading: _isApplying,
              onTap: _applyToGig,
            ),
          const SizedBox(height: 12),
          // Report
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.flag_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              label: Text(
                'Report this gig',
                style: AppText.body(size: 13, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyToGig() async {
    final msg = _messageCtrl.text.trim();
    if (msg.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message must be at least 10 characters',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isApplying = true);
    try {
      await ref
          .read(gigServiceProvider)
          .applyToGig(
            gigId: widget.gig.gigId,
            userId: user.userId,
            userName: user.name,
            userRating: user.rating,
            message: msg,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Application sent! 🎉',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppColors.violet,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to apply: $e',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppColors.coral,
        ),
      );
    }
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
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({
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

class _EmptyState extends StatelessWidget {
  final String label, sub;
  const _EmptyState({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 80),
    child: Column(
      children: [
        const Text('🔍', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(label, style: AppText.heading(size: 18)),
        const SizedBox(height: 6),
        Text(sub, style: AppText.body(size: 14, color: AppColors.textMuted)),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/rental_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_rental_providers.dart';
import '../../theme/app_theme.dart' hide RentalCategory;

// ─────────────────────────────────────────────
//  RENTAL BROWSE SCREEN
// ─────────────────────────────────────────────
class RentalBrowseScreen extends ConsumerStatefulWidget {
  const RentalBrowseScreen({super.key});
  @override
  ConsumerState<RentalBrowseScreen> createState() => _RentalBrowseScreenState();
}

class _RentalBrowseScreenState extends ConsumerState<RentalBrowseScreen> {
  String _selectedCat = 'All';
  final _search = TextEditingController();

  static const _cats = [
    'All',
    'Electronics',
    'Lab Gear',
    'Books',
    'Sports',
    'Clothing',
    'Other',
  ];

  /// Map UI string → model enum (null = all)
  RentalCategory? get _categoryEnum {
    if (_selectedCat == 'All') return null;
    return RentalCategory.values.firstWhere(
      (c) => c.label == _selectedCat,
      orElse: () => RentalCategory.other,
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
        _heroBanner(),
        _searchBar(),
        _categoryChips(),
        _rentalContent(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rentals', style: AppText.display(size: 26)),
                Text(
                  'Borrow anything on campus',
                  style: AppText.body(size: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );

  // ── hero banner ───────────────────────────────
  Widget _heroBanner() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A3D), Color(0xFF0A1A3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.violet.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'List your idle items',
                    style: AppText.heading(size: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Earn ₹ while stuff sits in your room.',
                    style: AppText.body(size: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => context.push('/rentals/list'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.violet,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Start Listing →',
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Text('📦', style: TextStyle(fontSize: 52)),
          ],
        ),
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
          hintText: 'Search items…',
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
          final color = cat == 'All' ? AppColors.cyan : _themeRentalColor(cat);
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
                      _themeRentalEmoji(cat),
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

  // ── rental content (AsyncValue) ───────────────
  Widget _rentalContent() {
    final rentalsAsync = ref.watch(rentalsByCategoryProvider(_categoryEnum));
    final currentUserId = ref
        .watch(currentUserProfileProvider)
        .valueOrNull
        ?.userId;

    return rentalsAsync.when(
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
      data: (rentals) {
        // Filter out own listings
        var filtered = rentals.where((r) {
          if (currentUserId != null && r.ownerId == currentUserId) return false;
          return true;
        }).toList();

        // Apply search
        final q = _search.text.toLowerCase();
        if (q.isNotEmpty) {
          filtered = filtered
              .where(
                (r) =>
                    r.itemName.toLowerCase().contains(q) ||
                    r.description.toLowerCase().contains(q),
              )
              .toList();
        }

        return SliverMainAxisGroup(
          slivers: [
            // count row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  '${filtered.length} item${filtered.length == 1 ? '' : 's'} available',
                  style: AppText.body(size: 13, color: AppColors.textMuted),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    children: [
                      const Text('📦', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text('No items found', style: AppText.heading(size: 18)),
                      const SizedBox(height: 6),
                      Text(
                        'Try a different filter',
                        style: AppText.body(
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RentalCard(rental: filtered[i]),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── FAB ───────────────────────────────────────
  Widget _fab() => GestureDetector(
    onTap: () => context.push('/rentals/list'),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0099BB), AppColors.cyan],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.35),
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
            'List Item',
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

  Color _themeRentalColor(String cat) {
    const m = {
      'Electronics': AppColors.cyan,
      'Lab Gear': AppColors.violet,
      'Books': AppColors.lime,
      'Sports': AppColors.coral,
      'Clothing': AppColors.amber,
    };
    return m[cat] ?? const Color(0xFF7777AA);
  }

  String _themeRentalEmoji(String cat) {
    const m = {
      'Electronics': '📷',
      'Lab Gear': '🔬',
      'Books': '📖',
      'Sports': '⚽',
      'Clothing': '🥼',
      'Other': '📦',
    };
    return m[cat] ?? '📦';
  }
}

// ─────────────────────────────────────────────
//  RENTAL CARD (grid tile)
// ─────────────────────────────────────────────
class _RentalCard extends StatelessWidget {
  final RentalModel rental;
  const _RentalCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final cc = _catColor(rental.category);
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // emoji icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cc.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cc.withOpacity(0.25)),
              ),
              child: Center(
                child: Text(
                  rental.category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // title
            Text(
              rental.itemName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.heading(size: 13),
            ),
            const SizedBox(height: 4),
            // owner
            Text(
              rental.ownerName,
              style: AppText.body(size: 11, color: AppColors.textMuted),
            ),
            const Spacer(),
            // availability badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.lime.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Available',
                style: AppText.label(size: 10, color: AppColors.lime),
              ),
            ),
            const SizedBox(height: 8),
            // daily rate
            Row(
              children: [
                Text('₹${rental.dailyRate}', style: AppText.price(size: 16)),
                Text(
                  '/day',
                  style: AppText.body(size: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            if (rental.deposit > 0) ...[
              const SizedBox(height: 2),
              Text(
                '+ ₹${rental.deposit} deposit',
                style: AppText.body(size: 11, color: AppColors.textMuted),
              ),
            ],
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
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => _RentalDetailSheet(rental: rental, sc: sc),
    ),
  );

  Color _catColor(RentalCategory cat) {
    switch (cat) {
      case RentalCategory.electronics:
        return AppColors.cyan;
      case RentalCategory.labGear:
        return AppColors.violet;
      case RentalCategory.books:
        return AppColors.lime;
      case RentalCategory.sports:
        return AppColors.coral;
      case RentalCategory.clothing:
        return AppColors.amber;
      case RentalCategory.other:
        return const Color(0xFF7777AA);
    }
  }
}

// ─────────────────────────────────────────────
//  RENTAL DETAIL SHEET
// ─────────────────────────────────────────────
class _RentalDetailSheet extends ConsumerStatefulWidget {
  final RentalModel rental;
  final ScrollController sc;
  const _RentalDetailSheet({required this.rental, required this.sc});
  @override
  ConsumerState<_RentalDetailSheet> createState() => _RentalDetailSheetState();
}

class _RentalDetailSheetState extends ConsumerState<_RentalDetailSheet> {
  DateTime? _start;
  DateTime? _end;
  bool _isApplying = false;
  bool _hasApplied = false;
  final _messageCtrl = TextEditingController();

  int get _days => (_start != null && _end != null && !_end!.isBefore(_start!))
      ? _end!.difference(_start!).inDays + 1
      : 0;

  int get _totalCost => _days * widget.rental.dailyRate + widget.rental.deposit;

  @override
  void initState() {
    super.initState();
    _checkIfApplied();
  }

  Future<void> _checkIfApplied() async {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) return;
    final applied = await ref
        .read(rentalServiceProvider)
        .hasUserAppliedToRental(widget.rental.rentalId, user.userId);
    if (mounted) setState(() => _hasApplied = applied);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cc = _catColor(widget.rental.category);
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
          const SizedBox(height: 20),
          // header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cc.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    widget.rental.category.emoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryBadge(
                      label: widget.rental.category.label,
                      color: cc,
                      emoji: widget.rental.category.emoji,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.rental.itemName,
                      style: AppText.heading(size: 17),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.rental.description,
            style: AppText.body(
              size: 14,
              color: AppColors.textMuted,
            ).copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.border),
          const SizedBox(height: 16),
          // pricing info
          Row(
            children: [
              Expanded(
                child: _PriceChip(
                  label: 'Daily Rate',
                  value: '₹${widget.rental.dailyRate}',
                  color: AppColors.lime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PriceChip(
                  label: 'Deposit',
                  value: widget.rental.deposit > 0
                      ? '₹${widget.rental.deposit}'
                      : 'None',
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PriceChip(
                  label: 'Rented',
                  value: '${widget.rental.totalRentals}x',
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // availability
          _InfoRow2(
            icon: Icons.event_available_rounded,
            label: 'Available',
            value: widget.rental.availabilityFormatted,
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.border),
          const SizedBox(height: 16),
          // date selector
          Text('SELECT RENTAL DATES', style: AppText.label()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Start Date',
                  date: _start,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('→', style: AppText.heading(size: 18)),
              ),
              Expanded(
                child: _DateButton(
                  label: 'End Date',
                  date: _end,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          if (_days > 0) ...[
            const SizedBox(height: 16),
            SurfaceCard(
              padding: const EdgeInsets.all(14),
              borderColor: AppColors.violet.withOpacity(0.3),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_days day${_days > 1 ? 's' : ''} rental',
                        style: AppText.body(
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Total Payable', style: AppText.label()),
                    ],
                  ),
                  const Spacer(),
                  Text('₹$_totalCost', style: AppText.price(size: 22)),
                ],
              ),
            ),
          ],
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
                hintText: 'Why do you need this item? (10-300 chars)',
              ),
            ),
            const SizedBox(height: 16),
          ],
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
              label: _days > 0 ? 'Apply for Rental  →' : 'Pick Dates First',
              width: double.infinity,
              isLoading: _isApplying,
              colors: _days > 0
                  ? [const Color(0xFF0099BB), AppColors.cyan]
                  : [AppColors.border, AppColors.border],
              onTap: _days > 0 ? _applyToRental : null,
            ),
        ],
      ),
    );
  }

  Future<void> _applyToRental() async {
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
    if (user == null || _start == null || _end == null) return;

    setState(() => _isApplying = true);
    try {
      await ref
          .read(rentalServiceProvider)
          .applyToRental(
            rentalId: widget.rental.rentalId,
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
            'Application sent! 📦',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppColors.cyan,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed: $e',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? DateTime.now() : (_start ?? DateTime.now()),
      firstDate: isStart ? DateTime.now() : (_start ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.cyan,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Color _catColor(RentalCategory cat) {
    switch (cat) {
      case RentalCategory.electronics:
        return AppColors.cyan;
      case RentalCategory.labGear:
        return AppColors.violet;
      case RentalCategory.books:
        return AppColors.lime;
      case RentalCategory.sports:
        return AppColors.coral;
      case RentalCategory.clothing:
        return AppColors.amber;
      case RentalCategory.other:
        return const Color(0xFF7777AA);
    }
  }
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────
class _PriceChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _PriceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.syne(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppText.label(size: 10)),
      ],
    ),
  );
}

class _InfoRow2 extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow2({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 8),
      Text(
        '$label: ',
        style: AppText.body(size: 13, color: AppColors.textMuted),
      ),
      Text(
        value,
        style: AppText.body(size: 13).copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  String get _formatted => date != null ? '${date!.day}/${date!.month}' : label;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: date != null ? AppColors.cyan : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            _formatted,
            style: AppText.body(
              size: 13,
              color: date != null ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'list_rental_screen.dart';        // same folder, no change

// ─────────────────────────────────────────────
//  RENTAL BROWSE SCREEN
// ─────────────────────────────────────────────
class RentalBrowseScreen extends StatefulWidget {
  const RentalBrowseScreen({super.key});
  @override
  State<RentalBrowseScreen> createState() => _RentalBrowseScreenState();
}

class _RentalBrowseScreenState extends State<RentalBrowseScreen> {
  String _selectedCat = 'All';
  final _search = TextEditingController();

  static const _cats = ['All', 'Electronics', 'Lab Gear', 'Books', 'Sports', 'Clothing', 'Other'];

  final _items = <_RentalData>[
    _RentalData(
      id: '1', title: 'Canon EOS 1500D DSLR',
      desc: 'Full kit — 18-55mm lens, bag, 2 batteries. Excellent condition. Used twice.',
      category: 'Electronics', dailyRate: 200, deposit: 1000,
      ownerName: 'Rahul K.', ownerRating: 4.9,
      availFrom: 'Dec 5', availTo: 'Dec 10', totalRentals: 8,
    ),
    _RentalData(
      id: '2', title: 'Casio Scientific Calculator fx-991EX',
      desc: 'Perfect for engineering exams. Includes original box and manual.',
      category: 'Electronics', dailyRate: 30, deposit: 200,
      ownerName: 'Meena R.', ownerRating: 4.7,
      availFrom: 'Now', availTo: 'Ongoing', totalRentals: 22,
    ),
    _RentalData(
      id: '3', title: 'Lab Coat (Size L)',
      desc: 'Clean white lab coat. Used only a couple of times. Washed and ironed.',
      category: 'Lab Gear', dailyRate: 25, deposit: 0,
      ownerName: 'Ananya S.', ownerRating: 4.5,
      availFrom: 'Now', availTo: 'Dec 12', totalRentals: 5,
    ),
    _RentalData(
      id: '4', title: 'Data Structures (CLRS) 3rd Ed.',
      desc: 'Introduction to Algorithms — Cormen. Minor highlights on Ch. 1-5. Very usable.',
      category: 'Books', dailyRate: 15, deposit: 100,
      ownerName: 'Vikram L.', ownerRating: 4.6,
      availFrom: 'Dec 6', availTo: 'Dec 20', totalRentals: 11,
    ),
    _RentalData(
      id: '5', title: 'Football (Nike Strike)',
      desc: 'Official match ball. Great for evening practice sessions. Pump included.',
      category: 'Sports', dailyRate: 20, deposit: 150,
      ownerName: 'Preet D.', ownerRating: 4.8,
      availFrom: 'Now', availTo: 'Ongoing', totalRentals: 14,
    ),
    _RentalData(
      id: '6', title: 'GoPro Hero 11 Black',
      desc: 'With waterproof housing + 64GB card. Perfect for sports and travel vids.',
      category: 'Electronics', dailyRate: 300, deposit: 2000,
      ownerName: 'Sanjay M.', ownerRating: 4.9,
      availFrom: 'Dec 7', availTo: 'Dec 14', totalRentals: 3,
    ),
  ];

  List<_RentalData> get _filtered => _items.where((r) {
    final catOk  = _selectedCat == 'All' || r.category == _selectedCat;
    final q      = _search.text.toLowerCase();
    final textOk = q.isEmpty || r.title.toLowerCase().contains(q) || r.desc.toLowerCase().contains(q);
    return catOk && textOk;
  }).toList();

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: CustomScrollView(slivers: [
      _appBar(),
      _heroBanner(),
      _searchBar(),
      _categoryChips(),
      _countRow(),
      _rentalGrid(),
      const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
    ]),
    floatingActionButton: _fab(),
  );

  // ── app bar ───────────────────────────────────
  Widget _appBar() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rentals', style: AppText.display(size: 26)),
          Text('Borrow anything on campus', style: AppText.body(size: 13, color: AppColors.textMuted)),
        ])),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.bookmark_border_rounded, color: AppColors.textMuted, size: 20),
        ),
      ]),
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
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.violet.withOpacity(0.3)),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('List your idle items', style: AppText.heading(size: 15)),
            const SizedBox(height: 4),
            Text('Earn ₹ while stuff sits in your room.',
              style: AppText.body(size: 13, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListRentalScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Start Listing →',
                  style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ])),
          const SizedBox(width: 16),
          const Text('📦', style: TextStyle(fontSize: 52)),
        ]),
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
          final color = cat == 'All' ? AppColors.cyan : RentalCategory.colorOf(cat);
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
                  Text(RentalCategory.emojiOf(cat), style: const TextStyle(fontSize: 13)),
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
        '${_filtered.length} item${_filtered.length == 1 ? '' : 's'} available',
        style: AppText.body(size: 13, color: AppColors.textMuted),
      ),
    ),
  );

  // ── rental grid ───────────────────────────────
  Widget _rentalGrid() {
    final list = _filtered;
    if (list.isEmpty) return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(children: [
          const Text('📦', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('No items found', style: AppText.heading(size: 18)),
          const SizedBox(height: 6),
          Text('Try a different filter', style: AppText.body(size: 14, color: AppColors.textMuted)),
        ]),
      ),
    );
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => _RentalCard(data: list[i]),
          childCount: list.length,
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────
  Widget _fab() => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListRentalScreen())),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0099BB), AppColors.cyan]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text('List Item', style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────
//  RENTAL DATA MODEL
// ─────────────────────────────────────────────
class _RentalData {
  final String id, title, desc, category, ownerName, availFrom, availTo;
  final int dailyRate, deposit, totalRentals;
  final double ownerRating;

  const _RentalData({
    required this.id,
    required this.title,
    required this.desc,
    required this.category,
    required this.dailyRate,
    required this.deposit,
    required this.ownerName,
    required this.ownerRating,
    required this.availFrom,
    required this.availTo,
    required this.totalRentals,
  });
}

// ─────────────────────────────────────────────
//  RENTAL CARD (grid tile)
// ─────────────────────────────────────────────
class _RentalCard extends StatelessWidget {
  final _RentalData data;
  const _RentalCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cc = RentalCategory.colorOf(data.category);
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // emoji icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: cc.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cc.withOpacity(0.25)),
            ),
            child: Center(child: Text(RentalCategory.emojiOf(data.category),
              style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(height: 10),
          // title
          Text(data.title,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: AppText.heading(size: 13)),
          const SizedBox(height: 4),
          // owner
          Text(data.ownerName, style: AppText.body(size: 11, color: AppColors.textMuted)),
          const Spacer(),
          // availability badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.lime.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Available', style: AppText.label(size: 10, color: AppColors.lime)),
          ),
          const SizedBox(height: 8),
          // daily rate
          Row(children: [
            Text('₹${data.dailyRate}', style: AppText.price(size: 16)),
            Text('/day', style: AppText.body(size: 11, color: AppColors.textMuted)),
          ]),
          if (data.deposit > 0) ...[
            const SizedBox(height: 2),
            Text('+ ₹${data.deposit} deposit', style: AppText.body(size: 11, color: AppColors.textMuted)),
          ],
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
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5,
      expand: false,
      builder: (_, sc) => _RentalDetailSheet(data: data, sc: sc),
    ),
  );
}

// ─────────────────────────────────────────────
//  RENTAL DETAIL SHEET
// ─────────────────────────────────────────────
class _RentalDetailSheet extends StatefulWidget {
  final _RentalData data;
  final ScrollController sc;
  const _RentalDetailSheet({required this.data, required this.sc});
  @override
  State<_RentalDetailSheet> createState() => _RentalDetailSheetState();
}

class _RentalDetailSheetState extends State<_RentalDetailSheet> {
  DateTime? _start;
  DateTime? _end;

  int get _days => (_start != null && _end != null && _end!.isAfter(_start!))
    ? _end!.difference(_start!).inDays : 0;

  int get _totalCost => _days * widget.data.dailyRate + widget.data.deposit;

  @override
  Widget build(BuildContext context) {
    final cc = RentalCategory.colorOf(widget.data.category);
    return SingleChildScrollView(
      controller: widget.sc,
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // handle
        Center(child: Container(width: 36, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        // header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: cc.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cc.withOpacity(0.3)),
            ),
            child: Center(child: Text(RentalCategory.emojiOf(widget.data.category),
              style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CategoryBadge(label: widget.data.category, color: cc, emoji: RentalCategory.emojiOf(widget.data.category)),
            const SizedBox(height: 6),
            Text(widget.data.title, style: AppText.heading(size: 17)),
          ])),
        ]),
        const SizedBox(height: 14),
        Text(widget.data.desc, style: AppText.body(size: 14, color: AppColors.textMuted).copyWith(height: 1.6)),
        const SizedBox(height: 20),
        Divider(color: AppColors.border),
        const SizedBox(height: 16),
        // pricing info
        Row(children: [
          Expanded(child: _PriceChip(label: 'Daily Rate', value: '₹${widget.data.dailyRate}', color: AppColors.lime)),
          const SizedBox(width: 10),
          Expanded(child: _PriceChip(label: 'Deposit', value: widget.data.deposit > 0 ? '₹${widget.data.deposit}' : 'None', color: AppColors.amber)),
          const SizedBox(width: 10),
          Expanded(child: _PriceChip(label: 'Rented', value: '${widget.data.totalRentals}x', color: AppColors.cyan)),
        ]),
        const SizedBox(height: 20),
        // availability
        _InfoRow2(icon: Icons.event_available_rounded, label: 'Available', value: '${widget.data.availFrom} → ${widget.data.availTo}'),
        const SizedBox(height: 20),
        Divider(color: AppColors.border),
        const SizedBox(height: 16),
        // date selector
        Text('SELECT RENTAL DATES', style: AppText.label()),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _DateButton(
            label: 'Start Date',
            date: _start,
            onTap: () => _pickDate(isStart: true),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('→', style: AppText.heading(size: 18)),
          ),
          Expanded(child: _DateButton(
            label: 'End Date',
            date: _end,
            onTap: () => _pickDate(isStart: false),
          )),
        ]),
        if (_days > 0) ...[
          const SizedBox(height: 16),
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            borderColor: AppColors.violet.withOpacity(0.3),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$_days day${_days > 1 ? 's' : ''} rental', style: AppText.body(size: 13, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text('Total Payable', style: AppText.label()),
              ]),
              const Spacer(),
              Text('₹$_totalCost', style: AppText.price(size: 22)),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        GradientButton(
          label: _days > 0 ? 'Request Rental  →' : 'Pick Dates First',
          width: double.infinity,
          colors: _days > 0 ? [const Color(0xFF0099BB), AppColors.cyan] : [AppColors.border, AppColors.border],
          onTap: _days > 0 ? () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Rental request sent! 📦', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
              backgroundColor: AppColors.cyan,
            ));
          } : null,
        ),
      ]),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? DateTime.now() : (_start ?? DateTime.now())).add(const Duration(days: 1)),
      firstDate: isStart ? DateTime.now() : (_start ?? DateTime.now()).add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.cyan, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { if (isStart) _start = picked; else _end = picked; });
  }
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────
class _PriceChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _PriceChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(children: [
      Text(value, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: AppText.label(size: 10)),
    ]),
  );
}

class _InfoRow2 extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow2({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: AppColors.textMuted),
    const SizedBox(width: 8),
    Text('$label: ', style: AppText.body(size: 13, color: AppColors.textMuted)),
    Text(value, style: AppText.body(size: 13).copyWith(fontWeight: FontWeight.w600)),
  ]);
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.date, required this.onTap});

  String get _formatted => date != null ? '${date!.day}/${date!.month}' : label;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: date != null ? AppColors.cyan : AppColors.border),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(_formatted, style: AppText.body(size: 13, color: date != null ? AppColors.textPrimary : AppColors.textMuted)),
      ]),
    ),
  );
}

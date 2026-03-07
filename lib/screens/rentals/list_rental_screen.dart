import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../models/rental_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gig_rental_providers.dart';
import '../../theme/app_theme.dart' hide RentalCategory;

// ─────────────────────────────────────────────
//  LIST RENTAL SCREEN
// ─────────────────────────────────────────────
class ListRentalScreen extends ConsumerStatefulWidget {
  const ListRentalScreen({super.key});
  @override
  ConsumerState<ListRentalScreen> createState() => _ListRentalScreenState();
}

class _ListRentalScreenState extends ConsumerState<ListRentalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  String _category = '';
  DateTime? _availFrom;
  DateTime? _availTo;
  bool _isListing = false;
  bool _noDeposit = false;

  static const _categories = [
    'Electronics',
    'Lab Gear',
    'Books',
    'Sports',
    'Clothing',
    'Other',
  ];

  int get _completedSteps => [
    _titleCtrl.text.isNotEmpty,
    _category.isNotEmpty,
    _descCtrl.text.isNotEmpty,
    _rateCtrl.text.isNotEmpty && _availFrom != null && _availTo != null,
  ].where((v) => v).length;

  @override
  void initState() {
    super.initState();
    for (final c in [_titleCtrl, _descCtrl, _rateCtrl, _depositCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _descCtrl, _rateCtrl, _depositCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: AppColors.bg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('List an Item', style: AppText.heading(size: 18)),
      elevation: 0,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _progressBar(),
          const SizedBox(height: 24),
          // ── earnings tip
          _earningsTip(),
          const SizedBox(height: 24),
          // ── item name
          _fieldLabel('ITEM NAME'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleCtrl,
            style: AppText.input(),
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: const InputDecoration(
              hintText: 'e.g. Canon EOS 1500D DSLR',
            ),
          ),
          const SizedBox(height: 20),
          // ── category
          _fieldLabel('CATEGORY'),
          const SizedBox(height: 10),
          _categoryGrid(),
          const SizedBox(height: 20),
          // ── description
          _fieldLabel('DESCRIPTION'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            style: AppText.input(size: 14).copyWith(height: 1.5),
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Describe the item' : null,
            decoration: const InputDecoration(
              hintText:
                  'Describe condition, included accessories, usage history…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          // ── pricing
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _rateField()),
              const SizedBox(width: 14),
              Expanded(child: _depositField()),
            ],
          ),
          const SizedBox(height: 6),
          // ── no deposit toggle
          GestureDetector(
            onTap: () => setState(() {
              _noDeposit = !_noDeposit;
              if (_noDeposit) _depositCtrl.clear();
            }),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _noDeposit ? AppColors.cyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _noDeposit ? AppColors.cyan : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: _noDeposit
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.black,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'No deposit required',
                  style: AppText.body(size: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── availability window
          _fieldLabel('AVAILABILITY WINDOW'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'From',
                  date: _availFrom,
                  onTap: () => _pickDate(isFrom: true),
                  color: AppColors.lime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTile(
                  label: 'To',
                  date: _availTo,
                  onTap: () => _pickDate(isFrom: false),
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // ── live preview
          if (_titleCtrl.text.isNotEmpty) ...[
            _fieldLabel('PREVIEW'),
            const SizedBox(height: 10),
            _livePreview(),
            const SizedBox(height: 28),
          ],
          // ── tips section
          _conditionTips(),
          const SizedBox(height: 24),
          // ── submit
          GradientButton(
            label: 'List Item  →',
            isLoading: _isListing,
            width: double.infinity,
            colors: [const Color(0xFF0099BB), AppColors.cyan],
            onTap: _submit,
          ),
        ],
      ),
    ),
  );

  // ── progress ──────────────────────────────────
  Widget _progressBar() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < _completedSteps ? AppColors.cyan : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Step $_completedSteps of 4',
        style: AppText.body(size: 12, color: AppColors.textMuted),
      ),
    ],
  );

  // ── earnings tip ──────────────────────────────
  Widget _earningsTip() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.lime.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.lime.withOpacity(0.25)),
    ),
    child: Row(
      children: [
        const Text('💡', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Items that list with clear photos + condition notes get 3× more requests.',
            style: AppText.body(
              size: 13,
              color: AppColors.lime.withOpacity(0.85),
            ).copyWith(height: 1.4),
          ),
        ),
      ],
    ),
  );

  Widget _fieldLabel(String label) => Text(label, style: AppText.label());

  // ── category grid ─────────────────────────────
  Widget _categoryGrid() => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 2.4,
    children: _categories.map((cat) {
      final sel = _category == cat;
      final color = _rentalColor(cat);
      return GestureDetector(
        onTap: () => setState(() => _category = cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: sel ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? color : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_rentalEmoji(cat), style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                cat,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );

  // ── rate field ────────────────────────────────
  Widget _rateField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _fieldLabel('DAILY RATE (₹)'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _rateCtrl,
        style: GoogleFonts.syne(
          color: AppColors.lime,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: GoogleFonts.syne(color: AppColors.textMuted, fontSize: 20),
          prefixText: '₹ ',
          prefixStyle: GoogleFonts.syne(
            color: AppColors.lime,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );

  // ── deposit field ─────────────────────────────
  Widget _depositField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _fieldLabel('DEPOSIT (₹)'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _depositCtrl,
        enabled: !_noDeposit,
        style: GoogleFonts.syne(
          color: AppColors.amber,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: _noDeposit ? 'None' : '0',
          hintStyle: GoogleFonts.syne(color: AppColors.textMuted, fontSize: 20),
          prefixText: _noDeposit ? '' : '₹ ',
          prefixStyle: GoogleFonts.syne(
            color: AppColors.amber,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          fillColor: _noDeposit
              ? AppColors.border.withOpacity(0.4)
              : AppColors.surfaceHigh,
        ),
      ),
    ],
  );

  // ── live preview ──────────────────────────────
  Widget _livePreview() {
    final cc = _category.isNotEmpty ? _rentalColor(_category) : AppColors.cyan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.cyan.withOpacity(0.06), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_category.isNotEmpty)
                CategoryBadge(
                  label: _category,
                  color: cc,
                  emoji: _rentalEmoji(_category),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lime.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AVAILABLE',
                  style: AppText.label(size: 10, color: AppColors.lime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_titleCtrl.text, style: AppText.heading(size: 15)),
          if (_descCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _descCtrl.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                size: 13,
                color: AppColors.textMuted,
              ).copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (_rateCtrl.text.isNotEmpty) ...[
                Text('₹${_rateCtrl.text}', style: AppText.price(size: 18)),
                Text(
                  '/day',
                  style: AppText.body(size: 11, color: AppColors.textMuted),
                ),
              ],
              const Spacer(),
              if (!_noDeposit && _depositCtrl.text.isNotEmpty)
                Text(
                  '+ ₹${_depositCtrl.text} dep.',
                  style: AppText.body(size: 12, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── condition tips ────────────────────────────
  Widget _conditionTips() => SurfaceCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LISTING TIPS', style: AppText.label()),
        const SizedBox(height: 12),
        ...const [
          '✅  Be honest about condition — it builds trust',
          '📸  Add photos when editing your listing later',
          '⏰  Keep your availability window accurate',
          '💬  Respond to requests within 2 hours for best results',
        ].map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tip,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── date picker ───────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final init = isFrom
        ? now
        : (_availFrom ?? now).add(const Duration(days: 1));
    final first = isFrom
        ? now
        : (_availFrom ?? now).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: now.add(const Duration(days: 90)),
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
    if (picked != null)
      setState(() {
        if (isFrom)
          _availFrom = picked;
        else
          _availTo = picked;
      });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category.isEmpty) {
      _snack('Pick a category', AppColors.coral);
      return;
    }
    if (_availFrom == null || _availTo == null) {
      _snack('Set availability window', AppColors.coral);
      return;
    }

    final user = ref.read(currentUserProfileProvider).valueOrNull;
    if (user == null) {
      _snack('Not logged in', AppColors.coral);
      return;
    }

    final categoryEnum = RentalCategory.values.firstWhere(
      (c) => c.label == _category,
      orElse: () => RentalCategory.other,
    );

    setState(() => _isListing = true);
    try {
      await ref
          .read(rentalServiceProvider)
          .createListing(
            ownerId: user.userId,
            ownerName: user.name,
            ownerRating: user.rating,
            itemName: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            category: categoryEnum,
            dailyRate: int.parse(_rateCtrl.text.trim()),
            deposit: _noDeposit
                ? 0
                : int.tryParse(_depositCtrl.text.trim()) ?? 0,
            availableFrom: _availFrom!,
            availableTo: _availTo!,
          );
      if (!mounted) return;
      context.go('/my-rentals');
      _snack('Item listed! 🎉', AppColors.cyan);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isListing = false);
      _snack('Failed: $e', AppColors.coral);
    }
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: color,
        ),
      );

  Color _rentalColor(String cat) {
    const m = {
      'Electronics': AppColors.cyan,
      'Lab Gear': AppColors.violet,
      'Books': AppColors.lime,
      'Sports': AppColors.coral,
      'Clothing': AppColors.amber,
    };
    return m[cat] ?? const Color(0xFF7777AA);
  }

  String _rentalEmoji(String cat) {
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
//  DATE TILE
// ─────────────────────────────────────────────
class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final Color color;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.color,
  });

  String get _text => date != null
      ? '${date!.day}/${date!.month}/${date!.year}'
      : 'Tap to pick';

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: date != null ? color : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.label(
              size: 10,
              color: date != null ? color : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: date != null ? color : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _text,
                style: AppText.body(
                  size: 13,
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

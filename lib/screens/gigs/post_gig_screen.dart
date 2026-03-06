import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'gig_browse_screen.dart';        // same folder, no change

// ─────────────────────────────────────────────
//  POST GIG SCREEN
// ─────────────────────────────────────────────
class PostGigScreen extends StatefulWidget {
  const PostGigScreen({super.key});
  @override
  State<PostGigScreen> createState() => _PostGigScreenState();
}

class _PostGigScreenState extends State<PostGigScreen> with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  String    _category    = '';
  DateTime? _deadline;
  bool      _isPosting   = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  static const _categories = ['Tutoring', 'Delivery', 'Writing', 'Coding', 'Errands', 'Other'];

  int get _completedSteps => [
    _titleCtrl.text.isNotEmpty,
    _category.isNotEmpty,
    _descCtrl.text.isNotEmpty,
    _priceCtrl.text.isNotEmpty && _deadline != null,
  ].where((v) => v).length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // Rebuild progress on every keystroke
    _titleCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(()  => setState(() {}));
    _priceCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post a Gig', style: AppText.heading(size: 18)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _progressBar(),
            const SizedBox(height: 24),
            // ── title
            _fieldLabel('GIG TITLE'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: AppText.body(),
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please add a title' : null,
              decoration: const InputDecoration(hintText: 'e.g. Calculus tutoring for 2 hrs'),
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
              style: AppText.body(size: 14).copyWith(height: 1.5),
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe the gig' : null,
              decoration: const InputDecoration(
                hintText: 'Describe exactly what you need…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            // ── price + deadline
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _priceField()),
              const SizedBox(width: 14),
              Expanded(child: _deadlineField()),
            ]),
            const SizedBox(height: 28),
            // ── live preview
            if (_titleCtrl.text.isNotEmpty) ...[
              _fieldLabel('LIVE PREVIEW'),
              const SizedBox(height: 10),
              _livePreview(),
              const SizedBox(height: 28),
            ],
            // ── post button
            GradientButton(
              label: 'Post Gig  →',
              isLoading: _isPosting,
              width: double.infinity,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  // ── progress bar ──────────────────────────────
  Widget _progressBar() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: List.generate(4, (i) => Expanded(
        child: Container(
          height: 4,
          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
          decoration: BoxDecoration(
            color: i < _completedSteps ? AppColors.violet : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ))),
      const SizedBox(height: 8),
      Text('Step $_completedSteps of 4 complete',
        style: AppText.body(size: 12, color: AppColors.textMuted)),
    ],
  );

  // ── field label ───────────────────────────────
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
      final sel   = _category == cat;
      final color = GigCategory.colorOf(cat);
      return GestureDetector(
        onTap: () => setState(() => _category = cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color:  sel ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? color : AppColors.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(GigCategory.emojiOf(cat), style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(cat,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: sel ? Colors.white : AppColors.textMuted,
              )),
          ]),
        ),
      );
    }).toList(),
  );

  // ── price field ───────────────────────────────
  Widget _priceField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _fieldLabel('YOUR BUDGET (₹)'),
    const SizedBox(height: 8),
    TextFormField(
      controller: _priceCtrl,
      style: GoogleFonts.syne(color: AppColors.lime, fontSize: 20, fontWeight: FontWeight.w800),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: GoogleFonts.syne(color: AppColors.textMuted, fontSize: 20),
        prefixText: '₹ ',
        prefixStyle: GoogleFonts.syne(color: AppColors.lime, fontSize: 20, fontWeight: FontWeight.w800),
      ),
    ),
  ]);

  // ── deadline field ────────────────────────────
  Widget _deadlineField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _fieldLabel('DEADLINE'),
    const SizedBox(height: 8),
    GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _deadline != null ? AppColors.violet : AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            _deadline != null ? _fmtDate(_deadline!) : 'Pick date',
            style: AppText.body(size: 14, color: _deadline != null ? AppColors.textPrimary : AppColors.textMuted),
          ),
        ]),
      ),
    ),
  ]);

  // ── live preview card ─────────────────────────
  Widget _livePreview() {
    final cc = _category.isNotEmpty ? GigCategory.colorOf(_category) : AppColors.violet;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.violet.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.08), blurRadius: 20)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (_category.isNotEmpty)
            CategoryBadge(label: _category, color: cc, emoji: GigCategory.emojiOf(_category)),
          const Spacer(),
          // Pulse dot
          FadeTransition(
            opacity: _pulseAnim,
            child: Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 6),
          Text('OPEN', style: AppText.label(size: 10, color: AppColors.lime)),
        ]),
        const SizedBox(height: 10),
        Text(_titleCtrl.text, style: AppText.heading(size: 15)),
        if (_descCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_descCtrl.text,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: AppText.body(size: 13, color: AppColors.textMuted).copyWith(height: 1.4)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          if (_priceCtrl.text.isNotEmpty)
            Text('₹${_priceCtrl.text}', style: AppText.price(size: 18)),
          const Spacer(),
          if (_deadline != null) ...[
            const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(_fmtDate(_deadline!), style: AppText.body(size: 12, color: AppColors.textMuted)),
          ],
        ]),
      ]),
    );
  }

  // ── helpers ───────────────────────────────────
  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.violet, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please pick a category', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppColors.coral,
      ));
      return;
    }
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please set a deadline', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppColors.coral,
      ));
      return;
    }
    setState(() => _isPosting = true);
    // TODO: call FirestoreService.createGig(...)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isPosting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Gig posted! 🎉', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
      backgroundColor: AppColors.violet,
    ));
  }
}

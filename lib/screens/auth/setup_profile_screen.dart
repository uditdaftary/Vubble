import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});
  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _deptCtrl  = TextEditingController();
  final _bioCtrl   = TextEditingController();
  final _regNoCtrl = TextEditingController(); // registration number
  bool _isSaving   = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  int get _completedSteps => [
    _nameCtrl.text.isNotEmpty,
    _deptCtrl.text.isNotEmpty,
    _regNoCtrl.text.isNotEmpty,
  ].where((v) => v).length;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    for (final c in [_nameCtrl, _deptCtrl, _regNoCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _deptCtrl.dispose();
    _bioCtrl.dispose();
    _regNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final authService  = ref.read(authServiceProvider);
      final firebaseUser = authService.currentUser;
      if (firebaseUser == null) return;

      final user = UserModel(
        userId:             firebaseUser.uid,
        name:               _nameCtrl.text.trim(),
        email:              firebaseUser.email ?? '',
        department:         _deptCtrl.text.trim(),
        bio:                _bioCtrl.text.trim(),
        registrationNumber: _regNoCtrl.text.trim(),
        verificationStatus: VerificationStatus.verified,
        createdAt:          DateTime.now(),
      );

      await authService.createUserProfile(user);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save profile: $e',
              style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: AppColors.coral,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: CustomScrollView(slivers: [
            _header(),
            _progressSliver(),
            _formFields(),
            SliverPadding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 40)),
          ]),
        ),
      ),
    );
  }

  // ── header with live avatar preview ───────────
  Widget _header() => SliverToBoxAdapter(
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF180840), Color(0xFF08080E)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _LogoMark(),
        const SizedBox(height: 28),
        Row(children: [
          // live avatar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.violet, AppColors.cyan],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(
                color: AppColors.violet.withOpacity(0.3),
                blurRadius: 16, spreadRadius: 2,
              )],
            ),
            child: Center(
              child: Text(
                _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?',
                style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
              style: AppText.heading(size: 18),
            ),
            const SizedBox(height: 3),
            Text(
              _deptCtrl.text.isNotEmpty ? _deptCtrl.text : 'Department',
              style: AppText.body(size: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 5),
            // reg number live preview
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _regNoCtrl.text.isNotEmpty
                ? Container(
                    key: const ValueKey('reg'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                    ),
                    child: Text(
                      _regNoCtrl.text.toUpperCase(),
                      style: AppText.label(size: 10, color: AppColors.cyan),
                    ),
                  )
                : Container(
                    key: const ValueKey('verified'),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('✓ Verified', style: AppText.label(size: 10, color: AppColors.violet)),
                  ),
            ),
          ])),
        ]),
        const SizedBox(height: 20),
        Text('Set up your profile', style: AppText.display(size: 26)),
        const SizedBox(height: 6),
        Text('This is how others will see you on Vubble.',
          style: AppText.body(size: 14, color: AppColors.textMuted)),
      ]),
    ),
  );

  // ── progress bar ──────────────────────────────
  Widget _progressSliver() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(3, (i) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < _completedSteps ? AppColors.violet : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ))),
        const SizedBox(height: 8),
        Text('$_completedSteps of 3 required fields filled',
          style: AppText.body(size: 12, color: AppColors.textMuted)),
      ]),
    ),
  );

  // ── form fields ───────────────────────────────
  Widget _formFields() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    sliver: SliverList(delegate: SliverChildListDelegate([

      // ── full name ────────────────────────────
      _label('FULL NAME'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _nameCtrl,
        style: AppText.input(),
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'e.g. Alex Kumar',
          prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
      ),
      const SizedBox(height: 20),

      // ── department ───────────────────────────
      _label('DEPARTMENT'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _deptCtrl,
        style: AppText.input(),
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'e.g. Computer Science · 2nd Year',
          prefixIcon: Icon(Icons.school_outlined, size: 18),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your department' : null,
      ),
      const SizedBox(height: 20),

      // ── registration number ──────────────────
      _label('REGISTRATION NUMBER'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _regNoCtrl,
        style: AppText.input(),
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          hintText: 'e.g. CS21B042',
          prefixIcon: Icon(Icons.badge_outlined, size: 18),
        ),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Enter your registration number' : null,
      ),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text('Used to verify you as a campus member.',
          style: AppText.body(size: 12, color: AppColors.textMuted)),
      ]),
      const SizedBox(height: 20),

      // ── bio ──────────────────────────────────
      _label('BIO  (optional)'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _bioCtrl,
        style: AppText.input(size: 14).copyWith(height: 1.5),
        maxLines: 3,
        maxLength: 150,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Tell others what you can do…',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 32),

      // ── CTA ──────────────────────────────────
      GradientButton(
        label: 'Enter Vubble  →',
        isLoading: _isSaving,
        width: double.infinity,
        onTap: _saveProfile,
      ),
      const SizedBox(height: 16),
      Center(child: Text(
        'You can always update your profile later.',
        style: AppText.body(size: 12, color: AppColors.textMuted),
      )),
    ])),
  );

  Widget _label(String t) => Text(t, style: AppText.label());
}

// ─────────────────────────────────────────────
//  LOGO MARK
// ─────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.violet, AppColors.cyan]),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text('V',
          style: GoogleFonts.syne(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    ),
    const SizedBox(width: 8),
    Text('Vubble',
      style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
  ]);
}
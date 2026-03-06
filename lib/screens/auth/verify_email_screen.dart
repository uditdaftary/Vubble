import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  Timer? _checkTimer;
  Timer? _cooldownTimer;
  bool _resendCooldown  = false;
  int  _cooldownSeconds = 0;

  // ── animations ────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final AnimationController _spinCtrl;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _spinCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Poll every 4 s for email verification
    _checkTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final verified = await _authService.checkEmailVerified();
      if (verified && mounted) {
        _checkTimer?.cancel();
        context.go('/setup-profile');
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    await _authService.resendVerificationEmail();
    setState(() { _resendCooldown = true; _cooldownSeconds = 30; });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) { t.cancel(); setState(() => _resendCooldown = false); }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Verification email sent!',
          style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppColors.violet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              // ── top row ───────────────────────────────────
              Row(children: [
                _LogoMark(),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await _authService.logout();
                    if (mounted) context.go('/login');
                  },
                  child: Text('Log out',
                    style: AppText.body(size: 13, color: AppColors.textMuted)),
                ),
              ]),

              const Spacer(),

              // ── animated envelope ─────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([_pulseAnim, _spinCtrl]),
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // outer spinning ring
                    Transform.rotate(
                      angle: _spinCtrl.value * 2 * math.pi,
                      child: Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(colors: [
                            AppColors.violet.withOpacity(0.0),
                            AppColors.violet.withOpacity(0.6),
                            AppColors.cyan.withOpacity(0.0),
                          ]),
                        ),
                      ),
                    ),
                    // glow pulse
                    Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.violet.withOpacity(0.12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.violet.withOpacity(0.2),
                              blurRadius: 24, spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // icon
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.violet, AppColors.cyan],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.mark_email_unread_rounded,
                        size: 36, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── title ─────────────────────────────────────
              Text('Check your inbox', style: AppText.display(size: 28),
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('We sent a verification link to',
                style: AppText.body(size: 15, color: AppColors.textMuted),
                textAlign: TextAlign.center),
              const SizedBox(height: 6),

              // ── email pill ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.violet.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.violet.withOpacity(0.35)),
                ),
                child: Text(email,
                  style: GoogleFonts.syne(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.violet)),
              ),
              const SizedBox(height: 16),
              Text(
                'Click the link in the email to continue.\nThis page updates automatically.',
                style: AppText.body(size: 13, color: AppColors.textMuted).copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── waiting indicator ─────────────────────────
              SurfaceCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.violet),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Waiting for verification…',
                    style: AppText.body(size: 14, color: AppColors.textMuted)),
                ]),
              ),

              const Spacer(),

              // ── resend button ─────────────────────────────
              GradientButton(
                label: _resendCooldown
                  ? 'Resend in ${_cooldownSeconds}s'
                  : 'Resend Email',
                width: double.infinity,
                colors: _resendCooldown
                  ? [AppColors.border, AppColors.border]
                  : [AppColors.violet, const Color(0xFF5000EE)],
                onTap: _resendCooldown ? null : _resendEmail,
              ),
              const SizedBox(height: 12),

              // ── wrong email ───────────────────────────────
              GestureDetector(
                onTap: () async {
                  await _authService.logout();
                  if (mounted) context.go('/login');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text('Wrong email? Go back',
                    style: AppText.body(size: 14, color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

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
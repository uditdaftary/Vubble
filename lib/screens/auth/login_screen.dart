import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey          = GlobalKey<FormState>();
  final _emailController  = TextEditingController();
  final _passController   = TextEditingController();
  bool _obscure           = true;

  late final AnimationController _fadeCtrl;
  late final Animation<Offset>   _slideAnim;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authNotifierProvider.notifier).login(
      email:    _emailController.text.trim(),
      password: _passController.text,
    );
    if (success && mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── logo mark ────────────────────────────────
                    _LogoMark(),
                    const SizedBox(height: 32),

                    // ── headline ──────────────────────────────────
                    Text('Welcome\nback 👋', style: AppText.display(size: 34)),
                    const SizedBox(height: 8),
                    Text('Sign in to your campus account.',
                      style: AppText.body(size: 15, color: AppColors.textMuted)),
                    const SizedBox(height: 40),

                    // ── email ─────────────────────────────────────
                    _label('UNIVERSITY EMAIL'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppText.input(),
                      decoration: InputDecoration(
                        hintText: 'you@university.edu',
                        prefixIcon: const Icon(Icons.alternate_email_rounded,
                          size: 18, color: AppColors.textMuted),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your email';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── password ──────────────────────────────────
                    _label('PASSWORD'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passController,
                      obscureText: _obscure,
                      style: AppText.input(),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                          size: 18, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18, color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),
                    const SizedBox(height: 8),

                    // ── forgot password ───────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        child: Text('Forgot password?',
                          style: AppText.body(size: 13, color: AppColors.violet)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── error ─────────────────────────────────────
                    if (authState.hasError) ...[
                      _ErrorBanner(message: authState.errorMessage ?? ''),
                      const SizedBox(height: 16),
                    ],

                    // ── login button ──────────────────────────────
                    GradientButton(
                      label: 'Log In',
                      isLoading: authState.isLoading,
                      width: double.infinity,
                      onTap: _login,
                    ),
                    const SizedBox(height: 32),

                    // ── divider ───────────────────────────────────
                    _OrDivider(),
                    const SizedBox(height: 28),

                    // ── sign up ───────────────────────────────────
                    Center(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text("Don't have an account?  ",
                          style: AppText.body(size: 14, color: AppColors.textMuted)),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text('Sign Up',
                            style: GoogleFonts.syne(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: AppColors.violet,
                            )),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── terms note ────────────────────────────────
                    Center(
                      child: Text(
                        'By continuing you agree to Vubble\'s Terms & Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: AppText.body(size: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: AppText.label());
}

// ─────────────────────────────────────────────
//  SHARED AUTH WIDGETS  (used across all 4 screens)
// ─────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.violet, AppColors.cyan],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text('V',
          style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    ),
    const SizedBox(width: 10),
    Text('Vubble',
      style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
  ]);
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.coral.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.coral.withValues(alpha: 0.35)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.coral),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
        style: AppText.body(size: 13, color: AppColors.coral))),
    ]),
  );
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: AppColors.border)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text('or', style: AppText.body(size: 13, color: AppColors.textMuted)),
    ),
    Expanded(child: Divider(color: AppColors.border)),
  ]);
}
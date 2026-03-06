import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey                  = GlobalKey<FormState>();
  final _emailController          = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // password strength 0–4
  int get _strength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8)                         s++;
    if (RegExp(r'[A-Z]').hasMatch(p))          s++;
    if (RegExp(r'[0-9]').hasMatch(p))          s++;
    if (RegExp(r'[!@#\$%^&*]').hasMatch(p))   s++;
    return s;
  }

  Color get _strengthColor {
    switch (_strength) {
      case 1: return AppColors.coral;
      case 2: return AppColors.amber;
      case 3: return const Color(0xFF88CC00);
      case 4: return AppColors.lime;
      default: return AppColors.border;
    }
  }

  String get _strengthLabel {
    switch (_strength) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authNotifierProvider.notifier).register(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) context.go('/verify-email');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── header ────────────────────────────────────
                _LogoMark(),
                const SizedBox(height: 28),
                Text('Create your\naccount ✨', style: AppText.display(size: 32)),
                const SizedBox(height: 8),
                Text('Use your university email to join Vubble.',
                  style: AppText.body(size: 15, color: AppColors.textMuted)),
                const SizedBox(height: 36),

                // ── university email ──────────────────────────
                _label('UNIVERSITY EMAIL'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppText.input(),
                  decoration: const InputDecoration(
                    hintText: 'you@university.edu',
                    prefixIcon: Icon(Icons.alternate_email_rounded,
                      size: 18, color: AppColors.textMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // campus email note
                Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text('Only university emails are accepted.',
                    style: AppText.body(size: 12, color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 20),

                // ── password ──────────────────────────────────
                _label('PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePass,
                  style: AppText.input(),
                  decoration: InputDecoration(
                    hintText: 'Min. 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                      size: 18, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18, color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                // strength bar
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    ...List.generate(4, (i) => Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: i < _strength ? _strengthColor : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                    const SizedBox(width: 10),
                    Text(_strengthLabel,
                      style: AppText.label(size: 10, color: _strengthColor)),
                  ]),
                ],
                const SizedBox(height: 20),

                // ── confirm password ──────────────────────────
                _label('CONFIRM PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: AppText.input(),
                  decoration: InputDecoration(
                    hintText: 'Re-enter password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                      size: 18, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18, color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) =>
                    v != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),

                // ── error ─────────────────────────────────────
                if (authState.hasError) ...[
                  _ErrorBanner(message: authState.errorMessage ?? ''),
                  const SizedBox(height: 16),
                ],

                // ── register button ───────────────────────────
                GradientButton(
                  label: 'Create Account',
                  isLoading: authState.isLoading,
                  width: double.infinity,
                  onTap: _register,
                ),
                const SizedBox(height: 28),

                // ── sign in redirect ──────────────────────────
                Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Already have an account?  ',
                      style: AppText.body(size: 14, color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('Log In',
                        style: GoogleFonts.syne(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.violet,
                        )),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: AppText.label());
}

// ── shared widgets (duplicated here for standalone file)
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
      color: AppColors.coral.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.coral.withOpacity(0.35)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.coral),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: AppText.body(size: 13, color: AppColors.coral))),
    ]),
  );
}
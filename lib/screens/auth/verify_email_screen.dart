import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final AuthService _authService = AuthService();
  Timer? _checkTimer;
  bool _resendCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Poll every 4 seconds to check if email was verified
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
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    await _authService.resendVerificationEmail();
    setState(() {
      _resendCooldown = true;
      _cooldownSeconds = 30;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) {
        timer.cancel();
        setState(() => _resendCooldown = false);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 48,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              Text(
                'We sent a verification link to',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Click the link in the email to continue. This page will update automatically.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Waiting indicator
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Waiting for verification...'),
                ],
              ),

              const SizedBox(height: 32),

              // Resend button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _resendCooldown ? null : _resendEmail,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _resendCooldown
                        ? 'Resend in ${_cooldownSeconds}s'
                        : 'Resend Email',
                    style: const TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Wrong email / logout
              TextButton(
                onPressed: () async {
                  await _authService.logout();
                  if (mounted) context.go('/login');
                },
                child: Text(
                  'Wrong email? Go back',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

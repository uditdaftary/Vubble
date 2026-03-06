import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';

// ─────────────────────────────────────────────
//  ADMIN DASHBOARD SCREEN
// ─────────────────────────────────────────────
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(adminServiceProvider)
          .broadcastAnnouncement(
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
          );
      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Announcement sent! 📢', style: AppText.body(size: 14)),
          backgroundColor: AppColors.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send announcement',
            style: AppText.body(size: 14),
          ),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _header(),
            _statsSection(statsAsync),
            _quickNavSection(),
            _announcementSection(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────
  Widget _header() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/dashboard'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Panel', style: AppText.display(size: 24)),
                Text(
                  'Manage your campus platform',
                  style: AppText.body(size: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.coral, AppColors.amber],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );

  // ── stats cards ───────────────────────────────
  Widget _statsSection(AsyncValue<Map<String, dynamic>> statsAsync) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: statsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.violet),
            ),
          ),
          error: (e, _) => SurfaceCard(
            child: Text(
              'Failed to load stats',
              style: AppText.body(color: AppColors.coral),
            ),
          ),
          data: (stats) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      emoji: '👥',
                      label: 'Active Users',
                      value: '${stats['activeUsers']}',
                      color: AppColors.violet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      emoji: '⚡',
                      label: 'Open Gigs',
                      value: '${stats['openGigs']}',
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      emoji: '📦',
                      label: 'Open Rentals',
                      value: '${stats['openRentals']}',
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      emoji: '🚩',
                      label: 'Pending Reports',
                      value: '${stats['pendingReports']}',
                      color: AppColors.coral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatCard(
                emoji: '⚠️',
                label: 'Dispute Rate',
                value: '${stats['disputeRate']}',
                color: AppColors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── quick nav ─────────────────────────────────
  Widget _quickNavSection() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MANAGEMENT', style: AppText.label()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NavTile(
                  emoji: '👥',
                  label: 'Users',
                  grad: [AppColors.violet, const Color(0xFF5000EE)],
                  onTap: () => context.go('/admin/users'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NavTile(
                  emoji: '🚩',
                  label: 'Reports',
                  grad: [AppColors.coral, const Color(0xFFCC2244)],
                  onTap: () => context.go('/admin/reports'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ── announcement broadcast ────────────────────
  Widget _announcementSection() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GlowCard(
        gradientColors: [AppColors.violet, AppColors.cyan],
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📢', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Broadcast Announcement',
                  style: AppText.heading(size: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleCtrl,
              style: AppText.input(),
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bodyCtrl,
              style: AppText.input(),
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Message body'),
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Send to All Users',
              isLoading: _sending,
              onTap: _sendAnnouncement,
              width: double.infinity,
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.price(size: 18, color: color)),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppText.body(size: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NavTile extends StatelessWidget {
  final String emoji, label;
  final List<Color> grad;
  final VoidCallback onTap;

  const _NavTile({
    required this.emoji,
    required this.label,
    required this.grad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

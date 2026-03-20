import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/report_model.dart';

// ─────────────────────────────────────────────
//  REPORTS QUEUE SCREEN
// ─────────────────────────────────────────────
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

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
    super.dispose();
  }

  void _showActions(ReportModel report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.border),
            left: BorderSide(color: AppColors.border),
            right: BorderSide(color: AppColors.border),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Take Action', style: AppText.heading(size: 18)),
            const SizedBox(height: 6),
            Text(
              'Report ID: ${report.reportId.substring(0, 8)}…',
              style: AppText.body(size: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.close_rounded,
                    label: 'Dismiss',
                    color: AppColors.textMuted,
                    onTap: () {
                      ref
                          .read(adminServiceProvider)
                          .resolveReport(report.reportId, 'dismissed');
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.warning_rounded,
                    label: 'Warn',
                    color: AppColors.amber,
                    onTap: () {
                      ref
                          .read(adminServiceProvider)
                          .resolveReport(report.reportId, 'warned');
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.pause_circle_rounded,
                    label: 'Suspend',
                    color: AppColors.amber,
                    onTap: () {
                      ref
                          .read(adminServiceProvider)
                          .resolveReport(report.reportId, 'suspended');
                      // Also suspend the target if it's a user
                      if (report.targetType == 'user') {
                        ref
                            .read(adminServiceProvider)
                            .suspendUser(report.targetId);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.block_rounded,
                    label: 'Ban',
                    color: AppColors.coral,
                    onTap: () {
                      ref
                          .read(adminServiceProvider)
                          .resolveReport(report.reportId, 'banned');
                      if (report.targetType == 'user') {
                        ref.read(adminServiceProvider).banUser(report.targetId);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(openReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/admin'),
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
                      child: Text(
                        'Reports Queue',
                        style: AppText.display(size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Reports list ────────────────────
            reportsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.violet),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Failed to load reports',
                    style: AppText.body(color: AppColors.coral),
                  ),
                ),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return SliverFillRemaining(child: _emptyState());
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _ReportTile(
                        report: reports[i],
                        onTap: () => _showActions(reports[i]),
                      ),
                    ),
                    childCount: reports.length,
                  ),
                );
              },
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.lime,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        Text('All clear!', style: AppText.heading(size: 18)),
        const SizedBox(height: 8),
        Text(
          'No open reports at the moment.\nKeep up the good work! 🎉',
          textAlign: TextAlign.center,
          style: AppText.body(size: 14, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

class _ReportTile extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const _ReportTile({required this.report, required this.onTap});

  IconData get _targetIcon {
    switch (report.targetType) {
      case 'user':
        return Icons.person_rounded;
      case 'gig':
        return Icons.flash_on_rounded;
      case 'rental':
        return Icons.inventory_2_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Color get _targetColor {
    switch (report.targetType) {
      case 'user':
        return AppColors.coral;
      case 'gig':
        return AppColors.violet;
      case 'rental':
        return AppColors.cyan;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        borderColor: AppColors.coral.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _targetColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_targetIcon, color: _targetColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CategoryBadge(
                            label: report.targetType.toUpperCase(),
                            color: _targetColor,
                          ),
                          const Spacer(),
                          Text(
                            timeago.format(report.createdAt),
                            style: AppText.body(
                              size: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.reason,
                        style: AppText.body(
                          size: 14,
                        ).copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (report.evidence != null && report.evidence!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.evidence!,
                        style: AppText.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reporter: ${report.reporterId.substring(0, 8)}…',
                  style: AppText.body(size: 11, color: AppColors.textMuted),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'TAP TO ACT',
                    style: AppText.label(size: 9, color: AppColors.coral),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: AppText.label(size: 10, color: color)),
        ],
      ),
    ),
  );
}

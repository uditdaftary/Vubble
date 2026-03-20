import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';

// ─────────────────────────────────────────────
//  NOTIFICATIONS SCREEN
// ─────────────────────────────────────────────
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
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

  // ── helpers ────────────────────────────────────
  IconData _iconForType(String type) {
    switch (type) {
      case 'gig_accepted':
        return Icons.flash_on_rounded;
      case 'rental_requested':
        return Icons.inventory_2_rounded;
      case 'rental_approved':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'rating_received':
        return Icons.star_rounded;
      case 'report_update':
        return Icons.flag_rounded;
      case 'admin_announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'gig_accepted':
        return AppColors.violet;
      case 'rental_requested':
        return AppColors.cyan;
      case 'rental_approved':
        return AppColors.lime;
      case 'completed':
        return AppColors.lime;
      case 'rating_received':
        return AppColors.amber;
      case 'report_update':
        return AppColors.coral;
      case 'admin_announcement':
        return AppColors.violet;
      default:
        return AppColors.textMuted;
    }
  }

  void _onTap(NotificationModel notif) {
    final authState = ref.read(authStateProvider);
    final userId = authState.valueOrNull?.uid;
    if (userId == null) return;

    // Mark as read
    ref.read(notificationServiceProvider).markAsRead(userId, notif.id);

    // Navigate based on type
    if (notif.targetId != null) {
      switch (notif.type) {
        case 'gig_accepted':
        case 'completed':
        case 'application_selected':
        case 'early_completion':
          context.push('/my-gigs');
          break;
        case 'rental_requested':
        case 'rental_approved':
        case 'early_return':
          context.push('/my-rentals');
          break;
        case 'rating_received':
          context.push('/profile');
          break;
        default:
          break;
      }
    }
  }

  void _markAllRead() {
    final authState = ref.read(authStateProvider);
    final userId = authState.valueOrNull?.uid;
    if (userId == null) return;
    ref.read(notificationServiceProvider).markAllAsRead(userId);
  }

  // ── build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.valueOrNull?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── App bar ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
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
                        'Notifications',
                        style: AppText.display(size: 24),
                      ),
                    ),
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.violet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Read all',
                          style: AppText.label(
                            size: 11,
                            color: AppColors.violet,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Notification list ───────────────────
            if (userId != null)
              _notificationList(userId)
            else
              SliverFillRemaining(child: _emptyState()),

            const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
          ],
        ),
      ),
    );
  }

  Widget _notificationList(String userId) {
    final notificationsAsync = ref.watch(notificationsProvider(userId));

    return notificationsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.violet),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.coral,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: AppText.body(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
      data: (notifications) {
        if (notifications.isEmpty) {
          return SliverFillRemaining(child: _emptyState());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _NotificationTile(
                notification: notifications[i],
                icon: _iconForType(notifications[i].type),
                color: _colorForType(notifications[i].type),
                onTap: () => _onTap(notifications[i]),
              ),
            ),
            childCount: notifications.length,
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
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
              Icons.notifications_off_rounded,
              color: AppColors.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text('No notifications yet', style: AppText.heading(size: 18)),
          const SizedBox(height: 8),
          Text(
            'When you get updates on gigs,\nrentals or reviews, they\'ll show up here.',
            textAlign: TextAlign.center,
            style: AppText.body(size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NOTIFICATION TILE
// ─────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border
                : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // ── Content ───────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppText.body(size: 14).copyWith(
                      fontWeight: notification.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: AppText.body(size: 12, color: AppColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Time + unread dot ──────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeago.format(notification.createdAt, locale: 'en_short'),
                  style: AppText.body(size: 11, color: AppColors.textMuted),
                ),
                if (!notification.isRead) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

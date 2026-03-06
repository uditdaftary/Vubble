import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

// ── Notifications stream (requires userId) ────────────────────────────────────

final notificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
      return ref.watch(notificationServiceProvider).getNotifications(userId);
    });

// ── Unread count stream (feeds dashboard bell badge) ──────────────────────────

final unreadCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(notificationServiceProvider).getUnreadCount(userId);
});

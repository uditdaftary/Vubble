import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Get notifications stream ─────────────────────────────────────────────

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ── Unread count stream ──────────────────────────────────────────────────

  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ── Mark single notification as read ─────────────────────────────────────

  Future<void> markAsRead(String userId, String notificationId) async {
    await _db
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // ── Mark all notifications as read ───────────────────────────────────────

  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final unread = await _db
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Send a notification to a user ────────────────────────────────────────

  Future<void> sendNotification(
    String userId,
    NotificationModel notification,
  ) async {
    await _db
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .add(notification.toFirestore());
  }
}

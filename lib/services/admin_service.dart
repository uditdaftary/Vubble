import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Admin stats ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminStats() async {
    final usersSnap = await _db
        .collection('users')
        .where('isBanned', isEqualTo: false)
        .get();
    final activeUsers = usersSnap.docs.length;

    final gigsSnap = await _db
        .collection('gigs')
        .where('status', isEqualTo: 'open')
        .get();
    final openGigs = gigsSnap.docs.length;

    final rentalsSnap = await _db
        .collection('rentalListings')
        .where('status', isEqualTo: 'available')
        .get();
    final openRentals = rentalsSnap.docs.length;

    final reportsSnap = await _db
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .get();
    final pendingReports = reportsSnap.docs.length;

    final allReports = await _db.collection('reports').get();
    final totalReports = allReports.docs.length;

    final disputedRentals = await _db
        .collection('rentalRequests')
        .where('status', isEqualTo: 'disputed')
        .get();
    final disputeRate = totalReports > 0
        ? ((disputedRentals.docs.length / (openRentals > 0 ? openRentals : 1)) *
                  100)
              .toStringAsFixed(1)
        : '0.0';

    return {
      'activeUsers': activeUsers,
      'openGigs': openGigs,
      'openRentals': openRentals,
      'pendingReports': pendingReports,
      'disputeRate': '$disputeRate%',
    };
  }

  // ── Users ────────────────────────────────────────────────────────────────

  Stream<List<UserModel>> getAllUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> suspendUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isSuspended': true});
  }

  Future<void> banUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isBanned': true});
  }

  Future<void> liftRestriction(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isSuspended': false,
      'isBanned': false,
    });
  }

  // ── Reports ──────────────────────────────────────────────────────────────

  Stream<List<ReportModel>> getOpenReports() {
    return _db
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ReportModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> resolveReport(String reportId, String action) async {
    await _db.collection('reports').doc(reportId).update({
      'status': 'resolved',
      'resolvedAction': action,
      'resolvedAt': Timestamp.now(),
    });
  }

  // ── Broadcast announcement ───────────────────────────────────────────────

  Future<void> broadcastAnnouncement({
    required String title,
    required String body,
  }) async {
    final usersSnap = await _db.collection('users').get();
    final batch = _db.batch();

    for (final userDoc in usersSnap.docs) {
      final notifRef = _db
          .collection('notifications')
          .doc(userDoc.id)
          .collection('items')
          .doc();

      batch.set(notifRef, {
        'type': 'admin_announcement',
        'title': title,
        'body': body,
        'targetId': null,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }
}

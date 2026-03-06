import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Submit a rating & review ─────────────────────────────────────────────
  /// Writes to `reviews` collection and atomically updates the target user's
  /// `rating` (recalculated average) and `totalRatings` within a transaction.

  Future<void> submitRating({
    required String targetUserId,
    required String reviewerUserId,
    required String sourceId, // gigId or rentalId
    required String sourceType, // 'gig' or 'rental'
    required int stars,
    required String review,
  }) async {
    final userRef = _db.collection('users').doc(targetUserId);

    await _db.runTransaction((txn) async {
      // 1. Read current user data
      final userSnap = await txn.get(userRef);
      if (!userSnap.exists) throw Exception('Target user not found.');

      final userData = userSnap.data()!;
      final currentRating = (userData['rating'] ?? 0.0).toDouble();
      final currentTotal = (userData['totalRatings'] ?? 0) as int;

      // 2. Compute new average
      final newTotal = currentTotal + 1;
      final newRating = ((currentRating * currentTotal) + stars) / newTotal;

      // 3. Write the review document
      final reviewRef = _db.collection('reviews').doc();
      txn.set(reviewRef, {
        'targetUserId': targetUserId,
        'reviewerUserId': reviewerUserId,
        'sourceId': sourceId,
        'sourceType': sourceType,
        'stars': stars,
        'review': review,
        'createdAt': Timestamp.now(),
      });

      // 4. Update the user's rating & totalRatings
      txn.update(userRef, {
        'rating': double.parse(newRating.toStringAsFixed(2)),
        'totalRatings': newTotal,
      });
    });
  }
}

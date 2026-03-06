import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String targetUserId;
  final String reviewerUserId;
  final String sourceId; // gigId or rentalId
  final String sourceType; // 'gig' or 'rental'
  final int stars;
  final String review;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.targetUserId,
    required this.reviewerUserId,
    required this.sourceId,
    required this.sourceType,
    required this.stars,
    this.review = '',
    required this.createdAt,
  });

  // ── Firestore serialization ──────────────────────────────────────────────

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      reviewId: doc.id,
      targetUserId: data['targetUserId'] ?? '',
      reviewerUserId: data['reviewerUserId'] ?? '',
      sourceId: data['sourceId'] ?? '',
      sourceType: data['sourceType'] ?? '',
      stars: data['stars'] ?? 0,
      review: data['review'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'targetUserId': targetUserId,
      'reviewerUserId': reviewerUserId,
      'sourceId': sourceId,
      'sourceType': sourceType,
      'stars': stars,
      'review': review,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

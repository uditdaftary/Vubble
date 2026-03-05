import 'package:cloud_firestore/cloud_firestore.dart';

enum GigCategory { tutoring, delivery, writing, coding, errands, other }

enum GigStatus { open, accepted, inProgress, completedPendingReview, closed, cancelled, reported }

class GigModel {
  final String gigId;
  final String creatorId;
  final String? acceptedById;

  final String title;
  final String description;
  final GigCategory category;
  final double price;
  final DateTime deadline;

  final GigStatus status;

  final double? creatorRating;       // rating given by creator → executor
  final String? creatorReview;
  final double? executorRating;      // rating given by executor → creator
  final String? executorReview;

  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? closedAt;

  GigModel({
    required this.gigId,
    required this.creatorId,
    this.acceptedById,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.deadline,
    this.status = GigStatus.open,
    this.creatorRating,
    this.creatorReview,
    this.executorRating,
    this.executorReview,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.closedAt,
  });

  bool get isExpired =>
      status == GigStatus.open && DateTime.now().isAfter(deadline);

  bool get hasExecutor => acceptedById != null;

  // ── Firestore serialization ──────────────────────────────────────────────

  factory GigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GigModel(
      gigId: doc.id,
      creatorId: data['creatorId'] ?? '',
      acceptedById: data['acceptedById'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: GigCategory.values.firstWhere(
        (c) => c.name == (data['category'] ?? 'other'),
        orElse: () => GigCategory.other,
      ),
      price: (data['price'] ?? 0.0).toDouble(),
      deadline: (data['deadline'] as Timestamp).toDate(),
      status: GigStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'open'),
        orElse: () => GigStatus.open,
      ),
      creatorRating: data['creatorRating']?.toDouble(),
      creatorReview: data['creatorReview'],
      executorRating: data['executorRating']?.toDouble(),
      executorReview: data['executorReview'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      closedAt: data['closedAt'] != null
          ? (data['closedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'acceptedById': acceptedById,
      'title': title,
      'description': description,
      'category': category.name,
      'price': price,
      'deadline': Timestamp.fromDate(deadline),
      'status': status.name,
      'creatorRating': creatorRating,
      'creatorReview': creatorReview,
      'executorRating': executorRating,
      'executorReview': executorReview,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    };
  }

  GigModel copyWith({
    String? acceptedById,
    GigStatus? status,
    double? creatorRating,
    String? creatorReview,
    double? executorRating,
    String? executorReview,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? closedAt,
  }) {
    return GigModel(
      gigId: gigId,
      creatorId: creatorId,
      acceptedById: acceptedById ?? this.acceptedById,
      title: title,
      description: description,
      category: category,
      price: price,
      deadline: deadline,
      status: status ?? this.status,
      creatorRating: creatorRating ?? this.creatorRating,
      creatorReview: creatorReview ?? this.creatorReview,
      executorRating: executorRating ?? this.executorRating,
      executorReview: executorReview ?? this.executorReview,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

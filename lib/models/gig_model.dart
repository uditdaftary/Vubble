import 'package:cloud_firestore/cloud_firestore.dart';

enum GigStatus {
  open,
  accepted,
  inProgress,
  completedPendingReview,
  closed,
  cancelled,
  reported,
}

enum GigCategory { tutoring, delivery, writing, coding, errands, other }

extension GigStatusLabel on GigStatus {
  String get label {
    switch (this) {
      case GigStatus.open:
        return 'OPEN';
      case GigStatus.accepted:
        return 'ACCEPTED';
      case GigStatus.inProgress:
        return 'IN PROGRESS';
      case GigStatus.completedPendingReview:
        return 'PENDING REVIEW';
      case GigStatus.closed:
        return 'CLOSED';
      case GigStatus.cancelled:
        return 'CANCELLED';
      case GigStatus.reported:
        return 'REPORTED';
    }
  }

  String get firestoreValue {
    switch (this) {
      case GigStatus.open:
        return 'open';
      case GigStatus.accepted:
        return 'accepted';
      case GigStatus.inProgress:
        return 'inProgress';
      case GigStatus.completedPendingReview:
        return 'completedPendingReview';
      case GigStatus.closed:
        return 'closed';
      case GigStatus.cancelled:
        return 'cancelled';
      case GigStatus.reported:
        return 'reported';
    }
  }
}

extension GigCategoryLabel on GigCategory {
  String get label {
    switch (this) {
      case GigCategory.tutoring:
        return 'Tutoring';
      case GigCategory.delivery:
        return 'Delivery';
      case GigCategory.writing:
        return 'Writing';
      case GigCategory.coding:
        return 'Coding';
      case GigCategory.errands:
        return 'Errands';
      case GigCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case GigCategory.tutoring:
        return '📚';
      case GigCategory.delivery:
        return '🚚';
      case GigCategory.writing:
        return '✍️';
      case GigCategory.coding:
        return '💻';
      case GigCategory.errands:
        return '🏃';
      case GigCategory.other:
        return '⚡';
    }
  }
}

class GigModel {
  final String gigId;
  final String title;
  final String description;
  final GigCategory category;
  final int price;
  final DateTime deadline;

  // Participants
  final String creatorId;
  final String creatorName;
  final double creatorRating;
  final String? acceptedById;
  final String? acceptedByName;

  // State
  final GigStatus status;

  // Timestamps
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? closedAt;

  // Review
  final bool creatorRated;
  final bool executorRated;

  // Application tracking (REQ-01)
  final int applicationCount;

  // Early completion (REQ-12)
  final bool earlyCompletionRequested;

  const GigModel({
    required this.gigId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.deadline,
    required this.creatorId,
    required this.creatorName,
    this.creatorRating = 0.0,
    this.acceptedById,
    this.acceptedByName,
    this.status = GigStatus.open,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.closedAt,
    this.creatorRated = false,
    this.executorRated = false,
    this.applicationCount = 0,
    this.earlyCompletionRequested = false,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool get isOpen => status == GigStatus.open;
  bool get isAccepted => status == GigStatus.accepted;
  bool get isInProgress => status == GigStatus.inProgress;
  bool get isPending => status == GigStatus.completedPendingReview;
  bool get isClosed => status == GigStatus.closed;
  bool get isCancelled => status == GigStatus.cancelled;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get deadlineFormatted =>
      '${deadline.day}/${deadline.month}/${deadline.year}';

  bool get isOverdue =>
      DateTime.now().isAfter(deadline) && !isClosed && !isCancelled;

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory GigModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GigModel(
      gigId: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: GigCategory.values.firstWhere(
        (c) => c.name == (d['category'] ?? 'other'),
        orElse: () => GigCategory.other,
      ),
      price: (d['price'] ?? 0) as int,
      deadline: (d['deadline'] as Timestamp).toDate(),
      creatorId: d['creatorId'] ?? '',
      creatorName: d['creatorName'] ?? '',
      creatorRating: (d['creatorRating'] ?? 0.0).toDouble(),
      acceptedById: d['acceptedById'],
      acceptedByName: d['acceptedByName'],
      status: GigStatus.values.firstWhere(
        (s) => s.firestoreValue == (d['status'] ?? 'open'),
        orElse: () => GigStatus.open,
      ),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      acceptedAt: d['acceptedAt'] != null
          ? (d['acceptedAt'] as Timestamp).toDate()
          : null,
      startedAt: d['startedAt'] != null
          ? (d['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: d['completedAt'] != null
          ? (d['completedAt'] as Timestamp).toDate()
          : null,
      closedAt: d['closedAt'] != null
          ? (d['closedAt'] as Timestamp).toDate()
          : null,
      creatorRated: d['creatorRated'] ?? false,
      executorRated: d['executorRated'] ?? false,
      applicationCount: (d['applicationCount'] ?? 0) as int,
      earlyCompletionRequested: d['earlyCompletionRequested'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'category': category.name,
    'price': price,
    'deadline': Timestamp.fromDate(deadline),
    'creatorId': creatorId,
    'creatorName': creatorName,
    'creatorRating': creatorRating,
    'acceptedById': acceptedById,
    'acceptedByName': acceptedByName,
    'status': status.firestoreValue,
    'createdAt': Timestamp.fromDate(createdAt),
    'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
    'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    'creatorRated': creatorRated,
    'executorRated': executorRated,
    'applicationCount': applicationCount,
    'earlyCompletionRequested': earlyCompletionRequested,
  };

  GigModel copyWith({
    String? title,
    String? description,
    GigCategory? category,
    int? price,
    DateTime? deadline,
    String? acceptedById,
    String? acceptedByName,
    GigStatus? status,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? closedAt,
    bool? creatorRated,
    bool? executorRated,
    int? applicationCount,
    bool? earlyCompletionRequested,
  }) {
    return GigModel(
      gigId: gigId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      deadline: deadline ?? this.deadline,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorRating: creatorRating,
      acceptedById: acceptedById ?? this.acceptedById,
      acceptedByName: acceptedByName ?? this.acceptedByName,
      status: status ?? this.status,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      closedAt: closedAt ?? this.closedAt,
      creatorRated: creatorRated ?? this.creatorRated,
      executorRated: executorRated ?? this.executorRated,
      applicationCount: applicationCount ?? this.applicationCount,
      earlyCompletionRequested:
          earlyCompletionRequested ?? this.earlyCompletionRequested,
    );
  }
}

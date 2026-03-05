import 'package:cloud_firestore/cloud_firestore.dart';

enum RentalStatus {
  available,
  requested,
  active,
  returnPending,
  completed,
  disputed,
  cancelled,
}

class RentalListingModel {
  final String listingId;
  final String ownerId;

  final String itemName;
  final String description;
  final double dailyRate;
  final double? depositAmount;
  final String? itemPhotoUrl;

  final DateTime availableFrom;
  final DateTime availableTo;

  final RentalStatus status;

  final DateTime createdAt;

  RentalListingModel({
    required this.listingId,
    required this.ownerId,
    required this.itemName,
    required this.description,
    required this.dailyRate,
    this.depositAmount,
    this.itemPhotoUrl,
    required this.availableFrom,
    required this.availableTo,
    this.status = RentalStatus.available,
    required this.createdAt,
  });

  bool get isAvailable => status == RentalStatus.available;

  factory RentalListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalListingModel(
      listingId: doc.id,
      ownerId: data['ownerId'] ?? '',
      itemName: data['itemName'] ?? '',
      description: data['description'] ?? '',
      dailyRate: (data['dailyRate'] ?? 0.0).toDouble(),
      depositAmount: data['depositAmount']?.toDouble(),
      itemPhotoUrl: data['itemPhotoUrl'],
      availableFrom: (data['availableFrom'] as Timestamp).toDate(),
      availableTo: (data['availableTo'] as Timestamp).toDate(),
      status: RentalStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'available'),
        orElse: () => RentalStatus.available,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'itemName': itemName,
      'description': description,
      'dailyRate': dailyRate,
      'depositAmount': depositAmount,
      'itemPhotoUrl': itemPhotoUrl,
      'availableFrom': Timestamp.fromDate(availableFrom),
      'availableTo': Timestamp.fromDate(availableTo),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RentalListingModel copyWith({
    String? itemName,
    String? description,
    double? dailyRate,
    double? depositAmount,
    String? itemPhotoUrl,
    DateTime? availableFrom,
    DateTime? availableTo,
    RentalStatus? status,
  }) {
    return RentalListingModel(
      listingId: listingId,
      ownerId: ownerId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      dailyRate: dailyRate ?? this.dailyRate,
      depositAmount: depositAmount ?? this.depositAmount,
      itemPhotoUrl: itemPhotoUrl ?? this.itemPhotoUrl,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

// ── Rental Request (a specific booking against a listing) ──────────────────

class RentalRequestModel {
  final String requestId;
  final String listingId;
  final String renterId;
  final String ownerId;

  final DateTime startDate;
  final DateTime endDate;
  final double totalCost;
  final double? depositAmount;

  final RentalStatus status;

  final double? ownerRating;
  final String? ownerReview;
  final double? renterRating;
  final String? renterReview;

  final String? disputeReason;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? returnedAt;
  final DateTime? completedAt;

  RentalRequestModel({
    required this.requestId,
    required this.listingId,
    required this.renterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.totalCost,
    this.depositAmount,
    this.status = RentalStatus.requested,
    this.ownerRating,
    this.ownerReview,
    this.renterRating,
    this.renterReview,
    this.disputeReason,
    required this.createdAt,
    this.approvedAt,
    this.returnedAt,
    this.completedAt,
  });

  int get rentalDays => endDate.difference(startDate).inDays;

  bool get isLate =>
      status == RentalStatus.active && DateTime.now().isAfter(endDate);

  factory RentalRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalRequestModel(
      requestId: doc.id,
      listingId: data['listingId'] ?? '',
      renterId: data['renterId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalCost: (data['totalCost'] ?? 0.0).toDouble(),
      depositAmount: data['depositAmount']?.toDouble(),
      status: RentalStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'requested'),
        orElse: () => RentalStatus.requested,
      ),
      ownerRating: data['ownerRating']?.toDouble(),
      ownerReview: data['ownerReview'],
      renterRating: data['renterRating']?.toDouble(),
      renterReview: data['renterReview'],
      disputeReason: data['disputeReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      returnedAt: data['returnedAt'] != null
          ? (data['returnedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'renterId': renterId,
      'ownerId': ownerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalCost': totalCost,
      'depositAmount': depositAmount,
      'status': status.name,
      'ownerRating': ownerRating,
      'ownerReview': ownerReview,
      'renterRating': renterRating,
      'renterReview': renterReview,
      'disputeReason': disputeReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  RentalRequestModel copyWith({
    RentalStatus? status,
    double? ownerRating,
    String? ownerReview,
    double? renterRating,
    String? renterReview,
    String? disputeReason,
    DateTime? approvedAt,
    DateTime? returnedAt,
    DateTime? completedAt,
  }) {
    return RentalRequestModel(
      requestId: requestId,
      listingId: listingId,
      renterId: renterId,
      ownerId: ownerId,
      startDate: startDate,
      endDate: endDate,
      totalCost: totalCost,
      depositAmount: depositAmount,
      status: status ?? this.status,
      ownerRating: ownerRating ?? this.ownerRating,
      ownerReview: ownerReview ?? this.ownerReview,
      renterRating: renterRating ?? this.renterRating,
      renterReview: renterReview ?? this.renterReview,
      disputeReason: disputeReason ?? this.disputeReason,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      returnedAt: returnedAt ?? this.returnedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

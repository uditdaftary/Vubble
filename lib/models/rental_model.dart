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

enum RentalCategory { electronics, labGear, books, sports, clothing, other }

extension RentalStatusLabel on RentalStatus {
  String get label {
    switch (this) {
      case RentalStatus.available:
        return 'AVAILABLE';
      case RentalStatus.requested:
        return 'REQUESTED';
      case RentalStatus.active:
        return 'ACTIVE';
      case RentalStatus.returnPending:
        return 'RETURN PENDING';
      case RentalStatus.completed:
        return 'COMPLETED';
      case RentalStatus.disputed:
        return 'DISPUTED';
      case RentalStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get firestoreValue {
    switch (this) {
      case RentalStatus.available:
        return 'available';
      case RentalStatus.requested:
        return 'requested';
      case RentalStatus.active:
        return 'active';
      case RentalStatus.returnPending:
        return 'returnPending';
      case RentalStatus.completed:
        return 'completed';
      case RentalStatus.disputed:
        return 'disputed';
      case RentalStatus.cancelled:
        return 'cancelled';
    }
  }
}

extension RentalCategoryLabel on RentalCategory {
  String get label {
    switch (this) {
      case RentalCategory.electronics:
        return 'Electronics';
      case RentalCategory.labGear:
        return 'Lab Gear';
      case RentalCategory.books:
        return 'Books';
      case RentalCategory.sports:
        return 'Sports';
      case RentalCategory.clothing:
        return 'Clothing';
      case RentalCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case RentalCategory.electronics:
        return '📷';
      case RentalCategory.labGear:
        return '🔬';
      case RentalCategory.books:
        return '📖';
      case RentalCategory.sports:
        return '⚽';
      case RentalCategory.clothing:
        return '🥼';
      case RentalCategory.other:
        return '📦';
    }
  }
}

class RentalModel {
  final String rentalId;
  final String itemName;
  final String description;
  final RentalCategory category;
  final int dailyRate;
  final int deposit;

  // Availability window
  final DateTime availableFrom;
  final DateTime availableTo;

  // Owner
  final String ownerId;
  final String ownerName;
  final double ownerRating;

  // Renter (set once requested)
  final String? renterId;
  final String? renterName;

  // Rental period (set once active)
  final DateTime? rentalStart;
  final DateTime? rentalEnd;

  // State
  final RentalStatus status;

  // Computed
  final int totalRentals;

  // Timestamps
  final DateTime createdAt;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? returnRequestedAt;
  final DateTime? returnConfirmedAt;

  // Review flags
  final bool ownerRated;
  final bool renterRated;

  // Application tracking (REQ-01)
  final int applicationCount;

  // Handoff confirmation (REQ-03)
  final bool itemHandedOver;
  final bool itemReceived;

  // Early return (REQ-12)
  final bool earlyReturnRequested;
  final DateTime? actualReturnDate;

  const RentalModel({
    required this.rentalId,
    required this.itemName,
    required this.description,
    required this.category,
    required this.dailyRate,
    this.deposit = 0,
    required this.availableFrom,
    required this.availableTo,
    required this.ownerId,
    required this.ownerName,
    this.ownerRating = 0.0,
    this.renterId,
    this.renterName,
    this.rentalStart,
    this.rentalEnd,
    this.status = RentalStatus.available,
    this.totalRentals = 0,
    required this.createdAt,
    this.requestedAt,
    this.approvedAt,
    this.returnRequestedAt,
    this.returnConfirmedAt,
    this.ownerRated = false,
    this.renterRated = false,
    this.applicationCount = 0,
    this.itemHandedOver = false,
    this.itemReceived = false,
    this.earlyReturnRequested = false,
    this.actualReturnDate,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get isAvailable => status == RentalStatus.available;
  bool get isRequested => status == RentalStatus.requested;
  bool get isActive => status == RentalStatus.active;
  bool get isReturnPending => status == RentalStatus.returnPending;
  bool get isCompleted => status == RentalStatus.completed;
  bool get isDisputed => status == RentalStatus.disputed;

  int get rentalDays {
    if (rentalStart == null || rentalEnd == null) return 0;
    final days = rentalEnd!.difference(rentalStart!).inDays + 1;
    return days < 1 ? 1 : days;
  }

  int get totalCost => (rentalDays * dailyRate) + deposit;

  int get daysRemaining {
    if (rentalEnd == null) return 0;
    final remaining = rentalEnd!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isOverdue =>
      rentalEnd != null && DateTime.now().isAfter(rentalEnd!) && isActive;

  String get availabilityFormatted =>
      '${availableFrom.day}/${availableFrom.month} → ${availableTo.day}/${availableTo.month}';

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory RentalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RentalModel(
      rentalId: doc.id,
      itemName: d['itemName'] ?? '',
      description: d['description'] ?? '',
      category: RentalCategory.values.firstWhere(
        (c) => c.name == (d['category'] ?? 'other'),
        orElse: () => RentalCategory.other,
      ),
      dailyRate: (d['dailyRate'] ?? 0) as int,
      deposit: (d['deposit'] ?? 0) as int,
      availableFrom: (d['availableFrom'] as Timestamp).toDate(),
      availableTo: (d['availableTo'] as Timestamp).toDate(),
      ownerId: d['ownerId'] ?? '',
      ownerName: d['ownerName'] ?? '',
      ownerRating: (d['ownerRating'] ?? 0.0).toDouble(),
      renterId: d['renterId'],
      renterName: d['renterName'],
      rentalStart: d['rentalStart'] != null
          ? (d['rentalStart'] as Timestamp).toDate()
          : null,
      rentalEnd: d['rentalEnd'] != null
          ? (d['rentalEnd'] as Timestamp).toDate()
          : null,
      status: RentalStatus.values.firstWhere(
        (s) => s.firestoreValue == (d['status'] ?? 'available'),
        orElse: () => RentalStatus.available,
      ),
      totalRentals: (d['totalRentals'] ?? 0) as int,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      requestedAt: d['requestedAt'] != null
          ? (d['requestedAt'] as Timestamp).toDate()
          : null,
      approvedAt: d['approvedAt'] != null
          ? (d['approvedAt'] as Timestamp).toDate()
          : null,
      returnRequestedAt: d['returnRequestedAt'] != null
          ? (d['returnRequestedAt'] as Timestamp).toDate()
          : null,
      returnConfirmedAt: d['returnConfirmedAt'] != null
          ? (d['returnConfirmedAt'] as Timestamp).toDate()
          : null,
      ownerRated: d['ownerRated'] ?? false,
      renterRated: d['renterRated'] ?? false,
      applicationCount: (d['applicationCount'] ?? 0) as int,
      itemHandedOver: d['itemHandedOver'] ?? false,
      itemReceived: d['itemReceived'] ?? false,
      earlyReturnRequested: d['earlyReturnRequested'] ?? false,
      actualReturnDate: d['actualReturnDate'] != null
          ? (d['actualReturnDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'itemName': itemName,
    'description': description,
    'category': category.name,
    'dailyRate': dailyRate,
    'deposit': deposit,
    'availableFrom': Timestamp.fromDate(availableFrom),
    'availableTo': Timestamp.fromDate(availableTo),
    'ownerId': ownerId,
    'ownerName': ownerName,
    'ownerRating': ownerRating,
    'renterId': renterId,
    'renterName': renterName,
    'rentalStart': rentalStart != null
        ? Timestamp.fromDate(rentalStart!)
        : null,
    'rentalEnd': rentalEnd != null ? Timestamp.fromDate(rentalEnd!) : null,
    'status': status.firestoreValue,
    'totalRentals': totalRentals,
    'createdAt': Timestamp.fromDate(createdAt),
    'requestedAt': requestedAt != null
        ? Timestamp.fromDate(requestedAt!)
        : null,
    'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    'returnRequestedAt': returnRequestedAt != null
        ? Timestamp.fromDate(returnRequestedAt!)
        : null,
    'returnConfirmedAt': returnConfirmedAt != null
        ? Timestamp.fromDate(returnConfirmedAt!)
        : null,
    'ownerRated': ownerRated,
    'renterRated': renterRated,
    'applicationCount': applicationCount,
    'itemHandedOver': itemHandedOver,
    'itemReceived': itemReceived,
    'earlyReturnRequested': earlyReturnRequested,
    'actualReturnDate': actualReturnDate != null
        ? Timestamp.fromDate(actualReturnDate!)
        : null,
  };

  RentalModel copyWith({
    String? itemName,
    String? description,
    RentalCategory? category,
    int? dailyRate,
    int? deposit,
    DateTime? availableFrom,
    DateTime? availableTo,
    String? renterId,
    String? renterName,
    DateTime? rentalStart,
    DateTime? rentalEnd,
    RentalStatus? status,
    int? totalRentals,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? returnRequestedAt,
    DateTime? returnConfirmedAt,
    bool? ownerRated,
    bool? renterRated,
    int? applicationCount,
    bool? itemHandedOver,
    bool? itemReceived,
    bool? earlyReturnRequested,
    DateTime? actualReturnDate,
  }) {
    return RentalModel(
      rentalId: rentalId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      category: category ?? this.category,
      dailyRate: dailyRate ?? this.dailyRate,
      deposit: deposit ?? this.deposit,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerRating: ownerRating,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      rentalStart: rentalStart ?? this.rentalStart,
      rentalEnd: rentalEnd ?? this.rentalEnd,
      status: status ?? this.status,
      totalRentals: totalRentals ?? this.totalRentals,
      createdAt: createdAt,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      returnRequestedAt: returnRequestedAt ?? this.returnRequestedAt,
      returnConfirmedAt: returnConfirmedAt ?? this.returnConfirmedAt,
      ownerRated: ownerRated ?? this.ownerRated,
      renterRated: renterRated ?? this.renterRated,
      applicationCount: applicationCount ?? this.applicationCount,
      itemHandedOver: itemHandedOver ?? this.itemHandedOver,
      itemReceived: itemReceived ?? this.itemReceived,
      earlyReturnRequested: earlyReturnRequested ?? this.earlyReturnRequested,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
    );
  }
}

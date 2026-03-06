import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_model.dart';

class RentalService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _rentals => _db.collection('rentals');

  // ── Create ────────────────────────────────────────────────────────────────

  Future<String> createListing({
    required String ownerId,
    required String ownerName,
    required double ownerRating,
    required String itemName,
    required String description,
    required RentalCategory category,
    required int dailyRate,
    required int deposit,
    required DateTime availableFrom,
    required DateTime availableTo,
  }) async {
    final ref = _rentals.doc();
    final rental = RentalModel(
      rentalId:      ref.id,
      itemName:      itemName,
      description:   description,
      category:      category,
      dailyRate:     dailyRate,
      deposit:       deposit,
      availableFrom: availableFrom,
      availableTo:   availableTo,
      ownerId:       ownerId,
      ownerName:     ownerName,
      ownerRating:   ownerRating,
      status:        RentalStatus.available,
      createdAt:     DateTime.now(),
    );
    await ref.set(rental.toFirestore());

    await _db.collection('users').doc(ownerId).update({
      'activeRentalIds': FieldValue.arrayUnion([ref.id]),
    });

    return ref.id;
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// All available listings (browse screen)
  Stream<List<RentalModel>> watchAvailableListings() {
    return _rentals
      .where('status', isEqualTo: RentalStatus.available.firestoreValue)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(RentalModel.fromFirestore).toList());
  }

  /// Available listings by category
  Stream<List<RentalModel>> watchListingsByCategory(RentalCategory category) {
    return _rentals
      .where('status',   isEqualTo: RentalStatus.available.firestoreValue)
      .where('category', isEqualTo: category.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(RentalModel.fromFirestore).toList());
  }

  /// Items owned by user (My Listed Items)
  Stream<List<RentalModel>> watchItemsOwnedBy(String userId) {
    return _rentals
      .where('ownerId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(RentalModel.fromFirestore).toList());
  }

  /// Rentals where user is the renter (My Borrowed Items)
  Stream<List<RentalModel>> watchItemsRentedBy(String userId) {
    return _rentals
      .where('renterId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(RentalModel.fromFirestore).toList());
  }

  Future<RentalModel?> fetchRental(String rentalId) async {
    final doc = await _rentals.doc(rentalId).get();
    if (!doc.exists) return null;
    return RentalModel.fromFirestore(doc);
  }

  // ── State transitions ─────────────────────────────────────────────────────

  /// Renter requests a rental
  Future<void> requestRental({
    required String rentalId,
    required String renterId,
    required String renterName,
    required DateTime rentalStart,
    required DateTime rentalEnd,
  }) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    await _rentals.doc(rentalId).update({
      'status':      RentalStatus.requested.firestoreValue,
      'renterId':    renterId,
      'renterName':  renterName,
      'rentalStart': Timestamp.fromDate(rentalStart),
      'rentalEnd':   Timestamp.fromDate(rentalEnd),
      'requestedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _db.collection('users').doc(renterId).update({
      'activeRentalIds': FieldValue.arrayUnion([rentalId]),
    });

    await _sendNotification(
      toUserId: rental.ownerId,
      type:     'rental_requested',
      title:    'Rental Request!',
      body:     '$renterName wants to rent your ${rental.itemName}.',
      targetId: rentalId,
    );
  }

  /// Owner approves the rental request
  Future<void> approveRental(String rentalId) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    await _rentals.doc(rentalId).update({
      'status':     RentalStatus.active.firestoreValue,
      'approvedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _sendNotification(
      toUserId: rental.renterId!,
      type:     'rental_approved',
      title:    'Rental Approved!',
      body:     '${rental.ownerName} approved your request for ${rental.itemName}.',
      targetId: rentalId,
    );
  }

  /// Owner rejects the rental request → item goes back to available
  Future<void> rejectRental(String rentalId) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    await _rentals.doc(rentalId).update({
      'status':     RentalStatus.available.firestoreValue,
      'renterId':   null,
      'renterName': null,
      'rentalStart': null,
      'rentalEnd':   null,
      'requestedAt': null,
    });

    if (rental.renterId != null) {
      await _db.collection('users').doc(rental.renterId!).update({
        'activeRentalIds': FieldValue.arrayRemove([rentalId]),
      });

      await _sendNotification(
        toUserId: rental.renterId!,
        type:     'rental_rejected',
        title:    'Rental Request Declined',
        body:     '${rental.ownerName} declined your request for ${rental.itemName}.',
        targetId: rentalId,
      );
    }
  }

  /// Renter marks the item as returned
  Future<void> markReturnRequested(String rentalId) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    await _rentals.doc(rentalId).update({
      'status':            RentalStatus.returnPending.firestoreValue,
      'returnRequestedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _sendNotification(
      toUserId: rental.ownerId,
      type:     'return_pending',
      title:    'Item Return Initiated',
      body:     '${rental.renterName} has marked ${rental.itemName} as returned. Please confirm.',
      targetId: rentalId,
    );
  }

  /// Owner confirms they received the item back
  Future<void> confirmReturn(String rentalId) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    await _rentals.doc(rentalId).update({
      'status':            RentalStatus.completed.firestoreValue,
      'returnConfirmedAt': Timestamp.fromDate(DateTime.now()),
      'totalRentals':      FieldValue.increment(1),
    });

    final batch = _db.batch();
    final ownerRef  = _db.collection('users').doc(rental.ownerId);
    final renterRef = _db.collection('users').doc(rental.renterId!);
    batch.update(ownerRef, {
      'activeRentalIds':    FieldValue.arrayRemove([rentalId]),
      'completedRentals':   FieldValue.increment(1),
    });
    batch.update(renterRef, {
      'activeRentalIds':    FieldValue.arrayRemove([rentalId]),
      'completedRentals':   FieldValue.increment(1),
    });
    await batch.commit();

    await _sendNotification(
      toUserId: rental.renterId!,
      type:     'rental_completed',
      title:    'Return Confirmed!',
      body:     '${rental.ownerName} confirmed return of ${rental.itemName}.',
      targetId: rentalId,
    );
  }

  /// Raise a dispute (either party)
  Future<void> raiseDispute({
    required String rentalId,
    required String reporterId,
    required String reason,
  }) async {
    final batch = _db.batch();
    batch.update(_rentals.doc(rentalId), {
      'status': RentalStatus.disputed.firestoreValue,
    });
    final reportRef = _db.collection('reports').doc();
    batch.set(reportRef, {
      'reportId':   reportRef.id,
      'reporterId': reporterId,
      'targetId':   rentalId,
      'targetType': 'rental',
      'reason':     reason,
      'status':     'open',
      'createdAt':  Timestamp.fromDate(DateTime.now()),
    });
    await batch.commit();
  }

  /// Cancel a listing (owner, before any request)
  Future<void> cancelListing(String rentalId, String ownerId) async {
    await _rentals.doc(rentalId).update({
      'status': RentalStatus.cancelled.firestoreValue,
    });
    await _db.collection('users').doc(ownerId).update({
      'activeRentalIds': FieldValue.arrayRemove([rentalId]),
    });
  }

  /// Flag rental as rated by owner
  Future<void> markOwnerRated(String rentalId) async {
    await _rentals.doc(rentalId).update({'ownerRated': true});
  }

  /// Flag rental as rated by renter
  Future<void> markRenterRated(String rentalId) async {
    await _rentals.doc(rentalId).update({'renterRated': true});
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _sendNotification({
    required String toUserId,
    required String type,
    required String title,
    required String body,
    String? targetId,
  }) async {
    final ref = _db
      .collection('notifications')
      .doc(toUserId)
      .collection('items')
      .doc();
    await ref.set({
      'id':        ref.id,
      'type':      type,
      'title':     title,
      'body':      body,
      'targetId':  targetId,
      'isRead':    false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
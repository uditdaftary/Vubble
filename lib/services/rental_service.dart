import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_model.dart';
import '../models/application_model.dart';

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
      rentalId: ref.id,
      itemName: itemName,
      description: description,
      category: category,
      dailyRate: dailyRate,
      deposit: deposit,
      availableFrom: availableFrom,
      availableTo: availableTo,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerRating: ownerRating,
      status: RentalStatus.available,
      createdAt: DateTime.now(),
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
        .where('status', isEqualTo: RentalStatus.available.firestoreValue)
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

  /// Renter requests a rental (legacy — kept for compatibility)
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
      'status': RentalStatus.requested.firestoreValue,
      'renterId': renterId,
      'renterName': renterName,
      'rentalStart': Timestamp.fromDate(rentalStart),
      'rentalEnd': Timestamp.fromDate(rentalEnd),
      'requestedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _db.collection('users').doc(renterId).update({
      'activeRentalIds': FieldValue.arrayUnion([rentalId]),
    });
  }

  /// Owner approves the rental request
  Future<void> approveRental(String rentalId) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    await _rentals.doc(rentalId).update({
      'status': RentalStatus.active.firestoreValue,
      'approvedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Owner rejects the rental request → item goes back to available
  Future<void> rejectRental(String rentalId) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    await _rentals.doc(rentalId).update({
      'status': RentalStatus.available.firestoreValue,
      'renterId': null,
      'renterName': null,
      'rentalStart': null,
      'rentalEnd': null,
      'requestedAt': null,
    });

    if (rental.renterId != null) {
      await _db.collection('users').doc(rental.renterId!).update({
        'activeRentalIds': FieldValue.arrayRemove([rentalId]),
      });
    }
  }

  /// Renter marks the item as returned
  Future<void> markReturnRequested(String rentalId) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    await _rentals.doc(rentalId).update({
      'status': RentalStatus.returnPending.firestoreValue,
      'returnRequestedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Owner confirms they received the item back
  Future<void> confirmReturn(String rentalId) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    await _rentals.doc(rentalId).update({
      'status': RentalStatus.completed.firestoreValue,
      'returnConfirmedAt': Timestamp.fromDate(DateTime.now()),
      'totalRentals': FieldValue.increment(1),
      'ownerRated': false,
      'renterRated': false,
    });

    final batch = _db.batch();
    final ownerRef = _db.collection('users').doc(rental.ownerId);
    final renterRef = _db.collection('users').doc(rental.renterId!);
    batch.update(ownerRef, {
      'activeRentalIds': FieldValue.arrayRemove([rentalId]),
      'completedRentals': FieldValue.increment(1),
      'totalCompleted': FieldValue.increment(1),
    });
    batch.update(renterRef, {
      'activeRentalIds': FieldValue.arrayRemove([rentalId]),
      'completedRentals': FieldValue.increment(1),
      'totalCompleted': FieldValue.increment(1),
    });
    await batch.commit();
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
      'reportId': reportRef.id,
      'reporterId': reporterId,
      'targetId': rentalId,
      'targetType': 'rental',
      'reason': reason,
      'status': 'open',
      'createdAt': Timestamp.fromDate(DateTime.now()),
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

    // Reject all pending applications
    await _rejectAllApplications(rentalId);
  }

  /// Flag rental as rated by owner
  Future<void> markOwnerRated(String rentalId) async {
    await _rentals.doc(rentalId).update({'ownerRated': true});
  }

  /// Flag rental as rated by renter
  Future<void> markRenterRated(String rentalId) async {
    await _rentals.doc(rentalId).update({'renterRated': true});
  }

  // ── Applications (REQ-01) ─────────────────────────────────────────────────

  /// Apply to a rental with a message
  Future<void> applyToRental({
    required String rentalId,
    required String userId,
    required String userName,
    required double userRating,
    required String message,
  }) async {
    final appRef = _rentals
        .doc(rentalId)
        .collection('applications')
        .doc(userId);
    final application = ApplicationModel(
      applicantId: userId,
      applicantName: userName,
      applicantRating: userRating,
      message: message,
      appliedAt: DateTime.now(),
      status: 'pending',
    );

    final batch = _db.batch();
    batch.set(appRef, application.toFirestore());
    batch.update(_rentals.doc(rentalId), {
      'applicationCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Check if a user has already applied to a rental
  Future<bool> hasUserAppliedToRental(String rentalId, String userId) async {
    final doc = await _rentals
        .doc(rentalId)
        .collection('applications')
        .doc(userId)
        .get();
    return doc.exists;
  }

  /// Watch all applications for a rental
  Stream<List<ApplicationModel>> watchRentalApplications(String rentalId) {
    return _rentals
        .doc(rentalId)
        .collection('applications')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ApplicationModel.fromFirestore).toList());
  }

  /// Owner selects an applicant for the rental
  Future<void> selectRentalApplicant({
    required String rentalId,
    required String applicantUserId,
    required DateTime rentalStart,
    required DateTime rentalEnd,
  }) async {
    // Get the selected applicant's data
    final appDoc = await _rentals
        .doc(rentalId)
        .collection('applications')
        .doc(applicantUserId)
        .get();
    if (!appDoc.exists) throw Exception('Applicant not found');
    final applicant = ApplicationModel.fromFirestore(appDoc);

    // Get all applications
    final allApps = await _rentals
        .doc(rentalId)
        .collection('applications')
        .get();

    final batch = _db.batch();

    // Update rental: set renterId, status → active (skipping requested), reset applicationCount
    batch.update(_rentals.doc(rentalId), {
      'status': RentalStatus.active.firestoreValue,
      'renterId': applicantUserId,
      'renterName': applicant.applicantName,
      'rentalStart': Timestamp.fromDate(rentalStart),
      'rentalEnd': Timestamp.fromDate(rentalEnd),
      'approvedAt': Timestamp.fromDate(DateTime.now()),
      'applicationCount': 0,
    });

    // Mark selected application as accepted, all others as rejected
    for (final doc in allApps.docs) {
      batch.update(doc.reference, {
        'status': doc.id == applicantUserId ? 'accepted' : 'rejected',
      });
    }

    await batch.commit();

    // Add rental to renter's activeRentalIds
    await _db.collection('users').doc(applicantUserId).update({
      'activeRentalIds': FieldValue.arrayUnion([rentalId]),
    });
  }

  // ── Handoff Confirmation (REQ-03) ─────────────────────────────────────────

  /// Owner marks item as handed over
  Future<void> markItemGiven(String rentalId) async {
    await _rentals.doc(rentalId).update({'itemHandedOver': true});
  }

  /// Renter confirms they received the item
  Future<void> confirmItemReceived(String rentalId) async {
    await _rentals.doc(rentalId).update({'itemReceived': true});
  }

  // ── Early Return (REQ-12) ─────────────────────────────────────────────────

  /// Renter requests early return
  Future<void> requestEarlyReturn(String rentalId) async {
    await _rentals.doc(rentalId).update({'earlyReturnRequested': true});
  }

  /// Owner approves early return → recalculate cost, transition to returnPending
  Future<void> approveEarlyReturn(String rentalId) async {
    final rental = await fetchRental(rentalId);
    if (rental == null) return;

    final now = DateTime.now();

    await _rentals.doc(rentalId).update({
      'status': RentalStatus.returnPending.firestoreValue,
      'actualReturnDate': Timestamp.fromDate(now),
      'earlyReturnRequested': false,
      'returnRequestedAt': Timestamp.fromDate(now),
    });
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Reject all pending applications for a rental
  Future<void> _rejectAllApplications(String rentalId) async {
    final apps = await _rentals
        .doc(rentalId)
        .collection('applications')
        .where('status', isEqualTo: 'pending')
        .get();

    if (apps.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in apps.docs) {
      batch.update(doc.reference, {'status': 'rejected'});
    }
    batch.update(_rentals.doc(rentalId), {'applicationCount': 0});
    await batch.commit();
  }
}

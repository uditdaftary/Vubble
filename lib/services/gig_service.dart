import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gig_model.dart';
import '../models/application_model.dart';

class GigService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _gigs => _db.collection('gigs');

  // ── Create ────────────────────────────────────────────────────────────────

  Future<String> createGig({
    required String creatorId,
    required String creatorName,
    required double creatorRating,
    required String title,
    required String description,
    required GigCategory category,
    required int price,
    required DateTime deadline,
  }) async {
    final ref = _gigs.doc();
    final gig = GigModel(
      gigId: ref.id,
      title: title,
      description: description,
      category: category,
      price: price,
      deadline: deadline,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorRating: creatorRating,
      status: GigStatus.open,
      createdAt: DateTime.now(),
    );
    await ref.set(gig.toFirestore());

    // Add to creator's activeGigIds
    await _db.collection('users').doc(creatorId).update({
      'activeGigIds': FieldValue.arrayUnion([ref.id]),
    });

    return ref.id;
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// All open gigs (for browse screen)
  Stream<List<GigModel>> watchOpenGigs() {
    return _gigs
        .where('status', isEqualTo: GigStatus.open.firestoreValue)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(GigModel.fromFirestore).toList());
  }

  /// Open gigs filtered by category
  Stream<List<GigModel>> watchOpenGigsByCategory(GigCategory category) {
    return _gigs
        .where('status', isEqualTo: GigStatus.open.firestoreValue)
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(GigModel.fromFirestore).toList());
  }

  /// Gigs created by a user (My Posted Gigs)
  Stream<List<GigModel>> watchGigsPostedBy(String userId) {
    return _gigs
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(GigModel.fromFirestore).toList());
  }

  /// Gigs accepted/being executed by a user (My Accepted Gigs)
  Stream<List<GigModel>> watchGigsAcceptedBy(String userId) {
    return _gigs
        .where('acceptedById', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(GigModel.fromFirestore).toList());
  }

  Future<GigModel?> fetchGig(String gigId) async {
    final doc = await _gigs.doc(gigId).get();
    if (!doc.exists) return null;
    return GigModel.fromFirestore(doc);
  }

  // ── State transitions ─────────────────────────────────────────────────────

  /// Executor accepts an open gig (legacy — kept for compatibility)
  Future<void> acceptGig({
    required String gigId,
    required String executorId,
    required String executorName,
  }) async {
    await _gigs.doc(gigId).update({
      'status': GigStatus.accepted.firestoreValue,
      'acceptedById': executorId,
      'acceptedByName': executorName,
      'acceptedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _db.collection('users').doc(executorId).update({
      'activeGigIds': FieldValue.arrayUnion([gigId]),
    });
  }

  /// Executor marks gig as started
  Future<void> markStarted(String gigId) async {
    await _gigs.doc(gigId).update({
      'status': GigStatus.inProgress.firestoreValue,
      'startedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Executor marks gig as complete (moves to pending review)
  Future<void> markComplete(String gigId) async {
    final gig = await fetchGig(gigId);
    if (gig == null) return;

    await _gigs.doc(gigId).update({
      'status': GigStatus.completedPendingReview.firestoreValue,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Creator closes the gig after review
  Future<void> closeGig(String gigId) async {
    await _gigs.doc(gigId).update({
      'status': GigStatus.closed.firestoreValue,
      'closedAt': Timestamp.fromDate(DateTime.now()),
      'creatorRated': false,
      'executorRated': false,
    });

    final gig = await fetchGig(gigId);
    if (gig == null) return;

    // Remove from both users' activeGigIds, increment completedGigs + totalCompleted
    final batch = _db.batch();
    final creatorRef = _db.collection('users').doc(gig.creatorId);
    final executorRef = _db.collection('users').doc(gig.acceptedById!);
    batch.update(creatorRef, {
      'activeGigIds': FieldValue.arrayRemove([gigId]),
      'completedGigs': FieldValue.increment(1),
      'totalCompleted': FieldValue.increment(1),
    });
    batch.update(executorRef, {
      'activeGigIds': FieldValue.arrayRemove([gigId]),
      'completedGigs': FieldValue.increment(1),
      'totalCompleted': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Cancel a gig (before acceptance — creator only)
  Future<void> cancelGig(String gigId, String userId) async {
    await _gigs.doc(gigId).update({
      'status': GigStatus.cancelled.firestoreValue,
    });
    await _db.collection('users').doc(userId).update({
      'activeGigIds': FieldValue.arrayRemove([gigId]),
      'cancellations': FieldValue.increment(1),
    });

    // Reject all pending applications
    await _rejectAllApplications(gigId);
  }

  /// Flag gig as reviewed by creator (after rating)
  Future<void> markCreatorRated(String gigId) async {
    await _gigs.doc(gigId).update({'creatorRated': true});
  }

  /// Flag gig as reviewed by executor (after rating)
  Future<void> markExecutorRated(String gigId) async {
    await _gigs.doc(gigId).update({'executorRated': true});
  }

  // ── Applications (REQ-01) ─────────────────────────────────────────────────

  /// Apply to a gig with a message
  Future<void> applyToGig({
    required String gigId,
    required String userId,
    required String userName,
    required double userRating,
    required String message,
  }) async {
    final appRef = _gigs.doc(gigId).collection('applications').doc(userId);
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
    batch.update(_gigs.doc(gigId), {
      'applicationCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Check if a user has already applied to a gig
  Future<bool> hasUserApplied(String gigId, String userId) async {
    final doc = await _gigs
        .doc(gigId)
        .collection('applications')
        .doc(userId)
        .get();
    return doc.exists;
  }

  /// Watch all applications for a gig
  Stream<List<ApplicationModel>> watchApplications(String gigId) {
    return _gigs
        .doc(gigId)
        .collection('applications')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ApplicationModel.fromFirestore).toList());
  }

  /// Creator selects an applicant for the gig
  Future<void> selectApplicant({
    required String gigId,
    required String applicantUserId,
  }) async {
    // Get the selected applicant's data
    final appDoc = await _gigs
        .doc(gigId)
        .collection('applications')
        .doc(applicantUserId)
        .get();
    if (!appDoc.exists) throw Exception('Applicant not found');
    final applicant = ApplicationModel.fromFirestore(appDoc);

    // Get all applications
    final allApps = await _gigs.doc(gigId).collection('applications').get();

    final batch = _db.batch();

    // Update the gig: set acceptedById, status → accepted, reset applicationCount
    batch.update(_gigs.doc(gigId), {
      'status': GigStatus.accepted.firestoreValue,
      'acceptedById': applicantUserId,
      'acceptedByName': applicant.applicantName,
      'acceptedAt': Timestamp.fromDate(DateTime.now()),
      'applicationCount': 0,
    });

    // Mark selected application as accepted, all others as rejected
    for (final doc in allApps.docs) {
      batch.update(doc.reference, {
        'status': doc.id == applicantUserId ? 'accepted' : 'rejected',
      });
    }

    await batch.commit();

    // Add gig to executor's activeGigIds
    await _db.collection('users').doc(applicantUserId).update({
      'activeGigIds': FieldValue.arrayUnion([gigId]),
    });
  }

  // ── Early Completion (REQ-12) ─────────────────────────────────────────────

  /// Executor requests early completion
  Future<void> requestEarlyCompletion(String gigId) async {
    await _gigs.doc(gigId).update({'earlyCompletionRequested': true});
  }

  /// Creator approves early completion (transitions to completedPendingReview)
  Future<void> approveEarlyCompletion(String gigId) async {
    await _gigs.doc(gigId).update({
      'status': GigStatus.completedPendingReview.firestoreValue,
      'completedAt': Timestamp.fromDate(DateTime.now()),
      'earlyCompletionRequested': false,
    });
  }

  // ── Report ────────────────────────────────────────────────────────────────

  Future<void> reportGig({
    required String gigId,
    required String reporterId,
    required String reason,
  }) async {
    final batch = _db.batch();
    // Update gig status
    batch.update(_gigs.doc(gigId), {
      'status': GigStatus.reported.firestoreValue,
    });
    // Create report document
    final reportRef = _db.collection('reports').doc();
    batch.set(reportRef, {
      'reportId': reportRef.id,
      'reporterId': reporterId,
      'targetId': gigId,
      'targetType': 'gig',
      'reason': reason,
      'status': 'open',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    await batch.commit();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Reject all pending applications for a gig (used by cancelGig + deadline expiry)
  Future<void> _rejectAllApplications(String gigId) async {
    final apps = await _gigs
        .doc(gigId)
        .collection('applications')
        .where('status', isEqualTo: 'pending')
        .get();

    if (apps.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in apps.docs) {
      batch.update(doc.reference, {'status': 'rejected'});
    }
    batch.update(_gigs.doc(gigId), {'applicationCount': 0});
    await batch.commit();
  }
}

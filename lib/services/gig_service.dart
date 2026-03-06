import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gig_model.dart';

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
      gigId:         ref.id,
      title:         title,
      description:   description,
      category:      category,
      price:         price,
      deadline:      deadline,
      creatorId:     creatorId,
      creatorName:   creatorName,
      creatorRating: creatorRating,
      status:        GigStatus.open,
      createdAt:     DateTime.now(),
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
      .where('status',   isEqualTo: GigStatus.open.firestoreValue)
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

  /// Executor accepts an open gig
  Future<void> acceptGig({
    required String gigId,
    required String executorId,
    required String executorName,
  }) async {
    await _gigs.doc(gigId).update({
      'status':        GigStatus.accepted.firestoreValue,
      'acceptedById':  executorId,
      'acceptedByName': executorName,
      'acceptedAt':    Timestamp.fromDate(DateTime.now()),
    });

    await _db.collection('users').doc(executorId).update({
      'activeGigIds': FieldValue.arrayUnion([gigId]),
    });

    await _sendNotification(
      toUserId: await _getCreatorId(gigId),
      type:     'gig_accepted',
      title:    'Gig Accepted!',
      body:     '$executorName accepted your gig.',
      targetId: gigId,
    );
  }

  /// Executor marks gig as started
  Future<void> markStarted(String gigId) async {
    await _gigs.doc(gigId).update({
      'status':    GigStatus.inProgress.firestoreValue,
      'startedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Executor marks gig as complete (moves to pending review)
  Future<void> markComplete(String gigId) async {
    final gig = await fetchGig(gigId);
    if (gig == null) return;

    await _gigs.doc(gigId).update({
      'status':      GigStatus.completedPendingReview.firestoreValue,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _sendNotification(
      toUserId: gig.creatorId,
      type:     'gig_completed',
      title:    'Gig marked complete!',
      body:     '${gig.acceptedByName} has marked your gig as done. Please review.',
      targetId: gigId,
    );
  }

  /// Creator closes the gig after review
  Future<void> closeGig(String gigId) async {
    await _gigs.doc(gigId).update({
      'status':   GigStatus.closed.firestoreValue,
      'closedAt': Timestamp.fromDate(DateTime.now()),
    });

    final gig = await fetchGig(gigId);
    if (gig == null) return;

    // Remove from both users' activeGigIds, increment completedGigs
    final batch = _db.batch();
    final creatorRef  = _db.collection('users').doc(gig.creatorId);
    final executorRef = _db.collection('users').doc(gig.acceptedById!);
    batch.update(creatorRef,  {
      'activeGigIds':  FieldValue.arrayRemove([gigId]),
      'completedGigs': FieldValue.increment(1),
    });
    batch.update(executorRef, {
      'activeGigIds':  FieldValue.arrayRemove([gigId]),
      'completedGigs': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Cancel a gig (before acceptance — creator only)
  Future<void> cancelGig(String gigId, String userId) async {
    await _gigs.doc(gigId).update({
      'status': GigStatus.cancelled.firestoreValue,
    });
    await _db.collection('users').doc(userId).update({
      'activeGigIds':  FieldValue.arrayRemove([gigId]),
      'cancellations': FieldValue.increment(1),
    });
  }

  /// Flag gig as reviewed by creator (after rating)
  Future<void> markCreatorRated(String gigId) async {
    await _gigs.doc(gigId).update({'creatorRated': true});
  }

  /// Flag gig as reviewed by executor (after rating)
  Future<void> markExecutorRated(String gigId) async {
    await _gigs.doc(gigId).update({'executorRated': true});
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
      'reportId':   reportRef.id,
      'reporterId': reporterId,
      'targetId':   gigId,
      'targetType': 'gig',
      'reason':     reason,
      'status':     'open',
      'createdAt':  Timestamp.fromDate(DateTime.now()),
    });
    await batch.commit();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<String> _getCreatorId(String gigId) async {
    final doc = await _gigs.doc(gigId).get();
    return (doc.data() as Map<String, dynamic>)['creatorId'] ?? '';
  }

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
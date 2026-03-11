import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for gig/rental applications (REQ-01: Apply + Select flow)
class ApplicationModel {
  final String applicantId;
  final String applicantName;
  final double applicantRating;
  final String message;
  final DateTime appliedAt;
  final String status; // 'pending' | 'accepted' | 'rejected'

  const ApplicationModel({
    required this.applicantId,
    required this.applicantName,
    this.applicantRating = 0.0,
    required this.message,
    required this.appliedAt,
    this.status = 'pending',
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ApplicationModel(
      applicantId: d['applicantId'] ?? doc.id,
      applicantName: d['applicantName'] ?? '',
      applicantRating: (d['applicantRating'] ?? 0.0).toDouble(),
      message: d['message'] ?? '',
      appliedAt: (d['appliedAt'] as Timestamp).toDate(),
      status: d['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'applicantId': applicantId,
    'applicantName': applicantName,
    'applicantRating': applicantRating,
    'message': message,
    'appliedAt': Timestamp.fromDate(appliedAt),
    'status': status,
  };

  ApplicationModel copyWith({
    String? applicantName,
    double? applicantRating,
    String? message,
    String? status,
  }) {
    return ApplicationModel(
      applicantId: applicantId,
      applicantName: applicantName ?? this.applicantName,
      applicantRating: applicantRating ?? this.applicantRating,
      message: message ?? this.message,
      appliedAt: appliedAt,
      status: status ?? this.status,
    );
  }
}

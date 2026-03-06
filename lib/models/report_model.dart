import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { open, resolved, escalated }

enum ReportTargetType { user, gig, rental }

class ReportModel {
  final String reportId;
  final String reporterId;
  final String targetId; // userId, gigId, or rentalId
  final String targetType; // 'user' | 'gig' | 'rental'
  final String reason;
  final String? evidence;
  final String status; // 'open' | 'resolved' | 'escalated'
  final DateTime createdAt;

  ReportModel({
    required this.reportId,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    this.evidence,
    this.status = 'open',
    required this.createdAt,
  });

  // ── Firestore serialization ──────────────────────────────────────────────

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      reportId: doc.id,
      reporterId: data['reporterId'] ?? '',
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? 'user',
      reason: data['reason'] ?? '',
      evidence: data['evidence'],
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'evidence': evidence,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

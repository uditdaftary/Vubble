import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for recording transactions (REQ-11: Transactions framework)
class TransactionModel {
  final String transactionId;
  final String type; // 'gig' | 'rental'
  final String referenceId; // gigId or rentalId
  final String? referenceName; // gig title or rental item name
  final int amount;
  final int platformFee; // (amount * 0.05).round()
  final int netAmount; // amount - platformFee
  final String payerId;
  final String payeeId;
  final String status; // 'completed'
  final DateTime createdAt;

  const TransactionModel({
    required this.transactionId,
    required this.type,
    required this.referenceId,
    this.referenceName,
    required this.amount,
    required this.platformFee,
    required this.netAmount,
    required this.payerId,
    required this.payeeId,
    this.status = 'completed',
    required this.createdAt,
  });

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      transactionId: doc.id,
      type: d['type'] ?? '',
      referenceId: d['referenceId'] ?? '',
      referenceName: d['referenceName'],
      amount: (d['amount'] ?? 0) as int,
      platformFee: (d['platformFee'] ?? 0) as int,
      netAmount: (d['netAmount'] ?? 0) as int,
      payerId: d['payerId'] ?? '',
      payeeId: d['payeeId'] ?? '',
      status: d['status'] ?? 'completed',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type': type,
    'referenceId': referenceId,
    'referenceName': referenceName,
    'amount': amount,
    'platformFee': platformFee,
    'netAmount': netAmount,
    'payerId': payerId,
    'payeeId': payeeId,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

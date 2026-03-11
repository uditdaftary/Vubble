import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

/// Records financial transactions between users (REQ-11).
/// This is a framework — no real payment processing. Records intent only.
class TransactionService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _transactions => _db.collection('transactions');

  /// Record a completed transaction between two users.
  /// Automatically computes platform fee (5%) and net amount.
  Future<String> recordTransaction({
    required String type, // 'gig' | 'rental'
    required String referenceId, // gigId or rentalId
    String? referenceName, // gig title or rental item name
    required int amount,
    required String payerId,
    required String payeeId,
  }) async {
    final platformFee = (amount * 0.05).round();
    final netAmount = amount - platformFee;
    final ref = _transactions.doc();

    final tx = TransactionModel(
      transactionId: ref.id,
      type: type,
      referenceId: referenceId,
      referenceName: referenceName,
      amount: amount,
      platformFee: platformFee,
      netAmount: netAmount,
      payerId: payerId,
      payeeId: payeeId,
      status: 'completed',
      createdAt: DateTime.now(),
    );

    await ref.set(tx.toFirestore());
    return ref.id;
  }

  /// Watch all transactions involving a user (as payer or payee)
  Stream<List<TransactionModel>> watchUserTransactions(String userId) {
    // Firestore doesn't support OR queries across fields in a single query,
    // so we merge two streams: payer + payee
    final payerStream = _transactions
        .where('payerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TransactionModel.fromFirestore).toList());

    final payeeStream = _transactions
        .where('payeeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TransactionModel.fromFirestore).toList());

    // Merge and deduplicate
    return payerStream.asyncExpand((payerTxs) {
      return payeeStream.map((payeeTxs) {
        final allTxs = <String, TransactionModel>{};
        for (final tx in payerTxs) {
          allTxs[tx.transactionId] = tx;
        }
        for (final tx in payeeTxs) {
          allTxs[tx.transactionId] = tx;
        }
        final result = allTxs.values.toList();
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return result;
      });
    });
  }

  /// Fetch transactions where user is the payee (earnings)
  Stream<List<TransactionModel>> watchUserEarnings(String userId) {
    return _transactions
        .where('payeeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TransactionModel.fromFirestore).toList());
  }

  /// Fetch transactions where user is the payer (spending)
  Stream<List<TransactionModel>> watchUserSpending(String userId) {
    return _transactions
        .where('payerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TransactionModel.fromFirestore).toList());
  }
}

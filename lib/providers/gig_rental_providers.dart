import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gig_model.dart';
import '../models/rental_model.dart';
import '../models/application_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/gig_service.dart';
import '../services/rental_service.dart';
import '../services/transaction_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_provider.dart';

// ─────────────────────────────────────────────
//  SERVICE SINGLETONS
// ─────────────────────────────────────────────

final gigServiceProvider = Provider<GigService>((_) => GigService());

final rentalServiceProvider = Provider<RentalService>((_) => RentalService());

final transactionServiceProvider = Provider<TransactionService>(
  (_) => TransactionService(),
);

// ─────────────────────────────────────────────
//  BROWSE STREAMS  (used by browse screens)
// ─────────────────────────────────────────────

/// All open gigs for the browse feed
final openGigsProvider = StreamProvider<List<GigModel>>((ref) {
  return ref.watch(gigServiceProvider).watchOpenGigs();
});

/// Open gigs filtered by category — pass null for all
final gigsByCategoryProvider =
    StreamProvider.family<List<GigModel>, GigCategory?>((ref, category) {
      final service = ref.watch(gigServiceProvider);
      if (category == null) return service.watchOpenGigs();
      return service.watchOpenGigsByCategory(category);
    });

/// All available rental listings for the browse feed
final availableRentalsProvider = StreamProvider<List<RentalModel>>((ref) {
  return ref.watch(rentalServiceProvider).watchAvailableListings();
});

/// Rentals filtered by category — pass null for all
final rentalsByCategoryProvider =
    StreamProvider.family<List<RentalModel>, RentalCategory?>((ref, category) {
      final service = ref.watch(rentalServiceProvider);
      if (category == null) return service.watchAvailableListings();
      return service.watchListingsByCategory(category);
    });

// ─────────────────────────────────────────────
//  MY GIGS  (scoped to current user)
// ─────────────────────────────────────────────

/// Gigs the current user has POSTED
final myPostedGigsProvider = StreamProvider<List<GigModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(gigServiceProvider).watchGigsPostedBy(user.uid);
});

/// Gigs the current user has ACCEPTED as executor
final myAcceptedGigsProvider = StreamProvider<List<GigModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(gigServiceProvider).watchGigsAcceptedBy(user.uid);
});

// ─────────────────────────────────────────────
//  MY RENTALS  (scoped to current user)
// ─────────────────────────────────────────────

/// Rental listings the current user OWNS
final myOwnedRentalsProvider = StreamProvider<List<RentalModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(rentalServiceProvider).watchItemsOwnedBy(user.uid);
});

/// Rentals the current user is RENTING from others
final myBorrowedRentalsProvider = StreamProvider<List<RentalModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(rentalServiceProvider).watchItemsRentedBy(user.uid);
});

// ─────────────────────────────────────────────
//  SINGLE ITEM LOOKUPS
// ─────────────────────────────────────────────

final gigByIdProvider = FutureProvider.family<GigModel?, String>((ref, gigId) {
  return ref.watch(gigServiceProvider).fetchGig(gigId);
});

final rentalByIdProvider = FutureProvider.family<RentalModel?, String>((
  ref,
  rentalId,
) {
  return ref.watch(rentalServiceProvider).fetchRental(rentalId);
});

// ─────────────────────────────────────────────
//  ACTIVE COUNT  (feeds dashboard stats)
// ─────────────────────────────────────────────

/// Total active gig count for dashboard stat card
final activeGigCountProvider = Provider<int>((ref) {
  final posted = ref.watch(myPostedGigsProvider).valueOrNull ?? [];
  final accepted = ref.watch(myAcceptedGigsProvider).valueOrNull ?? [];
  final activeStatuses = {
    GigStatus.open,
    GigStatus.accepted,
    GigStatus.inProgress,
    GigStatus.completedPendingReview,
  };
  return [
    ...posted.where((g) => activeStatuses.contains(g.status)),
    ...accepted.where((g) => activeStatuses.contains(g.status)),
  ].length;
});

/// Total active rental count for dashboard
final activeRentalCountProvider = Provider<int>((ref) {
  final owned = ref.watch(myOwnedRentalsProvider).valueOrNull ?? [];
  final borrowed = ref.watch(myBorrowedRentalsProvider).valueOrNull ?? [];
  final activeStatuses = {
    RentalStatus.requested,
    RentalStatus.active,
    RentalStatus.returnPending,
  };
  return [
    ...owned.where((r) => activeStatuses.contains(r.status)),
    ...borrowed.where((r) => activeStatuses.contains(r.status)),
  ].length;
});

// ─────────────────────────────────────────────
//  APPLICATIONS (REQ-01)
// ─────────────────────────────────────────────

/// Stream of applications for a specific gig
final gigApplicationsProvider =
    StreamProvider.family<List<ApplicationModel>, String>((ref, gigId) {
      return ref.watch(gigServiceProvider).watchApplications(gigId);
    });

/// Stream of applications for a specific rental
final rentalApplicationsProvider =
    StreamProvider.family<List<ApplicationModel>, String>((ref, rentalId) {
      return ref.watch(rentalServiceProvider).watchRentalApplications(rentalId);
    });

// ─────────────────────────────────────────────
//  TRANSACTIONS (REQ-11)
// ─────────────────────────────────────────────

/// All transactions for a user (payer + payee combined)
final userTransactionsProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
      return ref
          .watch(transactionServiceProvider)
          .watchUserTransactions(userId);
    });

/// Transactions where user earned (payee)
final userEarningsProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
      return ref.watch(transactionServiceProvider).watchUserEarnings(userId);
    });

/// Transactions where user spent (payer)
final userSpendingProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
      return ref.watch(transactionServiceProvider).watchUserSpending(userId);
    });

// ─────────────────────────────────────────────
//  LEADERBOARD (REQ-04)
// ─────────────────────────────────────────────

/// Top 20 users by totalCompleted for the campus leaderboard
final leaderboardProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('totalCompleted', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());
});

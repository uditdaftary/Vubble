import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

// ── Admin stats ───────────────────────────────────────────────────────────────

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).getAdminStats();
});

// ── All users stream ──────────────────────────────────────────────────────────

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminServiceProvider).getAllUsers();
});

// ── Open reports stream ───────────────────────────────────────────────────────

final openReportsProvider = StreamProvider<List<ReportModel>>((ref) {
  return ref.watch(adminServiceProvider).getOpenReports();
});

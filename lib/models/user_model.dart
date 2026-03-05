import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, admin, moderator }

enum VerificationStatus { unverified, pending, verified }

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String department;
  final String bio;
  final List<String> skills;
  final String? profilePhotoUrl;

  final double rating;
  final int totalRatings;
  final int completedGigs;
  final int completedRentals;
  final int cancellations;
  final int reportCount;

  final UserRole role;
  final VerificationStatus verificationStatus;
  final bool isSuspended;
  final bool isBanned;

  final List<String> activeGigIds;
  final List<String> activeRentalIds;

  final DateTime createdAt;
  final DateTime? lastActiveAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.department,
    this.bio = '',
    this.skills = const [],
    this.profilePhotoUrl,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.completedGigs = 0,
    this.completedRentals = 0,
    this.cancellations = 0,
    this.reportCount = 0,
    this.role = UserRole.student,
    this.verificationStatus = VerificationStatus.unverified,
    this.isSuspended = false,
    this.isBanned = false,
    this.activeGigIds = const [],
    this.activeRentalIds = const [],
    required this.createdAt,
    this.lastActiveAt,
  });

  /// Completion rate as a percentage (0–100)
  double get completionRate {
    final total = completedGigs + completedRentals + cancellations;
    if (total == 0) return 0;
    return ((completedGigs + completedRentals) / total) * 100;
  }

  bool get isVerified => verificationStatus == VerificationStatus.verified;
  bool get isActive => !isSuspended && !isBanned;

  // ── Firestore serialization ──────────────────────────────────────────────

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      bio: data['bio'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      profilePhotoUrl: data['profilePhotoUrl'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      completedGigs: data['completedGigs'] ?? 0,
      completedRentals: data['completedRentals'] ?? 0,
      cancellations: data['cancellations'] ?? 0,
      reportCount: data['reportCount'] ?? 0,
      role: UserRole.values.firstWhere(
        (r) => r.name == (data['role'] ?? 'student'),
        orElse: () => UserRole.student,
      ),
      verificationStatus: VerificationStatus.values.firstWhere(
        (v) => v.name == (data['verificationStatus'] ?? 'unverified'),
        orElse: () => VerificationStatus.unverified,
      ),
      isSuspended: data['isSuspended'] ?? false,
      isBanned: data['isBanned'] ?? false,
      activeGigIds: List<String>.from(data['activeGigIds'] ?? []),
      activeRentalIds: List<String>.from(data['activeRentalIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'bio': bio,
      'skills': skills,
      'profilePhotoUrl': profilePhotoUrl,
      'rating': rating,
      'totalRatings': totalRatings,
      'completedGigs': completedGigs,
      'completedRentals': completedRentals,
      'cancellations': cancellations,
      'reportCount': reportCount,
      'role': role.name,
      'verificationStatus': verificationStatus.name,
      'isSuspended': isSuspended,
      'isBanned': isBanned,
      'activeGigIds': activeGigIds,
      'activeRentalIds': activeRentalIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }

  UserModel copyWith({
    String? name,
    String? department,
    String? bio,
    List<String>? skills,
    String? profilePhotoUrl,
    double? rating,
    int? totalRatings,
    int? completedGigs,
    int? completedRentals,
    int? cancellations,
    int? reportCount,
    UserRole? role,
    VerificationStatus? verificationStatus,
    bool? isSuspended,
    bool? isBanned,
    List<String>? activeGigIds,
    List<String>? activeRentalIds,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      email: email,
      department: department ?? this.department,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      completedGigs: completedGigs ?? this.completedGigs,
      completedRentals: completedRentals ?? this.completedRentals,
      cancellations: cancellations ?? this.cancellations,
      reportCount: reportCount ?? this.reportCount,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isSuspended: isSuspended ?? this.isSuspended,
      isBanned: isBanned ?? this.isBanned,
      activeGigIds: activeGigIds ?? this.activeGigIds,
      activeRentalIds: activeRentalIds ?? this.activeRentalIds,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

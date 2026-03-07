import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Current user stream ──────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Register ─────────────────────────────────────────────────────────────

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isUniversityEmail(email)) {
      throw AuthException('Please use your university email address.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Send verification email immediately
    await credential.user?.sendEmailVerification();

    return credential;
  }

  // ── Login ────────────────────────────────────────────────────────────────

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Email verification ───────────────────────────────────────────────────

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── Password reset ───────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Firestore profile ────────────────────────────────────────────────────

  Future<void> createUserProfile(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.userId)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<bool> profileExists(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _isUniversityEmail(String email) {
    // Adjust this domain to match your university
    // e.g. return email.endsWith('@university.edu');
    return email.contains('@') && email.trim().isNotEmpty;
  }
}

// ── Custom exception ─────────────────────────────────────────────────────────

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

// ── Firebase error code → readable message ────────────────────────────────────

String parseFirebaseAuthError(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'user-not-found':
      return 'No account found with this email.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'network-request-failed':
      return 'Network error. Check your connection.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

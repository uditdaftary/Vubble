import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Firebase auth state stream ────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Logged-in user's Firestore profile ────────────────────────────────────────

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return ref.read(authServiceProvider).getUserProfile(user.uid);
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

// ── Auth notifier (handles register / login / logout actions) ─────────────────

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.idle,
    this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  // ── Register ───────────────────────────────────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.registerWithEmail(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: parseFirebaseAuthError(e.code),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.loginWithEmail(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: parseFirebaseAuthError(e.code),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.idle, errorMessage: null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_coach/core/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_coach/features/assessment/presentation/providers/assessment_provider.dart';
import 'package:speech_coach/features/auth/data/auth_remote_datasource.dart';
import 'package:speech_coach/features/auth/data/auth_repository_impl.dart';
import 'package:speech_coach/features/auth/domain/auth_repository.dart';
import 'package:speech_coach/features/auth/domain/user_entity.dart';
import 'package:speech_coach/features/history/presentation/providers/session_history_provider.dart';
import 'package:speech_coach/features/progress/presentation/providers/progress_provider.dart';
import 'package:speech_coach/shared/providers/user_provider.dart';

// Repository providers
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDatasourceProvider));
});

// Auth state stream — also keeps Analytics user ID in sync
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges.map((user) {
    AnalyticsService.instance.setUserId(user?.uid);
    return user;
  });
});

// Auth notifier for actions
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(sharedPreferencesProvider),
    ref,
  );
});

// Auth state
class AuthState {
  final bool isLoading;
  final String? error;
  final UserEntity? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserEntity? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

// All SharedPreferences keys that belong to a specific user account.
// Cleared on sign-out so the next account gets a clean slate.
const _userDataKeys = [
  'session_history',
  'user_progress',
  'assessment_result',
  'learning_plan',
  'total_free_sessions_used',
  'is_pro_user',
];

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SharedPreferences _prefs;
  final Ref _ref;

  AuthNotifier(this._repository, this._prefs, this._ref) : super(const AuthState());

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signInWithEmail(email, password);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> registerWithEmail(
      String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user =
          await _repository.registerWithEmail(email, password, name);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signInWithGoogle();
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signInWithApple();
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    await _clearUserData();
    _invalidateUserProviders();
    state = const AuthState();
  }

  Future<void> _clearUserData() async {
    for (final key in _userDataKeys) {
      await _prefs.remove(key);
    }
    debugPrint('AuthNotifier: local user data cleared on sign-out');
  }

  // Force providers to re-initialize on next access so they fetch fresh
  // Firestore data under the new user UID instead of serving stale memory.
  void _invalidateUserProviders() {
    _ref.invalidate(progressProvider);
    _ref.invalidate(learningPlanProvider);
    _ref.invalidate(sessionHistoryProvider);
    _ref.invalidate(hasAssessmentProvider);
    _ref.invalidate(assessmentRepositoryProvider);
    debugPrint('AuthNotifier: user providers invalidated');
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  String _parseError(Object e) {
    debugPrint('Auth error: $e');
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'email-already-in-use' => 'This email is already registered.',
        'invalid-email' => 'The email address is invalid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' => 'No account found with this email.',
        'wrong-password' || 'invalid-credential' =>
          'Invalid email or password.',
        'weak-password' => 'Password is too weak.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'operation-not-allowed' =>
          'This sign-in method is not enabled. Please enable it in Firebase Console.',
        'CONFIGURATION_NOT_FOUND' =>
          'Email/Password sign-in is not enabled. Enable it in Firebase Console > Authentication > Sign-in method.',
        _ => e.message ?? 'Authentication failed.',
      };
    }
    if (e is FirebaseException) {
      if (e.message?.contains('CONFIGURATION_NOT_FOUND') ?? false) {
        return 'Sign-in method not enabled. Enable it in Firebase Console > Authentication > Sign-in method.';
      }
      return e.message ?? 'Firebase error occurred.';
    }
    final msg = e.toString();
    if (msg.contains('Google sign-in cancelled') ||
        msg.contains('sign_in_canceled')) {
      return 'Sign-in was cancelled.';
    }
    return msg;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

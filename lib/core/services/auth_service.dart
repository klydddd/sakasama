import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service wrapping Supabase Auth for login, registration, and session management.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  /// The current Supabase auth instance.
  GoTrueClient get _auth => _client.auth;

  // ── Auth State ────────────────────────────────────────────────────

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// The currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Whether there is an active session.
  bool get isAuthenticated => _auth.currentSession != null;

  /// Current session access token (for manual API calls if needed).
  String? get accessToken => _auth.currentSession?.accessToken;

  // ── Sign Up ───────────────────────────────────────────────────────

  /// Register a new user with email and password.
  ///
  /// Returns the [AuthResponse] on success.
  /// Throws [AuthException] on failure.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.signUp(email: email, password: password);
  }

  // ── Sign In ───────────────────────────────────────────────────────

  /// Sign in with email and password.
  ///
  /// Returns the [AuthResponse] on success.
  /// Throws [AuthException] on failure.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  // ── Sign Out ──────────────────────────────────────────────────────

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Password Reset ────────────────────────────────────────────────

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

/// Handles Google OAuth sign-in for Taya (web only).
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isSignedIn => currentSession != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Full browser redirect flow, handled entirely by Supabase.
  /// No return value — this triggers a page redirect. The session becomes
  /// available via authStateChanges (or currentSession on reload) once
  /// Google redirects back to the app.
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'http://localhost:3000', // defaults to current origin on web
      authScreenLaunchMode: LaunchMode.platformDefault,
      scopes: 'email profile https://www.googleapis.com/auth/calendar.events',
      queryParams: {
        'access_type': 'offline', // needed to get a refresh_token
        'prompt': 'consent',      // forces consent screen so refresh_token is actually returned
      },
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
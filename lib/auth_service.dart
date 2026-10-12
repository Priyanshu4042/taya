import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isSignedIn => currentSession != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb
          ? 'http://localhost:3000'
          : 'com.example.taya://login-callback',
      authScreenLaunchMode: LaunchMode.platformDefault,

      // CRITICAL: We added the gmail.readonly scope here
      scopes: 'email profile https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/gmail.modify',

      // CRITICAL: offline access and consent are required to get the refresh token
      queryParams: {
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
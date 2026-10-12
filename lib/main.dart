import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taya/homepage.dart';
import 'package:taya/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ljrmnomkwoybiubblizk.supabase.co',
    publishableKey: 'sb_publishable_qtDhCq7bbi4eDTmpPjjn7w_AohrJPxM',
  );

  runApp(const TayaApp());
}

class TayaApp extends StatelessWidget {
  const TayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taya',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      // No static '/home' route — HomePage needs a userId that's only
      // known at runtime once someone's signed in, so AuthGate builds
      // it directly below instead of going through a named route.
    );
  }
}

/// Decides whether to show the login page or the home page,
/// and stays in sync with auth state changes (covers both the
/// native flow and the web redirect flow).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStateStream;

  // @override
  // void initState() {
  //   super.initState();
  //   _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
  // }


  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
    _authStateStream.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        final refreshToken = session.providerRefreshToken;
        if (refreshToken != null) {
          _sendGoogleTokenToBackend(session.user.id, refreshToken);
        }
      }
    });
  }

  Future<void> _sendGoogleTokenToBackend(String userId, String refreshToken) async {
    final url = Uri.parse('https://taya-server-708184550477.asia-south1.run.app/google/store-token');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'provider_refresh_token': refreshToken,
          'provider_access_token': Supabase.instance.client.auth.currentSession?.providerToken,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to store Google token: ${response.statusCode} ${response.body}');
      } else {
        debugPrint('Success! Token sent to local backend via Ngrok.');
      }
    } catch (e) {
      debugPrint('Error sending Google token to backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        // Check the current session directly first — this covers the
        // case where the app just reloaded (e.g. after a web redirect)
        // and the stream hasn't emitted an event yet.
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return HomePage(userId: session.user.id);
        }
        return const LoginPage();
      },
    );
  }
}
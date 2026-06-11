import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OAuthService {
  OAuthService._();

  static final instance = OAuthService._();
  static const _redirectUrl = 'com.example.sushi_social://login-callback';

  final _auth = Supabase.instance.client.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Session? get currentSession => _auth.currentSession;

  Future<String?> signInWithGoogle() {
    return _attempt(() async {
      final launched = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : _redirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      return launched ? null : 'Could not open Google sign-in.';
    });
  }

  Future<String?> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _attempt(() async {
      await _auth.signInWithPassword(email: email, password: password);
      return null;
    });
  }

  Future<String?> signUpWithPassword({
    required String email,
    required String password,
    required String username,
  }) {
    return _attempt(() async {
      await _auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'display_name': username},
      );

      if (_auth.currentSession == null) {
        return 'Check your email to confirm your account.';
      }
      return null;
    });
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> _attempt(Future<String?> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong: $e';
    }
  }
}

import '../service/oauth_service.dart';

class AuthController {
  final _oauthService = OAuthService.instance;

  Future<String?> signInWithGoogle() => _oauthService.signInWithGoogle();

  Future<String?> signIn({required String email, required String password}) =>
      _oauthService.signInWithPassword(email: email, password: password);

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) => _oauthService.signUpWithPassword(
    email: email,
    password: password,
    username: username,
  );
}

import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: webClientId.isEmpty ? null : webClientId,
  );

  GoogleSignInAccount? currentUser;

  Future<GoogleSignInAccount?> restoreSession() async {
    currentUser = await _googleSignIn.signInSilently();
    return currentUser;
  }

  Future<GoogleSignInAccount> signIn() async {
    if (webClientId.isEmpty) {
      throw StateError('This APK is missing GOOGLE_WEB_CLIENT_ID.');
    }
    final account = await _googleSignIn.signIn();
    if (account == null) throw StateError('Google sign-in was cancelled.');
    currentUser = account;
    return account;
  }

  Future<String> idToken() async {
    final account = currentUser;
    if (account == null) throw StateError('Google sign-in is required.');
    final authentication = await account.authentication;
    final token = authentication.idToken;
    if (token == null) throw StateError('Google did not return an ID token.');
    return token;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    currentUser = null;
  }
}

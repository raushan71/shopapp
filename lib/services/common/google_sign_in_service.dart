import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:itrsp_shop/firebase_options.dart';

abstract class GoogleSignInService {
  Future<String?> requestAuthorizationCode({required String serverClientId});
}

class NativeGoogleSignInService implements GoogleSignInService {
  static Future<void>? _initialization;
  static String? _serverClientId;
  final GoogleSignIn _signIn = GoogleSignIn.instance;

  @override
  Future<String?> requestAuthorizationCode({
    required String serverClientId,
  }) async {
    if (_serverClientId != null && _serverClientId != serverClientId) {
      throw StateError(
        'Google sign-in configuration changed. Restart the app.',
      );
    }
    _serverClientId = serverClientId;
    await (_initialization ??= _signIn.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
      serverClientId: serverClientId,
    ));
    if (!_signIn.supportsAuthenticate()) {
      throw UnsupportedError('Interactive Google sign-in is unavailable.');
    }

    // A fresh interactive sign-in provides a new one-time server code and lets
    // the customer choose an account again after logging out or cancelling.
    await _signIn.signOut();
    const scopes = ['email', 'profile', 'openid'];
    final account = await _signIn.authenticate(scopeHint: scopes);
    final authorization = await account.authorizationClient.authorizeServer(
      scopes,
    );
    final code = authorization?.serverAuthCode;
    if (code == null || code.isEmpty) {
      throw StateError('Google did not return a server authorization code.');
    }
    return code;
  }
}

final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => NativeGoogleSignInService(),
);

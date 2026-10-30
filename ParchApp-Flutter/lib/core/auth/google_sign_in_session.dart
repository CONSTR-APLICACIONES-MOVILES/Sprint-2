import 'package:google_sign_in/google_sign_in.dart';

/// Login and optional Calendar authorization share the plugin singleton.
/// Authentication itself never requests Calendar permissions.
abstract final class GoogleSignInSession {
  static const serverClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID',
      defaultValue:
          '718308941728-i9lkar62kc4a6j8mv2mlfcd9tlkmip91.apps.googleusercontent.com');
  static Future<void>? _initialization;
  static Future<void> initialize() => _initialization ??=
      GoogleSignIn.instance.initialize(serverClientId: serverClientId);
  static Future<void> signOutIfInitialized() async {
    if (_initialization != null) {
      await _initialization;
      await GoogleSignIn.instance.signOut();
    }
  }
}

abstract interface class GoogleIdentitySource {
  Future<String> authenticate();
  Future<void> signOut();
}

class DeviceGoogleIdentitySource implements GoogleIdentitySource {
  const DeviceGoogleIdentitySource();
  @override
  Future<String> authenticate() async {
    await GoogleSignInSession.initialize();
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('Google did not return an identity token.');
    }
    return token;
  }

  @override
  Future<void> signOut() => GoogleSignInSession.signOutIfInitialized();
}

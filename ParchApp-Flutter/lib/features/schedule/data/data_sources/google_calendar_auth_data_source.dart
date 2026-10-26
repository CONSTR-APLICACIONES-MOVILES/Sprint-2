import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleCalendarAuthDataSource {
  static const String _iosClientId =
      '632049552762-f4kvc3h556t9ijsq36hnn3kk4d62g2od.apps.googleusercontent.com';

  static const List<String> calendarScopes = [
    'https://www.googleapis.com/auth/calendar.events.readonly',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    String? clientId;

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      clientId = _iosClientId;
    }

    await _googleSignIn.initialize(
      clientId: clientId,
    );

    _initialized = true;
  }

  Future<GoogleSignInAccount> authorizeCalendar() async {
    await initialize();

    final account = await _googleSignIn.authenticate();

    final existingAuthorization =
        await account.authorizationClient.authorizationForScopes(
      calendarScopes,
    );

    if (existingAuthorization == null) {
      await account.authorizationClient.authorizeScopes(
        calendarScopes,
      );
    }

    return account;
  }

  Future<GoogleSignInClientAuthorization>
      getCalendarAuthorization() async {
    await initialize();

    final account = await _googleSignIn.authenticate();

    final existingAuthorization =
        await account.authorizationClient.authorizationForScopes(
      calendarScopes,
    );

    if (existingAuthorization != null) {
      return existingAuthorization;
    }

    return account.authorizationClient.authorizeScopes(
      calendarScopes,
    );
  }
}
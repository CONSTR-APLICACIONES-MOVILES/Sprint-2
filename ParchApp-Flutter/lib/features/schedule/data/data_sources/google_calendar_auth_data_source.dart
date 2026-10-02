import 'package:google_sign_in/google_sign_in.dart';

class GoogleCalendarAuthDataSource {
  static const List<String> calendarScopes = [
    'https://www.googleapis.com/auth/calendar.events.readonly',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _googleSignIn.initialize(
      clientId:
          '632049552762-f4kvc3h556t9ijsq36hnn3kk4d62g2od.apps.googleusercontent.com',
    );

    _initialized = true;
  }

  Future<GoogleSignInAccount> authorizeCalendar() async {
    await initialize();

    final GoogleSignInAccount account =
        await _googleSignIn.authenticate();

    final existingAuthorization =
        await account.authorizationClient.authorizationForScopes(
      calendarScopes,
    );

    if (existingAuthorization != null) {
      return account;
    }

    await account.authorizationClient.authorizeScopes(
      calendarScopes,
    );

    return account;
  }
}
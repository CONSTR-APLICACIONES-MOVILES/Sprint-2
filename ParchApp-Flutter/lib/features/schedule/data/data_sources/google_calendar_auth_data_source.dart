import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/auth/google_sign_in_session.dart';

class GoogleCalendarAuthDataSource {
  static const List<String> calendarScopes = [
    'https://www.googleapis.com/auth/calendar.freebusy',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;
  GoogleSignInAccount? _account;

  Future<Map<String, String>> authorizationHeaders() async {
    final account = _account;
    if (account == null) throw StateError('Authorize Google Calendar first.');
    final headers = await account.authorizationClient
        .authorizationHeaders(calendarScopes, promptIfNecessary: true);
    if (headers == null) throw StateError('Calendar access was not granted.');
    return headers;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    await GoogleSignInSession.initialize();

    _initialized = true;
  }

  Future<GoogleSignInAccount> authorizeCalendar() async {
    await initialize();

    final GoogleSignInAccount account = await _googleSignIn.authenticate();
    _account = account;

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

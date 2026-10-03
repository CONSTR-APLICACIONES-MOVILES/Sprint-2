abstract final class AppRoutes {
  static const String welcome = '/';
  static const String signIn = '/sign-in';
  static const String createAccount = '/create-account';
  static const String authComplete = '/auth/complete';
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String groups = '/groups';
  static const String alerts = '/alerts';
  static const String profile = '/profile';
  static const String discover = '/discover';
  static const String activeGroups = '/groups/active';
  static const String createActivity = '/activities/new';
  static const String studySessionPattern =
      '/activities/study-sessions/:sessionId';
  static String studySession(String id) =>
      '/activities/study-sessions/${Uri.encodeComponent(id)}';
}

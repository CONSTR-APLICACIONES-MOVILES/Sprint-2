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
  static const String createGroup = '/groups/new';
  static const String groupInvitations = '/groups/invitations';
  static const String groupDetailsPattern = '/groups/details/:groupId';
  static String groupDetails(String id) =>
      '/groups/details/${Uri.encodeComponent(id)}';
  static const String activeGroups = '/groups/active';
  static const String activityResultPattern = '/activities/:activityId/created';
  static String activityResult(String id) =>
      '/activities/${Uri.encodeComponent(id)}/created';
  static const String activityInvitationPattern =
      '/activities/:activityId/invitation';
  static String activityInvitation(String id) =>
      '/activities/${Uri.encodeComponent(id)}/invitation';
  static const String createActivity = '/activities/new';
  static const String studySessionPattern =
      '/activities/study-sessions/:sessionId';
  static String studySession(String id) =>
      '/activities/study-sessions/${Uri.encodeComponent(id)}';
}

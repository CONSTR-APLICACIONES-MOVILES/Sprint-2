abstract interface class CommunityRepository {
  String? get sessionId;
  Future<List<Map<String, dynamic>>> peers();
  Future<List<Map<String, dynamic>>> invitations();
  Future<Map<String, dynamic>> details(String id);
  Future<Map<String, dynamic>?> pendingCreation();
  Future<Map<String, dynamic>> create(
      String key, String name, String category, List<String> ids);
  Future<void> respond(String id, String response);
  Future<void> revoke(String id, String invitee);
}

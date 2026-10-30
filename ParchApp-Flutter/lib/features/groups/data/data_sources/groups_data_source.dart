abstract interface class GroupsDataSource {
  String? get currentUserId;
  Future<List<Map<String, dynamic>>> listGroups();
  Future<Map<String, dynamic>> confirmGoing(String groupId);
}

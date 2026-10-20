abstract interface class ExpansionRepository {
  String? get sessionId;
  Future<Map<String, dynamic>> request(String name, Map<String, dynamic> input);
}

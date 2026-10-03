import '../models/activity_model.dart';

abstract interface class ActivityDataSource {
  String? get currentUserId;
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> input);
  Future<List<ActivityModel>> listActivities();
  Future<List<Map<String, dynamic>>> listGroups();
  Future<String> createActivity(Map<String, dynamic> fields);
  Future<void> updateActivity(String id, Map<String, dynamic> fields);
}

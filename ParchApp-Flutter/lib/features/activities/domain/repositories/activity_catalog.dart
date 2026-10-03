import '../entities/activity_summary.dart';

abstract interface class ActivityCatalog {
  Future<List<ActivitySummary>> listActivities();
}

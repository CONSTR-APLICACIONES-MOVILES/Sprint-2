import '../entities/activity_summary.dart';
import '../repositories/activity_catalog.dart';

class GetActivities {
  final ActivityCatalog _catalog;
  const GetActivities(this._catalog);
  Future<List<ActivitySummary>> call() => _catalog.listActivities();
}

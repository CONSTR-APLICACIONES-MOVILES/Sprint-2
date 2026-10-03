import '../entities/active_group.dart';
import '../entities/response_time_estimate.dart';
import '../repositories/response_time_insights_repository.dart';

class EstimateResponseTime {
  final ResponseTimeInsightsRepository _insights;
  const EstimateResponseTime(this._insights);

  Future<List<ResponseTimeEstimate>> loadEstimates() =>
      _insights.getEstimates();

  Map<String, ResponseTimeEstimate> forGroups(
      List<ActiveGroup> groups, List<ResponseTimeEstimate> estimates) {
    final result = <String, ResponseTimeEstimate>{};
    for (final group in groups) {
      if (!group.hasProgress) continue;
      final estimate = forGroupSize(group.memberCount, estimates);
      if (estimate != null) result[group.id] = estimate;
    }
    return Map.unmodifiable(result);
  }

  ResponseTimeEstimate? forGroupSize(
      int groupSize, List<ResponseTimeEstimate> estimates) {
    if (groupSize <= 0) return null;
    ResponseTimeEstimate? best;
    for (final estimate in estimates) {
      if (best == null) {
        best = estimate;
        continue;
      }
      final distance = (estimate.groupSize - groupSize).abs();
      final bestDistance = (best.groupSize - groupSize).abs();
      if (distance < bestDistance ||
          (distance == bestDistance && estimate.groupSize < best.groupSize)) {
        best = estimate;
      }
    }
    return best;
  }
}

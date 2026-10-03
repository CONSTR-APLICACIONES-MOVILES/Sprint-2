import '../../domain/entities/response_time_estimate.dart';
import '../../domain/repositories/response_time_insights_repository.dart';

class MockResponseTimeInsightsRepository
    implements ResponseTimeInsightsRepository {
  @override
  Future<List<ResponseTimeEstimate>> getEstimates() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const [
      ResponseTimeEstimate(
          groupSize: 4, minutes: 95, kind: EstimateKind.allResponded),
      ResponseTimeEstimate(
          groupSize: 6, minutes: 210, kind: EstimateKind.allResponded),
      ResponseTimeEstimate(
          groupSize: 12, minutes: 48, kind: EstimateKind.perResponse),
    ];
  }
}

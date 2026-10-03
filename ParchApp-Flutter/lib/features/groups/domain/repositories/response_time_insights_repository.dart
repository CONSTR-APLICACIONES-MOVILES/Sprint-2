import '../entities/response_time_estimate.dart';

abstract interface class ResponseTimeInsightsRepository {
  Future<List<ResponseTimeEstimate>> getEstimates();
}

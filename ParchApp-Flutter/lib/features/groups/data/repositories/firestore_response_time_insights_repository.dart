import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/response_time_estimate.dart';
import '../../domain/repositories/response_time_insights_repository.dart';

class FirestoreResponseTimeInsightsRepository
    implements ResponseTimeInsightsRepository {
  final FirebaseFirestore _db;
  const FirestoreResponseTimeInsightsRepository(this._db);

  @override
  Future<List<ResponseTimeEstimate>> getEstimates() async {
    try {
      final snapshot =
          await _db.collection('insights').doc('bq5_response_time').get();
      return parseEstimates(snapshot.data());
    } catch (_) {
      return const [];
    }
  }
}

List<ResponseTimeEstimate> parseEstimates(Map<String, dynamic>? data) {
  final rows = data?['by_group_size'];
  if (rows is! List) return const [];
  final estimates = <ResponseTimeEstimate>[];
  for (final row in rows) {
    if (row is! Map) continue;
    final size = row['group_size'];
    final minutes = row['estimate_minutes'];
    final kind = switch (row['estimate_kind']) {
      'all_responded' => EstimateKind.allResponded,
      'per_response' => EstimateKind.perResponse,
      _ => null,
    };
    if (size is num && minutes is num && kind != null && minutes > 0) {
      estimates.add(ResponseTimeEstimate(
          groupSize: size.toInt(), minutes: minutes.toDouble(), kind: kind));
    }
  }
  return List.unmodifiable(estimates);
}

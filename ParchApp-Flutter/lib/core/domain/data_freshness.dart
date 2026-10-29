/// Metadata belongs to the loaded snapshot, never to optimistic local edits.
class DataFreshness {
  final bool offline;
  final DateTime? cachedAt;
  const DataFreshness({this.offline = false, this.cachedAt});
  factory DataFreshness.fromMap(Map<String, dynamic> data) => DataFreshness(
      offline: data['offline'] == true,
      cachedAt: DateTime.tryParse(data['cachedAt'] as String? ?? ''));
  bool isStale(DateTime now) =>
      cachedAt == null ||
      now.toUtc().difference(cachedAt!.toUtc()) > const Duration(minutes: 15);
}

abstract interface class CacheAwareRepository {
  DataFreshness get freshness;
}

abstract interface class AnalyticsService {
  Future<void> track(String name, [Map<String, Object> parameters = const {}]);

  Future<void> setUserId(String? rawUserId);
}

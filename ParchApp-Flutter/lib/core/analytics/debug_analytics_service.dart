import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

class DebugAnalyticsService implements AnalyticsService {
  final List<({String name, Map<String, Object> parameters})> events = [];

  @override
  Future<void> track(String name,
      [Map<String, Object> parameters = const {}]) async {
    events.add((name: name, parameters: Map.unmodifiable(parameters)));
    debugPrint('ParchAnalytics $name $parameters');
  }

  @override
  Future<void> setUserId(String? rawUserId) async {}
}

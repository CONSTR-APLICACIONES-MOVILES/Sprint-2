import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_events.dart';
import 'analytics_service.dart';
import 'user_id_anonymiser.dart';

class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsService([FirebaseAnalytics? analytics])
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> track(String name,
      [Map<String, Object> parameters = const {}]) async {
    try {
      await _analytics.logEvent(name: name, parameters: {
        ...parameters,
        AnalyticsEvents.paramClientTs: DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      return;
    }
  }

  @override
  Future<void> setUserId(String? rawUserId) => _analytics.setUserId(
      id: rawUserId == null ? null : anonymiseUserId(rawUserId));
}

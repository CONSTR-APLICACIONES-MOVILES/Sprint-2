import '../entities/app_alert.dart';

abstract interface class AlertsRepository {
  Future<List<AppAlert>> getAlerts();
  Future<List<AppAlert>> markAllRead();
  Future<List<AppAlert>> respond(String id, AlertResponse response);
}

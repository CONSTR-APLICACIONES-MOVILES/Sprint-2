import '../entities/app_alert.dart';
import '../repositories/alerts_repository.dart';

class ManageAlerts {
  final AlertsRepository _repository;
  const ManageAlerts(this._repository);

  Future<List<AppAlert>> load() => _repository.getAlerts();
  Future<List<AppAlert>> markAllRead() => _repository.markAllRead();

  Future<List<AppAlert>> respond(AppAlert alert, AlertResponse response) {
    final allowed = switch (alert.kind) {
      AlertKind.reminder => {AlertResponse.onMyWay},
      AlertKind.overlap || AlertKind.digest => {AlertResponse.dismissed},
      AlertKind.invitation => {
          AlertResponse.accepted,
          AlertResponse.maybe,
          AlertResponse.declined
        },
      AlertKind.friendRequest => {
          AlertResponse.accepted,
          AlertResponse.declined
        },
      AlertKind.timeChanged => {AlertResponse.acknowledged},
      AlertKind.groupInvite => {AlertResponse.joined, AlertResponse.declined},
    };
    if (alert.isResolved || !allowed.contains(response)) {
      throw StateError('This alert cannot receive that response.');
    }
    return _repository.respond(alert.id, response);
  }
}

import '../../domain/entities/app_alert.dart';

enum AlertsFilter {
  all,
  priority,
  invitations,
  schedule,
  friends,
  groups,
  unread
}

class AlertsState {
  final List<AppAlert> alerts;
  final AlertsFilter filter;
  final String query;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  AlertsState(
      {List<AppAlert> alerts = const [],
      this.filter = AlertsFilter.all,
      this.query = '',
      this.isLoading = false,
      this.isUpdating = false,
      this.error})
      : alerts = List.unmodifiable(alerts);

  int get unreadCount =>
      alerts.where((alert) => !alert.isRead && !alert.isResolved).length;

  List<AppAlert> get visibleAlerts {
    final search = query.trim().toLowerCase();
    return alerts.where((alert) {
      if (alert.isResolved) return false;
      final matches = switch (filter) {
        AlertsFilter.all => true,
        AlertsFilter.priority => alert.isPriority,
        AlertsFilter.invitations =>
          alert.kind == AlertKind.invitation || alert.kind == AlertKind.digest,
        AlertsFilter.schedule => alert.kind == AlertKind.overlap ||
            alert.kind == AlertKind.timeChanged,
        AlertsFilter.friends => alert.kind == AlertKind.friendRequest,
        AlertsFilter.groups => alert.kind == AlertKind.groupInvite ||
            alert.kind == AlertKind.timeChanged,
        AlertsFilter.unread => !alert.isRead,
      };
      return matches &&
          '${alert.title} ${alert.description}'.toLowerCase().contains(search);
    }).toList(growable: false);
  }

  AlertsState copyWith(
          {List<AppAlert>? alerts,
          AlertsFilter? filter,
          String? query,
          bool? isLoading,
          bool? isUpdating,
          String? error}) =>
      AlertsState(
          alerts: alerts ?? this.alerts,
          filter: filter ?? this.filter,
          query: query ?? this.query,
          isLoading: isLoading ?? this.isLoading,
          isUpdating: isUpdating ?? this.isUpdating,
          error: error);
}

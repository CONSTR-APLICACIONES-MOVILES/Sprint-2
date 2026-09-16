import 'package:flutter/foundation.dart';
import '../../domain/entities/app_alert.dart';
import '../../domain/use_cases/manage_alerts.dart';
import 'alerts_state.dart';

class AlertsViewModel extends ValueNotifier<AlertsState> {
  final ManageAlerts _alerts;
  bool _disposed = false;
  AlertsViewModel(this._alerts) : super(AlertsState());

  void _emit(AlertsState state) {
    if (!_disposed) value = state;
  }

  Future<void> load() async {
    if (_disposed || value.isLoading || value.isUpdating) return;
    _emit(value.copyWith(isLoading: true));
    try {
      final items = await _alerts.load();
      _emit(value.copyWith(alerts: items, isLoading: false));
    } catch (_) {
      _emit(value.copyWith(
          isLoading: false, error: 'Unable to load alerts. Please try again.'));
    }
  }

  void setFilter(AlertsFilter filter) =>
      _emit(value.copyWith(filter: filter, error: value.error));
  void search(String query) =>
      _emit(value.copyWith(query: query, error: value.error));
  void clearFilters() => _emit(
      value.copyWith(filter: AlertsFilter.all, query: '', error: value.error));

  Future<bool> markAllRead() => _update(_alerts.markAllRead);
  Future<bool> respond(AppAlert alert, AlertResponse response) =>
      _update(() => _alerts.respond(alert, response));

  Future<bool> _update(Future<List<AppAlert>> Function() operation) async {
    if (_disposed || value.isLoading || value.isUpdating) return false;
    _emit(value.copyWith(isUpdating: true));
    try {
      final items = await operation();
      if (_disposed) return false;
      _emit(value.copyWith(alerts: items, isUpdating: false));
      return true;
    } catch (_) {
      _emit(value.copyWith(
          isUpdating: false,
          error: 'Unable to update this alert. Please try again.'));
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

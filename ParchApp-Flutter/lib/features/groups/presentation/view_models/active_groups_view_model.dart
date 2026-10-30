import 'package:flutter/foundation.dart';
import '../../domain/entities/active_group.dart';
import '../../domain/entities/response_time_estimate.dart';
import '../../domain/use_cases/estimate_response_time.dart';
import '../../domain/use_cases/forecast_activity_weather.dart';
import '../../domain/use_cases/manage_active_groups.dart';
import 'active_groups_state.dart';
import '../../domain/use_cases/activity_timing.dart';

class ActiveGroupsViewModel extends ValueNotifier<ActiveGroupsState> {
  final ManageActiveGroups _groups;
  final EstimateResponseTime? _estimate;
  final ForecastActivityWeather? _weather;
  final DateTime Function() _now;
  List<ResponseTimeEstimate> _responseTimes = const [];
  bool _disposed = false;
  int _generation = 0;

  ActiveGroupsViewModel(this._groups,
      {EstimateResponseTime? estimate,
      ForecastActivityWeather? weather,
      DateTime Function()? now})
      : _estimate = estimate,
        _weather = weather,
        _now = now ?? DateTime.now,
        super(ActiveGroupsState());

  Map<String, ResponseTimeEstimate> _estimatesFor(List<ActiveGroup> groups) =>
      _estimate?.forGroups(groups, _responseTimes) ?? const {};

  void _emit(ActiveGroupsState state) {
    if (!_disposed) value = state;
  }

  Future<void> load() async {
    if (_disposed || value.isLoading || value.isUpdating) return;
    _emit(value.copyWith(isLoading: true));
    final generation = ++_generation;
    try {
      final estimates = _estimate
          ?.loadEstimates()
          .timeout(const Duration(seconds: 3),
              onTimeout: () => const <ResponseTimeEstimate>[])
          .catchError((Object _) => const <ResponseTimeEstimate>[]);
      final items = ActivityTiming.byUpcoming(await _groups.load(), _now());
      if (_disposed || generation != _generation) return;
      _emit(value.copyWith(
          groups: items, freshness: _groups.freshness, isLoading: false));
      if (estimates != null) _responseTimes = await estimates;
      if (_disposed || generation != _generation) return;
      _emit(value.copyWith(
          groups: items,
          freshness: _groups.freshness,
          estimates: _estimatesFor(items),
          isLoading: false));
    } catch (_) {
      _emit(value.copyWith(
          isLoading: false,
          freshness: _groups.freshness,
          error: _groups.freshness.offline
              ? 'You are offline. No saved groups are available. Connect to load them.'
              : 'Unable to load your groups. Please try again.'));
      return;
    }
    await _loadWeather(value.groups);
  }

  Future<void> _loadWeather(List<ActiveGroup> groups) async {
    final weather = _weather;
    if (weather == null || _disposed || value.freshness.offline) return;
    try {
      final forecasts = await weather.forGroups(groups, _now());
      _emit(value.copyWith(weather: forecasts, error: value.error));
    } catch (_) {}
  }

  void setFilter(GroupsFilter filter) =>
      _emit(value.copyWith(filter: filter, error: value.error));

  Future<bool> confirmRsvp(ActiveGroup group) =>
      _update(() => _groups.confirmRsvp(group));

  Future<bool> dropIn(ActiveGroup group) =>
      _update(() => _groups.dropIn(group));

  Future<bool> _update(Future<List<ActiveGroup>> Function() operation) async {
    if (_disposed || value.isLoading || value.isUpdating) return false;
    _emit(value.copyWith(isUpdating: true));
    try {
      final items = ActivityTiming.byUpcoming(await operation(), _now());
      if (_disposed) return false;
      _emit(value.copyWith(
          groups: items, estimates: _estimatesFor(items), isUpdating: false));
      return true;
    } catch (_) {
      _emit(value.copyWith(
          isUpdating: false, error: 'Unable to update this group.'));
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

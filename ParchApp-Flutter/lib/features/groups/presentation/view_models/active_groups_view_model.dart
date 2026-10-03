import 'package:flutter/foundation.dart';
import '../../domain/entities/active_group.dart';
import '../../domain/entities/response_time_estimate.dart';
import '../../domain/use_cases/estimate_response_time.dart';
import '../../domain/use_cases/manage_active_groups.dart';
import 'active_groups_state.dart';

class ActiveGroupsViewModel extends ValueNotifier<ActiveGroupsState> {
  final ManageActiveGroups _groups;
  final EstimateResponseTime? _estimate;
  List<ResponseTimeEstimate> _responseTimes = const [];
  bool _disposed = false;

  ActiveGroupsViewModel(this._groups, {EstimateResponseTime? estimate})
      : _estimate = estimate,
        super(ActiveGroupsState());

  Map<String, ResponseTimeEstimate> _estimatesFor(List<ActiveGroup> groups) =>
      _estimate?.forGroups(groups, _responseTimes) ?? const {};

  void _emit(ActiveGroupsState state) {
    if (!_disposed) value = state;
  }

  Future<void> load() async {
    if (_disposed || value.isLoading || value.isUpdating) return;
    _emit(value.copyWith(isLoading: true));
    try {
      final estimates = _estimate?.loadEstimates();
      final items = await _groups.load();
      if (estimates != null) _responseTimes = await estimates;
      _emit(value.copyWith(
          groups: items, estimates: _estimatesFor(items), isLoading: false));
    } catch (_) {
      _emit(value.copyWith(
          isLoading: false,
          error: 'Unable to load your groups. Please try again.'));
    }
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
      final items = await operation();
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
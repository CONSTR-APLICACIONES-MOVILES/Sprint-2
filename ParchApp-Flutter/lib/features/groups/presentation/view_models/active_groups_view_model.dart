import 'package:flutter/foundation.dart';
import '../../domain/entities/active_group.dart';
import '../../domain/use_cases/manage_active_groups.dart';
import 'active_groups_state.dart';

class ActiveGroupsViewModel extends ValueNotifier<ActiveGroupsState> {
  final ManageActiveGroups _groups;
  bool _disposed = false;

  ActiveGroupsViewModel(this._groups) : super(ActiveGroupsState());

  void _emit(ActiveGroupsState state) {
    if (!_disposed) value = state;
  }

  Future<void> load() async {
    if (_disposed || value.isLoading || value.isUpdating) return;
    _emit(value.copyWith(isLoading: true));
    try {
      final items = await _groups.load();
      _emit(value.copyWith(groups: items, isLoading: false));
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
      _emit(value.copyWith(groups: items, isUpdating: false));
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
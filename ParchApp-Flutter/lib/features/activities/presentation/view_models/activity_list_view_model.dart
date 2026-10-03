import 'package:flutter/foundation.dart';
import '../../domain/entities/activity_summary.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/use_cases/get_activities.dart';

class ActivityListState {
  final List<ActivitySummary> activities;
  final bool loading;
  final String? error;
  ActivityListState(
      {List<ActivitySummary> activities = const [],
      this.loading = true,
      this.error})
      : activities = List.unmodifiable(activities);
}

class ActivityListViewModel extends ValueNotifier<ActivityListState> {
  final GetActivities _getActivities;
  bool _disposed = false;
  bool _loading = false;
  ActivityListViewModel(this._getActivities) : super(ActivityListState());
  Future<void> load() async {
    if (_disposed || _loading) return;
    _loading = true;
    value = ActivityListState(activities: value.activities);
    try {
      final activities = await _getActivities();
      if (!_disposed) {
        value = ActivityListState(activities: activities, loading: false);
      }
    } catch (error) {
      if (!_disposed) {
        value = ActivityListState(
            activities: value.activities,
            loading: false,
            error: error is SessionFailure
                ? error.message
                : 'Unable to load activities. Please try again.');
      }
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import '../../../activities/domain/repositories/activity_catalog.dart';
import '../../../activities/presentation/view_models/activity_list_view_model.dart';
import '../../../alerts/domain/repositories/alerts_repository.dart';
import '../../../alerts/presentation/view_models/alerts_state.dart';
import '../../../groups/domain/repositories/active_groups_repository.dart';
import '../../../groups/presentation/view_models/active_groups_state.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/view_models/profile_state.dart';

class HomeState {
  final ActivityListState activities;
  final ActiveGroupsState groups;
  final AlertsState alerts;
  final ProfileState profile;
  HomeState(
      {ActivityListState? activities,
      ActiveGroupsState? groups,
      AlertsState? alerts,
      ProfileState? profile})
      : activities = activities ?? ActivityListState(),
        groups = groups ?? ActiveGroupsState(isLoading: true),
        alerts = alerts ?? AlertsState(isLoading: true),
        profile = profile ?? ProfileState(isLoading: true);

  HomeState copyWith(
          {ActivityListState? activities,
          ActiveGroupsState? groups,
          AlertsState? alerts,
          ProfileState? profile}) =>
      HomeState(
          activities: activities ?? this.activities,
          groups: groups ?? this.groups,
          alerts: alerts ?? this.alerts,
          profile: profile ?? this.profile);
}

/// Each section can fail independently and retains its last successful data.
class HomeViewModel extends ValueNotifier<HomeState> {
  final ActivityCatalog catalog;
  final ActiveGroupsRepository? groups;
  final AlertsRepository? alerts;
  final ProfileRepository? profiles;
  final String? Function()? currentUserId;
  bool _disposed = false;
  Future<void>? _pending;
  String? _owner;
  int _generation = 0;

  HomeViewModel(
      {required this.catalog,
      this.groups,
      this.alerts,
      this.profiles,
      this.currentUserId})
      : super(HomeState());

  Future<void> load() {
    final uid = currentUserId?.call();
    if (_disposed) return Future.value();
    if (_pending != null && uid == _owner) return _pending!;
    if (uid != _owner) value = HomeState();
    _owner = uid;
    final request = _load(uid, ++_generation);
    _pending = request;
    return request.whenComplete(() {
      if (identical(_pending, request)) _pending = null;
    });
  }

  bool _valid(String? uid, int generation) =>
      !_disposed &&
      generation == _generation &&
      uid == _owner &&
      (currentUserId == null || (uid != null && currentUserId!() == uid));

  Future<void> _load(String? uid, int generation) async {
    value = value.copyWith(
        activities: ActivityListState(activities: value.activities.activities),
        groups: value.groups.copyWith(isLoading: true),
        alerts: value.alerts.copyWith(isLoading: true),
        profile: value.profile.copyWith(isLoading: true));
    await Future.wait([
      _section(uid, generation, () async {
        final records = await catalog.listActivities();
        if (_valid(uid, generation)) {
          value = value.copyWith(
              activities:
                  ActivityListState(activities: records, loading: false));
        }
      },
          () => value.copyWith(
              activities: ActivityListState(
                  activities: value.activities.activities,
                  loading: false,
                  error: 'Unable to load activities. Please try again.'))),
      _section(uid, generation, () async {
        if (groups == null) throw StateError('Groups unavailable');
        final records = await groups!.getActiveGroups();
        if (_valid(uid, generation)) {
          value = value.copyWith(groups: ActiveGroupsState(groups: records));
        }
      },
          () => value.copyWith(
              groups: value.groups.copyWith(
                  isLoading: false,
                  error: 'Unable to load groups. Please try again.'))),
      _section(uid, generation, () async {
        if (alerts == null) throw StateError('Alerts unavailable');
        final records = await alerts!.getAlerts();
        if (_valid(uid, generation)) {
          value = value.copyWith(alerts: AlertsState(alerts: records));
        }
      },
          () => value.copyWith(
              alerts: value.alerts.copyWith(
                  isLoading: false,
                  error: 'Unable to load invitations. Please try again.'))),
      _section(uid, generation, () async {
        if (profiles == null) throw StateError('Profile unavailable');
        final user = await profiles!.getProfile();
        if (_valid(uid, generation)) {
          value = value.copyWith(profile: ProfileState(user: user));
        }
      },
          () => value.copyWith(
              profile: value.profile.copyWith(
                  isLoading: false,
                  error: 'Unable to load your profile. Please try again.'))),
    ]);
    if (!_disposed &&
        generation == _generation &&
        uid == _owner &&
        !_valid(uid, generation)) {
      // No old account's content survives a session change during a request.
      value = HomeState(
          activities: ActivityListState(
              loading: false, error: 'Session changed. Reload Home.'),
          groups: ActiveGroupsState(error: 'Session changed. Reload Home.'),
          alerts: AlertsState(error: 'Session changed. Reload Home.'),
          profile: ProfileState(error: 'Session changed. Reload Home.'));
    }
  }

  Future<void> _section(String? uid, int generation,
      Future<void> Function() operation, HomeState Function() failure) async {
    try {
      await operation();
    } catch (_) {
      if (_valid(uid, generation)) value = failure();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

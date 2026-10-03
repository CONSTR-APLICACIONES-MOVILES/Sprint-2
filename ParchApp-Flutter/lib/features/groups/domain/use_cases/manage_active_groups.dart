import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../entities/active_group.dart';
import '../repositories/active_groups_repository.dart';

class ManageActiveGroups {
  final ActiveGroupsRepository _repository;
  final AnalyticsService? _analytics;
  final DateTime Function() _now;

  const ManageActiveGroups(this._repository,
      {AnalyticsService? analytics, DateTime Function()? now})
      : _analytics = analytics,
        _now = now ?? DateTime.now;

  Future<List<ActiveGroup>> load() => _repository.getActiveGroups();

  Future<List<ActiveGroup>> confirmRsvp(ActiveGroup group) async {
    if (!group.hasProgress) {
      throw StateError('This group does not track RSVPs.');
    }
    if (group.progressCurrent! >= group.progressTotal!) {
      throw StateError('The roster is already full.');
    }
    final groups = await _repository.confirmRsvp(group.id);
    _trackResponse(group, AnalyticsEvents.responseGoing);
    return groups;
  }

  Future<List<ActiveGroup>> dropIn(ActiveGroup group) {
    if (group.primaryAction != GroupAction.dropIn) {
      throw StateError('This group does not support drop-in.');
    }
    return _repository.dropIn(group.id);
  }

  void _trackResponse(ActiveGroup group, String response) {
    final analytics = _analytics;
    if (analytics == null || !group.hasInvitation) return;
    final elapsed = _now().difference(group.invitationSentAt!).inMilliseconds;
    analytics.track(AnalyticsEvents.rsvpSubmitted, {
      AnalyticsEvents.paramActivityId: group.invitationId!,
      AnalyticsEvents.paramGroupSize: group.memberCount,
      AnalyticsEvents.paramResponseMs: elapsed < 0 ? 0 : elapsed,
      AnalyticsEvents.paramResponse: response,
    });
  }
}

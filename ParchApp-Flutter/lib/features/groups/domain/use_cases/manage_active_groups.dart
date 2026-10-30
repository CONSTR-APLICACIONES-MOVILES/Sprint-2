import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../entities/active_group.dart';
import '../repositories/active_groups_repository.dart';

class ManageActiveGroups {
  final ActiveGroupsRepository _repository;
  final AnalyticsService? _analytics;
  final DateTime Function() _now;
  final String? Function()? _currentUserId;

  const ManageActiveGroups(this._repository,
      {AnalyticsService? analytics,
      DateTime Function()? now,
      String? Function()? currentUserId})
      : _analytics = analytics,
        _currentUserId = currentUserId,
        _now = now ?? DateTime.now;

  Future<List<ActiveGroup>> load() => _repository.getActiveGroups();

  Future<List<ActiveGroup>> confirmRsvp(ActiveGroup group) async {
    if (group.hasResponded) {
      throw StateError('You have already responded to this invitation.');
    }
    if (!group.hasProgress) {
      throw StateError('This group has no attendance request.');
    }
    if (group.progressCurrent! >= group.progressTotal!) {
      throw StateError('The roster is already full.');
    }
    final groups = await _repository.confirmRsvp(group.id);
    await _trackResponse(group, AnalyticsEvents.responseGoing);
    return groups;
  }

  Future<List<ActiveGroup>> dropIn(ActiveGroup group) {
    if (group.primaryAction != GroupAction.dropIn) {
      throw StateError('This group does not support drop-in.');
    }
    return _repository.dropIn(group.id);
  }

  Future<void> _trackResponse(ActiveGroup group, String response) async {
    final analytics = _analytics;
    if (analytics == null || !group.hasInvitation) return;
    final elapsed = _now().difference(group.invitationSentAt!).inMilliseconds;
    try {
      // BQ5 deduplicates by user_id. The analytics adapter hashes the raw UID.
      if (_currentUserId != null) {
        final uid = _currentUserId();
        if (uid == null) return;
        await analytics.setUserId(uid);
      }
      await analytics.track(AnalyticsEvents.rsvpSubmitted, {
        AnalyticsEvents.paramActivityId: group.invitationId!,
        AnalyticsEvents.paramGroupSize: group.memberCount,
        AnalyticsEvents.paramResponseMs: elapsed < 0 ? 0 : elapsed,
        AnalyticsEvents.paramResponse: response,
      });
    } catch (_) {
      // The RSVP is already committed. Telemetry must not turn it into a failure.
    }
  }
}

import '../../domain/entities/active_group.dart';
import '../../../../core/domain/data_freshness.dart';
import '../../domain/repositories/active_groups_repository.dart';
import '../data_sources/groups_data_source.dart';

class FirebaseActiveGroupsRepository
    implements ActiveGroupsRepository, CacheAwareRepository {
  @override
  DataFreshness get freshness => _source is CacheAwareRepository
      ? (_source as CacheAwareRepository).freshness
      : const DataFreshness();
  final GroupsDataSource _source;
  List<Map<String, dynamic>> _records = [];
  String? _owner;
  FirebaseActiveGroupsRepository(this._source);

  String _requireUser() {
    final uid = _source.currentUserId;
    if (_owner != uid) {
      _records = [];
      _owner = uid;
    }
    if (uid == null) throw StateError('Sign in to view your groups.');
    return uid;
  }

  @override
  Future<List<ActiveGroup>> getActiveGroups() async {
    final uid = _requireUser();
    final records = await _source.listGroups();
    if (_source.currentUserId != uid) throw StateError('Session changed.');
    _records = records;
    return _entities(uid);
  }

  @override
  Future<List<ActiveGroup>> confirmRsvp(String id) async {
    final uid = _requireUser();
    final index = _records.indexWhere((record) => record['id'] == id);
    if (index < 0 || _records[index]['invitationId'] == null) {
      throw StateError('Refresh the group before responding.');
    }
    if (_records[index]['activityAttendance'] == true) {
      throw StateError('Open the activity invitation to respond.');
    }
    final updated = await _source.confirmGoing(id);
    if (_source.currentUserId != uid) throw StateError('Session changed.');
    // A committed write is success even when a later refresh is unavailable.
    _records[index] = {..._records[index], ...updated};
    return _entities(uid);
  }

  @override
  Future<List<ActiveGroup>> dropIn(String id) =>
      Future.error(StateError('Drop-in is unavailable for these groups.'));

  List<ActiveGroup> _entities(String uid) =>
      List.unmodifiable(_records.map((r) {
        final ids = Set<String>.from(r['memberIds'] as List);
        final perActivity = r['activityAttendance'] == true;
        final participants = perActivity
            ? Set<String>.from(r['activityParticipantIds'] as List)
            : ids;
        final going = Set<String>.from(
            (perActivity ? r['activityGoingIds'] : r['goingIds']) as List)
          ..retainAll(participants);
        final responded =
            perActivity ? r['activityResponse'] != null : going.contains(uid);
        final attendanceUnavailable =
            r['activityAttendanceUnavailable'] == true;
        final invitation =
            attendanceUnavailable ? null : r['invitationId'] as String?;
        final category = switch (r['category'] ?? r['activityCategory']) {
          'study' => GroupCategory.study,
          'sports' => GroupCategory.sports,
          _ => GroupCategory.socialLiving,
        };
        return ActiveGroup(
          id: r['id'] as String,
          name: r['name'] as String,
          category: category,
          memberCount: ids.length,
          subtitle: 'Shared group',
          activityAttendance: perActivity,
          statusText: attendanceUnavailable
              ? 'Attendance is unavailable in this saved copy'
              : r['activityCancelled'] == true
                  ? 'Activity cancelled'
                  : invitation == null
                      ? 'No activity yet'
                      : '${going.length}/${participants.length} ${perActivity ? 'accepted · ${r['activityMaybeCount'] ?? 0} maybe · ${r['activityDeclinedCount'] ?? 0} declined' : 'going'}',
          statusTag: responded
              ? (perActivity
                  ? switch (r['activityResponse']) {
                      'accepted' => 'Accepted',
                      'maybe' => 'Maybe',
                      'declined' => 'Declined',
                      _ => 'No response'
                    }
                  : 'Going')
              : null,
          tone: responded ? GroupTone.success : GroupTone.info,
          detail:
              r['activityTitle'] as String? ?? r['planTitle'] as String? ?? '',
          progressLabel: invitation == null || r['activityCancelled'] == true
              ? null
              : perActivity
                  ? 'Activity attendance'
                  : 'Confirmed attendance',
          progressCurrent: invitation == null || r['activityCancelled'] == true
              ? null
              : going.length,
          progressTotal: invitation == null || r['activityCancelled'] == true
              ? null
              : participants.length,
          primaryAction: invitation != null &&
                  (perActivity
                      ? r['activityCancelled'] != true &&
                          r['activityOrganizedByMe'] != true &&
                          r['activityInvited'] == true
                      : !responded)
              ? GroupAction.voteRsvp
              : GroupAction.viewDetails,
          secondaryAction: GroupAction.viewSchedule,
          invitationId: invitation,
          invitationSentAt: r['invitationSentAt'] as DateTime?,
          hasResponded: responded,
          activityStartsAt: r['activityStartsAt'] as DateTime?,
          activityLatitude: _coordinate(r['activityLocation'], 'latitude'),
          activityLongitude: _coordinate(r['activityLocation'], 'longitude'),
        );
      }));
}

double? _coordinate(Object? place, String key) {
  final value = place is Map ? place[key] : null;
  return value is num ? value.toDouble() : null;
}

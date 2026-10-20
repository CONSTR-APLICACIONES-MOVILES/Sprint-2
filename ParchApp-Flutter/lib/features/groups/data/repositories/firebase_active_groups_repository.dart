import '../../domain/entities/active_group.dart';
import '../../domain/repositories/active_groups_repository.dart';
import '../data_sources/groups_data_source.dart';

class FirebaseActiveGroupsRepository implements ActiveGroupsRepository {
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
        final going = Set<String>.from(r['goingIds'] as List)..retainAll(ids);
        final responded = going.contains(uid);
        final invitation = r['invitationId'] as String?;
        final category = switch (r['activityCategory']) {
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
          statusText: invitation == null
              ? 'No activity yet'
              : '${going.length}/${ids.length} going',
          statusTag: responded ? 'Going' : null,
          tone: responded ? GroupTone.success : GroupTone.info,
          detail:
              r['activityTitle'] as String? ?? r['planTitle'] as String? ?? '',
          progressLabel: invitation == null ? null : 'Group RSVP',
          progressCurrent: invitation == null ? null : going.length,
          progressTotal: invitation == null ? null : ids.length,
          primaryAction: invitation != null && !responded
              ? GroupAction.voteRsvp
              : GroupAction.viewSchedule,
          secondaryAction: GroupAction.viewSchedule,
          invitationId: invitation,
          invitationSentAt: r['invitationSentAt'] as DateTime?,
          hasResponded: responded,
        );
      }));
}

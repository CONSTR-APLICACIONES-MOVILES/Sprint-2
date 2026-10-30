import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/core/analytics/analytics_service.dart';
import 'package:parchapp/features/groups/data/data_sources/groups_data_source.dart';
import 'package:parchapp/features/groups/data/repositories/firebase_active_groups_repository.dart';
import 'package:parchapp/features/groups/domain/entities/active_group.dart';
import 'package:parchapp/features/groups/domain/use_cases/manage_active_groups.dart';

class _Source implements GroupsDataSource {
  @override
  String? currentUserId = 'me';
  int writes = 0;
  bool failRead = false, failWrite = false;
  Map<String, dynamic> record = {
    'id': 'real-group',
    'name': 'Real group',
    'members': [
      {'id': 'me'},
      {'id': 'other'}
    ],
    'memberIds': ['me', 'other'],
    'goingIds': ['other'],
    'maybeIds': ['me'],
    'invitationId': 'real-activity',
    'invitationSentAt': DateTime(2026, 10, 19, 8),
    'activityTitle': 'Real activity',
    'activityCategory': 'study',
  };
  @override
  Future<List<Map<String, dynamic>>> listGroups() async {
    if (failRead) throw StateError('offline');
    return [
      {...record}
    ];
  }

  @override
  Future<Map<String, dynamic>> confirmGoing(String id) async {
    if (failWrite) throw StateError('permission denied');
    writes++;
    record = {
      ...record,
      'goingIds': ['other', 'me'],
      'maybeIds': <String>[]
    };
    return {...record}
      ..remove('invitationId')
      ..remove('invitationSentAt');
  }
}

class _Analytics implements AnalyticsService {
  final calls = <String>[];
  bool fail = false;
  @override
  Future<void> setUserId(String? id) async {
    calls.add('identity:$id');
    if (fail) throw StateError('analytics unavailable');
  }

  @override
  Future<void> track(String name,
      [Map<String, Object> parameters = const {}]) async {
    calls.add(name);
  }
}

void main() {
  late _Source source;
  late FirebaseActiveGroupsRepository repository;
  setUp(() {
    source = _Source();
    repository = FirebaseActiveGroupsRepository(source);
  });

  test('uses shared document IDs and latest activity for BQ5', () async {
    final group = (await repository.getActiveGroups()).single;
    expect(group.id, 'real-group');
    expect(group.invitationId, 'real-activity');
    expect(group.category, GroupCategory.study);
    expect(group.progressCurrent, 1);
    expect(group.progressTotal, 2);
    expect(group.primaryAction, GroupAction.voteRsvp);
  });
  test(
      'activity attendance ignores the legacy group arrays and opens the exact invitation',
      () async {
    source.record.addAll({
      'activityAttendance': true,
      'activityParticipantIds': ['me', 'other'],
      'activityGoingIds': <String>[],
      'activityMaybeCount': 1,
      'activityDeclinedCount': 0,
      'activityResponse': 'maybe',
      'activityInvited': true,
      'activityOrganizedByMe': false
    });
    final group = (await repository.getActiveGroups()).single;
    expect(group.invitationId, 'real-activity');
    expect(group.progressCurrent, 0);
    expect(group.statusText, contains('0/2 accepted'));
    expect(group.statusText, contains('1 maybe'));
    expect(group.statusTag, 'Maybe');
    expect(group.primaryAction, GroupAction.voteRsvp);
    await expectLater(repository.confirmRsvp(group.id), throwsStateError);
    expect(source.writes, 0);
  });
  test('cancelled group activity has no RSVP progress or vote action',
      () async {
    source.record.addAll({
      'activityAttendance': true,
      'activityParticipantIds': ['me', 'other'],
      'activityGoingIds': ['other'],
      'activityCancelled': true
    });
    final group = (await repository.getActiveGroups()).single;
    expect(group.statusText, 'Activity cancelled');
    expect(group.hasProgress, isFalse);
    expect(group.primaryAction, GroupAction.viewDetails);
  });
  test('BQ5 sets current identity before recording a successful RSVP',
      () async {
    final analytics = _Analytics();
    final group = (await repository.getActiveGroups()).single;
    await ManageActiveGroups(repository,
        analytics: analytics,
        currentUserId: () => source.currentUserId).confirmRsvp(group);
    expect(analytics.calls, ['identity:me', 'rsvp_submitted']);
  });
  test('analytics failure does not turn a committed RSVP into an error',
      () async {
    final analytics = _Analytics()..fail = true;
    final group = (await repository.getActiveGroups()).single;
    final result = await ManageActiveGroups(repository,
        analytics: analytics,
        currentUserId: () => source.currentUserId).confirmRsvp(group);
    expect(result.single.hasResponded, isTrue);
    expect(source.writes, 1);
  });
  test('committed RSVP survives refresh failure and prevents repeat responses',
      () async {
    final group = (await repository.getActiveGroups()).single;
    source.failRead = true;
    final manage = ManageActiveGroups(repository);
    final updated = (await manage.confirmRsvp(group)).single;
    expect(updated.hasResponded, isTrue);
    expect(updated.progressCurrent, 2);
    expect(updated.invitationId, 'real-activity');
    await expectLater(manage.confirmRsvp(updated), throwsStateError);
    expect(source.writes, 1);
  });
  test('failed write does not report a successful response', () async {
    final group = (await repository.getActiveGroups()).single;
    source.failWrite = true;
    await expectLater(repository.confirmRsvp(group.id), throwsStateError);
    expect(source.writes, 0);
    expect((await repository.getActiveGroups()).single.hasResponded, isFalse);
  });
  test('signed-out users cannot reuse previously loaded groups', () async {
    await repository.getActiveGroups();
    source.currentUserId = null;
    await expectLater(repository.confirmRsvp('real-group'), throwsStateError);
    expect(source.writes, 0);
  });
  test('groups without activities cannot send fabricated invitation responses',
      () async {
    source.record.remove('invitationId');
    source.record.remove('invitationSentAt');
    final group = (await repository.getActiveGroups()).single;
    expect(group.hasProgress, isFalse);
    expect(group.hasInvitation, isFalse);
    await expectLater(repository.confirmRsvp(group.id), throwsStateError);
  });
}

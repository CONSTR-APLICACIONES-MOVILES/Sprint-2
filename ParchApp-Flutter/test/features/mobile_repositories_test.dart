import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/features/profile/data/repositories/firebase_profile_repository.dart';
import 'package:parchapp/features/profile/domain/entities/profile_user.dart';
import 'package:parchapp/features/alerts/data/repositories/firebase_alerts_repository.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/schedule/data/repositories/firebase_schedule_repository.dart';
import 'package:parchapp/features/schedule/data/data_sources/google_free_busy_data_source.dart';
import 'package:parchapp/features/schedule/domain/entities/schedule_block.dart';

class _Api implements MobileApi {
  final calls = <(String, Map<String, dynamic>)>[];
  late Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)
      handle;
  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> input) {
    calls.add((name, input));
    return handle(name, input);
  }
}

void main() {
  test('alert cache cannot be reused after changing accounts', () async {
    var uid = 'first';
    final api = _Api()
      ..handle = (_, __) async => {
            'alerts': [
              {
                'id': 'private-first',
                'title': 'Plan',
                'description': '',
                'createdAt': '2026-10-19T15:00:00Z',
                'isRead': false,
                'response': null,
                'studySessionId': 'private-first',
              }
            ]
          };
    final repository = FirebaseAlertsRepository(api, currentUserId: () => uid);
    await repository.getAlerts();
    uid = 'second';
    await expectLater(
        repository.respond('private-first', AlertResponse.accepted),
        throwsStateError);
    expect(await repository.markAllRead(), isEmpty);
    expect(api.calls.length, 1);
  });
  test(
      'profile maps authenticated fields and leaves unavailable statistics unknown',
      () async {
    final api = _Api()
      ..handle = (_, __) async => {
            'id': 'real-user',
            'name': 'Real student',
            'verified': false,
            'activeGroups': 2,
            'plansCompleted': 0,
            'onTimeRate': null,
          };
    final user = await FirebaseProfileRepository(api).getProfile();
    expect(user.id, 'real-user');
    expect(user.program, isEmpty);
    expect(user.academicLevelLabel, 'Not set');
    expect(user.verified, isFalse);
    expect(user.onTimeRate, isNull);
  });
  test(
      'profile updates send only editable fields, never ownership or statistics',
      () async {
    final api = _Api();
    final profile = {
      'id': 'real-user',
      'name': 'Student',
      'activeGroups': 2,
      'plansCompleted': 0,
      'onTimeRate': null,
      'verified': false
    };
    api.handle = (name, data) async =>
        {...profile, if (name == 'updateProfile') ...data['fields'] as Map};
    final repository = FirebaseProfileRepository(api);
    final user = await repository.getProfile();
    final updated = await repository
        .updateProfile(user.copyWith(name: 'New name', program: 'Engineering'));
    expect(updated.name, 'New name');
    final fields = api.calls.last.$2['fields'] as Map;
    expect(fields.keys, isNot(contains('id')));
    expect(fields.keys, isNot(contains('verified')));
    expect(fields.keys, isNot(contains('plansCompleted')));
    final busy = await repository.updateStatus(AvailabilityStatus.busy);
    expect(busy.status, AvailabilityStatus.busy);
    expect(api.calls.last.$2, {
      'fields': {'status': 'busy'}
    });
  });
  test('profile errors propagate instead of substituting a sample identity',
      () async {
    final api = _Api()..handle = (_, __) async => throw StateError('offline');
    await expectLater(
        FirebaseProfileRepository(api).getProfile(), throwsStateError);
  });
  test('schedule maps private personal blocks and hides friend titles',
      () async {
    final api = _Api()
      ..handle = (_, __) async => {
            'schedules': [
              {
                'ownerId': 'me',
                'known': true,
                'busy': [
                  {'start': 600, 'end': 660}
                ]
              },
              {
                'ownerId': 'peer',
                'known': true,
                'busy': [
                  {'start': 720, 'end': 780}
                ]
              },
            ]
          };
    final repository = FirebaseScheduleRepository(api, () => 'me');
    final day = DateTime(2026, 10, 19);
    final mine = await repository.getMySchedule(day: day);
    final friends =
        await repository.getFriendsBusyBlocks(day: day, friendIds: ['peer']);
    expect(mine.single.start, DateTime(2026, 10, 19, 10));
    expect(friends.single.ownerId, 'peer');
    expect(friends.single.title, isNull);
    expect(friends.single.location, isNull);
    expect(api.calls.last.$2, {
      'date': '2026-10-19',
      'friendIds': ['peer']
    });
  });
  test('unknown availability cannot produce apparently empty free schedules',
      () async {
    final api = _Api()
      ..handle = (_, __) async => {
            'schedules': [
              {'ownerId': 'me', 'known': false, 'busy': []},
            ]
          };
    final repository = FirebaseScheduleRepository(api, () => 'me');
    await expectLater(repository.getMySchedule(day: DateTime(2026, 10, 20)),
        throwsStateError);
  });
  test('calendar persistence sends intervals only, never private event content',
      () async {
    final api = _Api()..handle = (_, __) async => {};
    final repository = FirebaseScheduleRepository(api, () => 'me');
    await repository.replaceImportedCalendarBlocks([
      ScheduleBlock(
          id: 'private-id',
          start: DateTime.utc(2026, 10, 19, 15),
          end: DateTime.utc(2026, 10, 19, 16),
          type: ScheduleBlockType.personalEvent,
          title: 'Private doctor',
          location: 'Private location')
    ]);
    final payload = api.calls.single.$2;
    expect(payload['days'], 56);
    expect((payload['intervals'] as List).single, {
      'start': '2026-10-19T15:00:00.000Z',
      'end': '2026-10-19T16:00:00.000Z',
    });
    expect(jsonEncode(payload), isNot(contains('Private')));
    expect(jsonEncode(payload), isNot(contains('private-id')));
  });
  test(
      'Google FreeBusy requests the Bogota window and reads only busy intervals',
      () async {
    final source = GoogleFreeBusyDataSource(
        headers: () async => {'Authorization': 'Bearer test'},
        now: () => DateTime.utc(2026, 10, 20, 2),
        createClient: () => MockClient((request) async {
              expect(request.url.path, '/calendar/v3/freeBusy');
              final body = jsonDecode(request.body) as Map;
              expect(body['timeMin'], '2026-10-19T05:00:00.000Z');
              expect(body['items'], [
                {'id': 'primary'}
              ]);
              return http.Response(
                  jsonEncode({
                    'calendars': {
                      'primary': {
                        'busy': [
                          {
                            'start': '2026-10-19T15:00:00Z',
                            'end': '2026-10-19T16:00:00Z'
                          },
                        ]
                      }
                    }
                  }),
                  200);
            }));
    final blocks = await source.importEvents();
    expect(blocks.single.title, 'Busy');
    expect(blocks.single.description, isNull);
    expect(blocks.single.start, DateTime.utc(2026, 10, 19, 15));
  });
  test(
      'Google partial failures and revoked access are errors, not empty calendars',
      () async {
    for (final status in [200, 403]) {
      final source = GoogleFreeBusyDataSource(
          headers: () async => {},
          createClient: () => MockClient((_) async => http.Response(
              jsonEncode({
                'calendars': {
                  'primary': {
                    'busy': [],
                    'errors': [
                      {'reason': 'forbidden'}
                    ]
                  }
                }
              }),
              status)));
      await expectLater(source.importEvents(), throwsStateError);
    }
  });
  test('an explicitly empty Google calendar is a successful import', () async {
    final source = GoogleFreeBusyDataSource(
        headers: () async => {},
        createClient: () => MockClient((_) async => http.Response(
            jsonEncode({
              'calendars': {
                'primary': {'busy': []}
              }
            }),
            200)));
    expect(await source.importEvents(), isEmpty);
  });
  test(
      'real alerts retain IDs, responses and read state after successful commands',
      () async {
    final api = _Api()
      ..handle = (name, _) async => name == 'getAlerts'
          ? {
              'alerts': [
                {
                  'id': 'activity-real',
                  'title': 'Plan',
                  'description': 'Library',
                  'createdAt': '2026-10-19T15:00:00Z',
                  'isRead': false,
                  'response': null,
                  'studySessionId': 'activity-real',
                  'groupSize': 3,
                }
              ]
            }
          : {};
    final repository = FirebaseAlertsRepository(api);
    final initial = (await repository.getAlerts()).single;
    expect(initial.studySessionId, 'activity-real');
    expect(initial.isRead, isFalse);
    expect((await repository.markAllRead()).single.isRead, isTrue);
    expect(api.calls.last.$2, {
      'ids': ['activity-real']
    });
    expect(
        (await repository.respond(initial.id, AlertResponse.accepted))
            .single
            .response,
        AlertResponse.accepted);
    expect(api.calls.last.$2, {
      'id': 'activity-real',
      'response': 'accepted',
      'expectedResponse': null
    });
  });
  test('an alert write failure does not resolve the local invitation',
      () async {
    final api = _Api()
      ..handle = (name, _) async {
        if (name == 'respondToActivityInvitation') throw StateError('offline');
        return {
          'alerts': [
            {
              'id': 'real',
              'title': 'Plan',
              'description': '',
              'createdAt': '2026-10-19T15:00:00Z',
              'isRead': false,
              'response': null,
              'studySessionId': 'real'
            }
          ]
        };
      };
    final repository = FirebaseAlertsRepository(api);
    await repository.getAlerts();
    await expectLater(
        repository.respond('real', AlertResponse.accepted), throwsStateError);
    // Read-state mutation returns the existing entity, whose response is still absent.
    expect((await repository.markAllRead()).single.response, isNull);
  });
}

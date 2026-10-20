import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parchapp/shared/widgets/offline_shell.dart';
import 'package:parchapp/shared/widgets/pending_invitations_panel.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/core/data/offline_mobile_api.dart';

class _Store implements OfflineStore {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('disk unavailable');
    values[key] = value;
  }
}

class _Remote implements MobileApi {
  bool unavailable = false, denied = false, conflict = false;
  int mutations = 0;
  final conflictIds = <String>{};
  final calls = <(String, Map<String, dynamic>)>[];
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    calls.add((name, input));
    if (unavailable) {
      throw FirebaseFunctionsException(code: 'unavailable', message: 'offline');
    }
    if (denied) {
      throw FirebaseFunctionsException(
          code: 'permission-denied', message: 'forbidden');
    }
    if (name == 'respondToActivityInvitation' || name == 'markAlertsRead') {
      if (conflict || conflictIds.contains(input['id'])) {
        throw FirebaseFunctionsException(
            code: 'failed-precondition', message: 'changed');
      }
      mutations++;
      return input;
    }
    if (name == 'getAlerts') {
      return {
        'alerts': [
          {'id': 'a1', 'response': null, 'isRead': false}
        ]
      };
    }
    if (name == 'updateProfile') {
      return {'id': 'u1', 'name': input['fields']['name']};
    }
    return {'id': 'u1', 'name': 'Actual student'};
  }
}

void main() {
  late _Store store;
  late _Remote remote;
  late OfflineMobileApi api;
  late DateTime now;
  String? uid;
  OfflineMobileApi create() => OfflineMobileApi(
      remote: remote,
      store: store,
      project: 'demo',
      currentUserId: () => uid,
      clock: () => now);
  setUp(() {
    now = DateTime.utc(2026, 10, 19);
    uid = 'u1';
    store = _Store();
    remote = _Remote();
    api = create();
  });
  tearDown(() => api.dispose());

  for (final debug in [false, true]) {
    testWidgets(
        'connectivity simulation controls require explicit opt-in: $debug',
        (tester) async {
      api.dispose();
      api = create();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const connectivity =
          MethodChannel('dev.fluttercommunity.plus/connectivity');
      const events =
          MethodChannel('dev.fluttercommunity.plus/connectivity_status');
      messenger.setMockMethodCallHandler(connectivity, (_) async => ['wifi']);
      messenger.setMockMethodCallHandler(events, (_) async => null);
      addTearDown(() {
        messenger.setMockMethodCallHandler(connectivity, null);
        messenger.setMockMethodCallHandler(events, null);
      });
      await tester.pumpWidget(MaterialApp(
          home: OfflineShell(
        api: api,
        showDebugControls: debug,
        child: const Text('App content'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('App content'), findsOneWidget);
      expect(find.text('Use offline'), debug ? findsOneWidget : findsNothing);
      expect(find.text('Online'), debug ? findsOneWidget : findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('review panel confirms discard of only the selected response',
      (tester) async {
    // Construct the serialization future inside the widget test's async zone.
    api.dispose();
    api = create();
    await api.setForcedOffline(true);
    for (final id in ['a1', 'a2']) {
      await api.call(
          'respondToActivityInvitation', {'id': id, 'response': 'accepted'});
    }
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PendingInvitationsPanel(api: api))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Discard this local response').first);
    await tester.pumpAndSettle();
    expect(
        find.text('Discard this local response? Other responses will be kept.'),
        findsOneWidget);
    expect(api.value.pending, 2);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(api.value.pending, 1);
    expect((await api.pendingInvitations()).single.id, 'a2');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('a rejected invitation does not block independent responses', () async {
    await api.setForcedOffline(true);
    for (final id in ['a1', 'a2']) {
      await api.call(
          'respondToActivityInvitation', {'id': id, 'response': 'accepted'});
    }
    remote.conflictIds.add('a1');
    await api.setForcedOffline(false);
    expect(remote.mutations, 1);
    expect(api.value.pending, 1);
    expect((await api.pendingInvitations()).single.id, 'a1');
    expect((await api.pendingInvitations()).single.blocked, true);
    final calls = remote.calls.length;
    await api.flush(automatic: true);
    expect(remote.calls.length, calls);
  });

  test('individual retry sends only the selected invitation', () async {
    await api.setForcedOffline(true);
    for (final id in ['a1', 'a2']) {
      await api.call(
          'respondToActivityInvitation', {'id': id, 'response': 'accepted'});
    }
    remote.conflict = true;
    await api.setForcedOffline(false);
    remote.conflict = false;
    final calls = remote.calls.length;
    await api.flush(invitationId: 'a2');
    expect(remote.calls.length, calls + 1);
    expect(remote.calls.last.$2['id'], 'a2');
    expect((await api.pendingInvitations()).single.id, 'a1');
  });

  test('discard keeps other invitations and read commands across restart',
      () async {
    await api.call('getAlerts', {});
    await api.setForcedOffline(true);
    for (final id in ['a1', 'a2']) {
      await api.call(
          'respondToActivityInvitation', {'id': id, 'response': 'accepted'});
    }
    await api.call('markAlertsRead', {
      'ids': ['a2']
    });
    await api.discardInvitation('a1');
    final restarted = create();
    addTearDown(restarted.dispose);
    await restarted.refreshSession();
    expect(restarted.value.pending, 2);
    expect((await restarted.pendingInvitations()).single.id, 'a2');
    await restarted.flush();
    expect(remote.mutations, 2);
    expect(
        remote.calls
            .where((c) => c.$1 == 'respondToActivityInvitation')
            .single
            .$2['id'],
        'a2');
  });

  test('failed individual discard preserves the durable response', () async {
    await api.setForcedOffline(true);
    await api.call(
        'respondToActivityInvitation', {'id': 'a1', 'response': 'accepted'});
    store.fail = true;
    await expectLater(api.discardInvitation('a1'), throwsStateError);
    expect((await api.pendingInvitations()).single.id, 'a1');
    expect(api.value.pending, 1);
  });

  test('individual discard is scoped to the active account', () async {
    await api.setForcedOffline(true);
    await api.call(
        'respondToActivityInvitation', {'id': 'a1', 'response': 'accepted'});
    uid = 'u2';
    await api.discardInvitation('a1');
    expect(await api.pendingInvitations(), isEmpty);
    uid = 'u1';
    expect((await api.pendingInvitations()).single.id, 'a1');
  });

  test(
      'automatic retries back off across restart and manual retry bypasses wait',
      () async {
    await api.setForcedOffline(true);
    await api.call(
        'respondToActivityInvitation', {'id': 'a1', 'response': 'accepted'});
    remote.unavailable = true;
    await api.setForcedOffline(false);
    expect(remote.calls.length, 1);
    final restarted = create();
    addTearDown(restarted.dispose);
    await restarted.flush(automatic: true);
    expect(remote.calls.length, 1);
    now = now.add(const Duration(seconds: 30));
    await restarted.flush(automatic: true);
    expect(remote.calls.length, 2);
    now = now.add(const Duration(seconds: 30));
    await restarted.flush(automatic: true);
    expect(remote.calls.length, 2);
    remote.unavailable = false;
    await restarted.flush();
    expect(remote.mutations, 1);
    expect(restarted.value.pending, 0);
  });

  test('server rejection pauses automatic replay until explicit retry',
      () async {
    await api.setForcedOffline(true);
    await api.call(
        'respondToActivityInvitation', {'id': 'a1', 'response': 'accepted'});
    remote.conflict = true;
    await api.setForcedOffline(false);
    now = now.add(const Duration(days: 1));
    final restarted = create();
    addTearDown(restarted.dispose);
    await restarted.flush(automatic: true);
    expect(remote.calls.length, 1);
    expect(restarted.value.pending, 1);
    expect(restarted.value.error, contains('review'));
    remote.conflict = false;
    await restarted.flush();
    expect(remote.mutations, 1);
    expect(restarted.value.pending, 0);
  });

  test('saved reads work after restart without contacting the server',
      () async {
    await api.call('getProfile', {});
    final restarted = create();
    addTearDown(restarted.dispose);
    await restarted.setForcedOffline(true);
    final saved = await restarted.call('getProfile', {});
    expect(saved['name'], 'Actual student');
    expect(saved['offline'], true);
    expect(saved['cachedAt'], isNotNull);
    expect(remote.calls.length, 1);
  });
  test('network failures use saved data but permission failures do not',
      () async {
    await api.call('getProfile', {});
    remote.unavailable = true;
    expect((await api.call('getProfile', {}))['offline'], true);
    remote.unavailable = false;
    remote.denied = true;
    await expectLater(
        api.call('getProfile', {}), throwsA(isA<FirebaseFunctionsException>()));
  });
  test('a view not previously loaded has no fabricated offline data', () async {
    await api.setForcedOffline(true);
    await expectLater(
        api.call('getScheduleDay', {'date': '2026-10-20', 'friendIds': []}),
        throwsStateError);
  });
  test(
      'offline invitation response persists, overlays the inbox and replays once',
      () async {
    await api.call('getAlerts', {});
    await api.setForcedOffline(true);
    final result = await api.call(
        'respondToActivityInvitation', {'id': 'a1', 'response': 'accepted'});
    expect(result['pending'], true);
    expect(remote.mutations, 0);
    final inbox = await api.call('getAlerts', {});
    expect((inbox['alerts'] as List).single['pendingSync'], true);
    final restarted = create();
    addTearDown(restarted.dispose);
    await restarted.refreshSession();
    expect(restarted.value.pending, 1);
    await restarted.flush();
    expect(restarted.value.pending, 0);
    expect(remote.mutations, 1);
    expect(remote.calls.last.$2['clientUserId'], 'u1');
    await restarted.flush();
    expect(remote.mutations, 1);
  });
  test(
      'identical pending commands coalesce and conflicting responses are rejected',
      () async {
    await api.setForcedOffline(true);
    for (var i = 0; i < 2; i++) {
      await api.call(
          'respondToActivityInvitation', {'id': 'a1', 'response': 'accepted'});
    }
    expect(api.value.pending, 1);
    await expectLater(
        api.call('respondToActivityInvitation',
            {'id': 'a1', 'response': 'declined'}),
        throwsStateError);
  });
  test('persistence failure never reports that an offline response was saved',
      () async {
    await api.setForcedOffline(true);
    store.fail = true;
    await expectLater(
        api.call('respondToActivityInvitation',
            {'id': 'a1', 'response': 'accepted'}),
        throwsStateError);
    expect(api.value.pending, 0);
  });
  test(
      'server conflicts retain a pending command for explicit retry or discard',
      () async {
    await api.setForcedOffline(true);
    await api.call(
        'respondToActivityInvitation', {'id': 'a1', 'response': 'accepted'});
    remote.conflict = true;
    await api.setForcedOffline(false);
    expect(api.value.pending, 1);
    expect(api.value.error, isNotNull);
    expect(remote.mutations, 0);
    await api.discardPending();
    expect(api.value.pending, 0);
  });
  test('cache and queue never cross accounts', () async {
    await api.call('getProfile', {});
    await api.setForcedOffline(true);
    await api.call(
        'respondToActivityInvitation', {'id': 'a1', 'response': 'accepted'});
    uid = 'u2';
    await api.refreshSession();
    expect(api.value.pending, 0);
    await expectLater(api.call('getProfile', {}), throwsStateError);
    await api.setForcedOffline(false);
    expect(remote.mutations, 0);
    uid = 'u1';
    await api.flush();
    expect(remote.mutations, 1);
  });
  test('concurrent offline saves do not overwrite one another', () async {
    await api.setForcedOffline(true);
    await Future.wait([
      for (var i = 0; i < 6; i++)
        api.call('respondToActivityInvitation',
            {'id': 'a$i', 'response': 'accepted'})
    ]);
    expect(api.value.pending, 6);
    await api.setForcedOffline(false);
    expect(remote.mutations, 6);
    expect(api.value.pending, 0);
  });
  test('non-idempotent profile writes require a connection', () async {
    await api.setForcedOffline(true);
    await expectLater(
        api.call('updateProfile', {
          'fields': {'name': 'Changed'}
        }),
        throwsStateError);
    expect(api.value.pending, 0);
  });
  test('a successful profile update refreshes its saved display name',
      () async {
    await api.call('getProfile', {});
    await api.call('updateProfile', {
      'fields': {'name': 'Edited name'}
    });
    await api.setForcedOffline(true);
    expect((await api.call('getProfile', {}))['name'], 'Edited name');
  });
  test(
      'a committed replay stays retryable if deleting its persisted queue entry fails',
      () async {
    await api.setForcedOffline(true);
    await api.call(
        'respondToActivityInvitation', {'id': 'a1', 'response': 'accepted'});
    store.fail = true;
    await api.setForcedOffline(false);
    expect(remote.mutations, 1);
    expect(api.value.pending, 1);
    expect(api.value.error, isNotNull);
    store.fail = false;
    await api.flush();
    expect(api.value.pending, 0);
  });
  test(
      'corrupt saved data is reported without overwriting the pending document',
      () async {
    store.values['offline.v1.demo.u1'] = '{broken';
    await api.refreshSession();
    expect(api.value.error, isNotNull);
    await api.flush();
    expect(store.values['offline.v1.demo.u1'], '{broken');
    expect(api.value.error, isNotNull);
  });
}

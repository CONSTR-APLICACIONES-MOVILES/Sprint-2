import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parchapp/features/activities/data/data_sources/creation_attempt_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });
  test('success and retry keep requestId but have distinct attempts', () async {
    final sent = <Map<String, dynamic>>[];
    final monitor = CreationAttemptMonitor(preferences,
        project: 'demo',
        uid: 'a',
        canSend: () => true,
        send: (event) async {
          sent.add(event);
        });
    expect(await monitor.observe('request', () async => 'id'), 'id');
    await monitor.flush();
    await monitor.observe('request', () async => 'id');
    await monitor.flush();
    final results = sent.where((e) => e['phase'] == 'result').toList();
    expect(results, hasLength(2));
    expect(results.map((e) => e['attemptId']).toSet(), hasLength(2));
    expect(
        results.every(
            (e) => e['requestId'] == 'request' && e['outcome'] == 'success'),
        isTrue);
  });
  test(
      'timeout preserves observation while late success is separate reconciliation',
      () async {
    final sent = <Map<String, dynamic>>[];
    final network = Completer<String>();
    final monitor = CreationAttemptMonitor(preferences,
        project: 'demo',
        uid: 'a',
        deadline: const Duration(milliseconds: 10),
        canSend: () => true,
        send: (event) async {
          sent.add(event);
        });
    await expectLater(monitor.observe('request', () => network.future),
        throwsA(isA<TimeoutException>()));
    network.complete('canonical-id');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await monitor.flush();
    expect(
        sent.where((e) => e['phase'] == 'result').single['outcome'], 'timeout');
    expect(sent.where((e) => e['phase'] == 'reconcile').single['outcome'],
        'success');
    expect(sent.map((e) => e['attemptId']).toSet(), hasLength(1));
  });
  test(
      'failed telemetry survives reload and another account/project cannot flush it',
      () async {
    final original = CreationAttemptMonitor(preferences,
        project: 'demo',
        uid: 'a',
        canSend: () => false,
        send: (_) async => throw StateError('offline'));
    expect(await original.observe('request', () async => 'id'), 'id');
    await preferences.reload();
    final sent = <Map<String, dynamic>>[];
    final wrong = CreationAttemptMonitor(preferences,
        project: 'demo',
      uid: 'a.child',
        canSend: () => true,
        send: (e) async {
          sent.add(e);
        });
    await wrong.flush();
    expect(sent, isEmpty);
    final other = CreationAttemptMonitor(preferences,
        project: 'other',
        uid: 'a',
        canSend: () => true,
        send: (e) async {
          sent.add(e);
        });
    await other.flush();
    expect(sent, isEmpty);
    final restored = CreationAttemptMonitor(preferences,
        project: 'demo',
        uid: 'a',
        canSend: () => true,
        send: (e) async {
          sent.add(e);
        });
    await restored.flush();
    expect(sent, hasLength(2));
    expect(preferences.getKeys().where((k) => k.startsWith(restored.prefix)),
        isEmpty);
  });
  test('server rejection persists a failure and rethrows original error',
      () async {
    final failure = StateError('rejected');
    final monitor = CreationAttemptMonitor(preferences,
        project: 'demo', uid: 'a', canSend: () => false, send: (_) async {});
    await expectLater(monitor.observe('request', () async => throw failure),
        throwsA(same(failure)));
    final result =
        preferences.getKeys().singleWhere((k) => k.endsWith('.result'));
    expect(jsonDecode(preferences.getString(result)!)['outcome'], 'failure');
  });
  test('logout during flush retains unsent account observations', () async {
    var signedIn = true;
    final monitor = CreationAttemptMonitor(preferences,
        project: 'demo',
        uid: 'a',
        canSend: () => signedIn,
        send: (_) async {
          signedIn = false;
        });
    await monitor.observe('request', () async => 'id');
    await monitor.flush();
    expect(preferences.getKeys().where((k) => k.startsWith(monitor.prefix)),
        isNotEmpty);
  });
}

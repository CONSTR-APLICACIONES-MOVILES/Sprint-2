@TestOn('vm')
library;

import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/io_client.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/core/data/offline_mobile_api.dart';
import 'package:parchapp/core/theme/app_theme.dart';
import 'package:parchapp/features/activities/data/data_sources/activity_data_source.dart';
import 'package:parchapp/features/activities/data/models/activity_model.dart';
import 'package:parchapp/features/activities/data/repositories/firebase_study_sessions_repository.dart';
import 'package:parchapp/features/activities/domain/use_cases/manage_study_session.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_editor_view_model.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_invitation_view_model.dart';
import 'package:parchapp/features/activities/presentation/widgets/activity_form.dart';
import 'package:parchapp/features/activities/presentation/views/activity_result_view.dart';
import 'package:parchapp/features/alerts/data/repositories/firebase_alerts_repository.dart';

// Opt-in integration test: actual Auth/Functions/Firestore over HTTP with a
// Flutter widget renderer. This does not claim to run on a physical device.
const enabled = bool.fromEnvironment('RUN_SPRINT3_E2E');

class HttpApi implements MobileApi {
  final IOClient client;
  final String token;
  HttpApi(this.client, this.token);
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    final response = await client.post(
        Uri.parse('http://127.0.0.1:5001/demo-parchapp/us-central1/$name'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Connection': 'close'
        },
        body: jsonEncode({'data': input}));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['error'] != null) {
      throw StateError('$name failed: ${data['error']}');
    }
    return Map<String, dynamic>.from(data['result'] as Map);
  }
}

class HttpActivities implements ActivityDataSource {
  final MobileApi api;
  @override
  final String currentUserId;
  final String groupId;
  HttpActivities(this.api, this.currentUserId, this.groupId);
  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> input) =>
      api.call(name, input);
  @override
  Future<List<Map<String, dynamic>>> listGroups() async {
    final group = await api.call('getGroupDetails', {'groupId': groupId});
    return [group];
  }

  @override
  Future<String> createActivity(Map<String, dynamic> input) async =>
      (await api.call('publishActivity', input))['activityId'] as String;
  @override
  Future<List<ActivityModel>> listActivities() async => [
        for (final row
            in (await api.call('getActivities', {}))['activities'] as List)
          ActivityModel(Map<String, dynamic>.from(row as Map))
      ];
  @override
  Future<void> updateActivity(String id, Map<String, dynamic> fields) async =>
      throw UnsupportedError('Use the versioned callable.');
}

class FileStore implements OfflineStore {
  final file = File('build/sprint3-e2e-cache.json');
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async {
    if (await file.exists()) {
      data.addAll(Map<String, String>.from(
          jsonDecode(await file.readAsString()) as Map));
    }
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
    await file.writeAsString(jsonEncode(data), flush: true);
  }
}

void main() {
  if (!enabled) {
    test('API/UI integration requires explicit local emulator opt-in', () {},
        skip:
            'Run with --dart-define=RUN_SPRINT3_E2E=true after seed-sprint3-e2e.cjs');
    return;
  }
  // Construct a real client before the widget binding installs its network stub.
  final client = IOClient(HttpClient());
  testWidgets('real API/UI: create, review and persisted result',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(client.close);
    Future<HttpApi> login(String email) async {
      final response = await client.post(
          Uri.parse(
              'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-emulator'),
          headers: {'Content-Type': 'application/json', 'Connection': 'close'},
          body: jsonEncode({
            'email': email,
            'password': 'Sprint3Qa123!',
            'returnSecureToken': true
          }));
      final data = jsonDecode(response.body) as Map;
      expect(response.statusCode, 200);
      return HttpApi(client, data['idToken'] as String);
    }

    late HttpApi owner;
    await tester.runAsync(() async {
      owner = await login('sprint3-qa-owner@parchapp.test');
    });
    final repo = FirebaseStudySessionsRepository(
        HttpActivities(owner, 'sprint3-qa-owner', 'sprint3-qa-group'));
    final model = ActivityEditorViewModel(ManageStudySession(repo));
    addTearDown(model.dispose);
    String? saved;
    late final GoRouter router;
    router = GoRouter(initialLocation: '/new', routes: [
      GoRoute(
          path: '/new',
          builder: (_, __) => Scaffold(
              body: ActivityForm(
                  viewModel: model,
                  onSaved: (id) {
                    saved = id;
                    router.go('/result/$id');
                  }))),
      GoRoute(
          path: '/result/:id',
          builder: (_, s) => ActivityResultView(
              activityId: s.pathParameters['id']!,
              repository: repo,
              acknowledged: true))
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        key: routerKey, theme: AppTheme.lightTheme, routerConfig: router));
    Future<void> settleUntil(bool Function() done) async {
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        if (done()) {
          await tester.pumpAndSettle();
          return;
        }
      }
      throw StateError('Timed out waiting for the real API');
    }

    await settleUntil(
        () => !model.value.loading && model.value.groups.isNotEmpty);
    await tester.enterText(find.widgetWithText(TextField, 'Activity name'),
        'Sprint 3 API/UI verification');
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Review Activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review Activity'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(find.text('Sprint 3 API/UI verification'), findsOneWidget);
    await tester.ensureVisible(find.text('Create Activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Activity'));
    await settleUntil(() =>
        saved != null &&
        find.text('Created · Not scheduled').evaluate().isNotEmpty);
    expect(find.text('Activity created'), findsOneWidget);
    debugPrint('E2E: creation and result verified');
    await tester.runAsync(() => File('build/sprint3-api-ui-e2e-result.json')
        .writeAsString(jsonEncode({'activityId': saved, 'created': true})));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
  test(
      'real API and view model: offline RSVP, durable restart, edit and cancel',
      () async {
    final live = IOClient(HttpOverrides.runWithHttpOverrides(
        () => HttpClient(), _LiveHttpOverrides()));
    addTearDown(live.close);
    Future<HttpApi> login(String email) async {
      final r = await live.post(
          Uri.parse(
              'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-emulator'),
          headers: {'Content-Type': 'application/json', 'Connection': 'close'},
          body: jsonEncode({
            'email': email,
            'password': 'Sprint3Qa123!',
            'returnSecureToken': true
          }));
      expect(r.statusCode, 200);
      return HttpApi(live, (jsonDecode(r.body) as Map)['idToken'] as String);
    }

    final owner = await login('sprint3-qa-owner@parchapp.test');
    final member = await login('sprint3-qa-member@parchapp.test');
    final receipt = Map<String, dynamic>.from(jsonDecode(
            await File('build/sprint3-api-ui-e2e-result.json').readAsString())
        as Map);
    final id = receipt['activityId'] as String;
    await File('build/sprint3-e2e-cache.json').writeAsString('{}');
    final api = OfflineMobileApi(
        remote: member,
        store: FileStore(),
        project: 'demo-parchapp',
        currentUserId: () => 'sprint3-qa-member');
    final repo = FirebaseStudySessionsRepository(
        HttpActivities(api, 'sprint3-qa-member', 'sprint3-qa-group'));
    final inbox =
        FirebaseAlertsRepository(api, currentUserId: () => 'sprint3-qa-member');
    await repo.getById(id);
    await inbox.getAlerts();
    await api.setForcedOffline(true);
    final model = ActivityInvitationViewModel(
        activityId: id, sessions: repo, alerts: inbox);
    await model.load();
    expect(model.value.invitation, isNotNull);
    await model.respond(AlertResponse.accepted);
    expect(model.value.invitation!.pendingSync, true);
    expect(api.value.pending, 1);
    model.dispose();
    api.dispose();
    final restarted = OfflineMobileApi(
        remote: member,
        store: FileStore(),
        project: 'demo-parchapp',
        currentUserId: () => 'sprint3-qa-member');
    await restarted.refreshSession();
    expect(restarted.value.pending, 1);
    await restarted.flush();
    expect(restarted.value.pending, 0);
    restarted.dispose();
    var details = await owner.call('getActivity', {'activityId': id});
    expect(
        (details['participants'] as List).firstWhere(
            (p) => p['id'] == 'sprint3-qa-member')['activityRsvpStatus'],
        'accepted');
    await owner.call('updateActivityDetails', {
      'activityId': id,
      'expectedVersion': details['version'],
      'fields': {
        'title': 'Sprint 3 API/UI edited',
        'category': 'study',
        'status': 'CONFIRMED'
      }
    });
    details = await owner.call('getActivity', {'activityId': id});
    expect(details['title'], 'Sprint 3 API/UI edited');
    await owner.call('cancelActivity',
        {'activityId': id, 'expectedVersion': details['version']});
    details = await owner.call('getActivity', {'activityId': id});
    expect(details['cancelled'], true);
    await File('build/sprint3-api-ui-e2e-result.json')
        .writeAsString(jsonEncode({
      ...receipt,
      'responsePersisted': true,
      'replayedAfterRestart': true,
      'edited': true,
      'cancelled': true
    }));
  }, timeout: const Timeout(Duration(minutes: 2)));
}

final routerKey = GlobalKey();

class _LiveHttpOverrides extends HttpOverrides {}

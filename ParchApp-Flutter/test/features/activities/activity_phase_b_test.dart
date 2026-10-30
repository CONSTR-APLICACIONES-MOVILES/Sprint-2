import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/app/router/app_extra_codec.dart';
import 'package:parchapp/features/activities/data/data_sources/activity_data_source.dart';
import 'package:parchapp/features/activities/data/repositories/firebase_study_sessions_repository.dart';
import 'package:parchapp/features/activities/domain/entities/activity_draft.dart';
import 'package:parchapp/features/activities/domain/entities/planning_context.dart';
import 'package:parchapp/features/activities/domain/use_cases/manage_study_session.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_editor_view_model.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_invitation_view_model.dart';
import 'package:parchapp/features/activities/presentation/views/activity_invitation_view.dart';
import 'package:parchapp/features/activities/presentation/views/activity_result_view.dart';
import 'package:parchapp/features/activities/presentation/widgets/activity_form.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/alerts/domain/repositories/alerts_repository.dart';
import 'firebase_study_sessions_repository_test.dart' show FakeActivitySource;

class RecoverableSource extends FakeActivitySource
    implements PublicationRecoveryDataSource {
  Map<String, dynamic>? journal;
  bool loseAcknowledgement = true;
  final received = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>?> pendingPublication() async => journal;
  @override
  Future<String> createActivity(Map<String, dynamic> input) async {
    received.add(input);
    journal = input;
    if (received.length == 1) await super.createActivity(input);
    if (loseAcknowledgement) {
      loseAcknowledgement = false;
      throw FirebaseFunctionsException(
          code: 'deadline-exceeded', message: 'acknowledgement lost');
    }
    journal = null;
    return 'created-document';
  }
}

class Inbox implements AlertsRepository {
  bool pending = false, fail = false;
  AppAlert invitation = const AppAlert(
      id: 'firestore-document',
      kind: AlertKind.invitation,
      period: AlertPeriod.today,
      title: 'Real activity',
      description: '',
      timeLabel: '12:00');
  @override
  Future<List<AppAlert>> getAlerts() async => [invitation];
  @override
  Future<List<AppAlert>> respond(String id, AlertResponse response) async {
    if (fail) throw StateError('disk or response conflict');
    invitation = invitation.copyWith(
        response: response, pendingSync: pending, isRead: true);
    return [invitation];
  }

  @override
  Future<List<AppAlert>> markAllRead() => getAlerts();
}

class FailedRead extends FakeActivitySource {
  int reads = 0;
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    if (name == 'getActivity') {
      reads++;
      throw StateError('read unavailable');
    }
    return super.call(name, input);
  }
}

void main() {
  final planning = PlanningContext(
      start: DateTime.utc(2030, 10, 2, 16),
      end: DateTime.utc(2030, 10, 2, 17),
      participantIds: const ['organizer', 'member'],
      groupId: 'group',
      sourceSlotId: 'slot-9',
      comparisonId: 'comparison-4',
      expiresAt: DateTime.utc(2030, 10, 2, 15));
  final draft = ActivityDraft(
      groupId: 'group',
      title: 'Compared activity',
      startsAt: planning.start,
      endsAt: planning.end,
      planning: planning);

  test('navigation codec preserves canonical context and server evidence', () {
    const codec = AppExtraCodec();
    final restored = codec.decode(codec.encode(planning)) as PlanningContext;
    expect(restored.start, planning.start);
    expect(restored.end, planning.end);
    expect(restored.participantIds, planning.participantIds);
    expect(restored.comparisonId, planning.comparisonId);
    expect(restored.expiresAt, planning.expiresAt);
    expect(restored.groupId, 'group');
    expect(restored.durationMinutes, 60);
    expect(restored.timeZone, 'America/Bogota');
  });

  test(
      'lost acknowledgement freezes the reviewed input and reuses its publication key',
      () async {
    final source = RecoverableSource();
    final model = ActivityEditorViewModel(
        ManageStudySession(FirebaseStudySessionsRepository(source)));
    addTearDown(model.dispose);
    await model.load();
    expect(await model.save(draft), isNull);
    expect(model.publicationUncertain, isTrue);
    expect(
        await model.save(
            const ActivityDraft(groupId: 'group', title: 'Changed input')),
        'created-document');
    expect(source.received[0], source.received[1]);
    expect(source.writes, hasLength(1));
    expect(source.received.last['comparisonId'], 'comparison-4');
    expect(source.received.last['participantIds'], ['organizer', 'member']);
  });

  test(
      'a new editor recovers the publication after a restart with the same request ID',
      () async {
    final source = RecoverableSource();
    final first = ActivityEditorViewModel(
        ManageStudySession(FirebaseStudySessionsRepository(source)));
    await first.load();
    await first.save(draft);
    final key = first.publicationKey;
    first.dispose();
    final second = ActivityEditorViewModel(
        ManageStudySession(FirebaseStudySessionsRepository(source)));
    addTearDown(second.dispose);
    await second.load();
    expect(second.publicationKey, key);
    expect(second.recoveredDraft!.title, draft.title);
    expect(second.recoveredDraft!.planning!.comparisonId, 'comparison-4');
    expect(await second.save(second.recoveredDraft!), 'created-document');
    expect(source.writes, hasLength(1));
    expect(source.journal, isNull);
  });

  testWidgets(
      'Details -> Review -> Details keeps the draft and does not publish early',
      (tester) async {
    final source = FakeActivitySource();
    final model = ActivityEditorViewModel(
        ManageStudySession(FirebaseStudySessionsRepository(source)),
        planning: planning);
    addTearDown(model.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ActivityForm(viewModel: model, onSaved: (_) {}))));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Activity name'), 'Reviewed title');
    final review = find.widgetWithText(FilledButton, 'Review Activity');
    await tester.ensureVisible(review);
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(source.writes, isEmpty);
    expect(find.text('Compared participants: 2'), findsOneWidget);
    await tester.ensureVisible(find.text('Back to Details'));
    await tester.tap(find.text('Back to Details'));
    await tester.pumpAndSettle();
    expect(find.text('Reviewed title'), findsOneWidget);
    expect(source.writes, isEmpty);
  });

  testWidgets('saved result retries only the summary after a read failure',
      (tester) async {
    final source = FailedRead();
    await tester.pumpWidget(MaterialApp(
        home: ActivityResultView(
            activityId: 'saved-id',
            acknowledged: true,
            repository: FirebaseStudySessionsRepository(source))));
    await tester.pumpAndSettle();
    expect(
        find.text('Your activity was saved. Its summary could not be loaded.'),
        findsOneWidget);
    await tester.tap(find.text('Retry summary'));
    await tester.pumpAndSettle();
    expect(source.reads, 2);
    expect(source.writes, isEmpty);
  });

  test(
      'pending invitation response is distinct from remote acceptance and preserves Maybe',
      () async {
    final source = FakeActivitySource()..currentUserId = 'member';
    final inbox = Inbox()..pending = true;
    final model = ActivityInvitationViewModel(
        activityId: 'firestore-document',
        sessions: FirebaseStudySessionsRepository(source),
        alerts: inbox);
    addTearDown(model.dispose);
    await model.load();
    await model.respond(AlertResponse.maybe);
    expect(model.value.invitation!.response, AlertResponse.maybe);
    expect(model.value.invitation!.pendingSync, isTrue);
    expect(model.value.acknowledgement, contains('Pending sync'));
    expect(source.writes, isEmpty);
  });

  test(
      'disk failure or individual response conflict never promises pending or success',
      () async {
    final source = FakeActivitySource()..currentUserId = 'member';
    final inbox = Inbox()..fail = true;
    final model = ActivityInvitationViewModel(
        activityId: 'firestore-document',
        sessions: FirebaseStudySessionsRepository(source),
        alerts: inbox);
    addTearDown(model.dispose);
    await model.load();
    await model.respond(AlertResponse.accepted);
    expect(model.value.invitation!.response, isNull);
    expect(model.value.acknowledgement, isNull);
    expect(model.value.error, isNotNull);
  });

  for (final width in [390.0, 320.0]) {
    testWidgets('creation Review fits $width with large text and keyboard',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final model = ActivityEditorViewModel(
          ManageStudySession(
              FirebaseStudySessionsRepository(FakeActivitySource())),
          planning: planning);
      addTearDown(model.dispose);
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: child!),
          home:
              Scaffold(body: ActivityForm(viewModel: model, onSaved: (_) {}))));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Activity name'),
          'A meeting with the project team');
      final review = find.widgetWithText(FilledButton, 'Review Activity');
      await tester.ensureVisible(review);
      await tester.tap(review);
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();
      await tester
          .ensureVisible(find.widgetWithText(FilledButton, 'Create Activity'));
      await tester.pump();
      expect(find.text('Compared participants: 2'), findsOneWidget);
    });
    testWidgets('invitation logistics and actions fit $width with large text',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = FakeActivitySource()..currentUserId = 'member';
      final model = ActivityInvitationViewModel(
          activityId: 'firestore-document',
          sessions: FirebaseStudySessionsRepository(source),
          alerts: Inbox());
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: child!),
          home: ActivityInvitationView(viewModel: model)));
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Maybe'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
    });
  }
}

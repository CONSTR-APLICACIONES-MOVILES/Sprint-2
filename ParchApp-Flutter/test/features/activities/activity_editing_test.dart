import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parchapp/app/app.dart';
import 'package:parchapp/app/dependency_injection/activities_dependencies.dart';
import 'package:parchapp/app/dependency_injection/alerts_dependencies.dart';
import 'package:parchapp/app/dependency_injection/auth_dependencies.dart';
import 'package:parchapp/app/dependency_injection/groups_dependencies.dart';
import 'package:parchapp/app/dependency_injection/profile_dependencies.dart';
import 'package:parchapp/app/dependency_injection/schedule_dependencies.dart';
import 'package:parchapp/app/router/app_router.dart';
import 'package:parchapp/app/router/app_routes.dart';
import 'package:parchapp/features/activities/data/repositories/firebase_study_sessions_repository.dart';
import 'package:parchapp/features/activities/domain/entities/activity_draft.dart';
import 'package:parchapp/features/activities/domain/entities/study_session.dart';
import 'package:parchapp/features/activities/domain/use_cases/manage_study_session.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_editor_view_model.dart';
import 'package:parchapp/features/activities/presentation/view_models/study_session_view_model.dart';
import 'package:parchapp/features/activities/presentation/widgets/activity_form.dart';
import 'package:parchapp/features/activities/presentation/views/study_session_view.dart';
import 'firebase_study_sessions_repository_test.dart' show FakeActivitySource;

const draft = ActivityDraft(
    groupId: 'group',
    title: 'Updated activity',
    description: 'Review chapter 3',
    category: 'social',
    location: 'Campus',
    status: 'CONFIRMED',
    date: 'Friday',
    time: 'After class');

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late FakeActivitySource source;
  late ManageStudySession manage;
  setUp(() {
    source = FakeActivitySource();
    manage = ManageStudySession(FirebaseStudySessionsRepository(source));
  });

  testWidgets(
      'Home creates an activity, opens its saved ID and lists it on return',
      (tester) async {
    final repository = FirebaseStudySessionsRepository(source);
    final router = AppRouter.create(AuthDependencies.mock(),
        alertsDependencies: AlertsDependencies.mock(),
        activitiesDependencies:
            ActivitiesDependencies(repository: repository, catalog: repository),
        scheduleDependencies: ScheduleDependencies.mock(),
        profileDependencies: ProfileDependencies.mock(),
        groupsDependencies: GroupsDependencies.mock(),
        initialLocation: AppRoutes.home);
    addTearDown(router.dispose);
    await tester.pumpWidget(ParchApp(router: router));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('New Activity'));
    await tester.tap(find.text('New Activity'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.createActivity);
    await tester.enterText(
        find.widgetWithText(TextField, 'Activity name'), 'Created from Home');
    await tester.ensureVisible(find.text('Create Activity'));
    await tester.tap(find.text('Create Activity'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.studySession('created-document'));
    expect(find.text('Created from Home'), findsOneWidget);
    expect(source.writes, hasLength(1));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.home);
    expect(find.text('Created from Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('create validates data and does not send schedule or analytics fields',
      () async {
    final editor = ActivityEditorViewModel(manage);
    addTearDown(editor.dispose);
    await editor.load();
    expect(await editor.save(const ActivityDraft(groupId: 'group', title: ' ')),
        isNull);
    expect(source.writes, isEmpty);
    expect(editor.value.error, contains('activity name'));
    expect(await editor.save(draft), 'created-document');
    final written = source.writes.single;
    expect(
        written.keys,
        unorderedEquals([
          'groupId',
          'title',
          'description',
          'category',
          'location',
          'status',
          'date',
          'time'
        ]));
    final reopened = await manage.load('created-document');
    expect(reopened!.title, draft.title);
    expect(reopened.startsAt, isNull);
    expect(source.decisions, 0);
  });

  test('concurrent submission creates only one activity', () async {
    final editor = ActivityEditorViewModel(manage);
    addTearDown(editor.dispose);
    await editor.load();
    await Future.wait([editor.save(draft), editor.save(draft)]);
    expect(source.writes, hasLength(1));
  });

  test(
      'metadata persists and a new repository reads it without a recommendation',
      () async {
    final saved = await manage.updateDetails('firestore-document', draft);
    expect(saved.title, draft.title);
    final reopened =
        await FirebaseStudySessionsRepository(source).getById(saved.id);
    expect(reopened!.description, draft.description);
    expect(reopened.location, draft.location);
    expect(reopened.status, 'CONFIRMED');
    expect(source.decisions, 0);
    expect(source.writes.single.containsKey('groupId'), isFalse);
  });

  test('scheduled metadata edits exclude schedule and legacy time fields',
      () async {
    source.details['startTime'] = '2030-10-02T16:00:00Z';
    source.details['endTime'] = '2030-10-02T17:00:00Z';
    final saved = await manage.updateDetails('firestore-document', draft);
    expect(saved.startsAt, DateTime.utc(2030, 10, 2, 16));
    expect(
        source.writes.single.keys,
        unorderedEquals(
            ['title', 'description', 'category', 'location', 'status']));
    await expectLater(
        manage.updateDetails(
            'firestore-document',
            const ActivityDraft(
                groupId: 'group', title: 'Test', date: 'Different day')),
        throwsA(isA<SessionFailure>()));
    expect(source.writes, hasLength(1));
  });

  test('non-organizers and group reassignment cannot edit', () async {
    source.currentUserId = 'member';
    await expectLater(manage.updateDetails('firestore-document', draft),
        throwsA(isA<SessionFailure>()));
    source.currentUserId = 'organizer';
    await expectLater(
        manage.updateDetails('firestore-document',
            const ActivityDraft(groupId: 'another-group', title: 'Test')),
        throwsA(isA<SessionFailure>()));
    expect(source.writes, isEmpty);
  });

  testWidgets('failed create retains form values and supports retry',
      (tester) async {
    final editor = ActivityEditorViewModel(manage);
    addTearDown(editor.dispose);
    String? savedId;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ActivityForm(
                viewModel: editor, onSaved: (id) => savedId = id))));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Activity name'), 'New activity');
    source.failWrite = true;
    await tester.ensureVisible(find.text('Create Activity'));
    await tester.tap(find.text('Create Activity'));
    await tester.pumpAndSettle();
    expect(savedId, isNull);
    expect(find.text('New activity'), findsOneWidget);
    expect(editor.value.error, isNotNull);
    source.failWrite = false;
    await tester.ensureVisible(find.text('Create Activity'));
    await tester.tap(find.text('Create Activity'));
    await tester.pumpAndSettle();
    expect(savedId, 'created-document');
  });

  testWidgets(
      'unscheduled details offer metadata editing and refresh saved title',
      (tester) async {
    final model = StudySessionViewModel(manage, 'firestore-document',
        autoLoadRecommendations: false);
    addTearDown(model.dispose);
    await tester
        .pumpWidget(MaterialApp(home: StudySessionView(viewModel: model)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modify Session'));
    await tester.pumpAndSettle();
    expect(find.text('Modify Activity Details'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Activity name'), 'Saved title');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Saved title'), findsOneWidget);
    expect(model.value.session!.startsAt, isNull);
    expect(source.details['title'], 'Saved title');
  });
}

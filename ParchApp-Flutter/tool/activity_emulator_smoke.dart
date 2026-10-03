// Run as a Flutter web or Android target with the fixture produced by
// tool/seed_activity_emulator.cjs. This exercises the real Firebase SDKs.
import 'package:flutter/material.dart';
import 'package:parchapp/app/dependency_injection/firebase_dependencies.dart';
import 'package:parchapp/features/activities/data/data_sources/firebase_activity_data_source.dart';
import 'package:parchapp/features/activities/data/repositories/firebase_study_sessions_repository.dart';
import 'package:parchapp/features/activities/domain/use_cases/get_recommended_slots.dart';
import 'package:parchapp/features/activities/domain/use_cases/manage_study_session.dart';
import 'package:parchapp/features/activities/presentation/view_models/study_session_view_model.dart';
import 'package:parchapp/features/activities/domain/entities/activity_draft.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_editor_view_model.dart';
import 'package:parchapp/features/auth/data/data_sources/firebase_auth_data_source.dart';
import 'package:parchapp/features/auth/data/repositories/auth_repository_impl.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String result;
  try {
    await verify();
    result =
        'PASS: Firebase sign-in, activity creation, metadata editing, reopening, acceptance, time modification and BQ3 (100% then 50%).';
  } catch (error, stack) {
    result = 'FAIL: $error';
    debugPrintStack(stackTrace: stack);
  }
  debugPrint(result);
  runApp(MaterialApp(
      home: Scaffold(
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24), child: Text(result))))));
}

Future<void> verify() async {
  check(
      const bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: true),
      'This verification target only supports local emulators.');
  const fixtureId = String.fromEnvironment('EMULATOR_ACTIVITY_ID');
  check(fixtureId.isNotEmpty, 'Seed a fresh emulator fixture before running.');
  final firebase = await FirebaseDependencies.initialize();
  final auth = AuthRepositoryImpl(FirebaseAuthDataSource(firebase.auth));
  await auth.signIn(const String.fromEnvironment('EMULATOR_EMAIL'),
      const String.fromEnvironment('EMULATOR_PASSWORD'));
  final source = FirebaseActivityDataSource(
      functions: firebase.functions,
      auth: firebase.auth,
      firestore: firebase.firestore);
  final repository = FirebaseStudySessionsRepository(source);
  check(
      (await repository.listActivities())
          .any((activity) => activity.id == fixtureId),
      'Activity discovery failed.');
  // Preserve the original SDK error if the callable transport fails.
  final fixture = await repository.getById(fixtureId);
  final manage = ManageStudySession(repository);
  final creator = ActivityEditorViewModel(manage);
  String? createdId;
  try {
    await creator.load();
    createdId = await creator.save(ActivityDraft(
        groupId: fixture!.groupId,
        title: 'Activity created from Flutter',
        description: 'Persistence test',
        location: 'Library'));
    check(createdId != null, 'Create failed: ${creator.value.error}');
  } finally {
    creator.dispose();
  }
  final id = createdId!;
  debugPrint('Created activity $id through the frontend repository.');
  final created =
      await firebase.firestore.collection('activities').doc(id).get();
  check(
      created.data()?['createdBy'] == firebase.auth.currentUser!.uid &&
          created.data()?['createdAt'] != null,
      'Server timestamp/ownership missing.');
  final initial = (await repository.getById(id))!;
  final editor = ActivityEditorViewModel(manage, session: initial);
  try {
    check(
        await editor.save(ActivityDraft(
                groupId: initial.groupId,
                title: 'Activity edited from Flutter',
                description: 'Persisted description',
                location: 'Campus',
                category: 'social')) ==
            id,
        'Details edit failed: ${editor.value.error}');
  } finally {
    editor.dispose();
  }
  final edited = (await FirebaseStudySessionsRepository(source).getById(id))!;
  check(
      edited.title == 'Activity edited from Flutter' &&
          edited.description == 'Persisted description' &&
          edited.location == 'Campus',
      'Reopened details did not retain metadata.');
  final model = StudySessionViewModel(ManageStudySession(repository), id,
      recommendations: GetRecommendedSlots(repository),
      autoLoadRecommendations: false,
      refreshAfterDecision: true);
  try {
    await model.load();
    check(model.value.session?.startsAt == null,
        'Fixture must start unscheduled.');
    check(model.value.session?.canOrganize == true,
        'Organizer mapping failed: ${model.value.error}');
    check(model.value.recommendationsStatus == RecommendationsStatus.idle,
        'Search must be explicit.');
    await model.loadRecommendations(durationMinutes: 30);
    check(model.value.recommendations?.expiresAt == null,
        'Backend has no expiry field.');
    check(model.value.recommendations?.slots.isNotEmpty == true,
        'No slots: ${model.value.recommendationsError}. Run before 22:30 Bogotá.');
    final first = model.value.recommendations!.slots.first;
    check(await model.acceptSlot(first.id),
        'Acceptance failed: ${model.value.error}');
    check(model.value.refreshError == null, 'Details refresh failed.');
    check(model.value.session!.startsAt == first.startsAt,
        'Canonical schedule mismatch.');
    final accepted = await source
        .call('getActivityRecommendationAnalytics', {'activityId': id});
    check(
        accepted['recommendations_presented'] == 1 &&
            accepted['accepted_recommendations_unchanged'] == 1 &&
            accepted['pct_unchanged_overall'] == 100,
        'Acceptance BQ3 mismatch: $accepted');
    await model.loadRecommendations(durationMinutes: 30);
    final second = model.value.recommendations!.slots.first;
    final session = model.value.session!;
    check(
        await model.update(
            title: session.title,
            room: '',
            startsAt: second.startsAt.add(const Duration(minutes: 15)),
            endsAt: second.endsAt.add(const Duration(minutes: 15)),
            sourceSlotId: second.id),
        'Modification failed: ${model.value.error}');
    check(
        model.value.session!.startsAt ==
            second.startsAt.add(const Duration(minutes: 15)),
        'Modified schedule mismatch.');
    final reopened = await FirebaseStudySessionsRepository(source).getById(id);
    check(
        reopened?.startsAt == model.value.session!.startsAt &&
            reopened?.endsAt == model.value.session!.endsAt,
        'A new repository must read the saved interval from the backend.');
    await manage.updateDetails(
        id,
        ActivityDraft(
            groupId: reopened!.groupId,
            title: 'Confirmed activity',
            description: reopened.description,
            category: reopened.category,
            location: 'Updated location',
            status: 'CONFIRMED',
            date: reopened.legacyDate,
            time: reopened.legacyTime));
    final afterEdit = (await repository.getById(id))!;
    check(
        afterEdit.status == 'CONFIRMED' &&
            afterEdit.location == 'Updated location' &&
            afterEdit.startsAt == reopened.startsAt &&
            afterEdit.endsAt == reopened.endsAt,
        'Metadata edit must preserve the canonical schedule.');
    final modified = await source
        .call('getActivityRecommendationAnalytics', {'activityId': id});
    check(
        modified['recommendations_presented'] == 2 &&
            modified['accepted_recommendations_unchanged'] == 1 &&
            modified['pct_unchanged_overall'] == 50,
        'Modification BQ3 mismatch: $modified');
  } finally {
    model.dispose();
    await auth.signOut();
    check(
        firebase.auth.currentUser == null, 'Firebase session was not cleared.');
  }
}

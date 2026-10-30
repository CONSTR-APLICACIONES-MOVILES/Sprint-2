// Run as a Flutter web or Android target with the fixture produced by
// tool/seed_activity_emulator.cjs. This exercises the real Firebase SDKs.
import 'package:flutter/material.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/core/data/offline_mobile_api.dart';
import 'package:parchapp/features/profile/data/repositories/firebase_profile_repository.dart';
import 'package:parchapp/features/profile/domain/entities/profile_user.dart';
import 'package:parchapp/features/schedule/data/repositories/firebase_schedule_repository.dart';
import 'package:parchapp/features/schedule/domain/entities/schedule_block.dart';
import 'package:parchapp/features/alerts/data/repositories/firebase_alerts_repository.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
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
import 'package:parchapp/features/groups/data/data_sources/firestore_groups_data_source.dart';
import 'package:parchapp/features/groups/data/repositories/firebase_active_groups_repository.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String result;
  try {
    await verify();
    result =
        'PASS: Firebase Auth, activities, recommendations/BQ3, groups/RSVP, persisted profile/photo, dated calendar availability, and two-user inbox/read/response persistence.';
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
  final auth = AuthRepositoryImpl(
      FirebaseAuthDataSource(firebase.auth, profiles: firebase.mobile));
  await auth.signIn(const String.fromEnvironment('EMULATOR_EMAIL'),
      const String.fromEnvironment('EMULATOR_PASSWORD'));
  final source = FirebaseActivityDataSource(
      functions: firebase.functions,
      auth: firebase.auth,
      firestore: firebase.firestore,
      api: firebase.mobile);
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
    final groups = FirebaseActiveGroupsRepository(
        FirestoreGroupsDataSource(firebase.firestore, firebase.auth));
    final group = (await groups.getActiveGroups())
        .firstWhere((group) => group.id == reopened.groupId);
    check(group.hasInvitation, 'Latest activity missing from group.');
    await groups.confirmRsvp(group.id);
    final reloadedGroups = FirebaseActiveGroupsRepository(
        FirestoreGroupsDataSource(firebase.firestore, firebase.auth));
    final reloaded = (await reloadedGroups.getActiveGroups())
        .firstWhere((item) => item.id == group.id);
    check(reloaded.hasResponded, 'RSVP did not persist across repositories.');
    final mobile = firebase.mobile;
    final profiles = FirebaseProfileRepository(mobile);
    final profile = await profiles.getProfile();
    check(profile.id == firebase.auth.currentUser!.uid,
        'Profile identity mismatch.');
    const photo =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII=';
    await profiles.updateProfile(profile.copyWith(
        name: 'Persisted student',
        program: 'Engineering',
        semester: 4,
        photoPath: photo));
    await profiles.updateStatus(AvailabilityStatus.busy);
    final savedProfile = await FirebaseProfileRepository(mobile).getProfile();
    check((await auth.getRecognizedUser())?.name == 'Persisted student',
        'Recognized sign-in name did not reflect the edited profile.');
    check(
        savedProfile.name == 'Persisted student' &&
            savedProfile.status == AvailabilityStatus.busy &&
            savedProfile.photoPath == photo,
        'Profile/photo did not survive reopening.');
    final schedule = FirebaseScheduleRepository(
        mobile, () => firebase.auth.currentUser?.uid);
    final bogota = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    final day = DateTime(bogota.year, bogota.month, bogota.day);
    final tomorrow = day.add(const Duration(days: 1));
    final from = DateTime.utc(tomorrow.year, tomorrow.month, tomorrow.day, 15);
    await schedule.replaceImportedCalendarBlocks([
      ScheduleBlock(
          id: 'private-calendar-block',
          start: from,
          end: from.add(const Duration(hours: 1)),
          type: ScheduleBlockType.personalEvent,
          title: 'Private appointment')
    ]);
    final savedSchedule = await FirebaseScheduleRepository(
            mobile, () => firebase.auth.currentUser?.uid)
        .getMySchedule(day: tomorrow);
    check(
        savedSchedule.single.start.hour == 10 &&
            savedSchedule.single.title == 'Busy',
        'Dated calendar persistence/privacy mismatch.');
    check((await schedule.getMySchedule(day: day)).isEmpty,
        'Explicitly empty calendar day was not saved.');
    await auth.signOut();
    await auth.signIn(const String.fromEnvironment('EMULATOR_MEMBER_EMAIL'),
        const String.fromEnvironment('EMULATOR_PASSWORD'));
    final memberProfile = await FirebaseProfileRepository(mobile).getProfile();
    check(memberProfile.name != 'Persisted student',
        'Private profile leaked across users.');
    final inbox = FirebaseAlertsRepository(mobile);
    check((await inbox.getAlerts()).any((alert) => alert.id == id),
        'Real activity invitation missing.');
    await inbox.markAllRead();
    check(
        (await FirebaseAlertsRepository(mobile).getAlerts())
            .firstWhere((a) => a.id == id)
            .isRead,
        'Read state did not persist.');
    await mobile.setForcedOffline(true);
    check(
        (await FirebaseProfileRepository(mobile).getProfile()).id ==
            firebase.auth.currentUser!.uid,
        'Profile could not be read offline.');
    await inbox.respond(id, AlertResponse.accepted);
    check(mobile.value.pending == 1, 'Offline response was not queued.');
    final authoritative =
        FirebaseAlertsRepository(FirebaseMobileApi(firebase.functions));
    check(
        (await authoritative.getAlerts())
                .firstWhere((a) => a.id == id)
                .response ==
            null,
        'An offline response must not pretend the server has saved it.');
    final restarted = OfflineMobileApi(
        remote: FirebaseMobileApi(firebase.functions),
        store: mobile.store,
        project: firebase.mobile.project,
        currentUserId: () => firebase.auth.currentUser?.uid);
    await restarted.refreshSession();
    check(restarted.value.pending == 1,
        'Pending response did not survive restart.');
    await restarted.flush();
    check(restarted.value.pending == 0 && restarted.value.error == null,
        'Offline response did not synchronize.');
    restarted.dispose();
    await mobile.setForcedOffline(false);
    await mobile.refreshSession();
    check(
        (await FirebaseAlertsRepository(mobile).getAlerts())
                .firstWhere((a) => a.id == id)
                .response ==
            AlertResponse.accepted,
        'Invitation response did not persist.');
    final details = await source.call('getActivity', {'activityId': id});
    check(
        (details['participants'] as List).any((p) =>
            p['id'] == firebase.auth.currentUser!.uid &&
            p['activityRsvpStatus'] == 'accepted'),
        'Activity details did not reflect invitation response.');
    await auth.signOut();
    final registered = await auth.createAccount(
        'New registered student',
        'new-${DateTime.now().millisecondsSinceEpoch}@parchapp.test',
        'ParchApp123!');
    check(registered.name == 'New registered student',
        'Registration returned a static name.');
    check((await auth.getRecognizedUser())?.name == 'New registered student',
        'Registered name was not persisted for recognized sign-in.');
  } finally {
    model.dispose();
    await auth.signOut();
    check(
        firebase.auth.currentUser == null, 'Firebase session was not cleared.');
  }
}

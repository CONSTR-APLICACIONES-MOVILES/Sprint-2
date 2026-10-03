import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/activities/data/repositories/mock_study_sessions_repository.dart';
import 'package:parchapp/features/activities/domain/entities/slot_recommendation.dart';
import 'package:parchapp/features/activities/domain/entities/study_session.dart';
import 'package:parchapp/features/activities/domain/use_cases/get_recommended_slots.dart';
import 'package:parchapp/features/activities/domain/use_cases/manage_study_session.dart';
import 'package:parchapp/features/activities/presentation/view_models/study_session_view_model.dart';
import 'package:parchapp/features/activities/presentation/views/study_session_view.dart';

final now = DateTime.utc(2030, 1, 1);
SlotRecommendations suggestions(
        {String activityId = 'linear-algebra', bool empty = false}) =>
    SlotRecommendations(
        id: 'ranking-42',
        activityId: activityId,
        expiresAt: now.add(const Duration(days: 7)),
        slots: empty
            ? []
            : [
                RecommendedSlot(
                    id: 'best',
                    startsAt: now.add(const Duration(days: 1)),
                    endsAt: now.add(const Duration(days: 1, hours: 2)),
                    availableParticipants: 4,
                    totalParticipants: 4,
                    reasons: [
                      'All participants are free; matches the group preference.'
                    ]),
                RecommendedSlot(
                    id: 'alternative',
                    startsAt: now.add(const Duration(days: 2)),
                    endsAt: now.add(const Duration(days: 2, hours: 2)),
                    availableParticipants: 3,
                    totalParticipants: 4,
                    reasons: [
                      'An earlier available afternoon for three participants.'
                    ]),
              ]);

class RecommendationRepository extends MockStudySessionsRepository {
  SlotRecommendations result = suggestions();
  bool failRecommendations = false;
  bool failSave = false;
  bool failAnalytics = false;
  bool organizer = true;
  int recommendationRequests = 0;
  int saves = 0;
  Completer<void>? pendingSave;
  Completer<void>? pendingRecommendations;

  @override
  Future<StudySession?> getById(String id) async {
    final session = await super.getById(id);
    if (session == null || organizer) return session;
    return StudySession(
        id: session.id,
        title: session.title,
        description: session.description,
        startsAt: session.startsAt,
        endsAt: session.endsAt,
        location: session.location,
        room: session.room,
        reminder: session.reminder,
        topics: session.topics,
        participants: session.participants,
        resources: session.resources);
  }

  @override
  Future<SlotRecommendations> getRecommendedSlots(String activityId,
      {int? durationMinutes}) async {
    recommendationRequests++;
    await pendingRecommendations?.future;
    if (failRecommendations) throw Exception('private transport error');
    return result;
  }

  @override
  Future<StudySession> save(StudySession session,
      {RecommendationEvent? recommendationEvent}) async {
    saves++;
    await pendingSave?.future;
    if (failSave) throw Exception('private transport error');
    return super.save(session, recommendationEvent: recommendationEvent);
  }

  @override
  Future<void> recordRecommendationShown(RecommendationEvent event) async {
    if (failAnalytics) throw Exception('private transport error');
    return super.recordRecommendationShown(event);
  }
}

void main() {
  late RecommendationRepository repository;
  late StudySessionViewModel model;
  late DateTime clock;
  setUp(() {
    clock = now;
    repository = RecommendationRepository();
    model = StudySessionViewModel(
        ManageStudySession(repository, now: () => clock), 'linear-algebra',
        recommendations: GetRecommendedSlots(repository, now: () => clock));
  });
  tearDown(() => model.dispose());

  test('details remain visible while suggestions load, fail and retry',
      () async {
    repository.pendingRecommendations = Completer<void>();
    repository.failRecommendations = true;
    final loading = model.load();
    await Future<void>.delayed(Duration.zero);
    expect(model.value.status, SessionLoadStatus.ready);
    expect(model.value.recommendationsStatus, RecommendationsStatus.loading);
    repository.pendingRecommendations!.complete();
    await loading;
    expect(model.value.session, isNotNull);
    expect(model.value.recommendationsStatus, RecommendationsStatus.error);
    expect(model.value.recommendationsError, isNot(contains('private')));
    repository.failRecommendations = false;
    await model.loadRecommendations();
    expect(model.value.recommendations!.slots.first.id, 'best');
    expect(model.value.recommendationsStatus, RecommendationsStatus.ready);
    expect(() => model.value.recommendations!.slots.clear(),
        throwsUnsupportedError);
  });

  test('empty recommendations have an explicit state', () async {
    repository.result = suggestions(empty: true);
    await model.load();
    expect(model.value.recommendationsStatus, RecommendationsStatus.empty);
    expect(await model.acceptSlot('best'), isFalse);
  });

  test('room changes during recommendation loading discard the stale result',
      () async {
    repository.pendingRecommendations = Completer<void>();
    final loading = model.load();
    await Future<void>.delayed(Duration.zero);
    final session = model.value.session!;
    expect(
        await model.update(
            title: session.title,
            room: 'New room',
            startsAt: session.startsAt!,
            endsAt: session.endsAt!),
        isTrue);
    repository.pendingRecommendations!.complete();
    await loading;
    expect(repository.recommendationRequests, 2);
    expect(model.value.session!.room, 'New room');
    expect(model.value.recommendationsStatus, RecommendationsStatus.ready);
  });

  for (final id in ['best', 'alternative']) {
    test('accepting $id persists exact instants and one correlated event',
        () async {
      await model.load();
      await model.recommendationShown('ranking-42', id);
      await model.recommendationShown('ranking-42', id);
      expect(await model.acceptSlot(id), isTrue);
      expect(await model.acceptSlot(id), isFalse);
      final slot = repository.result.getSlot(id);
      expect(model.value.session!.startsAt, slot.startsAt);
      expect(model.value.session!.endsAt, slot.endsAt);
      expect(repository.events.map((event) => event.type),
          [RecommendationEventType.shown, RecommendationEventType.accepted]);
      final event = repository.events.last;
      expect(event.activityId, 'linear-algebra');
      expect(event.recommendationId, 'ranking-42');
      expect(event.slotId, id);
      expect(event.selectedStart, event.suggestedStart);
      expect(repository.saves, 1);
    });
  }

  test('changed slot records original and selected times after save', () async {
    await model.load();
    final session = model.value.session!;
    final slot = repository.result.slots.first;
    expect(
        await model.update(
            title: session.title,
            room: session.room,
            startsAt: slot.startsAt.add(const Duration(minutes: 30)),
            endsAt: slot.endsAt.add(const Duration(minutes: 30)),
            sourceSlotId: slot.id),
        isTrue);
    final event = repository.events.single;
    expect(event.type, RecommendationEventType.modified);
    expect(event.suggestedStart, slot.startsAt);
    expect(event.selectedStart, slot.startsAt.add(const Duration(minutes: 30)));
  });

  test('ordinary editor attributes time changes but ignores metadata edits',
      () async {
    await model.load();
    await model.recommendationShown('ranking-42', 'best');
    final session = model.value.session!;
    await model.update(
        title: 'New title',
        room: session.room,
        startsAt: session.startsAt!,
        endsAt: session.endsAt!);
    expect(repository.events.length, 1);
    final slot = repository.result.slots.first;
    await model.update(
        title: session.title,
        room: session.room,
        startsAt: slot.startsAt.add(const Duration(hours: 1)),
        endsAt: slot.endsAt.add(const Duration(hours: 1)));
    expect(repository.events.last.type, RecommendationEventType.modified);
  });

  test('failed save retains prior session and emits no decision', () async {
    await model.load();
    final previous = model.value.session;
    repository.failSave = true;
    expect(await model.acceptSlot('best'), isFalse);
    expect(model.value.session, same(previous));
    expect(model.value.selectionSaved, isFalse);
    expect(repository.events, isEmpty);
    repository.failSave = false;
    expect(await model.acceptSlot('best'), isTrue);
    expect(repository.events.single.type, RecommendationEventType.accepted);
  });

  test('analytics retries preserve original exposure time even after expiry',
      () async {
    repository.failAnalytics = true;
    await model.load();
    await model.recommendationShown('ranking-42', 'best');
    expect(model.value.analyticsError, isNotNull);
    expect(model.value.session, isNotNull);
    clock = now.add(const Duration(days: 8));
    repository.failAnalytics = false;
    await model.retryAnalytics();
    expect(model.value.analyticsError, isNull);
    expect(repository.events.single.occurredAt, now);
    await model.retryAnalytics();
    expect(repository.events.length, 1);
  });

  test('expired, foreign and unknown recommendations cannot save', () async {
    repository.result = suggestions(activityId: 'different-session');
    await model.load();
    expect(model.value.recommendationsStatus, RecommendationsStatus.error);
    repository.result = suggestions();
    await model.loadRecommendations();
    expect(await model.acceptSlot('unknown'), isFalse);
    clock = now.add(const Duration(days: 8));
    expect(await model.acceptSlot('best'), isFalse);
    expect(model.value.error, contains('expired'));
    expect(repository.saves, 0);
  });

  test('non-organizers cannot save or contribute organizer impressions',
      () async {
    repository.organizer = false;
    await model.load();
    await model.recommendationShown('ranking-42', 'best');
    expect(await model.acceptSlot('best'), isFalse);
    expect(repository.saves, 0);
    expect(repository.events, isEmpty);
  });

  test('duplicate submissions are suppressed while a decision is pending',
      () async {
    await model.load();
    repository.pendingSave = Completer<void>();
    final pending = model.acceptSlot('best');
    await Future<void>.delayed(Duration.zero);
    expect(model.value.saving, isTrue);
    expect(await model.acceptSlot('alternative'), isFalse);
    repository.pendingSave!.complete();
    expect(await pending, isTrue);
    expect(repository.saves, 1);
  });

  test('late recommendation completion does not notify disposed model',
      () async {
    final temporary = StudySessionViewModel(
        ManageStudySession(repository), 'linear-algebra',
        recommendations: GetRecommendedSlots(repository, now: () => clock));
    repository.pendingRecommendations = Completer<void>();
    final pending = temporary.load();
    await Future<void>.delayed(Duration.zero);
    temporary.dispose();
    repository.pendingRecommendations!.complete();
    await pending;
  });

  testWidgets('modify slot reuses editor and records the changed date',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: StudySessionView(viewModel: model)));
    await tester.pumpAndSettle();
    final modify = find.text('Modify time').first;
    await tester.ensureVisible(modify);
    await tester.pumpAndSettle();
    await tester.tap(modify);
    await tester.pumpAndSettle();
    expect(find.text('Modify Session Details'), findsOneWidget);
    final dateButton = find.descendant(
        of: find.byType(BottomSheet), matching: find.byType(OutlinedButton));
    await tester.ensureVisible(dateButton);
    await tester.tap(dateButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Modify Session Details'), findsNothing);
    expect(repository.events.last.type, RecommendationEventType.modified);
    expect(repository.events.last.slotId, 'best');
    expect(repository.events.last.selectedStart!.toLocal().day, 3);
    await tester.pumpWidget(const SizedBox());
  });

  for (final width in [390.0, 320.0]) {
    testWidgets(
        'recommendations fit $width and visible suggestions are tracked',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: child!),
          home: StudySessionView(viewModel: model)));
      await tester.pumpAndSettle();
      final accept = find.text('Accept recommended slot');
      await tester.ensureVisible(accept);
      await tester.pumpAndSettle();
      expect(find.text('4 / 4 participants available'), findsOneWidget);
      expect(
          repository.events
              .any((event) => event.type == RecommendationEventType.shown),
          isTrue);
      expect(tester.takeException(), isNull);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(find.text('Selected time saved.'), findsOneWidget);
      expect(repository.events.last.type, RecommendationEventType.accepted);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/app/dependency_injection/activities_dependencies.dart';
import 'package:parchapp/app/dependency_injection/auth_dependencies.dart';
import 'package:parchapp/app/dependency_injection/alerts_dependencies.dart';
import 'package:parchapp/app/dependency_injection/groups_dependencies.dart';
import 'package:parchapp/app/dependency_injection/profile_dependencies.dart';
import 'package:parchapp/app/dependency_injection/schedule_dependencies.dart';
import 'package:parchapp/app/router/app_router.dart';
import 'package:parchapp/app/router/app_routes.dart';
import 'package:parchapp/features/activities/data/data_sources/activity_data_source.dart';
import 'package:parchapp/features/activities/data/models/activity_model.dart';
import 'package:parchapp/features/activities/data/repositories/firebase_study_sessions_repository.dart';
import 'package:parchapp/features/activities/domain/entities/study_session.dart';
import 'package:parchapp/features/activities/domain/entities/slot_recommendation.dart';
import 'package:parchapp/features/activities/domain/use_cases/get_recommended_slots.dart';
import 'package:parchapp/features/activities/domain/use_cases/manage_study_session.dart';
import 'package:parchapp/features/activities/presentation/view_models/study_session_view_model.dart';
import 'package:parchapp/features/activities/presentation/views/study_session_view.dart';

final start = DateTime.utc(2030, 10, 2, 16);
final end = start.add(const Duration(hours: 1));
Map<String, dynamic> activity() => {
      'id': 'firestore-document',
      'groupId': 'group',
      'createdBy': 'organizer',
      'title': 'Real activity',
      'description': '',
      'category': 'study',
      'date': 'Friday',
      'time': 'After class',
      'startTime': null,
      'endTime': null,
      'durationMinutes': null,
      'timeZone': 'America/Bogota',
      'status': 'PROPOSED',
      'location': 'Library',
      'participants': [
        {
          'id': 'organizer',
          'name': 'Organizer',
          'initials': 'OR',
          'groupRsvpStatus': 'NO_RESPONSE',
          'availability': 'UNKNOWN'
        },
      ],
    };

class FakeActivitySource implements ActivityDataSource {
  @override
  String? currentUserId = 'organizer';
  Map<String, dynamic> details = activity();
  final calls = <(String, Map<String, dynamic>)>[];
  Completer<void>? presentation;
  bool failPresentation = false;
  String? blockedPresentationId;
  bool failRefresh = false;
  String? decisionFailure;
  int decisions = 0;
  final writes = <Map<String, dynamic>>[];
  bool failWrite = false;
  @override
  Future<List<Map<String, dynamic>>> listGroups() async => [
        {'id': 'group', 'name': 'My group'}
      ];
  @override
  Future<String> createActivity(Map<String, dynamic> fields) async {
    if (failWrite) {
      throw FirebaseFunctionsException(
          code: 'permission-denied', message: 'test denied');
    }
    writes.add(fields);
    details = {...activity(), ...fields, 'id': 'created-document'};
    return 'created-document';
  }

  @override
  Future<void> updateActivity(String id, Map<String, dynamic> fields) async {
    if (failWrite) {
      throw FirebaseFunctionsException(
          code: 'permission-denied', message: 'test denied');
    }
    writes.add(fields);
    details = {...details, ...fields};
  }

  @override
  Future<List<ActivityModel>> listActivities() async =>
      [ActivityModel(details)];
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    calls.add((name, input));
    switch (name) {
      case 'getActivity':
        if (failRefresh && decisions > 0) {
          throw FirebaseFunctionsException(
              code: 'unavailable', message: 'test failure');
        }
        return details;
      case 'getActivityRecommendations':
        return {
          'activityId': details['id'],
          'batchId': 'batch-not-candidate',
          'date': '2030-10-02',
          'timeZone': 'America/Bogota',
          'durationMinutes': 60,
          'recommendations': [
            {
              'id': 'candidate-not-batch',
              'startTime': start.toIso8601String(),
              'endTime': end.toIso8601String(),
              'availableParticipants': 1,
              'totalParticipants': 1,
              'score': 1,
              'reasons': ['Everyone is available.']
            }
          ]
        };
      case 'presentActivityRecommendations':
        await presentation?.future;
        if (failPresentation ||
            (input['recommendationIds'] as List)
                .contains(blockedPresentationId)) {
          throw FirebaseFunctionsException(
              code: 'unavailable', message: 'test failure');
        }
        return {'presented': 1};
      case 'acceptActivityRecommendation':
      case 'modifyActivityRecommendation':
        if (decisionFailure != null) {
          throw FirebaseFunctionsException(
              code: decisionFailure!, message: 'test failure');
        }
        decisions++;
        final selectedStart = input['startTime'] ?? start.toIso8601String();
        final selectedEnd = input['endTime'] ?? end.toIso8601String();
        details = {
          ...details,
          'startTime': selectedStart,
          'endTime': selectedEnd,
          'durationMinutes': 60
        };
        return {
          'recommendationId': input['recommendationId'],
          'outcome':
              name.startsWith('accept') ? 'ACCEPTED_UNCHANGED' : 'MODIFIED',
          'startTime': selectedStart,
          'endTime': selectedEnd
        };
      default:
        throw StateError('Unexpected callable $name');
    }
  }
}

void main() {
  late FakeActivitySource source;
  late FirebaseStudySessionsRepository repository;
  late StudySessionViewModel model;
  setUp(() {
    source = FakeActivitySource();
    repository = FirebaseStudySessionsRepository(source);
    model = StudySessionViewModel(
        ManageStudySession(repository), 'firestore-document',
        recommendations: GetRecommendedSlots(repository),
        autoLoadRecommendations: false,
        refreshAfterDecision: true);
  });
  tearDown(() => model.dispose());

  Future<void> search() async {
    await model.load();
    await model.loadRecommendations(durationMinutes: 60);
  }

  test('legacy details keep null dates, permissions and actual group RSVP',
      () async {
    final session = (await repository.getById('firestore-document'))!;
    expect(session.startsAt, isNull);
    expect(session.endsAt, isNull);
    expect(session.canOrganize, isTrue);
    expect(session.supportsDetailsEditing, isFalse);
    expect(session.room, isEmpty);
    expect(session.topics, isEmpty);
    expect(session.participants.single.program, 'Group RSVP: NO_RESPONSE');
    source.currentUserId = 'someone-else';
    expect(
        (await repository.getById('firestore-document'))!.canOrganize, isFalse);
    expect((await repository.listActivities()).single.id, 'firestore-document');
  });

  test('generation is explicit and sends only supported arguments', () async {
    await model.load();
    expect(source.calls.map((call) => call.$1), ['getActivity']);
    await model.loadRecommendations(durationMinutes: 60);
    expect(source.calls.last.$1, 'getActivityRecommendations');
    expect(source.calls.last.$2,
        {'activityId': 'firestore-document', 'durationMinutes': 60});
    expect(model.value.recommendations!.id, 'batch-not-candidate');
    expect(model.value.recommendations!.slots.single.id, 'candidate-not-batch');
    expect(model.value.recommendations!.expiresAt, isNull);
  });

  test(
      'accept awaits in-flight presentation, uses candidate ID, then refreshes',
      () async {
    await search();
    source.presentation = Completer<void>();
    final showing =
        model.recommendationShown('batch-not-candidate', 'candidate-not-batch');
    final accepting = model.acceptSlot('candidate-not-batch');
    await Future<void>.delayed(Duration.zero);
    expect(source.decisions, 0);
    expect(
        source.calls
            .where((call) => call.$1 == 'presentActivityRecommendations')
            .length,
        1);
    source.presentation!.complete();
    await showing;
    expect(await accepting, isTrue);
    expect(
        source.calls
            .firstWhere((call) => call.$1 == 'presentActivityRecommendations')
            .$2,
        {
          'activityId': 'firestore-document',
          'recommendationIds': ['candidate-not-batch']
        });
    expect(
        source.calls
            .firstWhere((call) => call.$1 == 'acceptActivityRecommendation')
            .$2,
        {
          'activityId': 'firestore-document',
          'recommendationId': 'candidate-not-batch'
        });
    expect(source.calls.last.$1, 'getActivity');
    expect(model.value.session!.startsAt, start);
    expect(model.value.refreshError, isNull);
  });

  test('failed presentation blocks decisions and retries the same candidate',
      () async {
    await search();
    source.failPresentation = true;
    expect(await model.acceptSlot('candidate-not-batch'), isFalse);
    expect(source.decisions, 0);
    expect(model.value.selectionSaved, isFalse);
    source.failPresentation = false;
    expect(await model.acceptSlot('candidate-not-batch'), isTrue);
    expect(source.decisions, 1);
    expect(
        source.calls
            .where((call) => call.$1 == 'getActivityRecommendations')
            .length,
        1);
  });

  test('modified times are UTC minute-precision and room is not required',
      () async {
    await search();
    expect(
        await model.update(
            title: 'Real activity',
            room: '',
            startsAt: start.add(const Duration(minutes: 15)),
            endsAt: end.add(const Duration(minutes: 15)),
            sourceSlotId: 'candidate-not-batch'),
        isTrue);
    expect(
        source.calls
            .firstWhere((call) => call.$1 == 'modifyActivityRecommendation')
            .$2,
        {
          'activityId': 'firestore-document',
          'recommendationId': 'candidate-not-batch',
          'startTime': '2030-10-02T16:15:00.000Z',
          'endTime': '2030-10-02T17:15:00.000Z',
        });
  });

  test('all exposed candidates must be acknowledged before the batch closes',
      () async {
    await search();
    source.blockedPresentationId = 'another-visible-candidate';
    final exposure = RecommendationEvent(
        type: RecommendationEventType.shown,
        activityId: 'firestore-document',
        recommendationId: 'batch-not-candidate',
        slotId: 'another-visible-candidate',
        occurredAt: start,
        suggestedStart: start,
        suggestedEnd: end);
    await expectLater(repository.recordRecommendationShown(exposure),
        throwsA(isA<SessionFailure>()));
    expect(await model.acceptSlot('candidate-not-batch'), isFalse);
    expect(source.decisions, 0);
    source.blockedPresentationId = null;
    expect(await model.acceptSlot('candidate-not-batch'), isTrue);
    expect(source.decisions, 1);
  });

  test(
      'refresh failure is a successful save with independently retryable details',
      () async {
    await search();
    source.failRefresh = true;
    expect(await model.acceptSlot('candidate-not-batch'), isTrue);
    expect(model.value.selectionSaved, isTrue);
    expect(model.value.session!.startsAt, start);
    expect(model.value.error, isNull);
    expect(model.value.refreshError, contains('Time saved'));
    source.failRefresh = false;
    await model.refreshDetails();
    expect(model.value.refreshError, isNull);
    expect(source.decisions, 1);
  });

  test('server stale rejection preserves prior data and requests a new search',
      () async {
    await search();
    source.decisionFailure = 'failed-precondition';
    expect(await model.acceptSlot('candidate-not-batch'), isFalse);
    expect(model.value.session!.startsAt, isNull);
    expect(model.value.recommendationsStatus, RecommendationsStatus.error);
    expect(model.value.selectionSaved, isFalse);
  });

  test('unsupported edits and cancellation never reach backend writes',
      () async {
    await search();
    expect(
        await model.update(
            title: 'Changed title',
            room: '',
            startsAt: start,
            endsAt: end,
            sourceSlotId: 'candidate-not-batch'),
        isFalse);
    expect(await model.cancel(), isFalse);
    expect(await model.toggleTopic('invented'), isFalse);
    await expectLater(
        repository
            .save(model.value.session!.copyWith(room: 'Unsupported room')),
        throwsA(isA<SessionFailure>()));
    expect(source.writes, isEmpty);
    expect(source.decisions, 0);
  });

  test('Bogotá editor wall time round-trips independently of device timezone',
      () async {
    final session = (await repository.getById('firestore-document'))!;
    expect(session.displayTime(start).hour, 11);
    expect(session.fromDisplayTime(DateTime(2030, 10, 2, 11, 15)),
        DateTime.utc(2030, 10, 2, 16, 15));
  });

  testWidgets(
      'unscheduled details show explicit search and hide unsupported controls',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: StudySessionView(viewModel: model)));
    await tester.pumpAndSettle();
    expect(find.text('Not scheduled'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Modify Session'), findsOneWidget);
    expect(find.text('Topics & Objectives'), findsNothing);
    expect(
        source.calls.where((call) => call.$1 == 'getActivityRecommendations'),
        isEmpty);
    final duration = find.byType(TextField);
    await tester.ensureVisible(duration);
    await tester.enterText(duration, '60');
    final findTimes = find.text('Find times for today');
    await tester.ensureVisible(findTimes);
    await tester.tap(findTimes);
    await tester.pumpAndSettle();
    expect(find.text('Best recommended slot'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Home routes using the discovered Firestore ID without sample cards',
      (tester) async {
    final router = AppRouter.create(AuthDependencies.mock(),
        activitiesDependencies:
            ActivitiesDependencies(repository: repository, catalog: repository),
        alertsDependencies: AlertsDependencies.mock(),
        groupsDependencies: GroupsDependencies.mock(),
        profileDependencies: ProfileDependencies.mock(),
        scheduleDependencies: ScheduleDependencies.mock(),
        initialLocation: AppRoutes.home);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final card = find.text('Real activity');
    expect(card, findsOneWidget);
    expect(find.text('Study Session: Linear Algebra & Calculus'), findsNothing);
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.studySession('firestore-document'));
    expect(find.text('Not scheduled'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

import 'package:parchapp/app/dependency_injection/auth_dependencies.dart';
import 'package:parchapp/features/auth/presentation/views/sign_in_view.dart';
import 'package:parchapp/features/activities/domain/entities/study_session.dart';
import 'package:parchapp/features/activities/domain/entities/slot_recommendation.dart';
import 'package:parchapp/features/activities/presentation/view_models/study_session_view_model.dart';
import 'package:parchapp/features/activities/presentation/widgets/recommended_slots_card.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/features/expansions/domain/repositories/expansion_repository.dart';
import 'package:parchapp/features/expansions/domain/repositories/external_actions.dart';
import 'package:parchapp/features/expansions/data/repositories/firebase_expansion_repository.dart';
import 'package:parchapp/features/expansions/presentation/views/expansion_views.dart';
import 'package:parchapp/features/auth/presentation/widgets/password_recovery_sheet.dart';
import 'package:parchapp/features/alerts/data/repositories/firebase_alerts_repository.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/alerts/presentation/widgets/alert_card.dart';

class ExpansionFake implements ExpansionRepository, MobileApi {
  @override
  String? sessionId = 'owner';
  final calls = <Map<String, dynamic>>[];
  final searches = <String, Completer<Map<String, dynamic>>>{};
  bool failSearch = false,
      lostSave = false,
      canEdit = true,
      failCompletion = false;
  Map<String, dynamic> material = {
    'activityId': 'a1',
    'version': 'none',
    'canEdit': true,
    'cancelled': false,
    'topics': [
      {'id': 't1', 'title': 'Read chapter', 'completed': false}
    ],
    'resources': []
  };
  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> input) =>
      request(name, input);
  @override
  Future<Map<String, dynamic>> request(
      String name, Map<String, dynamic> input) async {
    calls.add({'method': name, ...input});
    switch (name) {
      case 'discover':
        if (failSearch) throw StateError('offline');
        final query = input['query'] as String;
        if (searches.containsKey(query)) return searches[query]!.future;
        return {
          'results': query == 'missing'
              ? []
              : [
                  {
                    'id': input['cursor'] == null ? 'g1' : 'g2',
                    'kind': 'groups',
                    'title': input['cursor'] == null
                        ? 'Study team'
                        : 'Another group',
                    'description': '2 members',
                    'targetId': 'g1'
                  }
                ],
          'cursor': input['cursor'] == null ? 'next' : null
        };
      case 'getSharedProfile':
        return {'id': input['userId'], 'name': 'Camila'};
      case 'getShareLinks':
        return {'links': []};
      case 'createShareLink':
        return {
          'token': 'x' * 43,
          'linkId': 'link1',
          'kind': 'group',
          'entityId': 'g1',
          'expiresAt': '2030-01-01T00:00:00Z'
        };
      case 'resolveShareLink':
        return {
          'title': 'Study team',
          'kind': 'group',
          'entityId': 'g1',
          'member': false,
          'expiresAt': '2030-01-01T00:00:00Z'
        };
      case 'joinSharedGroup':
        return {'groupId': 'g1', 'joined': true};
      case 'getActivityMaterials':
        return {...material, 'canEdit': canEdit};
      case 'saveActivityMaterials':
        if (lostSave) {
          lostSave = false;
          throw FirebaseFunctionsException(
              code: 'deadline-exceeded', message: 'ack lost');
        }
        material = {
          ...material,
          'topics': input['topics'],
          'resources': input['resources'],
          'version': 'v1'
        };
        return material;
      case 'setTopicCompletion':
        if (failCompletion) throw StateError('offline');
        return {'saved': true};
      case 'exportActivityCalendar':
        return {
          'fileName': 'a1.ics',
          'content': 'BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n'
        };
      case 'getCalendarImportStatus':
        return {
          'lastImportedAt': '2026-10-20T13:00:00Z',
          'days': 56,
          'startDate': '2026-10-20'
        };
      case 'getAlerts':
        return {
          'alerts': [
            {
              'id': 'group-alert',
              'kind': 'groupInvite',
              'groupId': 'g1',
              'title': 'Group invitation',
              'description': 'Review',
              'createdAt': '2026-10-20T13:00:00Z',
              'isRead': false
            },
            {
              'id': 'event-alert',
              'kind': 'timeChanged',
              'studySessionId': 'a1',
              'title': 'Time changed',
              'description': 'New time',
              'createdAt': '2026-10-20T13:00:00Z',
              'isRead': false
            },
          ]
        };
      case 'markNotificationEventsRead':
        return {'ids': input['ids']};
      default:
        throw StateError(name);
    }
  }
}

class ExternalFake implements ExternalActions {
  bool failCopy = false;
  String? copied, shared, calendar;
  @override
  String enrollmentUrl(String token) => 'https://app.example/#/join/$token';
  @override
  Future<void> copy(String text) async {
    if (failCopy) throw StateError('clipboard denied');
    copied = text;
  }

  @override
  Future<String> shareText(String text) async {
    shared = text;
    return 'Sharing cancelled.';
  }

  @override
  Future<String> shareCalendar(String fileName, String content) async {
    calendar = content;
    return 'Sharing cancelled.';
  }

  @override
  Future<bool> openResource(String url) async => false;
}

void main() {
  test('repository rejects a late response after account change', () async {
    final fake = ExpansionFake();
    final pending = Completer<Map<String, dynamic>>();
    fake.searches['slow'] = pending;
    final repo = FirebaseExpansionRepository(fake, () => fake.sessionId);
    final future = repo.request('discover', {'query': 'slow'});
    fake.sessionId = 'peer';
    pending.complete({'results': []});
    await expectLater(future, throwsStateError);
  });
  testWidgets(
      'Discover distinguishes failures from empty search and paginates real IDs',
      (tester) async {
    final repo = ExpansionFake()..failSearch = true;
    await tester.pumpWidget(MaterialApp(home: DiscoverView(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Retry search'), findsOneWidget);
    expect(find.text('No results for these filters.'), findsNothing);
    repo.failSearch = false;
    await tester.tap(find.text('Retry search'));
    await tester.pumpAndSettle();
    expect(find.text('Study team'), findsOneWidget);
    await tester.ensureVisible(find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(find.text('Another group'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('No results for these filters.'), findsOneWidget);
  });
  testWidgets('Discover ignores results from an earlier query', (tester) async {
    final repo = ExpansionFake();
    repo.searches['slow'] = Completer();
    await tester.pumpWidget(MaterialApp(home: DiscoverView(repository: repo)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'slow');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    repo.searches['slow']!.complete({
      'results': [
        {
          'id': 'wrong',
          'title': 'Late private result',
          'kind': 'groups',
          'description': '',
          'targetId': 'wrong'
        }
      ],
      'cursor': null
    });
    await tester.pumpAndSettle();
    expect(find.text('Late private result'), findsNothing);
    expect(find.text('No results for these filters.'), findsOneWidget);
  });
  testWidgets(
      'share QR uses the generated URL and clipboard failure never reports Copied',
      (tester) async {
    final repo = ExpansionFake(), external = ExternalFake()..failCopy = true;
    await tester.pumpWidget(MaterialApp(
        home: ShareEntityView(
            repository: repo,
            external: external,
            kind: 'group',
            entityId: 'g1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create share code'));
    await tester.pumpAndSettle();
    expect(tester.widget<QrImageView>(find.byType(QrImageView)).semanticsLabel,
        'Share link QR: https://app.example/#/join/${'x' * 43}');
    await tester.ensureVisible(find.text('Copy'));
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(find.text('Copied to clipboard.'), findsNothing);
    external.failCopy = false;
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(find.text('Copied to clipboard.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Share'));
    await tester.pumpAndSettle();
    expect(find.text('Sharing cancelled.'), findsOneWidget);
  });
  testWidgets(
      'enrollment link requires explicit confirmation before membership write',
      (tester) async {
    final repo = ExpansionFake();
    final router = GoRouter(initialLocation: '/join/token', routes: [
      GoRoute(
          path: '/join/:token',
          builder: (_, state) => JoinLinkView(
              repository: repo, token: state.pathParameters['token'])),
      GoRoute(
          path: '/groups/details/:groupId',
          builder: (_, state) =>
              Text('Joined ${state.pathParameters['groupId']}'))
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c['method'] == 'joinSharedGroup'), isEmpty);
    await tester.tap(find.text('Confirm joining group'));
    await tester.pumpAndSettle();
    expect(find.text('Joined g1'), findsOneWidget);
  });
  testWidgets(
      'resource save with lost acknowledgement retries the same data and ID',
      (tester) async {
    final repo = ExpansionFake()..lostSave = true;
    await tester.pumpWidget(MaterialApp(
        home: ActivityMaterialsView(
            repository: repo, external: ExternalFake(), activityId: 'a1')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'New topic'), 'Work through exercise');
    await tester.ensureVisible(find.text('Add topic'));
    await tester.tap(find.text('Add topic'));
    await tester.pumpAndSettle();
    expect(find.text('Resources saved.'), findsNothing);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Retry the same resource save'), -200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Retry the same resource save'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry the same resource save'));
    await tester.tap(find.text('Retry the same resource save'));
    await tester.pumpAndSettle();
    final writes = repo.calls
        .where((c) => c['method'] == 'saveActivityMaterials')
        .toList();
    expect(writes.length, 2);
    expect(writes[0], writes[1]);
    expect(find.text('Resources saved.'), findsOneWidget);
  });
  testWidgets('failed checklist write preserves the last acknowledged progress',
      (tester) async {
    final repo = ExpansionFake()..failCompletion = true;
    await tester.pumpWidget(MaterialApp(
        home: ActivityMaterialsView(
            repository: repo, external: ExternalFake(), activityId: 'a1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read chapter'));
    await tester.pumpAndSettle();
    expect(find.text('0/1 personal checklist items completed'), findsOneWidget);
  });
  testWidgets(
      'calendar export shares actual ICS and cancellation never claims a saved calendar',
      (tester) async {
    final repo = ExpansionFake(), external = ExternalFake();
    repo.canEdit = false;
    await tester.pumpWidget(MaterialApp(
        home: ActivityMaterialsView(
            repository: repo, external: external, activityId: 'a1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Share calendar file (.ics)'));
    await tester.tap(find.text('Share calendar file (.ics)'));
    await tester.pumpAndSettle();
    expect(external.calendar, 'BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n');
    expect(find.text('Sharing cancelled.'), findsOneWidget);
    expect(find.textContaining('Added to calendar'), findsNothing);
  });
  testWidgets(
      'recovery validates email, waits for acknowledgement and preserves failures',
      (tester) async {
    final pending = Completer<void>();
    var requests = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PasswordRecoverySheet(
                email: 'invalid',
                request: (email) async {
                  requests++;
                  await pending.future;
                }))));
    await tester.tap(find.text('Request password reset'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    await tester.enterText(find.byType(TextField), 'a.va@test.com');
    await tester.tap(find.text('Request password reset'));
    await tester.pump();
    expect(requests, 1);
    expect(find.textContaining('Request accepted.'), findsNothing);
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Recovery request failed'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'a.va@test.com');
  });
  testWidgets(
      'recovery acknowledgement avoids claiming verified email or delivery',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PasswordRecoverySheet(
                email: 'a.va@test.com', request: (_) async {}))));
    await tester.tap(find.text('Request password reset'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Request accepted.'), findsOneWidget);
    expect(find.textContaining('Email verified'), findsNothing);
  });
  test(
      'real alert kinds and targets are mapped and event read is not placed in RSVP queue',
      () async {
    final api = ExpansionFake();
    final repo =
        FirebaseAlertsRepository(api, currentUserId: () => api.sessionId);
    final alerts = await repo.getAlerts();
    expect(alerts.first.kind, AlertKind.groupInvite);
    expect(alerts.first.groupId, 'g1');
    expect(alerts.last.studySessionId, 'a1');
    await repo.markAllRead();
    expect(api.calls.last['method'], 'markNotificationEventsRead');
    await expectLater(
        repo.respond(alerts.first.id, AlertResponse.joined), throwsStateError);
  });
  testWidgets('real reminder only offers an implemented entity action',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AlertCard(
                alert: const AppAlert(
                    id: 'r',
                    kind: AlertKind.reminder,
                    period: AlertPeriod.today,
                    title: 'Starts soon',
                    description: 'Actual plan',
                    timeLabel: 'Now',
                    studySessionId: 'a1',
                    authoritative: true),
                busy: false,
                onRespond: (_) => throw StateError('unsupported'),
                onCreateActivity: () {},
                onProfile: () {},
                onDetails: () => opened = true))));
    expect(find.text("I'm on my way"), findsNothing);
    await tester.tap(find.text('View activity'));
    expect(opened, true);
  });
  testWidgets(
      'Suggested Times filters preserve server order and selected slot identity',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    String? selected;
    final session = StudySession(
        id: 'a1',
        title: 'Study',
        description: '',
        startsAt: null,
        endsAt: null,
        location: '',
        room: '',
        reminder: '',
        topics: [],
        participants: [],
        resources: [],
        canOrganize: true,
        timeZone: 'America/Bogota');
    final slots = [
      RecommendedSlot(
          id: 'morning',
          startsAt: DateTime.utc(2030, 1, 1, 14),
          endsAt: DateTime.utc(2030, 1, 1, 15),
          availableParticipants: 2,
          totalParticipants: 2,
          reasons: ['Morning server reason']),
      RecommendedSlot(
          id: 'afternoon',
          startsAt: DateTime.utc(2030, 1, 1, 19),
          endsAt: DateTime.utc(2030, 1, 1, 20),
          availableParticipants: 2,
          totalParticipants: 2,
          reasons: ['Afternoon server reason'])
    ];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ListView(controller: scroll, children: [
      RecommendedSlotsCard(
          showTimeFilters: true,
          state: StudySessionState(
              status: SessionLoadStatus.ready,
              session: session,
              recommendationsStatus: RecommendationsStatus.ready,
              recommendations: SlotRecommendations(
                  id: 'batch1', activityId: 'a1', slots: slots)),
          scrollController: scroll,
          onRetry: () {},
          onSearch: (_) {},
          onChangeDuration: () {},
          onRetryAnalytics: () {},
          onAccept: (id) => selected = id,
          onModify: (_) {},
          onShown: (_, slot) {})
    ]))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Afternoon/evening'));
    await tester.pumpAndSettle();
    expect(find.text('Morning server reason'), findsNothing);
    expect(find.text('Alternative 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Select this slot'));
    await tester.tap(find.text('Select this slot'));
    expect(selected, 'afternoon');
  });
  testWidgets(
      'sign-in preserves a shared-link destination after authenticating',
      (tester) async {
    final model = AuthDependencies.mock().createSignInViewModel();
    addTearDown(model.dispose);
    final router = GoRouter(
        initialLocation: '/sign-in?from=%2Fjoin%2Fshared-token',
        routes: [
          GoRoute(
              path: '/sign-in',
              builder: (_, state) => SignInView(viewModel: model)),
          GoRoute(
              path: '/join/:token',
              builder: (_, state) =>
                  Text('Review ${state.pathParameters['token']}'))
        ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Alex'));
    await tester.pumpAndSettle();
    expect(find.text('Review shared-token'), findsOneWidget);
  });
  for (final width in [390.0, 320.0]) {
    testWidgets('sharing and materials fit $width px at 180 percent text',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app(Widget child) => MaterialApp(
          builder: (context, widget) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: widget!),
          home: child);
      final repo = ExpansionFake();
      await tester.pumpWidget(app(ShareEntityView(
          repository: repo,
          external: ExternalFake(),
          kind: 'group',
          entityId: 'g1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create share code'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Copy'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(ActivityMaterialsView(
          repository: repo, external: ExternalFake(), activityId: 'a1')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('New topic'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(find.widgetWithText(TextField, 'New topic'),
          'A complete long topic for this activity');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Discover and calendar status fit $width px at 180 percent text',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app(Widget child) => MaterialApp(
          builder: (context, widget) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: widget!),
          home: child);
      final repo = ExpansionFake();
      await tester.pumpWidget(app(DiscoverView(repository: repo)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(CalendarStatusView(
          repository: repo,
          importCalendar: () async {
            throw StateError('provider');
          })));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.text('Authorize and import Google FreeBusy'), 200);
      await tester.tap(find.text('Authorize and import Google FreeBusy'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.textContaining('Last successful import:'), -200);
      expect(find.textContaining('Last successful import:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

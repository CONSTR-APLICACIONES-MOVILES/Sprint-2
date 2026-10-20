import 'package:parchapp/core/data/offline_mobile_api.dart';
import 'package:parchapp/features/groups/data/repositories/mock_active_groups_repository.dart';
import 'package:parchapp/features/groups/domain/use_cases/manage_active_groups.dart';
import 'package:parchapp/features/groups/presentation/view_models/active_groups_view_model.dart';
import 'package:parchapp/features/groups/presentation/views/active_groups_view.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/features/groups/data/repositories/firebase_community_repository.dart';
import 'package:parchapp/features/groups/presentation/views/community_views.dart';
import 'package:parchapp/features/profile/data/repositories/firebase_profile_repository.dart';
import 'package:parchapp/features/profile/domain/entities/profile_preferences.dart';
import 'package:parchapp/features/profile/domain/entities/profile_user.dart';
import 'package:parchapp/features/profile/presentation/widgets/presence_settings_sheets.dart';
import 'package:parchapp/features/activities/data/repositories/firebase_study_sessions_repository.dart';
import 'package:parchapp/features/activities/domain/use_cases/manage_study_session.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_editor_view_model.dart';
import 'package:parchapp/features/activities/presentation/widgets/activity_form.dart';
import '../activities/firebase_study_sessions_repository_test.dart'
    show FakeActivitySource;

class CommunityApi implements MobileApi {
  final requests = <Map<String, dynamic>>[];
  bool lostAck = false, failDetails = false, failPeers = false;
  Completer<Map<String, dynamic>>? pending;
  Map<String, dynamic> profile = {
    'id': 'owner',
    'name': 'Owner',
    'plansCompleted': 0,
    'activeGroups': 1,
    'status': 'inClass',
    'statusExpiresAt': '2030-01-01T15:00:00Z',
    'preferences': const ProfilePreferences().toMap()
  };
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    requests.add({'method': name, ...input});
    switch (name) {
      case 'getCommunityPeers':
        if (failPeers) throw StateError('offline peers');
        return {
          'peers': [
            {'id': 'peer', 'name': 'Camila'}
          ]
        };
      case 'getGroupDetails':
        if (pending != null) return pending!.future;
        if (failDetails) throw StateError('offline');
        return {
          'id': 'g1',
          'name': 'Study team',
          'category': 'study',
          'ownerId': 'owner',
          'members': [
            {'id': 'owner', 'name': 'Owner', 'status': 'focused'}
          ],
          'invitations': [],
          'activities': [
            {
              'id': 'a1',
              'title': 'Persistent activity',
              'status': 'PROPOSED',
              'cancelled': false,
              'startTime': null,
              'date': '',
              'time': '',
              'attendance': {'accepted': 1, 'maybe': 1, 'declined': 0}
            }
          ]
        };
      case 'createGroup':
        if (lostAck) {
          lostAck = false;
          throw FirebaseFunctionsException(
              code: 'deadline-exceeded', message: 'ack lost');
        }
        return {'groupId': 'g1', 'invitationCount': 1};
      case 'getGroupInvitations':
        return {
          'invitations': [
            {
              'groupId': 'g1',
              'groupName': 'Study team',
              'state': 'pending',
              'expiresAt': '2030-01-01T00:00:00Z'
            }
          ]
        };
      case 'respondGroupInvitation':
        return {'groupId': 'g1', 'state': input['response']};
      case 'getProfile':
        return profile;
      case 'updatePresence':
        profile = {
          ...profile,
          'status': input['status'],
          'statusExpiresAt': input['expiresAt']
        };
        return profile;
      case 'updatePreferences':
        profile = {...profile, 'preferences': input['preferences']};
        return profile;
      default:
        throw StateError(name);
    }
  }
}

class TwoGroups extends FakeActivitySource {
  @override
  Future<List<Map<String, dynamic>>> listGroups() async => [
        {'id': 'other', 'name': 'Other group'},
        {'id': 'real-group', 'name': 'Requested group'}
      ];
}

Widget sheet(Widget child, {double scale = 1}) => MaterialApp(
    home: Scaffold(
        body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(20), child: child)))));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'lost group acknowledgement is recovered after reopening by the same UID and project',
      () async {
    final api = CommunityApi()..lostAck = true;
    final repo = FirebaseCommunityRepository(api,
        currentUserId: () => 'owner', project: 'p1');
    await expectLater(repo.create('key1', 'Study team', 'study', ['peer']),
        throwsA(isA<FirebaseFunctionsException>()));
    final reopened = FirebaseCommunityRepository(api,
        currentUserId: () => 'owner', project: 'p1');
    final pending = await reopened.pendingCreation();
    expect(pending!['requestId'], 'key1');
    expect(
        await FirebaseCommunityRepository(api,
                currentUserId: () => 'peer', project: 'p1')
            .pendingCreation(),
        isNull);
    expect(
        await FirebaseCommunityRepository(api,
                currentUserId: () => 'owner', project: 'p2')
            .pendingCreation(),
        isNull);
    await expectLater(
        reopened.create('key2', 'Changed', 'study', []), throwsStateError);
    expect(
        (await reopened
            .create('key1', 'Study team', 'study', ['peer']))['groupId'],
        'g1');
    expect(await reopened.pendingCreation(), isNull);
    final creates =
        api.requests.where((r) => r['method'] == 'createGroup').toList();
    expect(creates.length, 2);
    expect(creates[0], creates[1]);
  });
  test('community response from an old session cannot be delivered', () async {
    final api = CommunityApi()..pending = Completer();
    String uid = 'owner';
    final repo = FirebaseCommunityRepository(api, currentUserId: () => uid);
    final future = repo.details('g1');
    uid = 'peer';
    api.pending!.complete({'id': 'g1'});
    await expectLater(future, throwsStateError);
  });
  test(
      'profile repository persists expanded status and preferences without changing calendar data',
      () async {
    final api = CommunityApi(),
        repo = FirebaseProfileRepository(CommunityApi());
    expect((await repo.getProfile()).status, AvailabilityStatus.inClass);
    final real = FirebaseProfileRepository(api);
    final updated = await real.updatePresence(
        AvailabilityStatus.inTransit, DateTime.utc(2030, 1, 1, 16), 'private');
    expect(updated.status, AvailabilityStatus.inTransit);
    await real.updatePreferences(const ProfilePreferences(
        scheduleVisibility: 'private',
        closeFriendIds: ['peer'],
        invitationBadges: false));
    expect((await real.getProfile()).preferences.invitationBadges, false);
    expect(api.requests.any((r) => r['method'] == 'importCalendarAvailability'),
        false);
    expect(
        updated.copyWith(statusExpiresAt: DateTime.utc(2000)).effectiveStatus,
        AvailabilityStatus.offline);
  });
  testWidgets(
      'group creation reviews real peers before sending and navigates only after receipt',
      (tester) async {
    final api = CommunityApi();
    final router = GoRouter(initialLocation: '/groups/new', routes: [
      GoRoute(
          path: '/groups/new',
          builder: (_, state) =>
              CreateGroupView(repository: FirebaseCommunityRepository(api))),
      GoRoute(
          path: '/groups/details/:groupId',
          builder: (_, state) =>
              Text('Saved ${state.pathParameters['groupId']}'))
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Study team');
    await tester.tap(find.text('Camila'));
    await tester.pump();
    await tester.ensureVisible(find.text('Review group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review group'));
    await tester.pumpAndSettle();
    expect(find.text('Camila'), findsOneWidget);
    expect(api.requests.where((r) => r['method'] == 'createGroup'), isEmpty);
    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Create Group'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create Group'));
    await tester.pumpAndSettle();
    expect(find.text('Saved g1'), findsOneWidget);
  });
  testWidgets(
      'reopening uncertain group creation retains request even when peer list fails',
      (tester) async {
    final api = CommunityApi()..lostAck = true;
    final repo = FirebaseCommunityRepository(api, currentUserId: () => 'owner');
    await expectLater(repo.create('retry1', 'Study team', 'study', ['peer']),
        throwsA(isA<FirebaseFunctionsException>()));
    api.failPeers = true;
    await tester
        .pumpWidget(MaterialApp(home: CreateGroupView(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Review group'), findsOneWidget);
    expect(find.text('Retry creation'), findsOneWidget);
    expect(find.text('Study team'), findsOneWidget);
    expect(find.text('peer'), findsOneWidget);
    final back = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Back to details'));
    expect(back.onPressed, isNull);
  });
  testWidgets(
      'details preserve group context in Create Activity and Compare schedules',
      (tester) async {
    final api = CommunityApi();
    final router = GoRouter(initialLocation: '/groups/details/g1', routes: [
      GoRoute(
          path: '/groups/details/:groupId',
          builder: (_, state) => GroupDetailsView(
              groupId: state.pathParameters['groupId']!,
              repository: FirebaseCommunityRepository(api))),
      GoRoute(
          path: '/activities/new',
          builder: (_, state) =>
              Text('Create for ${state.uri.queryParameters['groupId']}')),
      GoRoute(
          path: '/schedule',
          builder: (_, state) =>
              Text('Compare for ${state.uri.queryParameters['groupId']}')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Owner · Focused'), 200);
    expect(find.text('Owner · Focused'), findsOneWidget);
    await tester.tap(find.text('Create Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Create for g1'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Compare schedules'), -200);
    await tester.tap(find.text('Compare schedules'));
    await tester.pumpAndSettle();
    expect(find.text('Compare for g1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('details failure offers retry and never presents an empty group',
      (tester) async {
    final api = CommunityApi()..failDetails = true;
    await tester.pumpWidget(MaterialApp(
        home: GroupDetailsView(
            groupId: 'g1', repository: FirebaseCommunityRepository(api))));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No activities yet.'), findsNothing);
    api.failDetails = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Study team'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'accepting group invitation sends actual group ID then opens its details',
      (tester) async {
    final api = CommunityApi();
    final router = GoRouter(initialLocation: '/groups/invitations', routes: [
      GoRoute(
          path: '/groups/invitations',
          builder: (_, state) => GroupInvitationsView(
              repository: FirebaseCommunityRepository(api))),
      GoRoute(
          path: '/groups/details/:groupId',
          builder: (_, state) =>
              Text('Joined ${state.pathParameters['groupId']}'))
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text('Joined g1'), findsOneWidget);
    expect(api.requests.last, {
      'method': 'respondGroupInvitation',
      'groupId': 'g1',
      'response': 'accepted'
    });
  });
  testWidgets('own-group search is local and clearing restores the list',
      (tester) async {
    final model =
        ActiveGroupsViewModel(ManageActiveGroups(MockActiveGroupsRepository()));
    addTearDown(model.dispose);
    await tester
        .pumpWidget(MaterialApp(home: ActiveGroupsView(viewModel: model)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no-such-group');
    await tester.pumpAndSettle();
    expect(find.text('No groups match this filter.'), findsOneWidget);
    await tester.tap(find.text('Clear search and filter'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(find.text('No groups match this filter.'), findsNothing);
  });
  test('acknowledged presence and privacy update the offline profile copy',
      () async {
    final remote = CommunityApi();
    final api = OfflineMobileApi(
        remote: remote,
        store: PreferencesOfflineStore(await SharedPreferences.getInstance()),
        project: 'cache',
        currentUserId: () => 'owner');
    addTearDown(api.dispose);
    final profiles = FirebaseProfileRepository(api);
    await profiles.getProfile();
    await profiles.updatePresence(
        AvailabilityStatus.focused, DateTime.utc(2030, 1, 1, 16), 'private',
        ownerId: 'owner');
    await profiles.updatePreferences(
        const ProfilePreferences(invitationBadges: false),
        ownerId: 'owner');
    await api.setForcedOffline(true);
    final cached = await profiles.getProfile();
    expect(cached.status, AvailabilityStatus.focused);
    expect(cached.preferences.invitationBadges, false);
  });
  for (final width in [390.0, 320.0]) {
    testWidgets('group creation and details fit $width px at 180 percent text',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FirebaseCommunityRepository(CommunityApi());
      Widget app(Widget child) => MaterialApp(
          builder: (context, widget) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: widget!),
          home: child);
      await tester.pumpWidget(app(CreateGroupView(repository: repo)));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField), 'A group with a meaningful long name');
      tester.testTextInput.hide();
      await tester.scrollUntilVisible(find.text('Review group'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review group'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester
          .pumpWidget(app(GroupDetailsView(groupId: 'g1', repository: repo)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Persistent activity'), 200);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets(
        'status and privacy sheets fit $width px with 180 percent text and preserve failed choices',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final user = await FirebaseProfileRepository(CommunityApi()).getProfile();
      await tester.pumpWidget(sheet(
          PresenceSheet(
              user: user, onSave: (_, expires, visibility) async => false),
          scale: 1.8));
      await tester.ensureVisible(find.text('Save status'));
      await tester.tap(find.text('Save status'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Your choices are preserved'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(sheet(
          PrivacySettingsSheet(
              user: user,
              getPeers: () async => [
                    {'id': 'peer', 'name': 'Camila'}
                  ],
              onSave: (_) async => false),
          scale: 1.8));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save settings'));
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Your choices are preserved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('activity form preselects the group supplied by Group Details',
      (tester) async {
    final source = TwoGroups();
    final model = ActivityEditorViewModel(
        ManageStudySession(FirebaseStudySessionsRepository(source)),
        requestedGroupId: 'real-group');
    addTearDown(model.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ActivityForm(viewModel: model, onSaved: (_) {}))));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).first);
    // The source defines the real-group roster, so the requested ID is selectable.
    expect(dropdown.initialValue, 'real-group');
  });
}

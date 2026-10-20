import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parchapp/core/theme/app_theme.dart';
import 'package:parchapp/features/home/presentation/views/home_view.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_list_view_model.dart';
import 'package:parchapp/features/alerts/presentation/view_models/alerts_state.dart';
import 'package:parchapp/features/groups/presentation/view_models/active_groups_state.dart';
import 'package:parchapp/features/groups/data/repositories/firebase_community_repository.dart';
import 'package:parchapp/features/groups/presentation/views/community_views.dart';
import 'package:parchapp/features/profile/domain/entities/profile_user.dart';
import 'package:parchapp/features/profile/presentation/widgets/presence_settings_sheets.dart';
import 'package:parchapp/features/activities/data/repositories/firebase_study_sessions_repository.dart';
import 'package:parchapp/features/activities/domain/use_cases/manage_study_session.dart';
import 'package:parchapp/features/activities/presentation/view_models/study_session_view_model.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_invitation_view_model.dart';
import 'package:parchapp/features/activities/presentation/views/activity_invitation_view.dart';
import 'package:parchapp/features/activities/presentation/views/study_session_view.dart';
import 'package:parchapp/shared/widgets/parch_visuals.dart';
import 'features/groups/community_phase_c_test.dart' show CommunityApi;
import 'features/activities/firebase_study_sessions_repository_test.dart'
    show FakeActivitySource;
import 'features/activities/activity_phase_b_test.dart' show Inbox;
import 'features/home_dashboard_test.dart' as home_fixture;
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/alerts/domain/use_cases/manage_alerts.dart';
import 'package:parchapp/features/alerts/presentation/view_models/alerts_view_model.dart';
import 'package:parchapp/features/alerts/presentation/views/alerts_view.dart';
import 'package:parchapp/features/groups/domain/use_cases/manage_active_groups.dart';
import 'package:parchapp/features/groups/data/repositories/mock_active_groups_repository.dart';
import 'package:parchapp/features/groups/presentation/view_models/active_groups_view_model.dart';
import 'package:parchapp/features/groups/presentation/views/active_groups_view.dart';

// Local fixtures only; never connects to Firebase or mutates demo data.
const profile = ProfileUser(
    id: 'owner',
    name: 'Alex',
    program: 'Engineering',
    verified: false,
    semester: 6,
    year: 2026,
    academicLevel: AcademicLevel.undergraduate,
    campus: '',
    university: '',
    studentId: '',
    status: AvailabilityStatus.active,
    plansCompleted: 0,
    activeGroups: 1,
    onTimeRate: null);

class VisualCommunity extends CommunityApi {
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    final result = await super.call(name, input);
    if (name != 'getGroupDetails') return result;
    return {
      ...result,
      'name': 'Friday Plans',
      'category': 'social',
      'members': [
        {'id': 'owner', 'name': 'Alex Valenzuela', 'status': 'active'},
        {'id': 'peer', 'name': 'Camila Gomez', 'status': 'focused'},
        {'id': 'mateo', 'name': 'Mateo Rios', 'status': 'busy'}
      ],
      'activities': [
        {
          'id': 'a1',
          'title': 'End of Semester Dinner',
          'status': 'PROPOSED',
          'cancelled': false,
          'startTime': '2030-10-24T00:00:00Z',
          'date': '',
          'time': '',
          'location': 'Zona T, Bogota',
          'attendance': {'accepted': 2, 'maybe': 0, 'declined': 0, 'pending': 1}
        }
      ]
    };
  }
}

class VisualInbox extends Inbox {
  @override
  Future<List<AppAlert>> getAlerts() async => const [
        AppAlert(
            id: 'reminder',
            kind: AlertKind.reminder,
            period: AlertPeriod.today,
            title: 'Study Session: Linear Algebra',
            description: 'Starts in 20 minutes · Central Library',
            timeLabel: '15:40',
            authoritative: true),
        AppAlert(
            id: 'update',
            kind: AlertKind.timeChanged,
            period: AlertPeriod.today,
            title: 'Dinner plan updated',
            description:
                'The organizer changed the activity. Open details to review the latest plan.',
            timeLabel: '14:15',
            authoritative: true),
      ];
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([inter.load(), icons.load()]);
  });
  testWidgets('brand and restored layouts render with the production theme',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool decoded = false;
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    Future<void> capture(String name, Widget child) async {
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: child,
              debugShowCheckedModeBanner: false)));
      await tester.pumpAndSettle();
      if (!decoded) {
        await tester.runAsync(() async {
          await precacheImage(
              const AssetImage('assets/images/activity_social_reference.jpg'),
              key.currentContext!);
          await precacheImage(
              const AssetImage('assets/images/activity_study_reference.jpg'),
              key.currentContext!);
        });
        decoded = true;
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull, reason: name);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/visual-review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture(
        'dashboard',
        HomeView(
            profile: profile,
            activityState: ActivityListState(
                loading: false, activities: [home_fixture.plan]),
            groupsState: ActiveGroupsState(groups: [home_fixture.group]),
            alertsState: AlertsState(alerts: [home_fixture.alert])));
    expect(find.byType(ParchBrand), findsOneWidget);
    final groupsModel =
        ActiveGroupsViewModel(ManageActiveGroups(MockActiveGroupsRepository()));
    await capture('groups', ActiveGroupsView(viewModel: groupsModel));
    groupsModel.dispose();
    final alertsModel = AlertsViewModel(ManageAlerts(VisualInbox()));
    await capture('alerts', AlertsView(viewModel: alertsModel));
    await tester.pumpWidget(const SizedBox());
    alertsModel.dispose();
    final repo = FirebaseCommunityRepository(VisualCommunity(),
        currentUserId: () => 'owner');
    await capture(
        'group-details', GroupDetailsView(groupId: 'g1', repository: repo));
    expect(find.text('23/10/2030 · 19:00 · Bogotá'), findsOneWidget);
    await capture('create-group', CreateGroupView(repository: repo));
    await capture(
        'availability',
        Scaffold(
            body: SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: PresenceSheet(
                        user: profile, onSave: (_, __, ___) async => false)))));
    final source = FakeActivitySource();
    source.details = {
      ...source.details,
      'title': 'Coffee @ Student Union',
      'category': 'social',
      'location': 'Main Lounge',
      'startTime': '2030-10-18T19:30:00Z',
      'endTime': '2030-10-18T21:00:00Z'
    };
    final sessions = FirebaseStudySessionsRepository(source);
    await capture(
        'activity-invitation',
        ActivityInvitationView(
            viewModel: ActivityInvitationViewModel(
                activityId: 'firestore-document',
                sessions: sessions,
                alerts: Inbox())));
    final model = StudySessionViewModel(
        ManageStudySession(sessions), 'firestore-document',
        autoLoadRecommendations: false);
    await capture('activity-details', StudySessionView(viewModel: model));
    await tester.pumpWidget(const SizedBox());
    model.dispose();
    debugDisableShadows = true;
  });
}

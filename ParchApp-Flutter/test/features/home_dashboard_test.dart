import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/activities/domain/entities/activity_summary.dart';
import 'package:parchapp/features/activities/presentation/view_models/activity_list_view_model.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/alerts/presentation/view_models/alerts_state.dart';
import 'package:parchapp/features/groups/domain/entities/active_group.dart';
import 'package:parchapp/features/groups/presentation/view_models/active_groups_state.dart';
import 'package:parchapp/features/home/presentation/views/home_view.dart';

const plan = ActivitySummary(
    id: 'plan-42',
    title: 'Project meeting',
    location: 'Library',
    date: '',
    time: '',
    confirmed: true);
const group = ActiveGroup(
    id: 'group-7',
    name: 'Project team',
    category: GroupCategory.study,
    memberCount: 7,
    subtitle: '',
    statusText: '',
    tone: GroupTone.info,
    detail: '',
    primaryAction: GroupAction.viewSchedule,
    secondaryAction: GroupAction.viewSchedule);
const alert = AppAlert(
    id: 'alert-9',
    kind: AlertKind.invitation,
    period: AlertPeriod.today,
    title: 'Invitation',
    description: '',
    timeLabel: '12:00');

void main() {
  testWidgets('real data appears as cards with actual member and unread counts',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: HomeView(
            userName: 'Gabriel',
            userInitials: 'GP',
            activityState:
                ActivityListState(loading: false, activities: [plan]),
            groupsState: ActiveGroupsState(groups: [group]),
            alertsState: AlertsState(alerts: [alert]))));
    expect(find.text('GP'), findsOneWidget);
    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isTrue);
    expect((badge.label! as Text).data, '1');
    await tester.scrollUntilVisible(find.text('Project meeting'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Project meeting'), findsOneWidget);
    expect(find.text('Not scheduled'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Project team'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('7 members'), findsOneWidget);
    expect(find.text('4/4 ready'), findsNothing);
    expect(find.text('Open your groups'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('load errors do not become empty lists or a success badge',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
        home: HomeView(
            activityState:
                ActivityListState(loading: false, error: 'Activities failed'),
            groupsState: ActiveGroupsState(error: 'Groups failed'),
            alertsState: AlertsState(alerts: [alert], error: 'Inbox failed'),
            onRefreshActivities: () async {
              retries++;
            })));
    expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    expect(find.text('You are all caught up.'), findsNothing);
    expect(find.text('No activities in your groups yet.'), findsNothing);
    expect(find.text('No active groups yet.'), findsNothing);
    await tester.ensureVisible(find.text('Retry').first);
    await tester.tap(find.text('Retry').first);
    await tester.pump();
    expect(retries, 1);
  });

  for (final width in [390.0, 320.0]) {
    testWidgets('dashboard fits width $width with large text and scroll',
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
          home: HomeView(
              userName: 'Gabriel con un nombre largo',
              activityState:
                  ActivityListState(loading: false, activities: [plan]),
              groupsState: ActiveGroupsState(groups: [group]),
              alertsState: AlertsState())));
      for (var i = 0; i < 10; i++) {
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -250));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('7 members'), findsOneWidget);
    });
  }
}

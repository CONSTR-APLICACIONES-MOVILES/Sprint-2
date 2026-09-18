import 'package:parchapp/app/dependency_injection/activities_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parchapp/app/app.dart';
import 'package:parchapp/app/dependency_injection/alerts_dependencies.dart';
import 'package:parchapp/app/dependency_injection/auth_dependencies.dart';
import 'package:parchapp/app/dependency_injection/schedule_dependencies.dart';
import 'package:parchapp/app/router/app_router.dart';
import 'package:parchapp/app/router/app_routes.dart';
import 'package:parchapp/features/alerts/data/repositories/mock_alerts_repository.dart';
import 'package:parchapp/features/alerts/domain/use_cases/manage_alerts.dart';
import 'package:parchapp/features/alerts/domain/entities/app_alert.dart';
import 'package:parchapp/features/alerts/presentation/view_models/alerts_view_model.dart';
import 'package:parchapp/features/alerts/presentation/views/alerts_view.dart';
import 'package:parchapp/features/alerts/presentation/widgets/alert_card.dart';
import 'package:parchapp/app/dependency_injection/profile_dependencies.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('time-change card renders the supplied description',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AlertCard(
      alert: const AppAlert(
          id: 'other-session',
          kind: AlertKind.timeChanged,
          period: AlertPeriod.today,
          title: 'Physics review',
          description: 'Camila moved Physics to 11:30.',
          timeLabel: '10:00'),
      busy: false,
      onRespond: (_) {},
      onCreateActivity: () {},
      onProfile: () {},
      onDetails: () {},
    ))));
    expect(find.text('Camila moved Physics to 11:30.'), findsOneWidget);
    expect(find.textContaining('Mateo moved'), findsNothing);
  });

  Future<AlertsViewModel> mount(WidgetTester tester,
      {double width = 390, double scale = 1}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = AlertsViewModel(ManageAlerts(MockAlertsRepository()));
    addTearDown(model.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: AlertsView(viewModel: model),
    ));
    await tester.pumpAndSettle();
    return model;
  }

  for (final size in [(390.0, 1.0), (320.0, 1.8)]) {
    testWidgets('alert stream scrolls without overflow at $size',
        (tester) async {
      await mount(tester, width: size.$1, scale: size.$2);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('4 new'), findsOneWidget);
      expect(
          find.text('Mutual Free Window with Sarah Jenkins'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('search and mark read update the visible state', (tester) async {
    final model = await mount(tester);
    await tester.tap(find.byTooltip('Search alerts'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Carlos');
    await tester.pumpAndSettle();
    expect(find.byType(AlertCard), findsOneWidget);
    expect(find.text('Carlos Mendoza'), findsOneWidget);
    await tester.tap(find.text('Mark read'));
    await tester.pumpAndSettle();
    expect(model.value.unreadCount, 0);
    expect(find.text('4 new'), findsNothing);
    await tester.enterText(find.byType(TextField), 'no-match');
    await tester.pumpAndSettle();
    expect(find.text('All caught up!'), findsOneWidget);
  });

  testWidgets('accepting a friend request updates cards and counts',
      (tester) async {
    final model = await mount(tester);
    await tester.tap(find.byTooltip('Search alerts'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Carlos');
    await tester.pumpAndSettle();
    final accept = find.widgetWithText(FilledButton, 'Accept');
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(model.value.unreadCount, 3);
    expect(find.byType(AlertCard), findsNothing);
  });

  testWidgets('decline confirmation can be cancelled', (tester) async {
    final model = await mount(tester);
    await tester.tap(find.byTooltip('Search alerts'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Carlos');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Decline'));
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(model.value.unreadCount, 4);
    expect(find.byType(AlertCard), findsOneWidget);
  });

  testWidgets('quick activity sheet opens and closes without sending anything',
      (tester) async {
    final model = await mount(tester);
    final create = find.text('1-Tap Create Activity');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('1-Tap Activity Creator'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Coffee with Sarah');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(model.value.visibleAlerts.length, 7);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home opens Alerts and read status persists across visits',
      (tester) async {
    final router = AppRouter.create(AuthDependencies.mock(),
        alertsDependencies: AlertsDependencies.mock(),
        activitiesDependencies: ActivitiesDependencies.mock(),
        scheduleDependencies: ScheduleDependencies.mock(),
        initialLocation: AppRoutes.home);
    addTearDown(router.dispose);
    await tester.pumpWidget(ParchApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.alerts);
    await tester.tap(find.text('Mark read'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('4 new'), findsNothing);
    expect(find.byType(AlertsView), findsOneWidget);
  });
}

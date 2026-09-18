import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parchapp/app/dependency_injection/schedule_dependencies.dart';
import 'package:parchapp/core/theme/app_theme.dart';
import 'package:parchapp/app/dependency_injection/activities_dependencies.dart';
import 'package:parchapp/app/dependency_injection/alerts_dependencies.dart';
import 'package:parchapp/app/dependency_injection/auth_dependencies.dart';
import 'package:parchapp/app/router/app_router.dart';
import 'package:parchapp/app/router/app_routes.dart';
import 'package:parchapp/features/activities/presentation/views/study_session_view.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  Future<GoRouter> mount(WidgetTester tester,
      {String? location, double width = 390, double scale = 1}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = AppRouter.create(AuthDependencies.mock(),
        alertsDependencies: AlertsDependencies.mock(),
        activitiesDependencies: ActivitiesDependencies.mock(),
        scheduleDependencies: ScheduleDependencies.mock(),
        initialLocation: location ?? AppRoutes.studySession('linear-algebra'));

    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!)));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('Home study card opens detail and back returns to Home',
      (tester) async {
    final router = await mount(tester, location: AppRoutes.home);
    final card = find.text('Study Session: Linear Algebra & Calculus');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(StudySessionView), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.studySession('linear-algebra'));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.home);
  });

  testWidgets('alert links to its study session', (tester) async {
    final router = await mount(tester, location: AppRoutes.alerts);
    await tester.tap(find.byTooltip('Search alerts'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Study Session');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View session'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.studySession('linear-algebra'));
    expect(find.byType(StudySessionView), findsOneWidget);
  });

  for (final width in [390.0, 320.0]) {
    testWidgets('detail and editor fit width $width with large text',
        (tester) async {
      await mount(tester, width: width, scale: width == 320 ? 1.8 : 1);
      for (var i = 0; i < 12; i++) {
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('Modify Session'));
      await tester.pumpAndSettle();
      expect(find.text('Modify Session Details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('progress and edits survive reopening the detail',
      (tester) async {
    final router = await mount(tester);
    final topic = find.byKey(const ValueKey('topic-eigenvalues'));
    await tester.ensureVisible(topic);
    await tester.tap(topic);
    await tester.pumpAndSettle();
    expect(find.text('1 / 3 completed'), findsOneWidget);
    await tester.tap(find.text('Modify Session'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Session Title'), 'Calculus review');
    await tester.enterText(
        find.widgetWithText(TextField, 'Location / Room'), 'Room 5');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Modify Session Details'), findsNothing);
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    router.push(AppRoutes.studySession('linear-algebra'));
    await tester.pumpAndSettle();
    expect(find.text('Calculus review'), findsOneWidget);
    expect(find.text('Room 5'), findsOneWidget);
    expect(find.text('1 / 3 completed'), findsOneWidget);
  });

  testWidgets('empty title keeps editor open with validation error',
      (tester) async {
    await mount(tester);
    await tester.tap(find.text('Modify Session'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Session Title'), ' ');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Modify Session Details'), findsOneWidget);
    expect(find.text('Enter a session title and room.'), findsWidgets);
  });

  testWidgets('cancel requires confirmation and disables mutations',
      (tester) async {
    await mount(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep Session'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm cancellation'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Modify Session'))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<CheckboxListTile>(
                find.byKey(const ValueKey('topic-eigenvalues')))
            .onChanged,
        isNull);
  });

  testWidgets('missing session offers safe return without a route stack',
      (tester) async {
    final router =
        await mount(tester, location: AppRoutes.studySession('unknown'));
    expect(find.text('Session not found.'), findsOneWidget);
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.home);
  });

  testWidgets('Home bottom destinations are registered and can return',
      (tester) async {
    final router = await mount(tester, location: AppRoutes.home);
    for (final destination in [
      ('Groups', AppRoutes.groups),
      ('Schedule', AppRoutes.schedule)
    ]) {
      await tester.tap(find.text(destination.$1).last);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, destination.$2);
      expect(find.text('${destination.$1} is coming soon.'), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.home);
      expect(tester.takeException(), isNull);
    }
  });
}

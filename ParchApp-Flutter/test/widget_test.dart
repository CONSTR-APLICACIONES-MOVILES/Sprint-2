import 'package:parchapp/app/dependency_injection/activities_dependencies.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parchapp/app/app.dart';
import 'package:parchapp/app/dependency_injection/auth_dependencies.dart';
import 'package:parchapp/app/dependency_injection/alerts_dependencies.dart';
import 'package:parchapp/app/dependency_injection/schedule_dependencies.dart';
import 'package:parchapp/app/router/app_router.dart';
import 'package:parchapp/app/router/app_routes.dart';
import 'package:parchapp/features/auth/domain/entities/authenticated_user.dart';
import 'package:parchapp/features/auth/domain/use_cases/sign_in.dart';
import 'package:parchapp/features/auth/presentation/view_models/sign_in_view_model.dart';
import 'package:parchapp/features/auth/presentation/views/sign_in_view.dart';
import 'package:parchapp/features/home/presentation/views/home_view.dart';
import 'support/fake_auth_repository.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<GoRouter> mountApp(WidgetTester tester, FakeAuthRepository repository,
      {String location = AppRoutes.welcome}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = AppRouter.create(AuthDependencies(repository: repository),
        scheduleDependencies: ScheduleDependencies.mock(),
        alertsDependencies: AlertsDependencies.mock(),
        activitiesDependencies: ActivitiesDependencies.mock(),
        initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(ParchApp(router: router));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> submitSignIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'student@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    final button = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  testWidgets('welcome opens account creation and sign-in routes',
      (tester) async {
    final router = await mountApp(tester, FakeAuthRepository());
    expect(find.text('PARCHAPP'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.createAccount);
    expect(find.text('Create your ParchApp account'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.signIn);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('sign-in View renders the injected dependency', (tester) async {
    final repository = FakeAuthRepository();
    final model = SignInViewModel(SignIn(repository));
    addTearDown(model.dispose);
    await tester.pumpWidget(MaterialApp(home: SignInView(viewModel: model)));
    await tester.pumpAndSettle();
    expect(find.text('Test Student'), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('successful credential sign-in opens the Home dashboard',
      (tester) async {
    final repository = FakeAuthRepository();
    final router =
        await mountApp(tester, repository, location: AppRoutes.signIn);
    await submitSignIn(tester);
    await tester.pumpAndSettle();
    expect(repository.signInCalls, 1);
    expect(router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeView), findsOneWidget);
    expect(find.text('Hello, Alex! 👋'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('Home notifications opens the connected alerts view',
      (tester) async {
    final router =
        await mountApp(tester, FakeAuthRepository(), location: AppRoutes.home);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.alerts);
    expect(find.text('Mutual Free Window with Sarah Jenkins'), findsOneWidget);
  });

  testWidgets('rejected credentials keep the form and display the failure',
      (tester) async {
    final repository = FakeAuthRepository()..rejectCredentials = true;
    final router =
        await mountApp(tester, repository, location: AppRoutes.signIn);
    await submitSignIn(tester);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.signIn);
    expect(find.text('Invalid credentials.'), findsOneWidget);
  });

  testWidgets('leaving sign-in during a request cannot navigate on completion',
      (tester) async {
    final repository = FakeAuthRepository()
      ..pendingSignIn = Completer<AuthenticatedUser>();
    final router =
        await mountApp(tester, repository, location: AppRoutes.signIn);
    await submitSignIn(tester);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    router.go(AppRoutes.welcome);
    await tester.pump();
    repository.pendingSignIn!.complete(FakeAuthRepository.user);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.welcome);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Google suggestion fills fields and account creation navigates',
      (tester) async {
    final repository = FakeAuthRepository();
    final router =
        await mountApp(tester, repository, location: AppRoutes.createAccount);
    await tester.tap(find.text('google@example.com'));
    await tester.pump();
    expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        'Google Student');
    expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        'google@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password');
    await tester.enterText(find.byType(TextField).at(3), 'password');
    final button = find.widgetWithText(FilledButton, 'Continue');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(repository.createCalls, 1);
    expect(router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeView), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('legacy auth completion route redirects to Home', (tester) async {
    final router = await mountApp(tester, FakeAuthRepository(),
        location: AppRoutes.authComplete);
    expect(router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeView), findsOneWidget);
    expect(find.text('Home will be implemented next.'), findsNothing);
  });

  testWidgets('recognized account sign-in opens Home', (tester) async {
    final router = await mountApp(tester, FakeAuthRepository(),
        location: AppRoutes.signIn);
    await tester.tap(find.text('Continue as Test'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('Google sign-in opens Home', (tester) async {
    final router = await mountApp(tester, FakeAuthRepository(),
        location: AppRoutes.signIn);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeView), findsOneWidget);
  });
}

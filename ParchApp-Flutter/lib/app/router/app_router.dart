import 'package:go_router/go_router.dart';

import '../../features/welcome/presentation/views/welcome_view.dart';
import '../../features/home/presentation/views/home_view.dart';

import '../dependency_injection/auth_dependencies.dart';
import '../dependency_injection/alerts_dependencies.dart';
import '../dependency_injection/activities_dependencies.dart';
import '../dependency_injection/profile_dependencies.dart';
import 'app_routes.dart';
import '../dependency_injection/schedule_dependencies.dart';
import '../dependency_injection/groups_dependencies.dart';

abstract final class AppRouter {
  static GoRouter create(
    AuthDependencies dependencies, {
    required AlertsDependencies alertsDependencies,
    required ActivitiesDependencies activitiesDependencies,
    required ScheduleDependencies scheduleDependencies,
    required ProfileDependencies profileDependencies,
    required GroupsDependencies groupsDependencies,
    String initialLocation = AppRoutes.welcome,
  }) =>
      GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: AppRoutes.studySessionPattern,
            builder: (context, state) => activitiesDependencies
                .route(state.pathParameters['sessionId']!),
          ),
          GoRoute(
            path: AppRoutes.activeGroups,
            name: 'activeGroups',
            builder: (context, state) =>
                groupsDependencies.activeGroupsRoute(),
          ),
          GoRoute(
            path: AppRoutes.groups,
            builder: (context, state) =>
                groupsDependencies.activeGroupsRoute(),
          ),
          GoRoute(
            path: AppRoutes.schedule,
            builder: (context, state) => scheduleDependencies.route(),
          ),
          GoRoute(
            path: AppRoutes.welcome,
            name: 'welcome',
            builder: (context, state) => const WelcomeView(),
          ),
          GoRoute(
            path: AppRoutes.signIn,
            name: 'signIn',
            builder: (context, state) => dependencies.signInRoute(),
          ),
          GoRoute(
            path: AppRoutes.createAccount,
            name: 'createAccount',
            builder: (context, state) => dependencies.createAccountRoute(),
          ),
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            path: AppRoutes.alerts,
            name: 'alerts',
            builder: (context, state) => alertsDependencies.route(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => profileDependencies.route(),
          ),
          GoRoute(
            path: AppRoutes.authComplete,
            redirect: (context, state) => AppRoutes.home,
          ),
        ],
      );
}

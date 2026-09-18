import 'package:go_router/go_router.dart';

import '../../features/welcome/presentation/views/welcome_view.dart';
import '../../features/home/presentation/views/home_view.dart';

import '../dependency_injection/auth_dependencies.dart';
import '../dependency_injection/alerts_dependencies.dart';
import '../dependency_injection/activities_dependencies.dart';
import '../../shared/widgets/unavailable_feature_view.dart';
import '../dependency_injection/profile_dependencies.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static GoRouter create(
    AuthDependencies dependencies, {
    required AlertsDependencies alertsDependencies,
    required ActivitiesDependencies activitiesDependencies,
    required ProfileDependencies profileDependencies,
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
              path: AppRoutes.groups,
              builder: (context, state) => const UnavailableFeatureView(
                  title: 'Groups', selectedIndex: 1)),
          GoRoute(
              path: AppRoutes.schedule,
              builder: (context, state) => const UnavailableFeatureView(
                  title: 'Schedule', selectedIndex: 2)),
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

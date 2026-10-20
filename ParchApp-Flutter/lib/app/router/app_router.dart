import '../dependency_injection/expansion_dependencies.dart';
import '../../features/activities/domain/entities/planning_context.dart';
import 'package:go_router/go_router.dart';
import 'app_extra_codec.dart';
import '../../shared/widgets/unavailable_feature_view.dart';

import '../../features/welcome/presentation/views/welcome_view.dart';

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
    ExpansionDependencies? expansions,
    String initialLocation = AppRoutes.welcome,
    GoRouterRedirect? redirect,
  }) =>
      GoRouter(
        extraCodec: const AppExtraCodec(),
        initialLocation: initialLocation,
        redirect: redirect,
        routes: [
          if (expansions != null) ...[
            GoRoute(
                path: '/join',
                builder: (context, state) => expansions.join(null)),
            GoRoute(
                path: '/join/:token',
                builder: (context, state) =>
                    expansions.join(state.pathParameters['token'])),
            GoRoute(
                path: '/people/:userId',
                builder: (context, state) =>
                    expansions.sharedProfile(state.pathParameters['userId']!)),
            GoRoute(
                path: '/share/:kind/:entityId',
                builder: (context, state) => expansions.share(
                    state.pathParameters['kind']!,
                    state.pathParameters['entityId']!)),
            GoRoute(
                path: '/calendar',
                builder: (context, state) => expansions.calendar()),
            GoRoute(
                path: '/activities/:activityId/materials',
                builder: (context, state) =>
                    expansions.materials(state.pathParameters['activityId']!)),
          ],
          GoRoute(
              path: '/activities/:activityId/suggested-times',
              builder: (context, state) => activitiesDependencies
                  .suggestedTimesRoute(state.pathParameters['activityId']!)),
          GoRoute(
              path: AppRoutes.createGroup,
              builder: (context, state) => groupsDependencies.createRoute()),
          GoRoute(
              path: AppRoutes.groupInvitations,
              builder: (context, state) =>
                  groupsDependencies.invitationsRoute()),
          GoRoute(
              path: AppRoutes.groupDetailsPattern,
              builder: (context, state) => groupsDependencies
                  .detailsRoute(state.pathParameters['groupId']!)),
          GoRoute(
            path: AppRoutes.discover,
            builder: (context, state) =>
                expansions?.discover() ??
                const UnavailableFeatureView(
                    title: 'Discover',
                    selectedIndex: 0,
                    actionLabel: 'View your groups',
                    actionRoute: AppRoutes.groups),
          ),
          GoRoute(
              path: AppRoutes.createActivity,
              builder: (context, state) => activitiesDependencies.createRoute(
                  groupId: state.uri.queryParameters['groupId'],
                  planning: state.extra is PlanningContext
                      ? state.extra as PlanningContext
                      : null,
                  date: state.uri.queryParameters['date'] ?? '',
                  time: state.uri.queryParameters['time'] ?? '')),
          GoRoute(
              path: AppRoutes.activityResultPattern,
              builder: (context, state) => activitiesDependencies.resultRoute(
                  state.pathParameters['activityId']!,
                  acknowledged:
                      state.extra == state.pathParameters['activityId'])),
          GoRoute(
              path: AppRoutes.activityInvitationPattern,
              builder: (context, state) => activitiesDependencies
                  .invitationRoute(state.pathParameters['activityId']!)),
          GoRoute(
            path: AppRoutes.studySessionPattern,
            builder: (context, state) => activitiesDependencies
                .route(state.pathParameters['sessionId']!),
          ),
          GoRoute(
            path: AppRoutes.activeGroups,
            name: 'activeGroups',
            builder: (context, state) => groupsDependencies.activeGroupsRoute(),
          ),
          GoRoute(
            path: AppRoutes.groups,
            builder: (context, state) => groupsDependencies.activeGroupsRoute(),
          ),
          GoRoute(
            path: AppRoutes.schedule,
            builder: (context, state) => scheduleDependencies.route(
                groupId: state.uri.queryParameters['groupId'],
                initialDay:
                    DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
                activityHeader: state.uri.queryParameters['activityId'] == null
                    ? null
                    : activitiesDependencies.scheduleHeader(
                        state.uri.queryParameters['activityId']!)),
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
            builder: (context, state) => activitiesDependencies.homeRoute(),
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

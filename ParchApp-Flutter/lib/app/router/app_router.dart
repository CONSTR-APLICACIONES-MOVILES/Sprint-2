import 'package:go_router/go_router.dart';

import '../../features/welcome/presentation/views/welcome_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../dependency_injection/auth_dependencies.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static GoRouter create(
    AuthDependencies dependencies, {
    String initialLocation = AppRoutes.welcome,
  }) =>
      GoRouter(
        initialLocation: initialLocation,
        routes: [
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
            path: AppRoutes.authComplete,
            redirect: (context, state) => AppRoutes.home,
          ),
        ],
      );
}

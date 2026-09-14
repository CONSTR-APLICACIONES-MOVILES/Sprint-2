import 'package:go_router/go_router.dart';

import '../../features/welcome/presentation/views/welcome_view.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeView(),
      ),
    ],
  );
}

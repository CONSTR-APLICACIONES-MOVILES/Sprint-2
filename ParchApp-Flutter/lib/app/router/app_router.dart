import 'package:go_router/go_router.dart';

import '../../features/auth/view/views/sign_in_view.dart';
import '../../features/welcome/view/welcome_view.dart';
import '../../features/auth/view/views/create_account_view.dart';
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

      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInView(),
      ),

      GoRoute(
        path: AppRoutes.createAccount,
        name: 'createAccount',
        builder: (context, state) => const CreateAccountView(),
      ),
    ],
  );
}
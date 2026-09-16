import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import 'auth_dependencies.dart';

GoRouter createAppRouter() => AppRouter.create(AuthDependencies.mock());

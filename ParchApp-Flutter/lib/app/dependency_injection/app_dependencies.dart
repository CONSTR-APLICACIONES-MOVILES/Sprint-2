import 'package:go_router/go_router.dart';
import '../../core/analytics/firebase_analytics_service.dart';
import '../router/app_router.dart';
import 'auth_dependencies.dart';
import 'alerts_dependencies.dart';
import 'activities_dependencies.dart';
import 'profile_dependencies.dart';
import 'schedule_dependencies.dart';
import 'groups_dependencies.dart';
import 'firebase_dependencies.dart';
import '../router/app_routes.dart';

GoRouter createAppRouter(FirebaseDependencies firebase) {
  final auth =
      AuthDependencies.firebase(firebase.auth, profiles: firebase.mobile);
  return AppRouter.create(
    auth,
    alertsDependencies: AlertsDependencies.firebase(firebase),
    activitiesDependencies: ActivitiesDependencies.firebase(firebase),
    scheduleDependencies: ScheduleDependencies.firebase(firebase),
    profileDependencies:
        ProfileDependencies.firebase(firebase, authRepository: auth.repository),
    groupsDependencies: GroupsDependencies.firebase(
      firebase,
      analytics: FirebaseAnalyticsService(),
    ),
    initialLocation:
        firebase.auth.currentUser == null ? AppRoutes.welcome : AppRoutes.home,
    redirect: (context, state) {
      final public = [
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.createAccount
      ];
      if (firebase.auth.currentUser == null &&
          !public.contains(state.matchedLocation)) {
        return Uri(
            path: AppRoutes.signIn,
            queryParameters: {'from': state.uri.toString()}).toString();
      }
      return null;
    },
  );
}

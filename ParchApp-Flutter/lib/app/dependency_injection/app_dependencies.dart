import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/analytics/firebase_analytics_service.dart';
import '../../features/groups/data/repositories/firestore_response_time_insights_repository.dart';
import '../router/app_router.dart';
import 'auth_dependencies.dart';
import 'alerts_dependencies.dart';
import 'activities_dependencies.dart';
import 'profile_dependencies.dart';
import 'schedule_dependencies.dart';
import 'groups_dependencies.dart';

GoRouter createAppRouter({bool firebaseReady = false}) => AppRouter.create(
      AuthDependencies.mock(),
      alertsDependencies: AlertsDependencies.mock(),
      activitiesDependencies: ActivitiesDependencies.mock(),
      scheduleDependencies: ScheduleDependencies.mock(),
      profileDependencies: ProfileDependencies.mock(),
      groupsDependencies: firebaseReady
          ? GroupsDependencies.mock(
              insights: FirestoreResponseTimeInsightsRepository(
                  FirebaseFirestore.instance),
              analytics: FirebaseAnalyticsService(),
            )
          : GroupsDependencies.mock(),
    );

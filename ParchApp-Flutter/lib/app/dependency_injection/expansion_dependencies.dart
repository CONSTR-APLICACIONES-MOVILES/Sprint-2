import '../../features/expansions/presentation/views/coordination_insights_view.dart';
import '../../features/expansions/presentation/views/activity_participants_view.dart';
import '../../features/expansions/presentation/views/social_views.dart';
import '../../features/expansions/presentation/views/planning_metrics_view.dart';
import 'package:flutter/material.dart';
import '../../features/expansions/data/repositories/firebase_expansion_repository.dart';
import '../../features/expansions/data/repositories/platform_external_actions.dart';
import '../../features/expansions/domain/repositories/expansion_repository.dart';
import '../../features/expansions/domain/repositories/external_actions.dart';
import '../../features/expansions/presentation/views/expansion_views.dart';
import 'firebase_dependencies.dart';
import 'schedule_dependencies.dart';

class ExpansionDependencies {
  final ExpansionRepository repository;
  final Future<Map<String, dynamic>?> Function()? loadCoordinationInsight;
  final Future<MetricsSnapshot> Function()? loadMetrics;
  final Future<void> Function()? refreshMetrics;
  final ExternalActions external;
  final bool calendarImportEnabled;
  final Future<void> Function() importCalendar;
  const ExpansionDependencies(
      {required this.repository,
      this.loadCoordinationInsight,
      this.loadMetrics,
      this.refreshMetrics,
      this.calendarImportEnabled = true,
      required this.external,
      required this.importCalendar});
  factory ExpansionDependencies.firebase(FirebaseDependencies firebase) {
    final schedule = ScheduleDependencies.firebase(firebase);
    return ExpansionDependencies(
        calendarImportEnabled: schedule.calendarImportEnabled,
        repository: FirebaseExpansionRepository(
            firebase.mobile, () => firebase.auth.currentUser?.uid),
        external: const PlatformExternalActions(),
        importCalendar: () async {
          final owner = firebase.auth.currentUser?.uid;
          await schedule.calendarImportRepository.authorizeCalendar();
          final blocks =
              await schedule.calendarImportRepository.importCalendar();
          if (owner == null || firebase.auth.currentUser?.uid != owner) {
            throw StateError('Session changed.');
          }
          await schedule.repository.replaceImportedCalendarBlocks(blocks);
        });
  }
  Widget insights() => CoordinationInsightsView(
      loadInsight: loadCoordinationInsight ?? () async => null);
  Widget metrics() => PlanningMetricsView(
      load: loadMetrics ?? () async => {}, refresh: refreshMetrics);
  Widget discover() => DiscoverView(repository: repository);
  Widget friends() => FriendsView(repository: repository);
  Widget findPeople() => FriendsView(repository: repository, searchOnly: true);
  Widget username() => UsernameView(repository: repository);
  Widget sharedProfile(String id) =>
      PublicPersonView(key: ValueKey(id), repository: repository, userId: id);
  Widget share(String kind, String id) => ShareEntityView(
      key: ValueKey('$kind:$id'),
      repository: repository,
      external: external,
      kind: kind,
      entityId: id);
  Widget join(String? token) =>
      JoinLinkView(key: ValueKey(token), repository: repository, token: token);
  Widget calendar() => CalendarStatusView(
      repository: repository,
      importCalendar: importCalendar,
      canImport: calendarImportEnabled);
  Widget materials(String id) => ActivityMaterialsView(
      key: ValueKey(id),
      repository: repository,
      external: external,
      activityId: id);
  Widget participants(String id) => ActivityParticipantsView(
      key: ValueKey(id), repository: repository, activityId: id);
}

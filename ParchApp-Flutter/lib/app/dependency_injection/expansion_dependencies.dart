import '../../features/expansions/presentation/views/coordination_insights_view.dart';
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
  final ExternalActions external;
  final bool calendarImportEnabled;
  final Future<void> Function() importCalendar;
  const ExpansionDependencies(
      {required this.repository,
      this.loadCoordinationInsight,
      this.calendarImportEnabled = true,
      required this.external,
      required this.importCalendar});
  factory ExpansionDependencies.firebase(FirebaseDependencies firebase) {
    final schedule = ScheduleDependencies.firebase(firebase);
    return ExpansionDependencies(
        calendarImportEnabled: schedule.calendarImportEnabled,
        loadCoordinationInsight: () async {
          final result =
              await firebase.mobile.call('getCoordinationInsight', {});
          return result['insight'] == null
              ? null
              : Map<String, dynamic>.from(result['insight'] as Map);
        },
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
  Widget discover() => DiscoverView(repository: repository);
  Widget sharedProfile(String id) =>
      SharedProfileView(key: ValueKey(id), repository: repository, userId: id);
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
}

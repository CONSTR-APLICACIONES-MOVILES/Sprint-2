import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/core/analytics/debug_analytics_service.dart';
import 'package:parchapp/features/groups/data/repositories/mock_active_groups_repository.dart';
import 'package:parchapp/features/groups/data/repositories/mock_response_time_insights_repository.dart';
import 'package:parchapp/features/groups/domain/entities/active_group.dart';
import 'package:parchapp/features/groups/domain/entities/response_time_estimate.dart';
import 'package:parchapp/features/groups/domain/use_cases/estimate_response_time.dart';
import 'package:parchapp/features/groups/domain/use_cases/manage_active_groups.dart';
import 'package:parchapp/features/groups/presentation/view_models/active_groups_view_model.dart';

class _FailingRepository extends MockActiveGroupsRepository {
  @override
  Future<List<ActiveGroup>> confirmRsvp(String id) async =>
      throw Exception('offline');
}

class _AcceptingRepository extends MockActiveGroupsRepository {
  @override
  Future<List<ActiveGroup>> confirmRsvp(String id) async => const [];
}

Future<ActiveGroup> _futbol(MockActiveGroupsRepository repository) async =>
    (await repository.getActiveGroups()).firstWhere((g) => g.id == 'futbol-5');

void main() {
  test('confirming the roster logs rsvp_submitted for BQ5', () async {
    final repository = MockActiveGroupsRepository();
    final analytics = DebugAnalyticsService();
    final futbol = await _futbol(repository);
    final groups = ManageActiveGroups(repository,
        analytics: analytics,
        now: () => futbol.invitationSentAt!.add(const Duration(minutes: 30)));

    await groups.confirmRsvp(futbol);

    expect(analytics.events.single.name, 'rsvp_submitted');
    expect(analytics.events.single.parameters, {
      'activity_id': 'demo-futbol-5-match',
      'group_size': 12,
      'response_ms': 1800000,
      'response': 'going',
    });
  });

  test('a failed RSVP logs nothing', () async {
    final repository = _FailingRepository();
    final analytics = DebugAnalyticsService();
    final futbol = await _futbol(repository);
    final groups = ManageActiveGroups(repository, analytics: analytics);

    await expectLater(groups.confirmRsvp(futbol), throwsException);
    expect(analytics.events, isEmpty);
  });

  test('a group without an activity logs nothing', () async {
    final analytics = DebugAnalyticsService();
    final groups =
        ManageActiveGroups(_AcceptingRepository(), analytics: analytics);
    const noInvitation = ActiveGroup(
      id: 'new-team',
      name: 'New team',
      category: GroupCategory.sports,
      memberCount: 6,
      subtitle: '',
      statusText: '',
      tone: GroupTone.warning,
      detail: '',
      primaryAction: GroupAction.voteRsvp,
      secondaryAction: GroupAction.teamChat,
      progressCurrent: 1,
      progressTotal: 6,
    );

    await groups.confirmRsvp(noInvitation);
    expect(analytics.events, isEmpty);
  });

  test('the view model gives the roster card its BQ5 estimate', () async {
    final model = ActiveGroupsViewModel(
      ManageActiveGroups(MockActiveGroupsRepository()),
      estimate: EstimateResponseTime(MockResponseTimeInsightsRepository()),
    );
    addTearDown(model.dispose);

    await model.load();

    final futbol = model.value.groups.firstWhere((g) => g.id == 'futbol-5');
    final roomies =
        model.value.groups.firstWhere((g) => g.id == 'roomies-main-st');
    expect(model.value.estimateFor(futbol)!.groupSize, 12);
    expect(model.value.estimateFor(futbol)!.kind, EstimateKind.perResponse);
    expect(model.value.estimateFor(roomies), isNull);
  });
}
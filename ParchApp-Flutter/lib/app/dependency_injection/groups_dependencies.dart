import 'package:flutter/material.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/debug_analytics_service.dart';
import '../../features/groups/data/repositories/mock_active_groups_repository.dart';
import '../../features/groups/data/repositories/mock_response_time_insights_repository.dart';
import '../../features/groups/domain/repositories/active_groups_repository.dart';
import '../../features/groups/domain/repositories/response_time_insights_repository.dart';
import '../../features/groups/domain/use_cases/estimate_response_time.dart';
import '../../features/groups/domain/use_cases/manage_active_groups.dart';
import '../../features/groups/presentation/view_models/active_groups_view_model.dart';
import '../../features/groups/presentation/views/active_groups_view.dart';

class GroupsDependencies {
  final ActiveGroupsRepository repository;
  final ResponseTimeInsightsRepository insights;
  final AnalyticsService analytics;

  const GroupsDependencies({
    required this.repository,
    required this.insights,
    required this.analytics,
  });

  factory GroupsDependencies.mock({
    ResponseTimeInsightsRepository? insights,
    AnalyticsService? analytics,
  }) =>
      GroupsDependencies(
        repository: MockActiveGroupsRepository(),
        insights: insights ?? MockResponseTimeInsightsRepository(),
        analytics: analytics ?? DebugAnalyticsService(),
      );

  ActiveGroupsViewModel createViewModel() => ActiveGroupsViewModel(
        ManageActiveGroups(repository, analytics: analytics),
        estimate: EstimateResponseTime(insights),
      );

  Widget activeGroupsRoute() => _ActiveGroupsEntry(dependencies: this);
}

class _ActiveGroupsEntry extends StatefulWidget {
  final GroupsDependencies dependencies;
  const _ActiveGroupsEntry({required this.dependencies});

  @override
  State<_ActiveGroupsEntry> createState() => _ActiveGroupsEntryState();
}

class _ActiveGroupsEntryState extends State<_ActiveGroupsEntry> {
  late final ActiveGroupsViewModel _viewModel =
      widget.dependencies.createViewModel();

  @override
  Widget build(BuildContext context) =>
      ActiveGroupsView(viewModel: _viewModel);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
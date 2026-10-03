import 'package:flutter/material.dart';
import '../../features/alerts/data/repositories/mock_alerts_repository.dart';
import '../../features/alerts/domain/repositories/alerts_repository.dart';
import '../../features/alerts/domain/use_cases/manage_alerts.dart';
import '../../features/alerts/presentation/view_models/alerts_view_model.dart';
import '../../features/alerts/presentation/views/alerts_view.dart';

class AlertsDependencies {
  final AlertsRepository repository;
  const AlertsDependencies({required this.repository});
  factory AlertsDependencies.mock({bool includeActivityPreviews = true}) =>
      AlertsDependencies(
          repository: MockAlertsRepository(
              includeActivityPreviews: includeActivityPreviews));
  AlertsViewModel createViewModel() =>
      AlertsViewModel(ManageAlerts(repository));
  Widget route() => _AlertsEntry(dependencies: this);
}

class _AlertsEntry extends StatefulWidget {
  final AlertsDependencies dependencies;
  const _AlertsEntry({required this.dependencies});
  @override
  State<_AlertsEntry> createState() => _AlertsEntryState();
}

class _AlertsEntryState extends State<_AlertsEntry> {
  late final AlertsViewModel _viewModel = widget.dependencies.createViewModel();
  @override
  Widget build(BuildContext context) => AlertsView(viewModel: _viewModel);
  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}

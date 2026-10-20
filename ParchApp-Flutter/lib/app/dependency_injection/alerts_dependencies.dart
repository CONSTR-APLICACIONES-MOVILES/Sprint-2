import 'package:flutter/material.dart';
import 'firebase_dependencies.dart';
import '../../core/analytics/firebase_analytics_service.dart';
import '../../core/data/offline_mobile_api.dart';
import '../../features/alerts/data/repositories/firebase_alerts_repository.dart';
import '../../features/alerts/data/repositories/mock_alerts_repository.dart';
import '../../features/alerts/domain/repositories/alerts_repository.dart';
import '../../features/alerts/domain/use_cases/manage_alerts.dart';
import '../../features/alerts/presentation/view_models/alerts_view_model.dart';
import '../../features/alerts/presentation/views/alerts_view.dart';

class AlertsDependencies {
  final AlertsRepository repository;
  final OfflineMobileApi? synchronization;
  const AlertsDependencies({required this.repository, this.synchronization});
  factory AlertsDependencies.mock({bool includeActivityPreviews = true}) =>
      AlertsDependencies(
          repository: MockAlertsRepository(
              includeActivityPreviews: includeActivityPreviews));
  factory AlertsDependencies.firebase(FirebaseDependencies firebase) =>
      AlertsDependencies(
          synchronization: firebase.mobile,
          repository: FirebaseAlertsRepository(firebase.mobile,
              analytics: FirebaseAnalyticsService(),
              currentUserId: () => firebase.auth.currentUser?.uid));
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
  int previousPending = 0;
  @override
  void initState() {
    super.initState();
    previousPending = widget.dependencies.synchronization?.value.pending ?? 0;
    widget.dependencies.synchronization?.addListener(_synchronized);
  }

  void _synchronized() {
    final pending = widget.dependencies.synchronization?.value.pending ?? 0;
    if (pending < previousPending) _viewModel.load();
    previousPending = pending;
  }

  @override
  Widget build(BuildContext context) => AlertsView(viewModel: _viewModel);
  @override
  void dispose() {
    widget.dependencies.synchronization?.removeListener(_synchronized);
    _viewModel.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../../features/activities/data/repositories/mock_study_sessions_repository.dart';
import '../../features/activities/domain/repositories/study_sessions_repository.dart';
import '../../features/activities/domain/use_cases/manage_study_session.dart';
import '../../features/activities/presentation/view_models/study_session_view_model.dart';
import '../../features/activities/presentation/views/study_session_view.dart';

class ActivitiesDependencies {
  final StudySessionsRepository repository;
  const ActivitiesDependencies({required this.repository});
  factory ActivitiesDependencies.mock() =>
      ActivitiesDependencies(repository: MockStudySessionsRepository());
  StudySessionViewModel createViewModel(String id) =>
      StudySessionViewModel(ManageStudySession(repository), id);
  Widget route(String id) =>
      _SessionEntry(key: ValueKey(id), dependencies: this, id: id);
}

class _SessionEntry extends StatefulWidget {
  final ActivitiesDependencies dependencies;
  final String id;
  const _SessionEntry(
      {super.key, required this.dependencies, required this.id});
  @override
  State<_SessionEntry> createState() => _SessionEntryState();
}

class _SessionEntryState extends State<_SessionEntry> {
  late final model = widget.dependencies.createViewModel(widget.id);
  @override
  Widget build(BuildContext context) => StudySessionView(viewModel: model);
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }
}

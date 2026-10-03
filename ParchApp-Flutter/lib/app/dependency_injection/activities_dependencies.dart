import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_routes.dart';
import '../../features/activities/presentation/view_models/activity_editor_view_model.dart';
import '../../features/activities/presentation/widgets/activity_form.dart';
import '../../features/activities/data/data_sources/firebase_activity_data_source.dart';
import '../../features/activities/data/repositories/firebase_study_sessions_repository.dart';
import '../../features/activities/domain/repositories/activity_catalog.dart';
import '../../features/activities/domain/use_cases/get_activities.dart';
import '../../features/activities/presentation/view_models/activity_list_view_model.dart';
import '../../features/home/presentation/views/home_view.dart';
import 'firebase_dependencies.dart';
import '../../features/activities/data/repositories/mock_study_sessions_repository.dart';
import '../../features/activities/domain/repositories/study_sessions_repository.dart';
import '../../features/activities/domain/use_cases/manage_study_session.dart';
import '../../features/activities/domain/use_cases/get_recommended_slots.dart';
import '../../features/activities/presentation/view_models/study_session_view_model.dart';
import '../../features/activities/presentation/views/study_session_view.dart';

class ActivitiesDependencies {
  final StudySessionsRepository repository;
  final bool isDemo;
  final ActivityCatalog? catalog;
  const ActivitiesDependencies(
      {required this.repository, this.isDemo = false, this.catalog});
  factory ActivitiesDependencies.mock() => ActivitiesDependencies(
      repository: MockStudySessionsRepository(), isDemo: true);
  factory ActivitiesDependencies.firebase(FirebaseDependencies firebase) {
    final repository = FirebaseStudySessionsRepository(
        FirebaseActivityDataSource(
            functions: firebase.functions,
            auth: firebase.auth,
            firestore: firebase.firestore));
    return ActivitiesDependencies(repository: repository, catalog: repository);
  }
  StudySessionViewModel createViewModel(String id) =>
      StudySessionViewModel(ManageStudySession(repository), id,
          recommendations: GetRecommendedSlots(repository),
          autoLoadRecommendations: isDemo,
          refreshAfterDecision: !isDemo);
  Widget homeRoute() => isDemo
      ? const HomeView(demoStudySessionId: 'linear-algebra')
      : catalog == null
          ? HomeView(
              activityState: ActivityListState(
                  loading: false, error: 'Activity discovery is unavailable.'))
          : _HomeEntry(catalog: catalog!);
  Widget route(String id) =>
      _SessionEntry(key: ValueKey(id), dependencies: this, id: id);
  Widget createRoute({String date = '', String time = ''}) =>
      _CreateActivityEntry(repository: repository, date: date, time: time);
}

class _CreateActivityEntry extends StatefulWidget {
  final StudySessionsRepository repository;
  final String date, time;
  const _CreateActivityEntry(
      {required this.repository, required this.date, required this.time});
  @override
  State<_CreateActivityEntry> createState() => _CreateActivityEntryState();
}

class _CreateActivityEntryState extends State<_CreateActivityEntry> {
  late final model = ActivityEditorViewModel(
      ManageStudySession(widget.repository),
      requestedDate: widget.date,
      requestedTime: widget.time);
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('ParchApp'),
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (model.value.saving) return;
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              })),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ActivityForm(
                      viewModel: model,
                      onSaved: (id) =>
                          context.go(AppRoutes.studySession(id)))))));
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }
}

class _HomeEntry extends StatefulWidget {
  final ActivityCatalog catalog;
  const _HomeEntry({required this.catalog});
  @override
  State<_HomeEntry> createState() => _HomeEntryState();
}

class _HomeEntryState extends State<_HomeEntry> {
  late final model = ActivityListViewModel(GetActivities(widget.catalog))
    ..load();
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<ActivityListState>(
          valueListenable: model,
          builder: (context, state, _) =>
              HomeView(activityState: state, onRefreshActivities: model.load));
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }
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
  Widget build(BuildContext context) =>
      StudySessionView(viewModel: model, isDemo: widget.dependencies.isDemo);
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }
}

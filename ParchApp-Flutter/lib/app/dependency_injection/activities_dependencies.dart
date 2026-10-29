import '../../shared/widgets/parch_visuals.dart';
import '../../features/activities/presentation/views/suggested_times_view.dart';
import 'dart:async';
import '../../features/profile/presentation/widgets/presence_settings_sheets.dart';
import '../../features/profile/presentation/widgets/profile_sheets.dart';
import '../../features/profile/domain/repositories/presence_repository.dart';
import '../../features/activities/domain/entities/planning_context.dart';
import '../../features/activities/presentation/views/activity_result_view.dart';
import '../../features/activities/presentation/views/activity_invitation_view.dart';
import '../../features/activities/presentation/view_models/activity_invitation_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_routes.dart';
import '../../features/activities/presentation/view_models/activity_editor_view_model.dart';
import '../../features/activities/presentation/widgets/activity_form.dart';
import '../../features/activities/data/data_sources/firebase_activity_data_source.dart';
import '../../features/activities/data/repositories/firebase_study_sessions_repository.dart';
import '../../features/activities/domain/repositories/activity_catalog.dart';
import '../../features/home/presentation/view_models/home_view_model.dart';
import '../../features/groups/domain/repositories/active_groups_repository.dart';
import '../../features/groups/data/repositories/firebase_active_groups_repository.dart';
import '../../features/groups/data/data_sources/firestore_groups_data_source.dart';
import '../../features/alerts/domain/repositories/alerts_repository.dart';
import '../../features/alerts/data/repositories/firebase_alerts_repository.dart';
import '../../features/activities/presentation/view_models/activity_list_view_model.dart';
import '../../features/home/presentation/views/home_view.dart';
import 'firebase_dependencies.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/data/repositories/firebase_profile_repository.dart';
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
  final ProfileRepository? profiles;
  final ActiveGroupsRepository? groups;
  final AlertsRepository? alerts;
  final String? Function()? currentUserId;
  final String Function()? currentName;
  const ActivitiesDependencies(
      {required this.repository,
      this.isDemo = false,
      this.catalog,
      this.profiles,
      this.groups,
      this.alerts,
      this.currentUserId,
      this.currentName});
  factory ActivitiesDependencies.mock() => ActivitiesDependencies(
      repository: MockStudySessionsRepository(), isDemo: true);
  factory ActivitiesDependencies.firebase(FirebaseDependencies firebase) {
    final repository = FirebaseStudySessionsRepository(
        FirebaseActivityDataSource(
            functions: firebase.functions,
            auth: firebase.auth,
            firestore: firebase.firestore,
            api: firebase.mobile,
            offline: () =>
                firebase.mobile.value.offline || firebase.mobile.value.forced));
    return ActivitiesDependencies(
        repository: repository,
        catalog: repository,
        profiles: FirebaseProfileRepository(firebase.mobile),
        groups: FirebaseActiveGroupsRepository(FirestoreGroupsDataSource(
            firebase.firestore, firebase.auth, api: firebase.mobile)),
        alerts: FirebaseAlertsRepository(firebase.mobile,
            currentUserId: () => firebase.auth.currentUser?.uid),
        currentUserId: () => firebase.auth.currentUser?.uid,
        currentName: () =>
            firebase.auth.currentUser?.displayName ??
            firebase.auth.currentUser?.email ??
            'there');
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
          : _HomeEntry(
              catalog: catalog!,
              profiles: profiles,
              groups: groups,
              alerts: alerts,
              currentUserId: currentUserId,
              currentName: currentName);
  Widget route(String id) =>
      _SessionEntry(key: ValueKey(id), dependencies: this, id: id);
  Widget resultRoute(String id, {bool acknowledged = false}) =>
      ActivityResultView(
          activityId: id, repository: repository, acknowledged: acknowledged);
  Widget suggestedTimesRoute(String id) =>
      SuggestedTimesView(key: ValueKey(id), viewModel: createViewModel(id));
  Widget scheduleHeader(String id) => ActivityResultView(
      activityId: id, repository: repository, scheduleCard: true);
  Widget invitationRoute(String id) => ActivityInvitationView(
      viewModel: ActivityInvitationViewModel(
          activityId: id, sessions: repository, alerts: alerts));
  Widget createRoute(
          {String date = '',
          String time = '',
          String? groupId,
          CreationComparison? comparison,
          PlanningContext? planning}) =>
      _CreateActivityEntry(
          repository: repository,
          date: date,
          time: time,
          planning: planning,
          comparison: comparison,
          groupId: groupId);
}

class _CreateActivityEntry extends StatefulWidget {
  final StudySessionsRepository repository;
  final String date, time;
  final String? groupId;
  final PlanningContext? planning;
  final CreationComparison? comparison;
  const _CreateActivityEntry(
      {required this.repository,
      required this.date,
      required this.time,
      this.planning,
      this.comparison,
      this.groupId});
  @override
  State<_CreateActivityEntry> createState() => _CreateActivityEntryState();
}

class _CreateActivityEntryState extends State<_CreateActivityEntry> {
  late final model = ActivityEditorViewModel(
      ManageStudySession(widget.repository),
      requestedDate: widget.date,
      requestedTime: widget.time,
      planning: widget.planning,
      comparison: widget.comparison,
      requestedGroupId: widget.groupId);
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const ParchBrand(),
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
                      onSaved: (id) => context.go(AppRoutes.activityResult(id),
                          extra: id))))));
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }
}

class _HomeEntry extends StatefulWidget {
  final ActivityCatalog catalog;
  final ProfileRepository? profiles;
  final ActiveGroupsRepository? groups;
  final AlertsRepository? alerts;
  final String? Function()? currentUserId;
  final String Function()? currentName;
  const _HomeEntry(
      {required this.catalog,
      this.profiles,
      this.groups,
      this.alerts,
      this.currentUserId,
      this.currentName});
  @override
  State<_HomeEntry> createState() => _HomeEntryState();
}

class _HomeEntryState extends State<_HomeEntry> with WidgetsBindingObserver {
  Timer? _expiryTimer;
  late final model = HomeViewModel(
      catalog: widget.catalog,
      groups: widget.groups,
      alerts: widget.alerts,
      profiles: widget.profiles,
      currentUserId: widget.currentUserId)
    ..load();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) model.load();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<HomeState>(
      valueListenable: model,
      builder: (context, state, _) => HomeView(
          activityState: state.activities,
          groupsState: state.groups,
          alertsState: state.alerts,
          profile: state.profile.user,
          profileLoading: state.profile.isLoading,
          profileError: state.profile.error,
          onRefreshActivities: model.load,
          onManageStatus: state.profile.user == null
              ? null
              : () async {
                  final repository = widget.profiles;
                  if (repository is! PresenceRepository) return;
                  await showProfileSheet<bool>(context,
                      child: PresenceSheet(
                          user: state.profile.user!,
                          onSave: (status, expires, visibility) async {
                            await (repository as PresenceRepository)
                                .updatePresence(status, expires, visibility,
                                    ownerId: state.profile.user!.id);
                            await model.load();
                            return true;
                          }));
                },
          userName: widget.currentName?.call() ?? 'there'));
  @override
  void dispose() {
    _expiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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

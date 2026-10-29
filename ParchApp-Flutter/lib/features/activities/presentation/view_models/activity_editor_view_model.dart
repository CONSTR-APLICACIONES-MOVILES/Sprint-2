import 'dart:math';
import '../../domain/entities/planning_context.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/activity_draft.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/use_cases/manage_study_session.dart';

class ActivityEditorState {
  final bool loading, saving;
  final List<ActivityGroup> groups;
  final String? error;
  const ActivityEditorState(
      {this.loading = false,
      this.saving = false,
      this.groups = const [],
      this.error});
}

class ActivityEditorViewModel extends ValueNotifier<ActivityEditorState> {
  final ManageStudySession _sessions;
  final StudySession? session;
  final String requestedDate, requestedTime;
  final String? requestedGroupId;
  bool _disposed = false;
  String? _savedId;
  String publicationKey = List.generate(24,
          (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
  ActivityDraft? _attempt;
  ActivityDraft? recoveredDraft;
  bool publicationUncertain = false;
  final PlanningContext? planning;
  final CreationComparison? comparison;

  bool review(ActivityDraft draft) {
    try {
      draft.validated();
      if (session == null &&
          !publicationUncertain &&
          !value.groups.any((g) => g.id == draft.groupId)) {
        throw const SessionFailure(
            'Selected group is unavailable. Refresh your groups before reviewing.');
      }
      return true;
    } on SessionFailure catch (error) {
      _emit(ActivityEditorState(groups: value.groups, error: error.message));
      return false;
    }
  }

  ActivityEditorViewModel(this._sessions,
      {this.session,
      this.requestedDate = '',
      this.requestedTime = '',
      this.planning,
      this.comparison,
      this.requestedGroupId})
      : super(const ActivityEditorState());

  void _emit(ActivityEditorState state) {
    if (!_disposed) value = state;
  }

  Future<void> load() async {
    if (_disposed || value.loading || value.saving || session != null) return;
    _emit(const ActivityEditorState(loading: true));
    try {
      recoveredDraft ??= await _sessions.pendingPublication();
      if (recoveredDraft != null) {
        publicationKey = recoveredDraft!.requestId!;
        _attempt = recoveredDraft;
        publicationUncertain = true;
      }
      _emit(ActivityEditorState(groups: await _sessions.listGroups()));
    } catch (error) {
      _emit(ActivityEditorState(
          error: error is SessionFailure
              ? error.message
              : 'Unable to load your groups. Try again.'));
    }
  }

  Future<String?> save(ActivityDraft draft) async {
    if (_disposed || value.loading || value.saving) return null;
    if (_savedId != null) return _savedId;
    final groups = value.groups;
    _emit(ActivityEditorState(saving: true, groups: groups));
    try {
      if (session == null) {
        if (!publicationUncertain &&
            !groups.any((group) => group.id == draft.groupId)) {
          throw const SessionFailure('Choose one of your groups.');
        }
        final reviewed = publicationUncertain ? _attempt! : draft.validated();
        _attempt = reviewed;
        final input = ActivityDraft(
            groupId: reviewed.groupId,
            title: reviewed.title,
            description: reviewed.description,
            category: reviewed.category,
            location: reviewed.location,
            status: reviewed.status,
            date: reviewed.date,
            time: reviewed.time,
            startsAt: reviewed.startsAt,
            endsAt: reviewed.endsAt,
            planning: reviewed.planning,
            comparison: reviewed.comparison,
            measurementVersion: reviewed.measurementVersion,
            requestId: publicationKey);
        _savedId = await _sessions.createActivity(input);
        publicationUncertain = false;
      } else {
        _savedId = (await _sessions.updateDetails(session!.id, draft,
                expectedVersion: session!.version))
            .id;
      }
      _emit(ActivityEditorState(groups: groups));
      return _savedId;
    } catch (error) {
      publicationUncertain = session == null &&
          _attempt != null &&
          (error is! SessionFailure ||
              [
                'unavailable',
                'deadline-exceeded',
                'network-request-failed',
                'internal',
                'unknown',
                'cancelled'
              ].contains(error.code));
      if (!publicationUncertain) recoveredDraft = null;
      _emit(ActivityEditorState(
          groups: groups,
          error: error is SessionFailure
              ? error.message
              : 'Unable to save the activity. Please try again.'));
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

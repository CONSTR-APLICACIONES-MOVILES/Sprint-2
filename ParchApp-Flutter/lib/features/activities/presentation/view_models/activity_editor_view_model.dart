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
  bool _disposed = false;
  String? _savedId;
  ActivityEditorViewModel(this._sessions,
      {this.session, this.requestedDate = '', this.requestedTime = ''})
      : super(const ActivityEditorState());

  void _emit(ActivityEditorState state) {
    if (!_disposed) value = state;
  }

  Future<void> load() async {
    if (_disposed || value.loading || value.saving || session != null) return;
    _emit(const ActivityEditorState(loading: true));
    try {
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
        if (!groups.any((group) => group.id == draft.groupId)) {
          throw const SessionFailure('Choose one of your groups.');
        }
        _savedId = await _sessions.createActivity(draft);
      } else {
        _savedId = (await _sessions.updateDetails(session!.id, draft)).id;
      }
      _emit(ActivityEditorState(groups: groups));
      return _savedId;
    } catch (error) {
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

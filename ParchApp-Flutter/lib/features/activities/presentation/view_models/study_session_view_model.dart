import 'package:flutter/foundation.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/use_cases/manage_study_session.dart';

enum SessionLoadStatus { loading, ready, notFound, error }

class StudySessionState {
  final SessionLoadStatus status;
  final StudySession? session;
  final bool saving;
  final String? error;
  const StudySessionState(
      {this.status = SessionLoadStatus.loading,
      this.session,
      this.saving = false,
      this.error});
}

class StudySessionViewModel extends ValueNotifier<StudySessionState> {
  final ManageStudySession _sessions;
  final String sessionId;
  bool _disposed = false;
  bool _loading = false;
  StudySessionViewModel(this._sessions, this.sessionId)
      : super(const StudySessionState());

  void _emit(StudySessionState state) {
    if (!_disposed) value = state;
  }

  Future<void> load() async {
    if (_disposed || _loading || value.saving) return;
    _loading = true;
    _emit(const StudySessionState());
    try {
      final session = await _sessions.load(sessionId);
      _emit(StudySessionState(
          session: session,
          status: session == null
              ? SessionLoadStatus.notFound
              : SessionLoadStatus.ready));
    } catch (_) {
      _emit(const StudySessionState(
          status: SessionLoadStatus.error,
          error: 'Unable to load this session. Please try again.'));
    } finally {
      _loading = false;
    }
  }

  Future<bool> _save(Future<StudySession> Function() command) async {
    if (_disposed || _loading || value.saving || value.session == null) {
      return false;
    }
    final previous = value.session!;
    _emit(StudySessionState(
        status: SessionLoadStatus.ready, session: previous, saving: true));
    try {
      final session = await command();
      if (_disposed) return false;
      _emit(
          StudySessionState(status: SessionLoadStatus.ready, session: session));
      return true;
    } catch (error) {
      _emit(StudySessionState(
          status: SessionLoadStatus.ready,
          session: previous,
          error: error is SessionFailure
              ? error.message
              : 'Unable to save changes. Please try again.'));
      return false;
    }
  }

  Future<bool> toggleTopic(String id) =>
      _save(() => _sessions.toggleTopic(sessionId, id));
  Future<bool> cancel() => _save(() => _sessions.cancel(sessionId));
  Future<bool> update(
          {required String title,
          required String room,
          required DateTime startsAt,
          required DateTime endsAt}) =>
      _save(() => _sessions.update(sessionId,
          title: title, room: room, startsAt: startsAt, endsAt: endsAt));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import '../../../alerts/domain/entities/app_alert.dart';
import '../../../alerts/domain/repositories/alerts_repository.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/repositories/study_sessions_repository.dart';

class ActivityInvitationState {
  final StudySession? session;
  final AppAlert? invitation;
  final bool loading, saving;
  final String? error, acknowledgement;
  const ActivityInvitationState(
      {this.session,
      this.invitation,
      this.loading = false,
      this.saving = false,
      this.error,
      this.acknowledgement});
}

class ActivityInvitationViewModel
    extends ValueNotifier<ActivityInvitationState> {
  final String activityId;
  final StudySessionsRepository sessions;
  final AlertsRepository? alerts;
  bool _disposed = false;
  ActivityInvitationViewModel(
      {required this.activityId, required this.sessions, this.alerts})
      : super(const ActivityInvitationState());
  void _emit(ActivityInvitationState state) {
    if (!_disposed) value = state;
  }

  Future<void> load() async {
    if (_disposed || value.loading || value.saving) return;
    _emit(ActivityInvitationState(
        loading: true, session: value.session, invitation: value.invitation));
    try {
      final session = await sessions.getById(activityId);
      if (session == null) {
        throw const SessionFailure('This activity is no longer available.');
      }
      final inbox = await alerts?.getAlerts() ?? <AppAlert>[];
      _emit(ActivityInvitationState(
          session: session,
          invitation: inbox.where((a) => a.id == activityId).firstOrNull));
    } catch (_) {
      _emit(ActivityInvitationState(
          session: value.session,
          invitation: value.invitation,
          error: 'Unable to load this invitation. Retry when connected.'));
    }
  }

  Future<void> respond(AlertResponse response) async {
    if (_disposed ||
        value.loading ||
        value.saving ||
        value.session?.cancelled != false ||
        value.invitation == null ||
        value.invitation!.response != null ||
        alerts == null) {
      return;
    }
    final session = value.session;
    _emit(ActivityInvitationState(
        session: session, invitation: value.invitation, saving: true));
    try {
      final items = await alerts!.respond(activityId, response);
      if (_disposed) return;
      final invitation = items.where((a) => a.id == activityId).firstOrNull;
      _emit(ActivityInvitationState(
          session: session,
          invitation: invitation,
          acknowledgement: invitation?.pendingSync == true
              ? 'Saved on this device · Pending sync'
              : 'Response saved by the server'));
      if (invitation?.pendingSync != true) {
        try {
          final updated = await sessions.getById(activityId);
          _emit(ActivityInvitationState(
              session: updated ?? session,
              invitation: invitation,
              acknowledgement: 'Response saved by the server'));
        } catch (_) {
          _emit(ActivityInvitationState(
              session: session,
              invitation: invitation,
              acknowledgement: 'Response saved by the server',
              error:
                  'Attendance could not be refreshed. Retry loading; your response is saved.'));
        }
      }
    } catch (_) {
      _emit(ActivityInvitationState(
          session: session,
          invitation: value.invitation,
          error:
              'Unable to save this response. Reload to check for a conflict, or retry.'));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

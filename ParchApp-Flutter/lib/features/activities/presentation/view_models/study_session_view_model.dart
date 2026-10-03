import 'package:flutter/foundation.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/use_cases/manage_study_session.dart';
import '../../domain/entities/slot_recommendation.dart';
import '../../domain/use_cases/get_recommended_slots.dart';
import 'activity_editor_view_model.dart';

enum SessionLoadStatus { loading, ready, notFound, error }

enum RecommendationsStatus { idle, loading, ready, empty, error }

class StudySessionState {
  final SessionLoadStatus status;
  final StudySession? session;
  final bool saving;
  final String? error;
  final RecommendationsStatus recommendationsStatus;
  final SlotRecommendations? recommendations;
  final String? recommendationsError;
  final String? analyticsError;
  final bool selectionSaved;
  final String? refreshError;
  final bool refreshing;
  const StudySessionState(
      {this.status = SessionLoadStatus.loading,
      this.session,
      this.saving = false,
      this.error,
      this.recommendationsStatus = RecommendationsStatus.empty,
      this.recommendations,
      this.recommendationsError,
      this.analyticsError,
      this.selectionSaved = false,
      this.refreshError,
      this.refreshing = false});

  StudySessionState copyWith(
          {StudySession? session,
          bool? saving,
          String? error,
          RecommendationsStatus? recommendationsStatus,
          SlotRecommendations? recommendations,
          String? recommendationsError,
          String? analyticsError,
          bool clearAnalyticsError = false,
          String? refreshError,
          bool clearRefreshError = false,
          bool? refreshing,
          bool? selectionSaved}) =>
      StudySessionState(
          status: status,
          session: session ?? this.session,
          saving: saving ?? this.saving,
          error: error,
          refreshError:
              clearRefreshError ? null : refreshError ?? this.refreshError,
          refreshing: refreshing ?? this.refreshing,
          recommendationsStatus:
              recommendationsStatus ?? this.recommendationsStatus,
          recommendations: recommendations ?? this.recommendations,
          recommendationsError:
              recommendationsError ?? this.recommendationsError,
          analyticsError: clearAnalyticsError
              ? null
              : analyticsError ?? this.analyticsError,
          selectionSaved: selectionSaved ?? this.selectionSaved);
}

class StudySessionViewModel extends ValueNotifier<StudySessionState> {
  final ManageStudySession _sessions;
  final String sessionId;
  final GetRecommendedSlots? _recommendations;
  final bool autoLoadRecommendations;
  final bool refreshAfterDecision;
  int? _durationMinutes;
  bool _loadingRecommendations = false;
  int _contextRevision = 0;
  final Set<String> _shown = {};
  final Set<String> _showing = {};
  final Set<String> _decided = {};
  final Map<String, RecommendationEvent> _pendingImpressions = {};
  String? _lastDecisionSlotId;
  bool _disposed = false;
  bool _loading = false;
  StudySessionViewModel(this._sessions, this.sessionId,
      {GetRecommendedSlots? recommendations,
      this.autoLoadRecommendations = true,
      this.refreshAfterDecision = false})
      : _recommendations = recommendations,
        super(const StudySessionState());

  void _emit(StudySessionState state) {
    if (!_disposed) value = state;
  }

  ActivityEditorViewModel createDetailsEditor() =>
      ActivityEditorViewModel(_sessions, session: value.session);

  Future<void> load() async {
    if (_disposed ||
        _loading ||
        _loadingRecommendations ||
        value.saving ||
        value.refreshing) {
      return;
    }
    _loading = true;
    _emit(const StudySessionState());
    try {
      final session = await _sessions.load(sessionId);
      _emit(StudySessionState(
          session: session,
          recommendationsStatus: RecommendationsStatus.idle,
          status: session == null
              ? SessionLoadStatus.notFound
              : SessionLoadStatus.ready));
      _loading = false;
      if (!_disposed && session != null && autoLoadRecommendations) {
        await loadRecommendations();
      }
    } catch (error) {
      _emit(StudySessionState(
          status: SessionLoadStatus.error,
          error: error is SessionFailure
              ? error.message
              : 'Unable to load this session. Please try again.'));
    } finally {
      _loading = false;
    }
  }

  Future<void> loadRecommendations({int? durationMinutes}) async {
    if (_disposed ||
        _loadingRecommendations ||
        value.saving ||
        value.refreshing ||
        value.session == null ||
        !value.session!.canOrganize ||
        _recommendations == null) {
      return;
    }
    _loadingRecommendations = true;
    _durationMinutes =
        durationMinutes ?? _durationMinutes ?? value.session?.durationMinutes;
    final revision = _contextRevision;
    var refresh = false;
    _emit(value.copyWith(recommendationsStatus: RecommendationsStatus.loading));
    try {
      final result =
          await _recommendations(sessionId, durationMinutes: _durationMinutes);
      if (_disposed) return;
      refresh = revision != _contextRevision;
      if (!refresh) {
        _emit(value.copyWith(
            recommendations: result,
            selectionSaved: _decided.contains(result.id),
            recommendationsStatus: result.slots.isEmpty
                ? RecommendationsStatus.empty
                : RecommendationsStatus.ready));
      }
    } catch (error) {
      _emit(value.copyWith(
          recommendationsStatus: RecommendationsStatus.error,
          recommendationsError: error is SessionFailure
              ? error.message
              : 'Unable to load recommended times. Please try again.'));
    } finally {
      _loadingRecommendations = false;
    }
    if (refresh && !_disposed) await loadRecommendations();
  }

  void changeRecommendationDuration() {
    if (_disposed ||
        value.saving ||
        value.refreshing ||
        _loadingRecommendations) {
      return;
    }
    _emit(value.copyWith(recommendationsStatus: RecommendationsStatus.idle));
  }

  String _impressionKey(String batchId, String slotId) =>
      Uri(queryParameters: {'batch': batchId, 'slot': slotId}).query;

  Future<void> recommendationShown(String batchId, String slotId) async {
    final batch = value.recommendations;
    final key = _impressionKey(batchId, slotId);
    if (_disposed ||
        _recommendations == null ||
        batch == null ||
        batch.id != batchId ||
        value.session?.canOrganize != true ||
        value.session!.cancelled ||
        _shown.contains(key) ||
        _showing.contains(key)) {
      return;
    }
    try {
      _pendingImpressions.putIfAbsent(
          key, () => _recommendations.shownEvent(batch, slotId));
    } on SessionFailure {
      return;
    }
    await _sendImpression(key, _pendingImpressions[key]!);
  }

  Future<void> _sendImpression(String key, RecommendationEvent event) async {
    if (_disposed || !_showing.add(key)) return;
    try {
      await _recommendations!.recordShown(event);
      _shown.add(key);
      _pendingImpressions.remove(key);
      if (!_disposed) {
        _emit(value.copyWith(
            error: value.error,
            clearAnalyticsError: _pendingImpressions.isEmpty,
            recommendationsError: value.recommendationsError));
      }
    } catch (_) {
      if (!_disposed) {
        _emit(value.copyWith(
            error: value.error,
            recommendationsError: value.recommendationsError,
            analyticsError: 'Recommendation feedback could not be recorded.'));
      }
    } finally {
      _showing.remove(key);
    }
  }

  Future<void> retryAnalytics() async {
    for (final pending in _pendingImpressions.entries.toList()) {
      await _sendImpression(pending.key, pending.value);
    }
  }

  Future<bool> _save(Future<StudySession> Function() command) async {
    if (_disposed ||
        _loading ||
        value.saving ||
        value.refreshing ||
        value.session == null) {
      return false;
    }
    final previous = value.session!;
    _emit(value.copyWith(saving: true));
    try {
      final session = await command();
      if (_disposed) return false;
      if (session.room != previous.room ||
          session.startsAt != previous.startsAt ||
          session.endsAt != previous.endsAt) {
        _contextRevision++;
      }
      _emit(value.copyWith(session: session, saving: false));
      return true;
    } catch (error) {
      _emit(value.copyWith(
          saving: false,
          session: previous,
          recommendationsStatus:
              error is SessionFailure && error.code == 'failed-precondition'
                  ? RecommendationsStatus.error
                  : value.recommendationsStatus,
          recommendationsError:
              error is SessionFailure && error.code == 'failed-precondition'
                  ? error.message
                  : null,
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
      required DateTime endsAt,
      String? sourceSlotId}) async {
    final batch = value.recommendations;
    final session = value.session;
    // Attribute edits from the existing session editor only when the organizer
    // has actually seen the recommendation and is changing the scheduled time.
    if (sourceSlotId == null &&
        batch != null &&
        batch.slots.isNotEmpty &&
        session != null &&
        value.recommendationsStatus == RecommendationsStatus.ready &&
        (startsAt != session.startsAt || endsAt != session.endsAt)) {
      final candidate =
          batch.slots.any((slot) => slot.id == _lastDecisionSlotId)
              ? _lastDecisionSlotId!
              : batch.slots.first.id;
      final key = _impressionKey(batch.id, candidate);
      if (_shown.contains(key) || _pendingImpressions.containsKey(key)) {
        sourceSlotId = candidate;
      }
    }
    if (sourceSlotId != null &&
        (batch == null ||
            value.recommendationsStatus != RecommendationsStatus.ready)) {
      return false;
    }
    final success = await _save(() => _sessions.update(sessionId,
        title: title,
        room: room,
        startsAt: startsAt,
        endsAt: endsAt,
        recommendations: sourceSlotId == null ? null : batch,
        sourceSlotId: sourceSlotId));
    if (success && sourceSlotId != null) {
      _decided.add(batch!.id);
      _lastDecisionSlotId = sourceSlotId;
      if (refreshAfterDecision) {
        // The Firebase repository cannot commit a decision without acknowledging
        // its displayed candidates. Clear any earlier failed impression retries.
        for (final slot in batch.slots) {
          final key = _impressionKey(batch.id, slot.id);
          if (_pendingImpressions.remove(key) != null) _shown.add(key);
        }
      }
      _emit(value.copyWith(
          selectionSaved: true,
          clearAnalyticsError: _pendingImpressions.isEmpty));
      if (refreshAfterDecision) await refreshDetails();
    } else if (success &&
        session != null &&
        (session.room != room ||
            session.startsAt != startsAt ||
            session.endsAt != endsAt)) {
      await loadRecommendations();
    }
    return success;
  }

  Future<void> refreshDetails({String savedMessage = 'Time saved.'}) async {
    if (_disposed || value.refreshing || value.saving) return;
    _emit(value.copyWith(refreshing: true, clearRefreshError: true));
    try {
      final session = await _sessions.load(sessionId);
      if (session == null) {
        throw const SessionFailure('Activity no longer available.');
      }
      _emit(value.copyWith(
          session: session, refreshing: false, clearRefreshError: true));
    } catch (_) {
      _emit(value.copyWith(
          refreshing: false,
          refreshError:
              '$savedMessage Activity details could not be refreshed.'));
    }
  }

  Future<bool> acceptSlot(String slotId) async {
    final session = value.session;
    final batch = value.recommendations;
    if (session == null ||
        batch == null ||
        value.selectionSaved ||
        value.recommendationsStatus != RecommendationsStatus.ready) {
      return false;
    }
    final slot = batch.slots.where((slot) => slot.id == slotId).firstOrNull;
    if (slot == null) return false;
    return update(
        title: session.title,
        room: session.room,
        startsAt: slot.startsAt,
        endsAt: slot.endsAt,
        sourceSlotId: slot.id);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

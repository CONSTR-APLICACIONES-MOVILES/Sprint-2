import '../entities/study_session.dart';
import '../entities/slot_recommendation.dart';
import '../entities/activity_draft.dart';

abstract interface class StudySessionsRepository {
  Future<List<ActivityGroup>> listGroups();
  Future<String> createActivity(ActivityDraft draft);
  Future<StudySession?> getById(String id);

  /// Save supported activity metadata when no recommendation event is supplied.
  /// Otherwise persist the decision and session together.
  /// Never report a failed save solely because telemetry delivery failed after
  /// the session was committed. Backend authorization is still required.
  Future<StudySession> save(StudySession session,
      {RecommendationEvent? recommendationEvent});
  Future<SlotRecommendations> getRecommendedSlots(String activityId,
      {int? durationMinutes});
  Future<void> recordRecommendationShown(RecommendationEvent event);
}

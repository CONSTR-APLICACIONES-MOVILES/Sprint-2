import '../entities/slot_recommendation.dart';
import '../repositories/study_sessions_repository.dart';

class GetRecommendedSlots {
  final StudySessionsRepository _repository;
  final DateTime Function() _now;
  GetRecommendedSlots(this._repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  Future<SlotRecommendations> call(String activityId,
      {int? durationMinutes}) async {
    final result = await _repository.getRecommendedSlots(activityId,
        durationMinutes: durationMinutes);
    result.validateFor(activityId, _now());
    return result;
  }

  RecommendationEvent shownEvent(
      SlotRecommendations recommendations, String slotId) {
    recommendations.validateFor(recommendations.activityId, _now());
    final slot = recommendations.getSlot(slotId);
    return RecommendationEvent(
      type: RecommendationEventType.shown,
      activityId: recommendations.activityId,
      recommendationId: recommendations.id,
      slotId: slot.id,
      occurredAt: _now().toUtc(),
      suggestedStart: slot.startsAt.toUtc(),
      suggestedEnd: slot.endsAt.toUtc(),
    );
  }

  Future<void> recordShown(RecommendationEvent event) =>
      _repository.recordRecommendationShown(event);
}

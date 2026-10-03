import 'study_session.dart';

/// Server-ranked suggestions. Flutter preserves the supplied order and reasons.
class RecommendedSlot {
  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final int availableParticipants;
  final int totalParticipants;
  final List<String> reasons;

  RecommendedSlot({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.availableParticipants,
    required this.totalParticipants,
    required List<String> reasons,
  }) : reasons = List.unmodifiable(reasons) {
    if (id.isEmpty ||
        !endsAt.isAfter(startsAt) ||
        availableParticipants < 0 ||
        totalParticipants < 1 ||
        availableParticipants > totalParticipants ||
        reasons.isEmpty ||
        reasons.any((reason) => reason.trim().isEmpty)) {
      throw const SessionFailure('Invalid slot recommendation.');
    }
  }
}

class SlotRecommendations {
  final String id;
  final String activityId;
  final DateTime? expiresAt;
  final String? date;
  final String? timeZone;
  final List<RecommendedSlot> slots;

  SlotRecommendations(
      {required this.id,
      required this.activityId,
      this.expiresAt,
      this.date,
      this.timeZone,
      required List<RecommendedSlot> slots})
      : slots = List.unmodifiable(slots) {
    if (id.isEmpty ||
        activityId.isEmpty ||
        slots.map((slot) => slot.id).toSet().length != slots.length) {
      throw const SessionFailure('Invalid slot recommendations.');
    }
  }

  RecommendedSlot getSlot(String slotId) => slots.firstWhere(
        (slot) => slot.id == slotId,
        orElse: () => throw const SessionFailure('Recommendation not found.'),
      );

  void validateFor(String sessionId, DateTime now) {
    if (activityId != sessionId ||
        (expiresAt != null && !expiresAt!.isAfter(now))) {
      throw const SessionFailure(
          'Recommendations have expired. Refresh to try again.');
    }
  }
}

enum RecommendationEventType {
  shown('recommendation_shown'),
  accepted('recommendation_accepted'),
  modified('recommendation_modified');

  final String eventName;
  const RecommendationEventType(this.eventName);
}

/// Domain analytics data, not a proposed HTTP payload.
/// The transport must attach authenticated organizer identity and deduplicate
/// [deduplicationKey]. A decision must be committed with the session change.
class RecommendationEvent {
  final RecommendationEventType type;
  final String activityId;
  final String recommendationId;
  final String slotId;
  final DateTime occurredAt;
  final DateTime suggestedStart;
  final DateTime suggestedEnd;
  final DateTime? selectedStart;
  final DateTime? selectedEnd;

  const RecommendationEvent(
      {required this.type,
      required this.activityId,
      required this.recommendationId,
      required this.slotId,
      required this.occurredAt,
      required this.suggestedStart,
      required this.suggestedEnd,
      this.selectedStart,
      this.selectedEnd});

  String get deduplicationKey => Uri(queryParameters: {
        'activity': activityId,
        'recommendation': recommendationId,
        'slot': slotId,
        'type': type.eventName,
        if (selectedStart != null)
          'start': selectedStart!.toUtc().toIso8601String(),
        if (selectedEnd != null) 'end': selectedEnd!.toUtc().toIso8601String(),
      }).query;
}

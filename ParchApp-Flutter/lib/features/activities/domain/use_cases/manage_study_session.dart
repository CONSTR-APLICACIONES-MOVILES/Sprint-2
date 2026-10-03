import '../entities/study_session.dart';
import '../entities/slot_recommendation.dart';
import '../entities/activity_draft.dart';
import '../repositories/study_sessions_repository.dart';

class ManageStudySession {
  final StudySessionsRepository _repository;
  final DateTime Function() _now;
  ManageStudySession(this._repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  Future<StudySession?> load(String id) => _repository.getById(id);

  Future<List<ActivityGroup>> listGroups() => _repository.listGroups();

  Future<String> createActivity(ActivityDraft draft) =>
      _repository.createActivity(draft.validated());

  Future<StudySession> updateDetails(String id, ActivityDraft draft) async {
    final data = draft.validated();
    final session = await _editable(id);
    if (data.groupId != session.groupId) {
      throw const SessionFailure('The activity group cannot be changed.');
    }
    if (!session.supportsActivityEditing) {
      throw const SessionFailure('Activity details editing is unavailable.');
    }
    if (session.startsAt != null &&
        (data.date != session.legacyDate || data.time != session.legacyTime)) {
      throw const SessionFailure(
          'Change the scheduled time using recommendations.');
    }
    return _repository.save(session.copyWith(
        title: data.title,
        description: data.description,
        location: data.location,
        category: data.category,
        status: data.status,
        legacyDate: data.date,
        legacyTime: data.time));
  }

  Future<StudySession> _editable(String id) async {
    final session = await load(id);
    if (session == null) throw const SessionFailure('Session not found.');
    if (!session.canOrganize) {
      throw const SessionFailure('Only the organizer can change this session.');
    }
    if (session.cancelled) {
      throw const SessionFailure('This session has been cancelled.');
    }
    return session;
  }

  Future<StudySession> update(String id,
      {required String title,
      required String room,
      required DateTime startsAt,
      required DateTime endsAt,
      SlotRecommendations? recommendations,
      String? sourceSlotId}) async {
    if (title.trim().isEmpty ||
        (recommendations == null && room.trim().isEmpty)) {
      throw const SessionFailure('Enter a session title and room.');
    }
    if (!endsAt.isAfter(startsAt)) {
      throw const SessionFailure('End time must be after start time.');
    }
    final session = await _editable(id);
    if (!session.supportsDetailsEditing &&
        (recommendations == null ||
            title != session.title ||
            room != session.room)) {
      throw const SessionFailure(
          'Only recommended time changes are supported.');
    }
    RecommendationEvent? event;
    if (recommendations != null && sourceSlotId != null) {
      recommendations.validateFor(id, _now());
      final slot = recommendations.getSlot(sourceSlotId);
      final unchanged = startsAt.isAtSameMomentAs(slot.startsAt) &&
          endsAt.isAtSameMomentAs(slot.endsAt);
      event = RecommendationEvent(
        type: unchanged
            ? RecommendationEventType.accepted
            : RecommendationEventType.modified,
        activityId: id,
        recommendationId: recommendations.id,
        slotId: slot.id,
        occurredAt: _now().toUtc(),
        suggestedStart: slot.startsAt.toUtc(),
        suggestedEnd: slot.endsAt.toUtc(),
        selectedStart: startsAt.toUtc(),
        selectedEnd: endsAt.toUtc(),
      );
    } else if (recommendations != null || sourceSlotId != null) {
      throw const SessionFailure('Select a recommendation before saving.');
    }
    return _repository.save(
        session.copyWith(
            title: title.trim(),
            room: room.trim(),
            startsAt: startsAt,
            endsAt: endsAt),
        recommendationEvent: event);
  }

  Future<StudySession> toggleTopic(String id, String topicId) async {
    final session = await _editable(id);
    if (!session.supportsDetailsEditing) {
      throw const SessionFailure('Topic editing is not supported.');
    }
    if (!session.topics.any((topic) => topic.id == topicId)) {
      throw const SessionFailure('Topic not found.');
    }
    return _repository.save(session.copyWith(topics: [
      for (final topic in session.topics)
        topic.id == topicId ? topic.toggle() : topic,
    ]));
  }

  Future<StudySession> cancel(String id) async {
    final session = await _editable(id);
    if (!session.supportsDetailsEditing) {
      throw const SessionFailure('Cancellation is not supported.');
    }
    return _repository.save(session.copyWith(cancelled: true));
  }
}

import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/activity_summary.dart';
import '../../domain/entities/activity_draft.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/slot_recommendation.dart';
import '../../domain/repositories/study_sessions_repository.dart';
import '../../domain/repositories/activity_catalog.dart';
import '../data_sources/activity_data_source.dart';
import '../models/activity_model.dart';

class FirebaseStudySessionsRepository
    implements StudySessionsRepository, ActivityCatalog {
  final ActivityDataSource _source;
  final Map<String, Future<void>> _presentations = {};
  final Map<String, RecommendationEvent> _displayed = {};
  FirebaseStudySessionsRepository(this._source);

  @override
  Future<List<ActivityGroup>> listGroups() => _request(() async => [
        for (final group in await _source.listGroups())
          ActivityGroup(
              group['id'] as String, group['name'] as String? ?? 'Group'),
      ]);

  @override
  Future<String> createActivity(ActivityDraft draft) => _request(() {
        final data = draft.validated();
        return _source.createActivity({
          'groupId': data.groupId,
          'title': data.title,
          'description': data.description,
          'category': data.category,
          'location': data.location,
          'status': data.status,
          'date': data.date,
          'time': data.time
        });
      });

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw SessionFailure(
          switch (error.code) {
            'unauthenticated' || 'user-token-expired' => 'Sign in to continue.',
            'permission-denied' =>
              'You do not have permission to manage this activity.',
            'not-found' => 'This activity or recommendation no longer exists.',
            'failed-precondition' =>
              'This slot is no longer available. Search for new recommendations.',
            'invalid-argument' =>
              'Choose a valid time today in Bogotá (15–720 minutes).',
            _ => 'Unable to reach the activity service. Please try again.',
          },
          code: error.code);
    }
  }

  @override
  Future<StudySession?> getById(String id) async {
    try {
      return await _request(() async =>
          ActivityModel(await _source.call('getActivity', {'activityId': id}))
              .toEntity(_source.currentUserId));
    } on SessionFailure catch (error) {
      if (error.code == 'not-found') return null;
      rethrow;
    }
  }

  @override
  Future<List<ActivitySummary>> listActivities() =>
      _request(() async => List.unmodifiable(
          (await _source.listActivities()).map((model) => model.toSummary())));

  @override
  Future<SlotRecommendations> getRecommendedSlots(String activityId,
          {int? durationMinutes}) =>
      _request(() async => RecommendationsModel(
                  await _source.call('getActivityRecommendations', {
            'activityId': activityId,
            if (durationMinutes != null) 'durationMinutes': durationMinutes,
          }))
              .toEntity());

  @override
  Future<void> recordRecommendationShown(RecommendationEvent event) async {
    final key =
        '${_source.currentUserId}/${event.activityId}/${event.recommendationId}/${event.slotId}';
    _displayed[key] = event;
    final pending = _presentations.putIfAbsent(
        key,
        () => _request(() async {
              final response =
                  await _source.call('presentActivityRecommendations', {
                'activityId': event.activityId,
                'recommendationIds': [event.slotId],
              });
              if (response['presented'] != 1) {
                throw const SessionFailure(
                    'Recommendation presentation was not acknowledged. Retry before choosing a time.');
              }
            }));
    try {
      await pending;
    } catch (_) {
      if (identical(_presentations[key], pending)) _presentations.remove(key);
      rethrow;
    }
  }

  @override
  Future<StudySession> save(StudySession session,
      {RecommendationEvent? recommendationEvent}) async {
    final event = recommendationEvent;
    if (event == null) {
      if (!session.canOrganize || !session.supportsActivityEditing) {
        throw const SessionFailure(
            'Only the organizer can edit this activity.');
      }
      final current = await getById(session.id);
      if (current == null) throw const SessionFailure('Activity not found.');
      if (session.startsAt != current.startsAt ||
          session.endsAt != current.endsAt ||
          session.room != current.room ||
          session.cancelled != current.cancelled ||
          session.topics.isNotEmpty ||
          session.resources.isNotEmpty ||
          session.reminder != current.reminder) {
        throw const SessionFailure(
            'Use recommendations to change the time. Room, topic and cancellation changes are unavailable.');
      }
      ActivityDraft(
              groupId: current.groupId,
              title: session.title,
              description: session.description,
              category: session.category,
              status: session.status,
              location: session.location)
          .validated();
      // Only contract-supported metadata is writable here. Never include
      // ownership, membership, canonical times or recommendation analytics.
      await _request(() => _source.updateActivity(session.id, {
            'title': session.title,
            'description': session.description,
            'category': session.category,
            'location': session.location,
            'status': session.status,
            if (session.startsAt == null) ...{
              'date': session.legacyDate,
              'time': session.legacyTime,
            },
          }));
      return session;
    }
    if (event.type == RecommendationEventType.shown ||
        event.activityId != session.id) {
      throw const SessionFailure(
          'Only recommendation decisions can be saved by this service.');
    }
    // Coalesces an in-flight UI impression and does not decide unless the
    // server has acknowledged it. Both callables support identical retries.
    await recordRecommendationShown(event);
    final batchKey =
        '${_source.currentUserId}/${event.activityId}/${event.recommendationId}/';
    // A decision closes the batch. Acknowledge all candidates actually exposed
    // before closing it, including any whose earlier presentation failed.
    await Future.wait(_displayed.entries
        .where((entry) => entry.key.startsWith(batchKey))
        .map((entry) => recordRecommendationShown(entry.value))
        .toList());
    final modified = event.type == RecommendationEventType.modified;
    final result = await _request(() => _source.call(
            modified
                ? 'modifyActivityRecommendation'
                : 'acceptActivityRecommendation',
            {
              'activityId': session.id,
              'recommendationId': event.slotId,
              if (modified)
                'startTime': event.selectedStart!.toUtc().toIso8601String(),
              if (modified)
                'endTime': event.selectedEnd!.toUtc().toIso8601String(),
            }));
    // The decision response is authoritative for this command. A subsequent
    // details refresh belongs to a separate ViewModel state, never save failure.
    return session.copyWith(
        startsAt: DateTime.parse(result['startTime'] as String),
        endsAt: DateTime.parse(result['endTime'] as String));
  }
}

import '../../domain/entities/study_session.dart';
import '../../domain/entities/activity_draft.dart';
import '../../domain/entities/slot_recommendation.dart';
import '../../domain/repositories/study_sessions_repository.dart';

/// Session-scoped demo storage. No reservations or messages leave the app.
class MockStudySessionsRepository implements StudySessionsRepository {
  final Map<String, SlotRecommendations> recommendations;
  final Map<String, RecommendationEvent> _events = {};
  MockStudySessionsRepository({this.recommendations = const {}});
  List<RecommendationEvent> get events => List.unmodifiable(_events.values);

  @override
  Future<List<ActivityGroup>> listGroups() async =>
      const [ActivityGroup('demo-group', 'Demo group')];

  @override
  Future<String> createActivity(ActivityDraft draft) async {
    final data = draft.validated();
    final id = 'demo-${_sessions.length}';
    _sessions[id] = StudySession(
        id: id,
        groupId: data.groupId,
        title: data.title,
        description: data.description,
        location: data.location,
        category: data.category,
        status: data.status,
        legacyDate: data.date,
        legacyTime: data.time,
        startsAt: null,
        endsAt: null,
        room: '',
        reminder: '',
        topics: const [],
        participants: const [],
        resources: const [],
        canOrganize: true,
        supportsActivityEditing: true,
        supportsDetailsEditing: false);
    return id;
  }

  @override
  Future<SlotRecommendations> getRecommendedSlots(String activityId,
          {int? durationMinutes}) async =>
      recommendations[activityId] ??
      SlotRecommendations(
          id: 'demo-empty-$activityId',
          activityId: activityId,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          slots: const []);

  @override
  Future<void> recordRecommendationShown(RecommendationEvent event) async {
    _events.putIfAbsent(event.deduplicationKey, () => event);
  }

  final Map<String, StudySession> _sessions = {'linear-algebra': _sample()};

  @override
  Future<StudySession?> getById(String id) async => _sessions[id];

  @override
  Future<StudySession> save(StudySession session,
      {RecommendationEvent? recommendationEvent}) async {
    if (!_sessions.containsKey(session.id)) {
      throw const SessionFailure('Session not found.');
    }
    _sessions[session.id] = session;
    if (recommendationEvent != null) {
      _events.putIfAbsent(
          recommendationEvent.deduplicationKey, () => recommendationEvent);
    }
    return session;
  }
}

StudySession _sample() => StudySession(
      id: 'linear-algebra',
      canOrganize: true,
      labels: const ['Group Study', 'Midterm Exam #2'],
      amenities: const ['Eduroam Wi-Fi', '4 outlets • USB-C'],
      title: 'Study Session: Linear Algebra & Calculus',
      description:
          'Intensive review prior to the engineering faculty midterm exam.',
      startsAt: DateTime(2026, 10, 24, 16),
      endsAt: DateTime(2026, 10, 24, 18),
      location: 'Central Library • 3rd Floor',
      room: 'Collaborative Study Room 3B (Table 4)',
      reminder:
          'Bring a graphing calculator (TI or Casio) and 2023 exam sheets. Alex will bring spare grid paper.',
      topics: const [
        StudyTopic('eigenvalues', 'Eigenvalues and Eigenvectors',
            "Solve exercises 12 to 19 from Prof. Ramírez’s guide."),
        StudyTopic('matrices', 'Diagonalization and Symmetric Matrices',
            'Quick theorem proofs and 3x3 matrix tricks.'),
        StudyTopic('exam', 'Timed Mock Exam (30 min)',
            'Two past semester exam questions provided by Sofía.'),
      ],
      participants: const [
        StudyParticipant('Alex Valenzuela', 'AV', 'Systems Engineering • Sem 6',
            'Already at library (3rd Floor)',
            leader: true),
        StudyParticipant('Sofía Gómez', 'SG', 'B.S. in Math • Sem 5',
            'Arrives in 5 min (On the way)'),
        StudyParticipant(
            'Mateo Ríos', 'MR', 'Industrial Eng. • Sem 6', 'Confirmed on time'),
        StudyParticipant(
            'Camila Torres', 'CT', 'Systems Eng. • Sem 6', 'Confirmed on time'),
      ],
      resources: const [
        StudyResource(
            'Guia_Ejercicios_Algebra_P4.pdf', '3.4 MB • Uploaded by Sofía'),
        StudyResource('Drive Folder: Linear Algebra 2026',
            'Virtual whiteboard & shared notes'),
      ],
    );

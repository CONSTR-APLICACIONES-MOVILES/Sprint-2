import '../entities/study_session.dart';
import '../repositories/study_sessions_repository.dart';

class ManageStudySession {
  final StudySessionsRepository _repository;
  const ManageStudySession(this._repository);

  Future<StudySession?> load(String id) => _repository.getById(id);

  Future<StudySession> _editable(String id) async {
    final session = await load(id);
    if (session == null) throw const SessionFailure('Session not found.');
    if (session.cancelled) {
      throw const SessionFailure('This session has been cancelled.');
    }
    return session;
  }

  Future<StudySession> update(String id,
      {required String title,
      required String room,
      required DateTime startsAt,
      required DateTime endsAt}) async {
    if (title.trim().isEmpty || room.trim().isEmpty) {
      throw const SessionFailure('Enter a session title and room.');
    }
    if (!endsAt.isAfter(startsAt)) {
      throw const SessionFailure('End time must be after start time.');
    }
    final session = await _editable(id);
    return _repository.save(session.copyWith(
        title: title.trim(),
        room: room.trim(),
        startsAt: startsAt,
        endsAt: endsAt));
  }

  Future<StudySession> toggleTopic(String id, String topicId) async {
    final session = await _editable(id);
    if (!session.topics.any((topic) => topic.id == topicId)) {
      throw const SessionFailure('Topic not found.');
    }
    return _repository.save(session.copyWith(topics: [
      for (final topic in session.topics)
        topic.id == topicId ? topic.toggle() : topic,
    ]));
  }

  Future<StudySession> cancel(String id) async =>
      _repository.save((await _editable(id)).copyWith(cancelled: true));
}

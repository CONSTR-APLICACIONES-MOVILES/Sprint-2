import '../entities/study_session.dart';

abstract interface class StudySessionsRepository {
  Future<StudySession?> getById(String id);
  Future<StudySession> save(StudySession session);
}

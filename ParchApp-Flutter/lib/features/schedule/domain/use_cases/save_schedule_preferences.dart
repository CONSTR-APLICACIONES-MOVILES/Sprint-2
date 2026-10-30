import '../repositories/schedule_preferences_repository.dart';

class SaveSchedulePreferences {
  final SchedulePreferencesRepository _repository;

  const SaveSchedulePreferences(
    this._repository,
  );

  Future<void> call(
    List<int> quickDurationsMinutes,
  ) {
    return _repository.saveQuickDurations(
      quickDurationsMinutes,
    );
  }
}

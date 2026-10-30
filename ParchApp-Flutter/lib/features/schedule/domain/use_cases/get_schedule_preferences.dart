import '../entities/schedule_preferences.dart';
import '../repositories/schedule_preferences_repository.dart';

class GetSchedulePreferences {
  final SchedulePreferencesRepository _repository;

  const GetSchedulePreferences(
    this._repository,
  );

  Future<SchedulePreferences> call() {
    return _repository.getPreferences();
  }
}

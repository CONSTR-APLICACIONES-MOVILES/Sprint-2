import '../entities/schedule_preferences.dart';

abstract interface class SchedulePreferencesRepository {
  Future<SchedulePreferences> getPreferences();

  Future<void> saveQuickDurations(
    List<int> quickDurationsMinutes,
  );
}
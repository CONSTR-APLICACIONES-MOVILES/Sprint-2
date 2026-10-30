import '../../domain/entities/schedule_preferences.dart';
import '../../domain/repositories/schedule_preferences_repository.dart';
import '../../domain/repositories/schedule_cache_metadata_repository.dart';
import '../../../../core/connectivity/connectivity_service.dart';

/// Local defaults for explicit demo repositories without platform services.
class MemorySchedulePreferencesRepository
    implements SchedulePreferencesRepository {
  SchedulePreferences _preferences = SchedulePreferences.defaults();
  @override
  Future<SchedulePreferences> getPreferences() async => _preferences;
  @override
  Future<void> saveQuickDurations(List<int> minutes) async {
    _preferences = SchedulePreferences(quickDurationsMinutes: List.of(minutes));
  }
}

class MemoryScheduleCacheMetadataRepository
    implements ScheduleCacheMetadataRepository {
  final _updated = <DateTime, DateTime>{};
  @override
  Future<DateTime?> getLastUpdated(DateTime day) async => _updated[day];
  @override
  Future<void> markUpdated(DateTime day, DateTime updatedAt) async {
    _updated[day] = updatedAt;
  }
}

class DemoConnectivityService extends ConnectivityService {
  @override
  Future<bool> hasConnection() async => true;
  @override
  Stream<bool> get connectionChanges => const Stream.empty();
}

import '../entities/quick_status.dart';

abstract interface class QuickStatusRepository {
  Future<QuickStatus> load(String uid);
  Future<QuickStatus> save(String uid, String freeUntil, String nextActivity);
}

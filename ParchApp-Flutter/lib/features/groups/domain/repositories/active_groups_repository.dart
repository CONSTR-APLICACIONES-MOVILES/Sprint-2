import '../entities/active_group.dart';

abstract interface class ActiveGroupsRepository {
  Future<List<ActiveGroup>> getActiveGroups();
  Future<List<ActiveGroup>> confirmRsvp(String id);
  Future<List<ActiveGroup>> dropIn(String id);
}
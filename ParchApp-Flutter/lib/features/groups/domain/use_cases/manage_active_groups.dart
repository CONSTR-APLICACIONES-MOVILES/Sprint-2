import '../entities/active_group.dart';
import '../repositories/active_groups_repository.dart';

class ManageActiveGroups {
  final ActiveGroupsRepository _repository;
  const ManageActiveGroups(this._repository);

  Future<List<ActiveGroup>> load() => _repository.getActiveGroups();

  Future<List<ActiveGroup>> confirmRsvp(ActiveGroup group) {
    if (!group.hasProgress) {
      throw StateError('This group does not track RSVPs.');
    }
    if (group.progressCurrent! >= group.progressTotal!) {
      throw StateError('The roster is already full.');
    }
    return _repository.confirmRsvp(group.id);
  }

  Future<List<ActiveGroup>> dropIn(ActiveGroup group) {
    if (group.primaryAction != GroupAction.dropIn) {
      throw StateError('This group does not support drop-in.');
    }
    return _repository.dropIn(group.id);
  }
}
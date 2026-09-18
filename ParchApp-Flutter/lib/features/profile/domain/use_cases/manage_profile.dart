import '../entities/profile_user.dart';
import '../repositories/profile_repository.dart';

class ManageProfile {
  final ProfileRepository _repository;
  const ManageProfile(this._repository);

  Future<ProfileUser> load() => _repository.getProfile();

  Future<ProfileUser> changeStatus(
      ProfileUser user, AvailabilityStatus status) {
    if (user.status == status) {
      throw StateError('You already have that availability status.');
    }
    return _repository.updateStatus(status);
  }

  Future<ProfileUser> updateProfile(ProfileUser user) {
    if (user.name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }
    if (user.program.trim().isEmpty) {
      throw ArgumentError('Program cannot be empty.');
    }
    return _repository.updateProfile(user);
  }
}

import '../repositories/presence_repository.dart';
import '../entities/profile_preferences.dart';
import '../entities/profile_user.dart';
import '../repositories/profile_repository.dart';

class ManageProfile {
  final ProfileRepository _repository;
  const ManageProfile(this._repository);

  Future<ProfileUser> presence(AvailabilityStatus status, DateTime expiresAt,
      String visibility, String ownerId) {
    final repository = _repository;
    if (repository is! PresenceRepository) {
      throw StateError('Presence settings are unavailable.');
    }
    return (repository as PresenceRepository)
        .updatePresence(status, expiresAt, visibility, ownerId: ownerId);
  }

  Future<ProfileUser> preferences(
      ProfilePreferences preferences, String ownerId) {
    final repository = _repository;
    if (repository is! PresenceRepository) {
      throw StateError('Privacy settings are unavailable.');
    }
    return (repository as PresenceRepository)
        .updatePreferences(preferences, ownerId: ownerId);
  }

  Future<List<Map<String, dynamic>>> peers() {
    final repository = _repository;
    if (repository is! PresenceRepository) {
      throw StateError('Peers are unavailable.');
    }
    return (repository as PresenceRepository).getPeers();
  }

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

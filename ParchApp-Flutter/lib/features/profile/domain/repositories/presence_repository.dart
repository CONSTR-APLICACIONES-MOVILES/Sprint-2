import '../entities/profile_user.dart';
import '../entities/profile_preferences.dart';

abstract interface class PresenceRepository {
  Future<ProfileUser> updatePresence(
      AvailabilityStatus status, DateTime expiresAt, String visibility,
      {String? ownerId});
  Future<ProfileUser> updatePreferences(ProfilePreferences preferences,
      {String? ownerId});
  Future<List<Map<String, dynamic>>> getPeers();
}

import '../entities/profile_user.dart';

abstract interface class ProfileRepository {
  Future<ProfileUser> getProfile();
  Future<ProfileUser> updateStatus(AvailabilityStatus status);
  Future<ProfileUser> updateProfile(ProfileUser user);
}

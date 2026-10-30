import '../entities/profile_user.dart';
import '../repositories/profile_photo_repository.dart';
import '../repositories/profile_repository.dart';

class ChangeProfilePhoto {
  final ProfilePhotoRepository _photos;
  final ProfileRepository _profiles;

  const ChangeProfilePhoto(this._photos, this._profiles);

  Future<ProfileUser?> call(ProfileUser user) async {
    final path = await _photos.capture();
    if (path == null) return null;
    return _profiles.updateProfile(user.copyWith(photoPath: path));
  }
}

import '../entities/profile_offline.dart';
import '../entities/profile_user.dart';
import '../repositories/profile_photo_repository.dart';
import '../repositories/profile_repository.dart';

class ChangeProfilePhoto {
  final ProfilePhotoRepository _photos;
  final ProfileRepository _profiles;
  final Future<bool> Function()? _isOnline;

  const ChangeProfilePhoto(this._photos, this._profiles,
      {Future<bool> Function()? isOnline})
      : _isOnline = isOnline;

  Future<ProfileUser?> call(ProfileUser user) async {
    final online = _isOnline;
    if (online != null && !await online()) throw const ProfileOffline();
    final path = await _photos.capture();
    if (path == null) return null;
    return _profiles.updateProfile(user.copyWith(photoPath: path));
  }
}
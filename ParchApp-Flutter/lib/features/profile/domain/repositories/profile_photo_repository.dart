import '../entities/photo_source.dart';

abstract interface class ProfilePhotoRepository {
  Future<String?> capture(PhotoSource source);
}
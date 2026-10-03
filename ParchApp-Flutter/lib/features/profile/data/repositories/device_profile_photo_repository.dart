import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/photo_source.dart';
import '../../domain/repositories/profile_photo_repository.dart';

class DeviceProfilePhotoRepository implements ProfilePhotoRepository {
  final ImagePicker _picker;

  DeviceProfilePhotoRepository([ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  @override
  Future<String?> capture(PhotoSource source) async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: source == PhotoSource.frontCamera
          ? CameraDevice.front
          : CameraDevice.rear,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (photo == null) return null;
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(photo.path).copy(path);
    return path;
  }
}
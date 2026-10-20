import 'dart:convert';

import 'package:image_picker/image_picker.dart';

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
      maxWidth: 320,
      maxHeight: 320,
      imageQuality: 65,
    );
    if (photo == null) return null;
    final bytes = await photo.readAsBytes();
    if (bytes.length > 130000) throw StateError('Choose a smaller photo.');
    final mime = photo.mimeType ??
        (photo.name.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg');
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
}

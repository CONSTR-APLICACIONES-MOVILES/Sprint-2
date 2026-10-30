import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/profile/data/repositories/mock_profile_repository.dart';
import 'package:parchapp/features/profile/domain/repositories/profile_photo_repository.dart';
import 'package:parchapp/features/profile/domain/use_cases/change_profile_photo.dart';
import 'package:parchapp/features/profile/domain/use_cases/manage_profile.dart';
import 'package:parchapp/features/profile/presentation/view_models/profile_view_model.dart';

class _FakePhotoRepository implements ProfilePhotoRepository {
  String? nextPath = '/photos/picture.jpg';
  bool fail = false;
  int captures = 0;

  @override
  Future<String?> capture() async {
    captures++;
    if (fail) throw Exception('camera_access_denied');
    return nextPath;
  }
}

void main() {
  late _FakePhotoRepository photos;
  late ProfileViewModel model;

  setUp(() async {
    photos = _FakePhotoRepository();
    final profiles = MockProfileRepository();
    model = ProfileViewModel(ManageProfile(profiles),
        changePhoto: ChangeProfilePhoto(photos, profiles));
    await model.load();
  });
  tearDown(() => model.dispose());

  test('a picture becomes the profile photo', () async {
    expect(await model.changePhoto(), isTrue);
    expect(photos.captures, 1);
    expect(model.value.user!.photoPath, '/photos/picture.jpg');
    expect(model.value.isUpdating, isFalse);
  });

  test('closing the camera keeps the current photo', () async {
    photos.nextPath = null;
    expect(await model.changePhoto(), isFalse);
    expect(model.value.user!.photoPath, isNull);
    expect(model.value.error, isNull);
  });

  test('a denied camera permission shows an error', () async {
    photos.fail = true;
    expect(await model.changePhoto(), isFalse);
    expect(model.value.error, contains('camera'));
    expect(model.value.user, isNotNull);
  });
}
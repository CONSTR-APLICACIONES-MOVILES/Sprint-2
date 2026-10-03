import 'package:flutter/foundation.dart';
import '../../domain/entities/photo_source.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/use_cases/change_profile_photo.dart';
import '../../domain/use_cases/manage_profile.dart';
import 'profile_state.dart';
import '../../../auth/domain/use_cases/sign_out.dart';

class ProfileViewModel extends ValueNotifier<ProfileState> {
  final ManageProfile _profile;
  final SignOut? _signOut;
  final ChangeProfilePhoto? _changePhoto;
  bool _disposed = false;

  ProfileViewModel(this._profile,
      {SignOut? signOut, ChangeProfilePhoto? changePhoto})
      : _signOut = signOut,
        _changePhoto = changePhoto,
        super(ProfileState());

  Future<bool> signOut() async {
    if (_disposed || value.isUpdating) return false;
    _emit(value.copyWith(isUpdating: true));
    try {
      await _signOut?.call();
      _emit(value.copyWith(isUpdating: false));
      return !_disposed;
    } catch (_) {
      _emit(value.copyWith(
          isUpdating: false, error: 'Unable to sign out. Please try again.'));
      return false;
    }
  }

  void _emit(ProfileState state) {
    if (!_disposed) value = state;
  }

  Future<void> load() async {
    if (_disposed || value.isLoading || value.isUpdating) return;
    _emit(value.copyWith(isLoading: true));
    try {
      final user = await _profile.load();
      _emit(value.copyWith(user: user, isLoading: false));
    } catch (_) {
      _emit(value.copyWith(
          isLoading: false,
          error: 'Unable to load your profile. Please try again.'));
    }
  }

  Future<bool> changeStatus(AvailabilityStatus status) {
    final user = value.user;
    if (user == null) return Future.value(false);
    return _update(() => _profile.changeStatus(user, status));
  }

  Future<bool> updateProfile(ProfileUser user) =>
      _update(() => _profile.updateProfile(user));

  Future<bool> changePhoto(PhotoSource source) async {
    final user = value.user;
    final changePhoto = _changePhoto;
    if (_disposed ||
        user == null ||
        changePhoto == null ||
        value.isLoading ||
        value.isUpdating) {
      return false;
    }
    _emit(value.copyWith(isUpdating: true));
    try {
      final updated = await changePhoto(user, source);
      if (_disposed) return false;
      _emit(value.copyWith(user: updated, isUpdating: false));
      return updated != null;
    } catch (_) {
      _emit(value.copyWith(
          isUpdating: false,
          error:
              'We could not open the camera. Check the camera permission and try again.'));
      return false;
    }
  }

  Future<bool> _update(Future<ProfileUser> Function() operation) async {
    if (_disposed || value.isLoading || value.isUpdating) return false;
    _emit(value.copyWith(isUpdating: true));
    try {
      final user = await operation();
      if (_disposed) return false;
      _emit(value.copyWith(user: user, isUpdating: false));
      return true;
    } catch (_) {
      _emit(value.copyWith(
          isUpdating: false,
          error: 'Unable to save your changes. Please try again.'));
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
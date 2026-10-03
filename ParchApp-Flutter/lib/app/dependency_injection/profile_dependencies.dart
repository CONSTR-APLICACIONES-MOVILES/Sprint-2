import 'package:flutter/material.dart';
import '../../features/profile/data/repositories/mock_profile_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/use_cases/manage_profile.dart';
import '../../features/profile/presentation/view_models/profile_view_model.dart';
import '../../features/profile/presentation/views/profile_view.dart';
import '../../features/profile/data/repositories/device_profile_photo_repository.dart';
import '../../features/profile/domain/repositories/profile_photo_repository.dart';
import '../../features/profile/domain/use_cases/change_profile_photo.dart';

class ProfileDependencies {
  final ProfileRepository repository;
  final ProfilePhotoRepository photos;

  const ProfileDependencies({required this.repository, required this.photos});

  factory ProfileDependencies.mock() => ProfileDependencies(
        repository: MockProfileRepository(),
        photos: DeviceProfilePhotoRepository(),
      );

  ProfileViewModel createViewModel() => ProfileViewModel(
        ManageProfile(repository),
        changePhoto: ChangeProfilePhoto(photos, repository),
      );

  Widget route() => _ProfileEntry(dependencies: this);
}

class _ProfileEntry extends StatefulWidget {
  final ProfileDependencies dependencies;
  const _ProfileEntry({required this.dependencies});

  @override
  State<_ProfileEntry> createState() => _ProfileEntryState();
}

class _ProfileEntryState extends State<_ProfileEntry> {
  late final ProfileViewModel _viewModel =
      widget.dependencies.createViewModel();

  @override
  Widget build(BuildContext context) => ProfileView(viewModel: _viewModel);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}

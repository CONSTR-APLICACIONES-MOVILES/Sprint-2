import '../../domain/entities/profile_user.dart';

class ProfileState {
  final ProfileUser? user;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  ProfileState({
    this.user,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileUser? user,
    bool? isLoading,
    bool? isUpdating,
    String? error,
  }) =>
      ProfileState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        isUpdating: isUpdating ?? this.isUpdating,
        error: error,
      );
}

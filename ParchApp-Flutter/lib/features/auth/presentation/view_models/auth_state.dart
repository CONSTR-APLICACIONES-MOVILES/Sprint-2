import '../../domain/entities/authenticated_user.dart';
import '../../domain/entities/google_account.dart';

enum AuthStatus {
  idle,
  loading,
  authenticated,
  validationError,
  authenticationError
}

class AuthState {
  final AuthStatus status;
  final AuthenticatedUser? user;
  final AuthenticatedUser? recognizedUser;
  final GoogleAccount? suggestedGoogleAccount;
  final String? message;

  const AuthState(
      {this.status = AuthStatus.idle,
      this.user,
      this.recognizedUser,
      this.suggestedGoogleAccount,
      this.message});

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith(
          {AuthStatus? status,
          AuthenticatedUser? user,
          AuthenticatedUser? recognizedUser,
          GoogleAccount? suggestedGoogleAccount,
          String? message}) =>
      AuthState(
          status: status ?? this.status,
          user: user ?? this.user,
          recognizedUser: recognizedUser ?? this.recognizedUser,
          suggestedGoogleAccount:
              suggestedGoogleAccount ?? this.suggestedGoogleAccount,
          message: message);
}

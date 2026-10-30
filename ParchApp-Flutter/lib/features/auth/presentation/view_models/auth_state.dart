import '../../domain/entities/authenticated_user.dart';
import '../../domain/entities/biometric_sign_in.dart';
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
  final BiometricSignIn biometricSignIn;
  final String? message;

  const AuthState(
      {this.status = AuthStatus.idle,
      this.user,
      this.recognizedUser,
      this.suggestedGoogleAccount,
      this.biometricSignIn = BiometricSignIn.unavailable,
      this.message});

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith(
          {AuthStatus? status,
          AuthenticatedUser? user,
          AuthenticatedUser? recognizedUser,
          GoogleAccount? suggestedGoogleAccount,
          BiometricSignIn? biometricSignIn,
          String? message}) =>
      AuthState(
          status: status ?? this.status,
          user: user ?? this.user,
          recognizedUser: recognizedUser ?? this.recognizedUser,
          suggestedGoogleAccount:
              suggestedGoogleAccount ?? this.suggestedGoogleAccount,
          biometricSignIn: biometricSignIn ?? this.biometricSignIn,
          message: message);
}
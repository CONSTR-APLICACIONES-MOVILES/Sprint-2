import 'package:flutter/foundation.dart';

import '../../domain/entities/authenticated_user.dart';
import '../../domain/entities/auth_failure.dart';
import 'auth_state.dart';

/// Shared request lifecycle for the two auth forms; contains no UI callbacks.
abstract class AuthViewModel extends ValueNotifier<AuthState> {
  AuthViewModel() : super(const AuthState());
  bool _disposed = false;

  @protected
  bool get isDisposed => _disposed;

  @protected
  void emit(AuthState state) {
    if (!_disposed) value = state;
  }

  @protected
  Future<void> authenticate(Future<AuthenticatedUser> Function() action) async {
    if (_disposed ||
        value.isLoading ||
        value.status == AuthStatus.authenticated) {
      return;
    }
    emit(value.copyWith(status: AuthStatus.loading));
    try {
      final user = await action();
      emit(value.copyWith(status: AuthStatus.authenticated, user: user));
    } on AuthValidationException catch (error) {
      emit(value.copyWith(
          status: AuthStatus.validationError, message: error.message));
    } on AuthenticationException catch (error) {
      emit(value.copyWith(
          status: AuthStatus.authenticationError, message: error.message));
    } catch (_) {
      emit(value.copyWith(
          status: AuthStatus.authenticationError,
          message: 'Something went wrong. Please try again.'));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

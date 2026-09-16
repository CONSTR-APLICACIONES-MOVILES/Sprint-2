class AuthValidationException implements Exception {
  final String message;
  const AuthValidationException(this.message);
}

class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException(this.message);
}

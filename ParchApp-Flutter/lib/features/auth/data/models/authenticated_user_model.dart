import '../../domain/entities/authenticated_user.dart';

class AuthenticatedUserModel {
  final String id;
  final String name;
  final String email;
  final String program;
  final bool verified;

  const AuthenticatedUserModel(
      {required this.id,
      required this.name,
      required this.email,
      this.program = '',
      this.verified = false});

  AuthenticatedUser toEntity() => AuthenticatedUser(
      id: id, name: name, email: email, program: program, verified: verified);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/auth/data/data_sources/mock_auth_data_source.dart';
import 'package:parchapp/features/auth/data/models/authenticated_user_model.dart';
import 'package:parchapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parchapp/features/auth/domain/entities/auth_failure.dart';

class _Source extends MockAuthDataSource {
  bool fail = false;
  bool reject = false;
  @override
  Future<AuthenticatedUserModel?> signIn(String email, String password) async {
    if (fail) throw Exception('raw SDK failure');
    if (reject) return null;
    return AuthenticatedUserModel(
        id: '42',
        name: 'Student',
        email: email,
        program: 'Engineering',
        verified: true);
  }
}

void main() {
  test('repository maps transport data into a domain user', () async {
    final repository = AuthRepositoryImpl(_Source());
    final user = await repository.signIn('student@example.com', 'password');
    expect(user.id, '42');
    expect(user.email, 'student@example.com');
    expect(user.program, 'Engineering');
    expect(user.verified, isTrue);
  });
  test('repository translates rejected credentials into domain failure',
      () async {
    final repository = AuthRepositoryImpl(_Source()..reject = true);
    await expectLater(repository.signIn('student@example.com', 'incorrect'),
        throwsA(isA<AuthenticationException>()));
  });
  test('repository hides transport exceptions', () async {
    final repository = AuthRepositoryImpl(_Source()..fail = true);
    await expectLater(
        repository.signIn('student@example.com', 'password'),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.message, 'message', isNot(contains('SDK')))));
  });
}

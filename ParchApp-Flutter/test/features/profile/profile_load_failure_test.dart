import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/features/profile/data/repositories/firebase_profile_repository.dart';
import 'package:parchapp/features/profile/domain/entities/profile_load_failure.dart';

class _FailingApi implements MobileApi {
  final String code;
  _FailingApi(this.code);
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    throw FirebaseFunctionsException(code: code, message: 'server');
  }
}

void main() {
  for (final entry in {
    'unauthenticated': 'session',
    'permission-denied': 'permissions',
    'not-found': 'not deployed',
    'unavailable': 'unreachable'
  }.entries) {
    test('profile ${entry.key} explains the actual recovery action', () async {
      final repo = FirebaseProfileRepository(_FailingApi(entry.key));
      await expectLater(
          repo.getProfile(),
          throwsA(isA<ProfileLoadFailure>()
              .having((e) => e.message, 'message', contains(entry.value))));
    });
  }
}

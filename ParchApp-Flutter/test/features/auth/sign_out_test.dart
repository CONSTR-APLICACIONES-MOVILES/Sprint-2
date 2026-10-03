import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/auth/domain/use_cases/sign_out.dart';
import 'package:parchapp/features/profile/data/repositories/mock_profile_repository.dart';
import 'package:parchapp/features/profile/domain/use_cases/manage_profile.dart';
import 'package:parchapp/features/profile/presentation/view_models/profile_view_model.dart';
import '../../support/fake_auth_repository.dart';

void main() {
  test(
      'logout awaits the auth repository and does not report failed sign-out as success',
      () async {
    final auth = FakeAuthRepository();
    final model = ProfileViewModel(ManageProfile(MockProfileRepository()),
        signOut: SignOut(auth));
    addTearDown(model.dispose);
    auth.failSignOut = true;
    expect(await model.signOut(), isFalse);
    expect(model.value.error, isNotNull);
    auth.failSignOut = false;
    expect(await model.signOut(), isTrue);
    expect(auth.signOutCalls, 2);
    expect(model.value.error, isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/data/data_sources/firebase_auth_data_source.dart';

import '../../features/auth/data/data_sources/mock_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/use_cases/sign_in.dart';
import '../../features/auth/domain/use_cases/create_account.dart';
import '../../features/auth/presentation/view_models/sign_in_view_model.dart';
import '../../features/auth/presentation/view_models/create_account_view_model.dart';
import '../../features/auth/presentation/views/sign_in_view.dart';
import '../../features/auth/presentation/views/create_account_view.dart';

class AuthDependencies {
  final AuthRepository repository;
  const AuthDependencies({required this.repository});

  factory AuthDependencies.mock() =>
      AuthDependencies(repository: AuthRepositoryImpl(MockAuthDataSource()));
  factory AuthDependencies.firebase(FirebaseAuth auth) => AuthDependencies(
      repository: AuthRepositoryImpl(FirebaseAuthDataSource(auth)));

  SignInViewModel createSignInViewModel() =>
      SignInViewModel(SignIn(repository));
  CreateAccountViewModel createAccountViewModel() =>
      CreateAccountViewModel(CreateAccount(repository));

  Widget signInRoute() => _SignInEntry(dependencies: this);
  Widget createAccountRoute() => _CreateAccountEntry(dependencies: this);
}

class _SignInEntry extends StatefulWidget {
  final AuthDependencies dependencies;
  const _SignInEntry({required this.dependencies});
  @override
  State<_SignInEntry> createState() => _SignInEntryState();
}

class _SignInEntryState extends State<_SignInEntry> {
  late final SignInViewModel _viewModel =
      widget.dependencies.createSignInViewModel();
  @override
  Widget build(BuildContext context) => SignInView(viewModel: _viewModel);
  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}

class _CreateAccountEntry extends StatefulWidget {
  final AuthDependencies dependencies;
  const _CreateAccountEntry({required this.dependencies});
  @override
  State<_CreateAccountEntry> createState() => _CreateAccountEntryState();
}

class _CreateAccountEntryState extends State<_CreateAccountEntry> {
  late final CreateAccountViewModel _viewModel =
      widget.dependencies.createAccountViewModel();
  @override
  Widget build(BuildContext context) =>
      CreateAccountView(viewModel: _viewModel);
  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}

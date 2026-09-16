import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_primary_button.dart';
import '../../model/auth_user.dart';
import '../../model/mock_auth_model.dart';
import '../../presenter/sign_in_presenter.dart';
import '../contracts/sign_in_view_contract.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_auth_button.dart';
import '../widgets/recognized_user_card.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView>
    implements SignInViewContract {
  late final SignInPresenter presenter;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  AuthUser? recognizedUser;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    presenter = SignInPresenter(
      view: this,
      model: MockAuthModel(),
    );

    presenter.load();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  void showRecognizedUser(AuthUser? user) {
    if (!mounted) {
      return;
    }

    setState(() {
      recognizedUser = user;
    });
  }

  @override
  void showLoading(bool value) {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = value;
    });
  }

  @override
  void showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void showInfo(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void navigateToHome() {
    showInfo(
      'Authentication successful. Home will be implemented next.',
    );

    // When Home is ready:
    //
    // context.go(AppRoutes.home);
  }

@override
void navigateToCreateAccount() {
  context.push(
    AppRoutes.createAccount,
  );
}

  void _signIn() {
    presenter.onSignInPressed(
      email: emailController.text,
      password: passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.horizontalPadding,
            24,
            AppDimensions.horizontalPadding,
            32,
          ),
          child: Column(
            children: [
              const AuthHeader(
                title: 'Welcome back',
                subtitle:
                    'Sign in to continue planning with your friends.',
              ),

              const SizedBox(height: 24),

              if (recognizedUser != null) ...[
                RecognizedUserCard(
                  user: recognizedUser!,
                  isLoading: isLoading,
                  onContinue: isLoading
                      ? null
                      : presenter.onContinueAsRecognizedUserPressed,
                ),

                const SizedBox(height: 18),
              ],

              const AuthDivider(),

              const SizedBox(height: 18),

              GoogleAuthButton(
                onPressed: isLoading
                    ? null
                    : presenter.onGoogleSignInPressed,
              ),

              const SizedBox(height: 20),

              AuthTextField(
                hintText: 'University email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 12),

              AuthTextField(
                hintText: 'Password',
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
              ),

              const SizedBox(height: 4),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : presenter.onForgotPasswordPressed,
                  child: const Text(
                    'Forgot password?',
                  ),
                ),
              ),

              const SizedBox(height: 4),

              ParchPrimaryButton(
                label: 'Sign in',
                isLoading: isLoading,
                onPressed: _signIn,
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),

                  TextButton(
                    onPressed: isLoading
                        ? null
                        : presenter.onCreateAccountPressed,
                    child: const Text(
                      'Create one',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
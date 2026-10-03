import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_primary_button.dart';
import '../view_models/auth_state.dart';
import '../../domain/entities/authenticated_user.dart';
import '../view_models/sign_in_view_model.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/recognized_user_card.dart';

class SignInView extends StatefulWidget {
  final SignInViewModel viewModel;
  const SignInView({super.key, required this.viewModel});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late AuthState _previousState;
  bool get isLoading => widget.viewModel.value.isLoading;
  AuthenticatedUser? get recognizedUser =>
      widget.viewModel.value.recognizedUser;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _previousState = widget.viewModel.value;
    widget.viewModel.addListener(_onStateChanged);
    widget.viewModel.load();
  }

  @override
  void didUpdateWidget(covariant SignInView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onStateChanged);
      _attach();
    }
  }

  void _onStateChanged() {
    if (!mounted) return;
    final state = widget.viewModel.value;
    final previous = _previousState;
    _previousState = state;
    setState(() {});
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (state.status == AuthStatus.authenticated &&
        previous.status != AuthStatus.authenticated) {
      final destination = GoRouterState.of(context).uri.queryParameters['from'];
      context.go(destination != null && destination.startsWith('/activities/')
          ? destination
          : AppRoutes.home);
    } else if (state.message != null &&
        (state.message != previous.message ||
            state.status != previous.status)) {
      _showMessage(state.message!);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onStateChanged);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    widget.viewModel
        .signIn(email: emailController.text, password: passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                subtitle: 'Sign in to continue planning with your friends.',
              ),
              const SizedBox(height: 24),
              if (recognizedUser != null) ...[
                RecognizedUserCard(
                  user: recognizedUser!,
                  isLoading: isLoading,
                  onContinue: isLoading
                      ? null
                      : widget.viewModel.continueAsRecognizedUser,
                ),
                const SizedBox(height: 18),
              ],
              const AuthDivider(),
              const SizedBox(height: 18),
              GoogleAuthButton(
                onPressed: isLoading ? null : widget.viewModel.signInWithGoogle,
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
                      : () => _showMessage(
                          'Password recovery will be implemented next.'),
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
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                        : () => context.push(AppRoutes.createAccount),
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

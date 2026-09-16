import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_primary_button.dart';
import '../view_models/auth_state.dart';
import '../../domain/entities/google_account.dart';
import '../view_models/create_account_view_model.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_auth_button.dart';
import '../widgets/google_account_picker_card.dart';

class CreateAccountView extends StatefulWidget {
  final CreateAccountViewModel viewModel;
  const CreateAccountView({super.key, required this.viewModel});

  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late AuthState _previousState;
  bool get isLoading => widget.viewModel.value.isLoading;
  final fullNameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;
  GoogleAccount? get suggestedGoogleAccount =>
      widget.viewModel.value.suggestedGoogleAccount;

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
  void didUpdateWidget(covariant CreateAccountView oldWidget) {
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
      context.go(AppRoutes.authComplete);
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
    fullNameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _continueWithEmail() {
    widget.viewModel.createAccount(
        fullName: fullNameController.text,
        email: emailController.text,
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text);
  }

  void _fillGoogleAccount() {
    final account = widget.viewModel.value.suggestedGoogleAccount;
    if (account == null) return;
    fullNameController.text = account.name;
    emailController.text = account.email;
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
            12,
            AppDimensions.horizontalPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==============================
              // BACK BUTTON
              // ==============================

              SizedBox(
                width: 44,
                height: 44,
                child: OutlinedButton(
                  onPressed: isLoading ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==============================
              // HEADER
              // ==============================

              Text(
                'Create your ParchApp account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Join your friends, compare availability, '
                'and start planning together.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),

              const SizedBox(height: 24),

              // ==============================
              // GOOGLE
              // ==============================

              GoogleAuthButton(
                onPressed:
                    isLoading ? null : widget.viewModel.continueWithGoogle,
              ),

              if (suggestedGoogleAccount != null) ...[
                const SizedBox(height: 16),
                GoogleAccountPickerCard(
                  account: suggestedGoogleAccount!,
                  onAccountPressed: isLoading ? null : _fillGoogleAccount,
                  onUseAnotherAccountPressed: isLoading
                      ? null
                      : () => _showMessage(
                          'Google account selection will be connected later.'),
                ),
              ],

              const SizedBox(height: 20),

              const AuthDivider(
                label: 'OR EMAIL',
              ),

              const SizedBox(height: 20),

              // ==============================
              // FORM
              // ==============================

              AuthTextField(
                label: 'Full Name',
                hintText: 'Full Name',
                controller: fullNameController,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              AuthTextField(
                label: 'University Email',
                hintText: 'name@university.edu',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 14),

              AuthTextField(
                label: 'Password',
                hintText: 'Password',
                controller: passwordController,
                obscureText: !showPassword,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              AuthTextField(
                label: 'Confirm Password',
                hintText: 'Confirm Password',
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continueWithEmail(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      showConfirmPassword = !showConfirmPassword;
                    });
                  },
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ParchPrimaryButton(
                label: 'Continue',
                isLoading: isLoading,
                onPressed: _continueWithEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

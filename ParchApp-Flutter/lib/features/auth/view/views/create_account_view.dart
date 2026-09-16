import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_primary_button.dart';
import '../../model/google_account.dart';
import '../../model/mock_auth_model.dart';
import '../../presenter/create_account_presenter.dart';
import '../contracts/create_account_view_contract.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_account_picker_card.dart';
import '../widgets/google_auth_button.dart';

class CreateAccountView extends StatefulWidget {
  const CreateAccountView({super.key});

  @override
  State<CreateAccountView> createState() =>
      _CreateAccountViewState();
}

class _CreateAccountViewState
    extends State<CreateAccountView>
    implements CreateAccountViewContract {
  late final CreateAccountPresenter presenter;

  final fullNameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  GoogleAccount? suggestedGoogleAccount;

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void initState() {
    super.initState();

    presenter = CreateAccountPresenter(
      view: this,
      model: MockAuthModel(),
    );

    presenter.load();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  void showSuggestedGoogleAccount(
    GoogleAccount? account,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      suggestedGoogleAccount = account;
    });
  }

  @override
  void fillFormFromGoogleAccount(
    GoogleAccount account,
  ) {
    fullNameController.text = account.name;
    emailController.text = account.email;
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
  void navigateBack() {
    Navigator.of(context).pop();
  }

  @override
  void navigateToNextStep() {
    showInfo(
      'Account created successfully. The next step will be implemented next.',
    );
  }

  void _continueWithEmail() {
    presenter.onContinuePressed(
      fullName: fullNameController.text,
      email: emailController.text,
      password: passwordController.text,
      confirmPassword:
          confirmPasswordController.text,
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
            12,
            AppDimensions.horizontalPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==============================
              // BACK BUTTON
              // ==============================

              SizedBox(
                width: 44,
                height: 44,
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : presenter.onBackPressed,
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
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontSize: 13.5,
                      color:
                          AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),

              const SizedBox(height: 24),

              // ==============================
              // GOOGLE
              // ==============================

              GoogleAuthButton(
                onPressed: isLoading
                    ? null
                    : presenter
                        .onContinueWithGooglePressed,
              ),

              if (suggestedGoogleAccount != null) ...[
                const SizedBox(height: 16),

                GoogleAccountPickerCard(
                  account:
                      suggestedGoogleAccount!,
                  onAccountPressed: isLoading
                      ? null
                      : presenter
                          .onGoogleAccountSelected,
                  onUseAnotherAccountPressed:
                      isLoading
                          ? null
                          : presenter
                              .onUseAnotherGoogleAccountPressed,
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
                controller:
                    fullNameController,
                textInputAction:
                    TextInputAction.next,
              ),

              const SizedBox(height: 14),

              AuthTextField(
                label: 'University Email',
                hintText:
                    'name@university.edu',
                controller:
                    emailController,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
              ),

              const SizedBox(height: 14),

              AuthTextField(
                label: 'Password',
                hintText: 'Password',
                controller:
                    passwordController,
                obscureText: !showPassword,
                textInputAction:
                    TextInputAction.next,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      showPassword =
                          !showPassword;
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
                hintText:
                    'Confirm Password',
                controller:
                    confirmPasswordController,
                obscureText:
                    !showConfirmPassword,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) =>
                    _continueWithEmail(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      showConfirmPassword =
                          !showConfirmPassword;
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
                onPressed:
                    _continueWithEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_primary_button.dart';
import '../../../../shared/widgets/parch_secondary_button.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  void _showNextStep(BuildContext context, String screenName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$screenName will be implemented next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.horizontalPadding),
                child: Transform.translate(
                  offset: const Offset(0, -12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.logoRadius),
                        child: Image.asset(
                          'assets/images/parchapp_logo.png',
                          width: AppDimensions.logoSize,
                          height: AppDimensions.logoSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'PARCHAPP',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Find the time\n'),
                            const TextSpan(text: 'you '),
                            TextSpan(
                              text: 'share.',
                              style: GoogleFonts.inter(
                                color: AppColors.accent,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                                letterSpacing: -0.7,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                          letterSpacing: -0.7,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 305),
                        child: Text(
                          'Find when everyone is free, make the plan, and spend less time coordinating.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.55,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.horizontalPadding, 16, AppDimensions.horizontalPadding, 24),
              child: Column(
                children: [
                  ParchPrimaryButton(
                    label: 'Get started',
                    onPressed: () => _showNextStep(context, 'Create Account'),
                  ),
                  const SizedBox(height: 12),
                  ParchSecondaryButton(
                    label: 'I already have an account',
                    onPressed: () => _showNextStep(context, 'Sign In'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

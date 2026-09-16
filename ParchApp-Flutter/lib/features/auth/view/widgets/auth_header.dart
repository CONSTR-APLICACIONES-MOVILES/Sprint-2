import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/parchapp_logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.12,
                color: AppColors.textPrimary,
              ),
        ),

        const SizedBox(height: 8),

        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 305,
          ),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({
    super.key,
    this.label = 'OR',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppColors.border,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppColors.border,
          ),
        ),
      ],
    );
  }
}

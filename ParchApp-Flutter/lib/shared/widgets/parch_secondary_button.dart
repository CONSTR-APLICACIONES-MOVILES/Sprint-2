import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';

class ParchSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const ParchSecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.secondaryButtonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: const Color(0xFF1E293B),
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

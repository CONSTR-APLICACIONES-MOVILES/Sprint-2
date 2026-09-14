import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

class ParchPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const ParchPrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.primaryButtonHeight,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../shared/widgets/parch_secondary_button.dart';

class GoogleAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleAuthButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ParchSecondaryButton(
      label: 'Continue with Google',
      onPressed: onPressed,
      leading: const Text(
        'G',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}

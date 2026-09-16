import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SessionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  const SessionCard(
      {super.key, required this.child, this.title, this.icon, this.trailing});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x060047BA),
                  blurRadius: 12,
                  offset: Offset(0, 4))
            ]),
        child: Material(
            color: Colors.transparent,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    Row(children: [
                      if (icon != null) ...[
                        Icon(icon, color: AppColors.primary),
                        const SizedBox(width: 10)
                      ],
                      Expanded(
                          child: Text(title!,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700))),
                      if (trailing != null) trailing!,
                    ]),
                    const SizedBox(height: 16),
                  ],
                  child,
                ])),
      );
}

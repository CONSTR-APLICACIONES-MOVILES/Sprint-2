import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileSectionLabel extends StatelessWidget {
  final String label;
  const ProfileSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8)),
      );
}

class ProfileMenuGroup extends StatelessWidget {
  final List<Widget> children;
  const ProfileMenuGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6ECF7))),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, indent: 60, color: Color(0xFFF0F3F9)),
              children[i],
            ],
          ],
        ),
      );
}

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? badge;
  final VoidCallback onTap;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (badge != null) ...[badge!, const SizedBox(width: 8)],
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textSecondary),
          ]),
        ),
      );
}

class ProfileBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  const ProfileBadge(this.label,
      {super.key, required this.color, required this.background});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ParchBrand extends StatelessWidget {
  const ParchBrand({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'ParchApp',
        image: true,
        child: ExcludeSemantics(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/parchapp_logo.png', width: 34, height: 34),
          const SizedBox(width: 8),
          const Flexible(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('ParchApp',
                      style: TextStyle(
                          fontSize: 20,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)))),
        ])),
      );
}

class ParchSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const ParchSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18),
      this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.outlineSoft),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x080C2D63),
                  blurRadius: 14,
                  offset: Offset(0, 4))
            ]),
        child: Material(type: MaterialType.transparency, child: child),
      );
}

class ParchPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const ParchPill(this.label,
      {super.key, this.color = AppColors.primary, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: .22))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5)
          ],
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)))
        ]),
      );
}

class ParchAvatar extends StatelessWidget {
  final String name;
  final int index;
  const ParchAvatar(this.name, {super.key, this.index = 0});
  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join()
        .toUpperCase();
    final color = [
      AppColors.primary,
      const Color(0xFF7857CF),
      AppColors.success,
      const Color(0xFFC27A13)
    ][index % 4];
    return CircleAvatar(
        radius: 19,
        backgroundColor: color.withValues(alpha: .11),
        child: Text(initials,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)));
  }
}

class ActivityCover extends StatelessWidget {
  final String category;
  final double height;
  const ActivityCover({super.key, required this.category, this.height = 210});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
            category == 'social'
                ? 'assets/images/activity_social_reference.jpg'
                : 'assets/images/activity_study_reference.jpg',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, error, stack) => Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF0047BA), Color(0xFF4878D7)])),
                child: Icon(
                    category == 'social'
                        ? Icons.local_cafe_outlined
                        : Icons.menu_book_outlined,
                    color: Colors.white,
                    size: 72))),
      ));
}

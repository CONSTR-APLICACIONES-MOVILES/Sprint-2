import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/profile_user.dart';
import 'profile_menu_tile.dart';

class ProfileIdentityCard extends StatelessWidget {
  final ProfileUser user;
  final bool busy;
  final VoidCallback onChangeStatus;

  const ProfileIdentityCard({
    super.key,
    required this.user,
    required this.busy,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user.status == AvailabilityStatus.active;
    return Column(children: [
      Stack(children: [
        Container(
          width: 96,
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: user.photoPath == null
              ? Text(user.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800))
              : Image.file(File(user.photoPath!),
                  width: 96, height: 96, fit: BoxFit.cover),
        ),
        if (user.verified)
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3)),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ]),
      const SizedBox(height: 14),
      Text(user.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(user.program,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
            color: isActive
                ? AppColors.availabilityLight
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle,
              size: 9,
              color: isActive ? AppColors.success : AppColors.friendBusy),
          const SizedBox(width: 8),
          Flexible(
            child: Text(user.statusLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF065F46)
                        : AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: busy ? null : onChangeStatus,
            style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: const StadiumBorder()),
            child: const Text('Change', style: TextStyle(fontSize: 12)),
          ),
        ]),
      ),
    ]);
  }
}

class ProfileAcademicCard extends StatelessWidget {
  final ProfileUser user;
  const ProfileAcademicCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6ECF7))),
        child: Column(children: [
          _row(
            icon: Icons.school_outlined,
            text: '${user.semester}th Semester • ${user.year}',
            trailing: ProfileBadge(user.academicLevelLabel,
                color: AppColors.primary, background: const Color(0xFFE6EEFF)),
          ),
          const SizedBox(height: 12),
          _row(
            icon: Icons.location_on_outlined,
            text: '${user.campus} • ${user.university}',
          ),
          const SizedBox(height: 12),
          _row(
            icon: Icons.badge_outlined,
            text: 'ID: ${user.studentId}',
            trailing: Row(children: [
              Icon(Icons.circle,
                  size: 8,
                  color: user.status == AvailabilityStatus.active
                      ? AppColors.success
                      : AppColors.friendBusy),
              const SizedBox(width: 5),
              Text(user.status == AvailabilityStatus.active ? 'Active' : 'Busy',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ]),
          ),
        ]),
      );

  Widget _row(
          {required IconData icon, required String text, Widget? trailing}) =>
      Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
        if (trailing != null) trailing,
      ]);
}

class ProfileStatsRow extends StatelessWidget {
  final ProfileUser user;
  const ProfileStatsRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) => Row(children: [
        _stat(Icons.event_available_outlined, '${user.plansCompleted}',
            'Plans completed'),
        const SizedBox(width: 10),
        _stat(Icons.groups_outlined, '${user.activeGroups}', 'Active groups'),
        const SizedBox(width: 10),
        _stat(Icons.timer_outlined, '${user.onTimeRate}%', 'On-time rate'),
      ]);

  Widget _stat(IconData icon, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6ECF7))),
          child: Column(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      );
}

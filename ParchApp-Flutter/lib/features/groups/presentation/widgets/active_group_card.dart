import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/active_group.dart';
import '../../domain/entities/response_time_estimate.dart';

class ActiveGroupCard extends StatelessWidget {
  final ActiveGroup group;

  final ResponseTimeEstimate? estimate;
  final bool busy;
  final void Function(GroupAction action) onAction;

  const ActiveGroupCard({
    super.key,
    required this.group,
    this.estimate,
    required this.busy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6ECF7))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: _iconBackground,
                    borderRadius: BorderRadius.circular(11)),
                child: Icon(_icon, size: 20, color: _iconColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(group.memberLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (group.badge != null) _pill(group.badge!),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                  color: _toneBackground,
                  borderRadius: BorderRadius.circular(11)),
              child: Row(children: [
                Icon(Icons.circle, size: 8, color: _toneColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(group.statusText,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _toneColor)),
                ),
                if (group.statusTag != null) ...[
                  const SizedBox(width: 8),
                  Text(group.statusTag!,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _toneColor)),
                ],
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.event_outlined,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(group.detail,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textPrimary)),
              ),
            ]),
            if (group.hasProgress) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Text(group.progressLabel ?? 'Progress',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ),
                Text('${group.progressCurrent} of ${group.progressTotal} needed',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: group.progressValue,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE8EDF6),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.warning),
                ),
              ),
              if (estimate != null) _ResponseTimeHint(group, estimate!),
            ],
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _actionButton(group.primaryAction, true)),
              const SizedBox(width: 9),
              Expanded(child: _actionButton(group.secondaryAction, false)),
            ]),
          ],
        ),
      );

  Widget _actionButton(GroupAction action, bool primary) {
    final label = _actionLabel(action);
    final icon = _actionIcon(action);
    if (primary) {
      return FilledButton.icon(
        onPressed: busy ? null : () => onAction(action),
        icon: Icon(icon, size: 16),
        style: FilledButton.styleFrom(
            backgroundColor: _primaryButtonColor,
            minimumSize: const Size.fromHeight(40),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11))),
        label: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5)),
      );
    }
    return OutlinedButton.icon(
      onPressed: busy ? null : () => onAction(action),
      icon: Icon(icon, size: 16),
      style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: const Color(0xFFEEF4FF),
          side: const BorderSide(color: Color(0xFFD8E2FF)),
          minimumSize: const Size.fromHeight(40),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
      label: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5)),
    );
  }

  Color get _primaryButtonColor => switch (group.primaryAction) {
        GroupAction.voteRsvp => AppColors.success,
        GroupAction.dropIn => const Color(0xFFDB2777),
        _ => AppColors.primary,
      };

  IconData get _icon => switch (group.category) {
        GroupCategory.study => Icons.school_outlined,
        GroupCategory.socialLiving => Icons.home_outlined,
        GroupCategory.sports => Icons.sports_soccer_outlined,
      };

  Color get _iconColor => switch (group.category) {
        GroupCategory.study => AppColors.primary,
        GroupCategory.socialLiving => AppColors.warning,
        GroupCategory.sports => const Color(0xFFDB2777),
      };

  Color get _iconBackground => switch (group.category) {
        GroupCategory.study => const Color(0xFFEEF4FF),
        GroupCategory.socialLiving => const Color(0xFFFEF6E7),
        GroupCategory.sports => const Color(0xFFFCE7F3),
      };

  Color get _toneColor => switch (group.tone) {
        GroupTone.info => AppColors.primary,
        GroupTone.success => const Color(0xFF065F46),
        GroupTone.warning => const Color(0xFF92400E),
        GroupTone.casual => const Color(0xFFBE185D),
      };

  Color get _toneBackground => switch (group.tone) {
        GroupTone.info => const Color(0xFFEEF4FF),
        GroupTone.success => AppColors.availabilityLight,
        GroupTone.warning => const Color(0xFFFEF6E7),
        GroupTone.casual => const Color(0xFFFCE7F3),
      };

  Widget _pill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: _toneBackground, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: _toneColor, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

String _actionLabel(GroupAction action) => switch (action) {
      GroupAction.openChat => 'Open Chat',
      GroupAction.viewSchedule => 'View Schedule',
      GroupAction.roommateSync => 'Roommate Sync',
      GroupAction.viewNotes => 'View Notes',
      GroupAction.voteRsvp => 'Vote RSVP',
      GroupAction.teamChat => 'Team Chat',
      GroupAction.dropIn => 'Drop In',
      GroupAction.chat => 'Chat',
    };

IconData _actionIcon(GroupAction action) => switch (action) {
      GroupAction.openChat => Icons.chat_bubble_outline,
      GroupAction.viewSchedule => Icons.schedule,
      GroupAction.roommateSync => Icons.sync_alt,
      GroupAction.viewNotes => Icons.description_outlined,
      GroupAction.voteRsvp => Icons.check,
      GroupAction.teamChat => Icons.forum_outlined,
      GroupAction.dropIn => Icons.location_on_outlined,
      GroupAction.chat => Icons.chat_bubble_outline,
    };
class _ResponseTimeHint extends StatelessWidget {
  final ActiveGroup group;
  final ResponseTimeEstimate estimate;
  const _ResponseTimeHint(this.group, this.estimate);

  @override
  Widget build(BuildContext context) {
    final complete = group.progressCurrent! >= group.progressTotal!;
    final text = switch (estimate.kind) {
      EstimateKind.allResponded =>
        'Groups of ${estimate.groupSize} usually all reply within ~${estimate.durationLabel}',
      EstimateKind.perResponse =>
        'Members of groups of ${estimate.groupSize} usually reply in ~${estimate.durationLabel}',
    };
    final expectedAt = group.invitationSentAt?.add(estimate.duration);
    final late = expectedAt != null && DateTime.now().isAfter(expectedAt);
    final detail = complete || expectedAt == null
        ? null
        : estimate.kind != EstimateKind.allResponded
            ? null
            : late
                ? 'Taking longer than usual — a reminder may help'
                : 'Everyone should have replied by ${TimeOfDay.fromDateTime(expectedAt).format(context)}';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(late && !complete ? Icons.hourglass_bottom : Icons.schedule,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(text: text, children: [
              if (detail != null)
                TextSpan(
                    text: '\n$detail',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: late
                            ? const Color(0xFF92400E)
                            : AppColors.primary)),
            ]),
            key: const ValueKey('bq5-estimate'),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary, height: 1.35),
          ),
        ),
      ]),
    );
  }
}

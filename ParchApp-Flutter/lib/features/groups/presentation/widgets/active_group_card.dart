import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/active_group.dart';
import '../../domain/entities/response_time_estimate.dart';
import '../../domain/entities/activity_weather.dart';
import '../../domain/entities/weather_forecast.dart';
import '../../domain/use_cases/activity_timing.dart';

class ActiveGroupCard extends StatelessWidget {
  final ActiveGroup group;

  final ResponseTimeEstimate? estimate;
  final ActivityWeather? weather;
  final bool busy;
  final void Function(GroupAction action) onAction;

  const ActiveGroupCard({
    super.key,
    required this.group,
    this.estimate,
    this.weather,
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
              if (_timing != null) ...[
                const SizedBox(width: 8),
                Text(_timing!,
                    key: const ValueKey('activity-timing'),
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _soon ? AppColors.warning : AppColors.primary)),
              ],
            ]),
            if (group.hasProgress) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Text(group.progressLabel ?? 'Progress',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ),
                Text(
                    group.activityAttendance
                        ? '${group.progressCurrent} of ${group.progressTotal} accepted'
                        : '${group.progressCurrent} of ${group.progressTotal} needed',
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
                  valueColor: AlwaysStoppedAnimation(group.progressValue >= 1
                      ? AppColors.success
                      : AppColors.warning),
                ),
              ),
              estimate != null
                  ? _ResponseTimeHint(group, estimate!)
                  : const _ResponseTimeLearning(),
            ],
            if (weather != null)
              _WeatherHint(weather!,
                  outdoor: group.category == GroupCategory.sports),
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
    final label = action == GroupAction.voteRsvp && group.activityAttendance
        ? 'View invitation'
        : _actionLabel(action);
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

  String? get _timing =>
      ActivityTiming.label(group.activityStartsAt, DateTime.now());

  bool get _soon => ActivityTiming.isSoon(group.activityStartsAt, DateTime.now());

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
      GroupAction.viewDetails => 'View group',
      GroupAction.roommateSync => 'Roommate Sync',
      GroupAction.viewNotes => 'View Notes',
      GroupAction.voteRsvp => 'Confirm attendance',
      GroupAction.teamChat => 'Team Chat',
      GroupAction.dropIn => 'Drop In',
      GroupAction.chat => 'Chat',
    };

IconData _actionIcon(GroupAction action) => switch (action) {
      GroupAction.openChat => Icons.chat_bubble_outline,
      GroupAction.viewSchedule => Icons.schedule,
      GroupAction.viewDetails => Icons.groups_outlined,
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
      EstimateKind.allResponded => 'All reply in ~${estimate.durationLabel}',
      EstimateKind.perResponse => 'Each replies in ~${estimate.durationLabel}',
    };
    final expectedAt = group.invitationSentAt?.add(estimate.duration);
    final late = expectedAt != null && DateTime.now().isAfter(expectedAt);
    final detail = complete || expectedAt == null
        ? null
        : estimate.kind != EstimateKind.allResponded
            ? null
            : late
                ? 'Slower than usual · send a reminder'
                : 'Expected by ${TimeOfDay.fromDateTime(expectedAt).format(context)}';

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

class _ResponseTimeLearning extends StatelessWidget {
  const _ResponseTimeLearning();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Row(children: [
          Icon(Icons.insights_outlined,
              size: 14, color: AppColors.textSecondary),
          SizedBox(width: 6),
          Text('Reply estimate coming soon',
              key: ValueKey('bq5-learning'),
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );
}

class _WeatherHint extends StatelessWidget {
  final ActivityWeather weather;
  final bool outdoor;
  const _WeatherHint(this.weather, {required this.outdoor});

  @override
  Widget build(BuildContext context) {
    final forecast = weather.forecast;
    final bad = forecast.bad;
    final better = weather.betterHour;
    final advice = better != null
        ? '${TimeOfDay.fromDateTime(better.time.toLocal()).format(context)} is better: ${weather.reason}'
        : weather.noBetterTime
            ? (outdoor
                ? 'No drier time nearby · plan indoors or another day'
                : 'No drier time nearby · bring an umbrella')
            : null;
    final color = bad ? const Color(0xFF92400E) : AppColors.primary;
    return Container(
      key: const ValueKey('activity-weather'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
          color: bad ? const Color(0xFFFEF6E7) : const Color(0xFFEEF4FF),
          borderRadius: BorderRadius.circular(11)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_icon(forecast),
              size: 16, color: bad ? AppColors.warning : AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${forecast.label} at the activity time',
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
          ),
        ]),
        if (advice != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(
                better != null
                    ? Icons.lightbulb_outline
                    : Icons.umbrella_outlined,
                size: 15,
                color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(advice,
                  key: const ValueKey('weather-advice'),
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ),
          ]),
        ],
      ]),
    );
  }

  IconData _icon(WeatherForecast forecast) => switch (forecast.weatherCode) {
        0 => Icons.wb_sunny_outlined,
        >= 95 => Icons.thunderstorm_outlined,
        _ when forecast.rainLikely => Icons.umbrella_outlined,
        _ => Icons.cloud_outlined,
      };
}

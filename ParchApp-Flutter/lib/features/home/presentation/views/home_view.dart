import '../../domain/entities/quick_status.dart';
import '../../../../shared/widgets/parch_visuals.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_app_bar.dart';
import '../../../../shared/widgets/parch_navigation_bar.dart';
import '../../../activities/domain/entities/activity_summary.dart';
import '../../../activities/presentation/view_models/activity_list_view_model.dart';
import '../../../alerts/presentation/view_models/alerts_state.dart';
import '../../../groups/presentation/view_models/active_groups_state.dart';
import '../../../profile/domain/entities/profile_user.dart';
import 'home_preview_view.dart';
import '../../../../shared/widgets/data_freshness_banner.dart';

class HomeView extends StatelessWidget {
  final ActivityListState? activityState;
  final ActiveGroupsState? groupsState;
  final AlertsState? alertsState;
  final ProfileUser? profile;
  final String? profileError;
  final bool profileLoading;
  final Future<void> Function()? onRefreshActivities;
  final VoidCallback? onManageStatus, onEditQuickStatus;
  final QuickStatus quickStatus;
  final String? demoStudySessionId, userName, userInitials;
  final int? groupCount;
  const HomeView(
      {super.key,
      this.activityState,
      this.groupsState,
      this.alertsState,
      this.profile,
      this.profileError,
      this.profileLoading = false,
      this.onRefreshActivities,
      this.onManageStatus,
      this.onEditQuickStatus,
      this.quickStatus = const QuickStatus(),
      this.demoStudySessionId,
      this.userName,
      this.userInitials,
      this.groupCount});

  @override
  Widget build(BuildContext context) {
    if (demoStudySessionId != null) {
      return HomePreviewView(demoStudySessionId: demoStudySessionId);
    }
    final activities = activityState,
        groups = groupsState,
        alerts = alertsState;
    final unread = profile?.preferences.invitationBadges == false
        ? null
        : alerts != null && !alerts.isLoading && alerts.error == null
            ? alerts.unreadCount
            : null;
    return Scaffold(
      appBar: ParchAppBar(
          initials: profile?.initials ?? userInitials,
          unreadCount: unread,
          onReturn: onRefreshActivities),
      body: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
              onRefresh: onRefreshActivities ?? () async {},
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                  spacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                        'Hello, ${profile?.name ?? userName ?? 'there'}! 👋',
                                        style: const TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary)),
                                    if (profile != null)
                                      ActionChip(
                                        key: const ValueKey(
                                            'availability-status-bubble'),
                                        avatar: Icon(Icons.circle,
                                            size: 12,
                                            color: profile!.effectiveStatus ==
                                                    AvailabilityStatus.active
                                                ? Colors.green
                                                : profile!.effectiveStatus ==
                                                        AvailabilityStatus
                                                            .offline
                                                    ? Colors.grey
                                                    : Colors.orange),
                                        label: Text(profile!.effectiveStatus ==
                                                AvailabilityStatus.active
                                            ? 'Available now'
                                            : profile!.effectiveStatus.label),
                                        tooltip: 'Change availability status',
                                        onPressed: profileLoading
                                            ? null
                                            : onManageStatus,
                                      ),
                                  ]),
                              const SizedBox(height: 4),
                              const Text('Make time for your people.'),
                              const SizedBox(height: 20),
                              if (profile != null) ...[
                                _card(context,
                                    icon: Icons.share_outlined,
                                    title: 'Invite Friends to Sync',
                                    subtitle:
                                        'Share your profile with people in your groups.',
                                    action: 'Share profile',
                                    onTap: () => _open(context,
                                        '/share/profile/${Uri.encodeComponent(profile!.id)}')),
                                const SizedBox(height: 16),
                              ],
                              _quickStatus(context),
                              if (profile != null)
                                DataFreshnessBanner(
                                    freshness: profile!.freshness),
                              if (profileError != null) _retry(profileError!),
                              const SizedBox(height: 22),
                              _heading(
                                  context,
                                  'Your Activities',
                                  'View calendar',
                                  () => context.go(AppRoutes.schedule)),
                              if (activities?.loading == true)
                                const LinearProgressIndicator(
                                    semanticsLabel: 'Loading activities'),
                              if (activities?.error != null)
                                _retry(activities!.error!),
                              if (activities != null &&
                                  activities.activities.isNotEmpty)
                                DataFreshnessBanner(
                                    freshness:
                                        activities.activities.first.freshness),
                              if (activities != null &&
                                  !activities.loading &&
                                  activities.error == null)
                                Text(
                                    '${activities.activities.length} activities in your groups'),
                              const SizedBox(height: 12),
                              if (activities == null)
                                const Text('Activities unavailable.')
                              else if (!activities.loading &&
                                  activities.error == null &&
                                  activities.activities.isEmpty)
                                _card(context,
                                    icon: Icons.event_outlined,
                                    title: 'No activities in your groups yet.',
                                    subtitle: 'Start a plan with your group.',
                                    action: 'New Activity',
                                    onTap: () => _open(
                                        context, AppRoutes.createActivity)),
                              for (final activity in activities?.activities ??
                                  <ActivitySummary>[])
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _activity(context, activity)),
                              const SizedBox(height: 18),
                              ParchSurface(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.mail_outline,
                                          color: AppColors.primary),
                                      title: const Text('Your invitations',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                      subtitle: Text(
                                          alerts?.isLoading == true
                                              ? 'Loading invitations…'
                                              : alerts?.error != null
                                                  ? 'Unable to refresh invitations.'
                                                  : unread == null
                                                      ? 'Open your inbox to view invitations.'
                                                      : unread == 0
                                                          ? 'You are all caught up.'
                                                          : '$unread unread alerts in your inbox',
                                          style: const TextStyle(fontSize: 11)),
                                      trailing: const Icon(Icons.chevron_right,
                                          color: AppColors.primary),
                                      onTap: () =>
                                          _open(context, AppRoutes.alerts))),
                              if (alerts?.error != null) _retry(alerts!.error!),
                              const SizedBox(height: 24),
                              _heading(
                                  context,
                                  'Your Active Groups',
                                  'View all',
                                  () => context.go(AppRoutes.groups)),
                              if (groups?.isLoading == true)
                                const LinearProgressIndicator(
                                    semanticsLabel: 'Loading groups'),
                              if (groups?.error != null) _retry(groups!.error!),
                              if (groups == null)
                                const Text('Groups unavailable.')
                              else if (!groups.isLoading &&
                                  groups.error == null &&
                                  groups.groups.isEmpty)
                                const Text('No active groups yet.'),
                              if (groups != null)
                                for (final group in groups.groups)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _card(context,
                                          icon: Icons.groups_outlined,
                                          title: group.name,
                                          subtitle:
                                              '${group.memberCount} members',
                                          description: group.activityAttendance
                                              ? '${group.detail} · ${group.statusText}'
                                              : group.detail.isEmpty
                                                  ? null
                                                  : group.detail,
                                          action: 'View group',
                                          onTap: () => _open(
                                              context,
                                              AppRoutes.groupDetails(
                                                  group.id)))),
                            ]))),
              ))),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _open(context, AppRoutes.createActivity),
          icon: const Icon(Icons.add),
          label: const Text('New Activity')),
      bottomNavigationBar: const ParchNavigationBar(),
    );
  }

  String _nextActivity() {
    final now = DateTime.now();
    final plans = (activityState?.activities ?? <ActivitySummary>[])
        .where((a) =>
            !a.cancelled && a.startsAt != null && a.startsAt!.isAfter(now))
        .toList()
      ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
    return plans.isNotEmpty
        ? plans.first.title
        : quickStatus.nextActivity.isEmpty
            ? 'Set your next activity'
            : quickStatus.nextActivity;
  }

  Widget _quickStatus(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x240047BA),
                  blurRadius: 18,
                  offset: Offset(0, 7))
            ]),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .17),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.bolt_rounded, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('QUICK STATUS',
                      style: TextStyle(
                          color: Color(0xFFC5DCFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7)),
                  Text(
                      profileLoading
                          ? 'Loading your status…'
                          : profile == null
                              ? 'Status unavailable.'
                              : profile!.effectiveStatus ==
                                      AvailabilityStatus.active
                                  ? 'Available Now'
                                  : profile!.effectiveStatus.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ]))
          ]),
          const SizedBox(height: 12),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .16))),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('FREE UNTIL',
                          style: TextStyle(
                              color: Color(0xFFC5DCFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                          quickStatus.freeUntil.isEmpty
                              ? 'Set your free time'
                              : quickStatus.freeUntil,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ])),
                IconButton(
                    tooltip: 'Edit quick status',
                    onPressed: onEditQuickStatus,
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 19))
              ])),
          const SizedBox(height: 10),
          const Text('NEXT ACTIVITY',
              style: TextStyle(
                  color: Color(0xFFC5DCFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
          Text(_nextActivity(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 46)),
              onPressed: () => _open(context, AppRoutes.schedule),
              icon: const Icon(Icons.bolt, size: 18),
              label: const Text('Compare availability')),
          const SizedBox(height: 8),
          const Text(
              'Profile status · Calendar availability is compared separately.',
              style: TextStyle(color: Color(0xFFD6E5FF), fontSize: 10)),
        ]),
      );

  Widget _activity(BuildContext context, ActivitySummary activity) {
    final total = activity.attendance['total'] ?? 0,
        accepted = activity.attendance['accepted'] ?? 0;
    return InkWell(
        onTap: () => _open(context, AppRoutes.studySession(activity.id)),
        borderRadius: BorderRadius.circular(22),
        child: ParchSurface(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: ParchPill(
                      activity.cancelled
                          ? 'Cancelled'
                          : activity.confirmed
                              ? 'Confirmed'
                              : 'Proposed',
                      color: activity.cancelled
                          ? AppColors.error
                          : activity.confirmed
                              ? AppColors.success
                              : AppColors.warning,
                      icon: activity.cancelled
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline)),
              const SizedBox(height: 14),
              Text(activity.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _logistic(Icons.schedule, _timeLabel(activity)),
              const SizedBox(height: 8),
              _logistic(
                  Icons.location_on_outlined,
                  activity.location.isEmpty
                      ? 'Location not set'
                      : activity.location),
              if (total > 0) ...[
                const SizedBox(height: 16),
                ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: accepted / total,
                        minHeight: 5,
                        color: AppColors.success,
                        backgroundColor: AppColors.blueTint)),
                const SizedBox(height: 8),
                Text(
                    '$accepted accepted · ${activity.attendance['maybe'] ?? 0} maybe · ${activity.attendance['declined'] ?? 0} declined',
                    style: const TextStyle(fontSize: 12))
              ],
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () =>
                          _open(context, AppRoutes.studySession(activity.id)),
                      child: const Text('View activity'))),
            ])));
  }

  Widget _logistic(IconData icon, String text) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13)))
      ]);
  Future<void> _open(BuildContext context, String route) async {
    await context.push(route);
    if (context.mounted) await onRefreshActivities?.call();
  }

  String _timeLabel(ActivitySummary activity) {
    if (activity.startsAt != null && activity.endsAt != null) {
      final start =
              activity.startsAt!.toUtc().subtract(const Duration(hours: 5)),
          end = activity.endsAt!.toUtc().subtract(const Duration(hours: 5));
      String time(DateTime v) =>
          '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';
      return '${start.day}/${start.month}/${start.year} · ${time(start)} – ${time(end)} · Bogotá';
    }
    final proposed = '${activity.date} ${activity.time}'.trim();
    return proposed.isEmpty ? 'Not scheduled' : 'Proposed time: $proposed';
  }

  Widget _retry(String message) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message, style: const TextStyle(color: AppColors.error)),
        TextButton(onPressed: onRefreshActivities, child: const Text('Retry'))
      ]));
  Widget _heading(BuildContext context, String title, String action,
          VoidCallback onTap) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
                TextButton(onPressed: onTap, child: Text(action))
              ]));
  Widget _card(BuildContext context,
          {required IconData icon,
          required String title,
          required String subtitle,
          required String action,
          required VoidCallback onTap,
          String? description}) =>
      ParchSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.blueTint,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: AppColors.primary, size: 21)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle)
              ]))
        ]),
        if (description != null)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(description)),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onTap, child: Text(action))),
      ]));
}

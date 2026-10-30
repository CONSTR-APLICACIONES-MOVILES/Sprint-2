import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/inline_error_notice.dart';
import '../../../../shared/widgets/parch_visuals.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/parch_app_bar.dart';
import '../../../alerts/domain/entities/app_alert.dart';
import '../view_models/activity_invitation_view_model.dart';

class ActivityInvitationView extends StatefulWidget {
  final ActivityInvitationViewModel viewModel;
  const ActivityInvitationView({super.key, required this.viewModel});
  @override
  State<ActivityInvitationView> createState() => _ActivityInvitationViewState();
}

class _ActivityInvitationViewState extends State<ActivityInvitationView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void didUpdateWidget(covariant ActivityInvitationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.dispose();
      widget.viewModel.load();
    }
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<
          ActivityInvitationState>(
      valueListenable: widget.viewModel,
      builder: (context, state, _) {
        final session = state.session;
        final blocked = state.loading ||
            state.saving ||
            session?.cancelled != false ||
            state.invitation?.pendingSync == true;
        Widget feedback() =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (state.acknowledgement != null)
                Text(state.acknowledgement!,
                    style: const TextStyle(
                        color: AppColors.success, fontWeight: FontWeight.w600)),
              if (state.invitation?.response != null)
                Text(
                    'Your response: ${state.invitation!.response!.name}${state.invitation!.pendingSync ? ' · Pending sync' : ''}'),
              if (state.error != null) InlineErrorNotice(state.error!),
            ]);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const ParchAppBar(title: 'Invitation', showBack: true),
          bottomNavigationBar: state.invitation == null
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                              top: BorderSide(color: AppColors.outlineSoft))),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        if (state.acknowledgement != null ||
                            state.error != null ||
                            state.invitation?.response != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: feedback()),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      minimumSize: const Size(0, 52),
                                      side: const BorderSide(
                                          color: AppColors.error),
                                      shape: const StadiumBorder()),
                                  onPressed: blocked
                                      ? null
                                      : () => widget.viewModel
                                          .respond(AlertResponse.declined),
                                  child: const Text('Can’t attend',
                                      textAlign: TextAlign.center))),
                          const SizedBox(width: 12),
                          Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF008342),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 52),
                                      shape: const StadiumBorder()),
                                  onPressed: blocked
                                      ? null
                                      : () => widget.viewModel
                                          .respond(AlertResponse.accepted),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Join')))
                        ]),
                        TextButton(
                            onPressed: blocked
                                ? null
                                : () => widget.viewModel
                                    .respond(AlertResponse.maybe),
                            child: const Text('Maybe')),
                      ]))),
          body: SafeArea(
              child: RefreshIndicator(
                  onRefresh: widget.viewModel.load,
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      children: [
                        if (state.loading || state.saving)
                          const LinearProgressIndicator(),
                        if (session != null) ...[
                          ActivityCover(
                              category: session.category, height: 240),
                          Transform.translate(
                              offset: const Offset(0, -22),
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: ParchSurface(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                        Wrap(
                                            alignment:
                                                WrapAlignment.spaceBetween,
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              ParchPill(session.category,
                                                  icon: session.category ==
                                                          'social'
                                                      ? Icons
                                                          .local_cafe_outlined
                                                      : Icons
                                                          .menu_book_outlined),
                                              if (session.cancelled)
                                                const ParchPill('Cancelled',
                                                    color: AppColors.error)
                                            ]),
                                        const SizedBox(height: 12),
                                        Text(session.title,
                                            style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary)),
                                        const SizedBox(height: 18),
                                        _logistic(
                                            Icons.calendar_month_outlined,
                                            session.startsAt == null
                                                ? 'Not scheduled'
                                                : MaterialLocalizations.of(
                                                        context)
                                                    .formatFullDate(
                                                        session.displayTime(
                                                            session.startsAt!)),
                                            session.startsAt == null ||
                                                    session.endsAt == null
                                                ? '${session.legacyDate} ${session.legacyTime}'
                                                    .trim()
                                                : '${TimeOfDay.fromDateTime(session.displayTime(session.startsAt!)).format(context)} – ${TimeOfDay.fromDateTime(session.displayTime(session.endsAt!)).format(context)} · Bogotá'),
                                        const SizedBox(height: 16),
                                        _logistic(
                                            Icons.location_on_outlined,
                                            session.location.isEmpty
                                                ? 'Location not set'
                                                : session.location,
                                            session.description),
                                      ])))),
                          ParchSurface(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                const Text("Who's Invited",
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17)),
                                const SizedBox(height: 14),
                                Wrap(spacing: 7, runSpacing: 8, children: [
                                  for (var i = 0;
                                      i < session.participants.length;
                                      i++)
                                    Tooltip(
                                        message: session.participants[i].name,
                                        child: ParchAvatar(
                                            session.participants[i].name,
                                            index: i))
                                ]),
                                const SizedBox(height: 12),
                                for (final person in session.participants)
                                  ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(person.name),
                                      subtitle: Text(person.leader
                                          ? 'Organizer'
                                          : person.status))
                              ])),
                          const SizedBox(height: 16),
                          ParchSurface(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                const Text('Response Status',
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                const Text('Attendance (last loaded)'),
                                const SizedBox(height: 10),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  ParchPill(
                                      '${session.participants.where((p) => p.response == 'accepted').length} accepted',
                                      color: AppColors.success),
                                  ParchPill(
                                      '${session.participants.where((p) => p.response == 'maybe').length} maybe',
                                      color: AppColors.warning),
                                  ParchPill(
                                      '${session.participants.where((p) => p.response == 'declined').length} declined',
                                      color: AppColors.error)
                                ]),
                                const SizedBox(height: 12)
                              ])),
                        ] else
                          feedback(),
                        TextButton(
                            onPressed:
                                state.saving ? null : widget.viewModel.load,
                            child: const Text('Reload invitation')),
                        if (state.invitation == null &&
                            !state.loading &&
                            session?.cancelled != true)
                          OutlinedButton(
                              onPressed: session == null
                                  ? null
                                  : () async {
                                      await context.push(
                                          '/activities/${Uri.encodeComponent(widget.viewModel.activityId)}/participants');
                                      if (mounted) {
                                        await widget.viewModel.load();
                                      }
                                    },
                              child: const Text('Join activity')),
                        TextButton(
                            onPressed: () => context.push(
                                AppRoutes.studySession(
                                    widget.viewModel.activityId)),
                            child: const Text('Activity Details')),
                      ]))),
        );
      });
  Widget _logistic(IconData icon, String title, String subtitle) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
                color: AppColors.blueTint, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 22)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13))
          ]
        ]))
      ]);
}

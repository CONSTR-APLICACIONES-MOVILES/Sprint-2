import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_navigation_bar.dart';
import '../../domain/entities/study_session.dart';
import '../view_models/study_session_view_model.dart';
import '../widgets/edit_session_sheet.dart';
import '../widgets/session_card.dart';

class StudySessionView extends StatefulWidget {
  final StudySessionViewModel viewModel;
  const StudySessionView({super.key, required this.viewModel});
  @override
  State<StudySessionView> createState() => _StudySessionViewState();
}

class _StudySessionViewState extends State<StudySessionView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void didUpdateWidget(covariant StudySessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) widget.viewModel.load();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _sheet(String title, Widget content) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        constraints: BoxConstraints(
            maxWidth: 600, maxHeight: MediaQuery.sizeOf(context).height * .9),
        builder: (context) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  content,
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close')),
                ])),
      );

  Future<void> _edit(StudySession session) => showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        constraints: BoxConstraints(
            maxWidth: 600, maxHeight: MediaQuery.sizeOf(context).height * .9),
        builder: (_) => EditSessionSheet(
            session: session,
            onSave: (draft) async {
              final success = await widget.viewModel.update(
                  title: draft.title,
                  room: draft.room,
                  startsAt: draft.startsAt,
                  endsAt: draft.endsAt);
              return success
                  ? null
                  : widget.viewModel.value.error ?? 'Unable to save changes.';
            }),
      );

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Cancel this study session?'),
              content: const Text(
                  'This cancels the demo session on this device. No room reservation is released and no notifications are sent.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Keep Session')),
                FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Confirm cancellation')),
              ],
            ));
    if (mounted && confirmed == true) await widget.viewModel.cancel();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<StudySessionState>(
        valueListenable: widget.viewModel,
        builder: (context, state, _) => Scaffold(
          backgroundColor: const Color(0xFFF8FAFE),
          appBar: AppBar(
            leading: IconButton(
                tooltip: 'Back',
                onPressed: _back,
                icon: const Icon(Icons.arrow_back)),
            title: const Text('ParchApp',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                  tooltip: 'Alerts',
                  onPressed: () => context.push(AppRoutes.alerts),
                  icon: const Icon(Icons.notifications_outlined))
            ],
          ),
          body: SafeArea(top: false, bottom: false, child: _body(state)),
          bottomNavigationBar:
              Column(mainAxisSize: MainAxisSize.min, children: [
            if (state.session != null)
              SafeArea(
                  top: false,
                  bottom: false,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed:
                                  state.saving || state.session!.cancelled
                                      ? null
                                      : _cancel,
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  minimumSize: const Size(0, 48)),
                              child: const Text('Cancel'))),
                      const SizedBox(width: 12),
                      Expanded(
                          flex: 2,
                          child: FilledButton(
                              onPressed:
                                  state.saving || state.session!.cancelled
                                      ? null
                                      : () => _edit(state.session!),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 48)),
                              child: const Text('Modify Session',
                                  textAlign: TextAlign.center))),
                    ]),
                  )),
            const ParchNavigationBar(selectedIndex: 2),
          ]),
        ),
      );

  Widget _body(StudySessionState state) {
    if (state.status == SessionLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.session == null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.event_busy, size: 48),
                const SizedBox(height: 16),
                Text(
                    state.status == SessionLoadStatus.notFound
                        ? 'Session not found.'
                        : state.error!,
                    textAlign: TextAlign.center),
                TextButton(
                    onPressed: widget.viewModel.load,
                    child: const Text('Retry')),
                TextButton(onPressed: _back, child: const Text('Back to Home')),
              ])));
    }
    final session = state.session!;
    final done = session.topics.where((topic) => topic.completed).length;
    final blocked = state.saving || session.cancelled;
    final date =
        MaterialLocalizations.of(context).formatFullDate(session.startsAt);
    final time =
        '${TimeOfDay.fromDateTime(session.startsAt).format(context)} – ${TimeOfDay.fromDateTime(session.endsAt).format(context)}';
    return RefreshIndicator(
        onRefresh: widget.viewModel.load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.saving) const LinearProgressIndicator(),
                  if (state.error != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(state.error!,
                            style: const TextStyle(color: AppColors.error))),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Chip(
                        avatar: Icon(
                            session.cancelled
                                ? Icons.cancel_outlined
                                : Icons.check_circle,
                            color: session.cancelled
                                ? AppColors.error
                                : AppColors.success),
                        label: Text(session.cancelled
                            ? 'Cancelled'
                            : 'Confirmed • ${session.participants.length}/${session.participants.length} ready')),
                    const Chip(label: Text('Demo • saved in memory')),
                  ]),
                  const SizedBox(height: 12),
                  SessionCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Wrap(spacing: 8, runSpacing: 8, children: [
                          Chip(label: Text('Group Study')),
                          Chip(label: Text('Midterm Exam #2'))
                        ]),
                        const SizedBox(height: 12),
                        Text(session.title,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.15)),
                        const SizedBox(height: 12),
                        Text(session.description,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 20),
                        _info(Icons.calendar_month_outlined, date),
                        const SizedBox(height: 12),
                        _info(Icons.schedule, time),
                      ])),
                  SessionCard(
                      title: session.location,
                      icon: Icons.apartment,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(session.room,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(16)),
                                child: const Column(children: [
                                  Icon(Icons.local_library_outlined,
                                      size: 48, color: AppColors.primary),
                                  SizedBox(height: 12),
                                  Text('North Library Gate',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text('Campus location preview',
                                      textAlign: TextAlign.center)
                                ])),
                            const SizedBox(height: 12),
                            Wrap(spacing: 12, runSpacing: 8, children: [
                              TextButton.icon(
                                  onPressed: () => _sheet(
                                      'Campus Walking Route',
                                      const Text(
                                          'Walking directions require a connected maps provider. No live location is being read.')),
                                  icon: const Icon(Icons.directions_walk),
                                  label: const Text('Route')),
                              TextButton.icon(
                                  onPressed: () => _sheet(
                                      'Study room',
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(session.location),
                                            Text(session.room),
                                            const SizedBox(height: 16),
                                            const Text(
                                                'Room reservations and access codes are not connected.')
                                          ])),
                                  icon: const Icon(Icons.meeting_room_outlined),
                                  label: const Text('View room')),
                            ]),
                          ])),
                  SessionCard(
                      title: 'Topics & Objectives',
                      icon: Icons.assignment_outlined,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('$done / ${session.topics.length} completed',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            for (final topic in session.topics)
                              CheckboxListTile(
                                key: ValueKey('topic-${topic.id}'),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: topic.completed,
                                activeColor: AppColors.success,
                                onChanged: blocked
                                    ? null
                                    : (_) =>
                                        widget.viewModel.toggleTopic(topic.id),
                                title: Text(topic.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        decoration: topic.completed
                                            ? TextDecoration.lineThrough
                                            : null)),
                                subtitle: Text(
                                    '${topic.completed ? 'Completed' : 'Pending'}\n${topic.objective}'),
                              ),
                          ])),
                  SessionCard(
                      title: 'Participants (${session.participants.length})',
                      icon: Icons.people_outline,
                      trailing: IconButton(
                          tooltip: 'Invite classmate',
                          onPressed: blocked
                              ? null
                              : () => _sheet(
                                  'Invite Classmate',
                                  const Text(
                                      'Invitations will be available when the backend is connected. No invitation has been sent.')),
                          icon: const Icon(Icons.person_add_alt)),
                      child: Column(children: [
                        for (final person in session.participants)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEFF4FF),
                                child: Text(person.initials)),
                            title: Text(
                                '${person.name}${person.leader ? ' • Leader' : ''}'),
                            subtitle:
                                Text('${person.program}\n${person.status}'),
                            isThreeLine: true,
                            onTap: () => _sheet(
                                person.name,
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(person.program),
                                      Text(person.status),
                                      const SizedBox(height: 16),
                                      const Text(
                                          'Direct messages are not connected yet.'),
                                    ])),
                          )
                      ])),
                  SessionCard(
                      title: 'Logistics & Shared Resources',
                      icon: Icons.folder_shared_outlined,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Wrap(spacing: 8, runSpacing: 8, children: [
                              Chip(
                                  avatar: Icon(Icons.wifi),
                                  label: Text('Eduroam Wi-Fi')),
                              Chip(
                                  avatar: Icon(Icons.power_outlined),
                                  label: Text('4 outlets • USB-C'))
                            ]),
                            const Text(
                                'Room amenities from the demo listing; connectivity is not measured.',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            for (final resource in session.resources)
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                      Icons.description_outlined,
                                      color: AppColors.primary),
                                  title: Text(resource.title),
                                  subtitle: Text(resource.description),
                                  onTap: () => _sheet(
                                      resource.title,
                                      const Text(
                                          'Resource preview. No file URL is configured and nothing has been downloaded.'))),
                            const SizedBox(height: 16),
                            Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text('Reminder: ${session.reminder}')),
                          ])),
                ]),
          )),
        ));
  }

  Widget _info(IconData icon, String text) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(text))
      ]);
}

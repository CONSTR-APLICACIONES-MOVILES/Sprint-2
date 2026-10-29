import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parch_visuals.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/parch_app_bar.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/repositories/study_sessions_repository.dart';

class ActivityResultView extends StatefulWidget {
  final String activityId;
  final StudySessionsRepository repository;
  final bool scheduleCard;
  final bool acknowledged;
  const ActivityResultView(
      {super.key,
      required this.activityId,
      required this.repository,
      this.scheduleCard = false,
      this.acknowledged = false});
  @override
  State<ActivityResultView> createState() => _ActivityResultViewState();
}

class _ActivityResultViewState extends State<ActivityResultView> {
  late Future<StudySession?> _result = _read();
  Future<StudySession?> _read() async {
    try {
      return await widget.repository.getById(widget.activityId);
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant ActivityResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityId != widget.activityId ||
        oldWidget.repository != widget.repository) {
      _result = _read();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = FutureBuilder<StudySession?>(
        future: _result,
        builder: (context, snapshot) {
          final session = snapshot.data;
          return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.scheduleCard)
                      Column(children: [
                        if (widget.acknowledged) ...[
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                  color: Color(0xFFE5FAF0),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded,
                                  color: AppColors.success, size: 42)),
                          const SizedBox(height: 16),
                        ],
                        Text(
                            widget.acknowledged
                                ? 'Activity created'
                                : 'Activity',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 25,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('Make time. Make memories.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                      ]),
                    if (snapshot.connectionState != ConnectionState.done)
                      const LinearProgressIndicator(),
                    if (snapshot.connectionState == ConnectionState.done &&
                        session == null) ...[
                      Text(widget.scheduleCard
                          ? 'Activity could not be loaded.'
                          : widget.acknowledged
                              ? 'Your activity was saved. Its summary could not be loaded.'
                              : 'Activity could not be loaded.'),
                      TextButton(
                          onPressed: () => setState(() {
                                _result = _read();
                              }),
                          child: const Text('Retry summary')),
                    ],
                    if (session != null) ...[
                      ParchSurface(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Text(session.title,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 10),
                            Text(session.cancelled
                                ? 'Cancelled'
                                : session.startsAt == null
                                    ? 'Created · Not scheduled'
                                    : 'Scheduled in ParchApp'),
                            if (!session.cancelled)
                              Text(
                                  'Activity status: ${session.status == 'CONFIRMED' ? 'Confirmed' : 'Proposed'}'),
                            if (session.startsAt != null)
                              Text(
                                  '${MaterialLocalizations.of(context).formatFullDate(session.displayTime(session.startsAt!))}\n${TimeOfDay.fromDateTime(session.displayTime(session.startsAt!)).format(context)} – ${TimeOfDay.fromDateTime(session.displayTime(session.endsAt!)).format(context)} · Bogotá'),
                            const SizedBox(height: 10),
                            Text(session.location.isEmpty
                                ? 'Location not set'
                                : session.location),
                            const SizedBox(height: 12),
                            const Divider(height: 28),
                            const Text('Participants',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              for (var i = 0;
                                  i < session.participants.length;
                                  i++)
                                Tooltip(
                                    message: session.participants[i].name,
                                    child: ParchAvatar(
                                        session.participants[i].name,
                                        index: i))
                            ]),
                            const SizedBox(height: 10),
                            for (final person in session.participants)
                              Text(
                                  '${person.name}${person.leader ? ' · Organizer' : ''}'),
                          ])),
                      const SizedBox(height: 16),
                      if (!widget.scheduleCard)
                        Text(session.cancelled
                            ? 'This activity was cancelled. Invitations no longer accept responses.'
                            : 'Invited participants can respond in their ParchApp inbox.'),
                      if (!widget.scheduleCard && session.startsAt != null)
                        TextButton(
                            onPressed: () => context.go(Uri(
                                    path: AppRoutes.schedule,
                                    queryParameters: {
                                      'activityId': session.id,
                                      'date': session
                                          .displayTime(session.startsAt!)
                                          .toIso8601String()
                                          .substring(0, 10),
                                      'groupId': session.groupId
                                    }).toString()),
                            child: const Text('View in Schedule')),
                    ],
                    if (!widget.scheduleCard) ...[
                      const SizedBox(height: 18),
                      FilledButton(
                          onPressed: () => context
                              .go(AppRoutes.studySession(widget.activityId)),
                          child: const Text('View Details')),
                      TextButton(
                          onPressed: () => context.go(AppRoutes.home),
                          child: const Text('Home')),
                    ],
                  ]));
        });
    if (widget.scheduleCard) return summary;
    return Scaffold(
        appBar: const ParchAppBar(showBack: true),
        body: SafeArea(child: SingleChildScrollView(child: summary)));
  }
}

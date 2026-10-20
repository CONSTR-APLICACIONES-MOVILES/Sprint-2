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
                      Text(
                          widget.acknowledged ? 'Activity created' : 'Activity',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
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
                      Text(session.title,
                          style: Theme.of(context).textTheme.titleLarge),
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
                            '${session.displayTime(session.startsAt!)} → ${session.displayTime(session.endsAt!)} · ${session.timeZone}'),
                      Text(session.location.isEmpty
                          ? 'Location not set'
                          : session.location),
                      const SizedBox(height: 12),
                      const Text('Participants'),
                      for (final person in session.participants)
                        Text(
                            '${person.name}${person.leader ? ' · Organizer' : ''}'),
                      if (!widget.scheduleCard)
                        Text(session.cancelled
                            ? 'This activity was cancelled. Invitations no longer accept responses.'
                            : 'Invited participants can respond in their app inbox. No external calendar export or push delivery has been performed.'),
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
                      TextButton(
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

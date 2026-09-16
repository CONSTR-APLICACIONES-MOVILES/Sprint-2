class StudyTopic {
  final String id;
  final String title;
  final String objective;
  final bool completed;
  const StudyTopic(this.id, this.title, this.objective,
      {this.completed = false});
  StudyTopic toggle() =>
      StudyTopic(id, title, objective, completed: !completed);
}

class StudyParticipant {
  final String name;
  final String initials;
  final String program;
  final String status;
  final bool leader;
  const StudyParticipant(this.name, this.initials, this.program, this.status,
      {this.leader = false});
}

class StudyResource {
  final String title;
  final String description;
  const StudyResource(this.title, this.description);
}

class StudySession {
  final String id;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime endsAt;
  final String location;
  final String room;
  final String reminder;
  final bool cancelled;
  final List<StudyTopic> topics;
  final List<StudyParticipant> participants;
  final List<StudyResource> resources;

  StudySession(
      {required this.id,
      required this.title,
      required this.description,
      required this.startsAt,
      required this.endsAt,
      required this.location,
      required this.room,
      required this.reminder,
      required List<StudyTopic> topics,
      required List<StudyParticipant> participants,
      required List<StudyResource> resources,
      this.cancelled = false})
      : topics = List.unmodifiable(topics),
        participants = List.unmodifiable(participants),
        resources = List.unmodifiable(resources);

  StudySession copyWith(
          {String? title,
          DateTime? startsAt,
          DateTime? endsAt,
          String? room,
          bool? cancelled,
          List<StudyTopic>? topics}) =>
      StudySession(
          id: id,
          title: title ?? this.title,
          description: description,
          startsAt: startsAt ?? this.startsAt,
          endsAt: endsAt ?? this.endsAt,
          location: location,
          room: room ?? this.room,
          reminder: reminder,
          topics: topics ?? this.topics,
          participants: participants,
          resources: resources,
          cancelled: cancelled ?? this.cancelled);
}

class SessionFailure implements Exception {
  final String message;
  const SessionFailure(this.message);
}

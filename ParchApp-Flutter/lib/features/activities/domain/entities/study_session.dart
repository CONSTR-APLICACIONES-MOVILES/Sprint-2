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
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? durationMinutes;
  final String timeZone;
  final String legacyDate;
  final String legacyTime;
  final String status;
  final bool supportsDetailsEditing;
  final bool supportsActivityEditing;
  final String groupId;
  final String category;
  final String location;
  final String room;
  final String reminder;
  final bool cancelled;
  final bool canOrganize;
  final List<String> labels;
  final List<String> amenities;
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
      this.cancelled = false,
      this.durationMinutes,
      this.timeZone = '',
      this.legacyDate = '',
      this.legacyTime = '',
      this.status = '',
      this.supportsDetailsEditing = true,
      this.supportsActivityEditing = false,
      this.groupId = '',
      this.category = 'study',
      this.canOrganize = false,
      List<String> labels = const [],
      List<String> amenities = const []})
      : topics = List.unmodifiable(topics),
        labels = List.unmodifiable(labels),
        amenities = List.unmodifiable(amenities),
        participants = List.unmodifiable(participants),
        resources = List.unmodifiable(resources);

  StudySession copyWith(
          {String? title,
          String? description,
          String? location,
          String? category,
          String? status,
          String? legacyDate,
          String? legacyTime,
          DateTime? startsAt,
          DateTime? endsAt,
          String? room,
          bool? cancelled,
          List<StudyTopic>? topics}) =>
      StudySession(
          id: id,
          title: title ?? this.title,
          description: description ?? this.description,
          startsAt: startsAt ?? this.startsAt,
          endsAt: endsAt ?? this.endsAt,
          location: location ?? this.location,
          room: room ?? this.room,
          reminder: reminder,
          topics: topics ?? this.topics,
          participants: participants,
          resources: resources,
          durationMinutes: startsAt != null && endsAt != null
              ? endsAt.difference(startsAt).inMinutes
              : durationMinutes,
          timeZone: timeZone,
          legacyDate: legacyDate ?? this.legacyDate,
          legacyTime: legacyTime ?? this.legacyTime,
          status: status ?? this.status,
          groupId: groupId,
          category: category ?? this.category,
          supportsActivityEditing: supportsActivityEditing,
          supportsDetailsEditing: supportsDetailsEditing,
          canOrganize: canOrganize,
          labels: category == null ? labels : [category],
          amenities: amenities,
          cancelled: cancelled ?? this.cancelled);

  // Bogotá has a fixed UTC-05 offset. Do not interpret its wall times in the
  // device timezone when editing today's backend recommendations.
  DateTime displayTime(DateTime instant) => timeZone == 'America/Bogota'
      ? instant.toUtc().subtract(const Duration(hours: 5))
      : instant.toLocal();
  DateTime fromDisplayTime(DateTime wallTime) => timeZone == 'America/Bogota'
      ? DateTime.utc(wallTime.year, wallTime.month, wallTime.day, wallTime.hour,
              wallTime.minute)
          .add(const Duration(hours: 5))
      : wallTime;
}

class SessionFailure implements Exception {
  final String message;
  final String? code;
  const SessionFailure(this.message, {this.code});
}

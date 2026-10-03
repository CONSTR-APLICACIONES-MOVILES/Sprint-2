import '../../domain/entities/activity_summary.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/entities/slot_recommendation.dart';

class ActivityModel {
  final Map<String, dynamic> data;
  const ActivityModel(this.data);

  StudySession toEntity(String? uid) => StudySession(
        id: data['id'] as String,
        title: data['title'] as String,
        description: data['description'] as String? ?? '',
        startsAt: _instant(data['startTime']),
        endsAt: _instant(data['endTime']),
        durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
        timeZone: data['timeZone'] as String,
        legacyDate: data['date'] as String? ?? '',
        legacyTime: data['time'] as String? ?? '',
        status: data['status'] as String,
        location: data['location'] as String? ?? '',
        room: '',
        reminder: '',
        canOrganize: uid != null && uid == data['createdBy'],
        supportsDetailsEditing: false,
        supportsActivityEditing: true,
        groupId: data['groupId'] as String,
        category: data['category'] as String,
        labels: [if (data['category'] case final String category) category],
        topics: const [],
        resources: const [],
        participants: [
          for (final raw in data['participants'] as List)
            _participant(Map<String, dynamic>.from(raw as Map))
        ],
      );

  StudyParticipant _participant(Map<String, dynamic> person) =>
      StudyParticipant(
          person['name'] as String,
          person['initials'] as String? ?? '',
          'Group RSVP: ${person['groupRsvpStatus']}',
          'Availability: ${person['availability']}',
          leader: person['id'] == data['createdBy']);

  static DateTime? _instant(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  ActivitySummary toSummary() => ActivitySummary(
      id: data['id'] as String,
      title: data['title'] as String,
      location: data['location'] as String? ?? '',
      date: data['date'] as String? ?? '',
      time: data['time'] as String? ?? '',
      confirmed: data['status'] == 'CONFIRMED');
}

class RecommendationsModel {
  final Map<String, dynamic> data;
  const RecommendationsModel(this.data);
  SlotRecommendations toEntity() => SlotRecommendations(
          id: data['batchId'] as String,
          activityId: data['activityId'] as String,
          date: data['date'] as String,
          timeZone: data['timeZone'] as String,
          slots: [
            for (final raw in data['recommendations'] as List)
              _slot(Map<String, dynamic>.from(raw as Map))
          ]);

  RecommendedSlot _slot(Map<String, dynamic> slot) => RecommendedSlot(
      id: slot['id'] as String,
      startsAt: DateTime.parse(slot['startTime'] as String),
      endsAt: DateTime.parse(slot['endTime'] as String),
      availableParticipants: (slot['availableParticipants'] as num).toInt(),
      totalParticipants: (slot['totalParticipants'] as num).toInt(),
      reasons: List<String>.from(slot['reasons'] as List));
}

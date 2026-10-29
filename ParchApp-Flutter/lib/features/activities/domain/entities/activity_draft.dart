import 'study_session.dart';
import 'planning_context.dart';

class ActivityGroup {
  final String id;
  final String name;
  final Map<String, String> members;
  const ActivityGroup(this.id, this.name, {this.members = const {}});
}

/// Editable fields from the shared Firestore activity contract. Canonical
/// start/end times are changed only through recommendation decisions.
class ActivityDraft {
  final DateTime? startsAt, endsAt;
  final PlanningContext? planning;
  final CreationComparison? comparison;
  final int? measurementVersion;
  final String? requestId;
  final String groupId,
      title,
      description,
      category,
      location,
      status,
      date,
      time;
  const ActivityDraft(
      {required this.groupId,
      required this.title,
      this.description = '',
      this.category = 'study',
      this.location = '',
      this.status = 'PROPOSED',
      this.date = '',
      this.time = '',
      this.startsAt,
      this.endsAt,
      this.planning,
      this.comparison,
      this.measurementVersion = 1,
      this.requestId});

  Map<String, dynamic> publication(String key) => {
        'requestId': key,
        'groupId': groupId,
        if (measurementVersion != null)
          'measurementVersion': measurementVersion,
        'fields': {
          'title': title,
          'description': description,
          'category': category,
          'location': location,
          'status': status,
          'date': date,
          'time': time
        },
        if (startsAt != null) 'startTime': startsAt!.toUtc().toIso8601String(),
        if (endsAt != null) 'endTime': endsAt!.toUtc().toIso8601String(),
        'timeZone': 'America/Bogota',
        if (comparison != null) ...{
          'comparisonEvidenceId': comparison!.comparisonEvidenceId,
          'participantIds': comparison!.participantIds,
        },
        if (planning?.comparisonEvidenceId != null)
          'comparisonEvidenceId': planning!.comparisonEvidenceId,
        if (planning != null) ...{
          'participantIds': planning!.participantIds,
          'comparisonId': planning!.comparisonId,
        },
      };

  ActivityDraft validated() {
    if ((startsAt == null) != (endsAt == null) ||
        startsAt != null &&
            (!endsAt!.isAfter(startsAt!) ||
                endsAt!.difference(startsAt!).inMinutes < 15 ||
                endsAt!.difference(startsAt!).inMinutes > 720)) {
      throw const SessionFailure(
          'Choose a start and end, lasting 15–720 minutes.');
    }
    if (location.trim().length > 500) {
      throw const SessionFailure('Location must be at most 500 characters.');
    }
    if (groupId.isEmpty) throw const SessionFailure('Choose a group.');
    if (title.trim().isEmpty || title.trim().length > 120) {
      throw const SessionFailure(
          'Enter an activity name of 1 to 120 characters.');
    }
    if (description.trim().length > 5000) {
      throw const SessionFailure(
          'Description must be at most 5000 characters.');
    }
    if (!['study', 'sports', 'social', 'other'].contains(category) ||
        !['PROPOSED', 'CONFIRMED'].contains(status)) {
      throw const SessionFailure('Choose a valid category and status.');
    }
    return ActivityDraft(
        groupId: groupId,
        title: title.trim(),
        description: description.trim(),
        category: category,
        location: location.trim(),
        status: status,
        date: date.trim(),
        time: time.trim(),
        startsAt: startsAt,
        endsAt: endsAt,
        planning: planning,
        comparison: comparison,
        measurementVersion: measurementVersion,
        requestId: requestId);
  }
}

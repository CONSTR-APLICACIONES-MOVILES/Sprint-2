import 'study_session.dart';

class ActivityGroup {
  final String id;
  final String name;
  const ActivityGroup(this.id, this.name);
}

/// Editable fields from the shared Firestore activity contract. Canonical
/// start/end times are changed only through recommendation decisions.
class ActivityDraft {
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
      this.time = ''});

  ActivityDraft validated() {
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
        time: time.trim());
  }
}

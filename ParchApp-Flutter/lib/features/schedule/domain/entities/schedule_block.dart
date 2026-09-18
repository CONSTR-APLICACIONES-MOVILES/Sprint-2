enum ScheduleBlockType {
  personalEvent,
  friendBusy,
  sharedActivity,
}

class ScheduleBlock {
  final String id;
  final DateTime start;
  final DateTime end;
  final ScheduleBlockType type;

  final String? title;
  final String? subtitle;
  final String? location;
  final String? ownerId;

  const ScheduleBlock({
    required this.id,
    required this.start,
    required this.end,
    required this.type,
    this.title,
    this.subtitle,
    this.location,
    this.ownerId,
  });

  bool overlaps(
    DateTime candidateStart,
    DateTime candidateEnd,
  ) {
    return start.isBefore(candidateEnd) && end.isAfter(candidateStart);
  }
}

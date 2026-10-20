class ActivitySummary {
  final String id;
  final String title;
  final String location;
  final String date;
  final String time;
  final bool confirmed;
  final bool cancelled;
  final DateTime? startsAt, endsAt;
  final Map<String, int> attendance;
  const ActivitySummary(
      {required this.id,
      required this.title,
      required this.location,
      required this.date,
      required this.time,
      required this.confirmed,
      this.cancelled = false,
      this.startsAt,
      this.endsAt,
      this.attendance = const {}});
}

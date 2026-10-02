class GoogleCalendarEventModel {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime start;
  final DateTime end;

  const GoogleCalendarEventModel({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.location,
  });
}
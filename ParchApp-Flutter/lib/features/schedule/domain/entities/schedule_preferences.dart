class SchedulePreferences {
  static const List<int> defaultQuickDurationsMinutes = [
    30,
    45,
    60,
    120,
  ];

  final List<int> quickDurationsMinutes;

  const SchedulePreferences({
    required this.quickDurationsMinutes,
  });

  factory SchedulePreferences.defaults() {
    return const SchedulePreferences(
      quickDurationsMinutes: defaultQuickDurationsMinutes,
    );
  }
}

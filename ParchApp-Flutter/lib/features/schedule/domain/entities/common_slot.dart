class CommonSlot {
  final String id;
  final DateTime start;
  final DateTime end;

  const CommonSlot({
    required this.id,
    required this.start,
    required this.end,
  });

  Duration get duration => end.difference(start);
}

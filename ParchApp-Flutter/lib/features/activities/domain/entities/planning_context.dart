/// Canonical handoff from Schedule. Instants are UTC; labels are never parsed.
class PlanningContext {
  final DateTime start, end;
  final List<String> participantIds;
  final String? groupId, comparisonId;
  final String sourceSlotId, timeZone;
  final DateTime? expiresAt;
  const PlanningContext(
      {required this.start,
      required this.end,
      required this.participantIds,
      required this.sourceSlotId,
      this.groupId,
      this.comparisonId,
      this.expiresAt,
      this.timeZone = 'America/Bogota'});
  int get durationMinutes => end.difference(start).inMinutes;
  Map<String, dynamic> toMap() => {
        'startTime': start.toUtc().toIso8601String(),
        'endTime': end.toUtc().toIso8601String(),
        'participantIds': participantIds,
        'sourceSlotId': sourceSlotId,
        'timeZone': timeZone,
        if (groupId != null) 'groupId': groupId,
      };
  factory PlanningContext.fromMap(Map<String, dynamic> data) => PlanningContext(
      start: DateTime.parse(data['startTime'] as String),
      end: DateTime.parse(data['endTime'] as String),
      participantIds: List<String>.from(data['participantIds'] as List),
      sourceSlotId: data['sourceSlotId'] as String? ?? '',
      groupId: data['groupId'] as String?,
      comparisonId: data['comparisonId'] as String?,
      expiresAt: data['expiresAt'] == null
          ? null
          : DateTime.parse(data['expiresAt'] as String),
      timeZone: data['timeZone'] as String? ?? 'America/Bogota');
}

abstract interface class PlanningSlotValidator {
  Future<PlanningContext> validatePlanningSlot(PlanningContext context);
}

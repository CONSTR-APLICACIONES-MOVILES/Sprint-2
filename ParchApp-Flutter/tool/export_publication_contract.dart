import 'dart:convert';
import 'dart:io';
import 'package:parchapp/features/activities/domain/entities/activity_draft.dart';
import 'package:parchapp/features/activities/domain/entities/planning_context.dart';

// Generate backend contract fixtures from the actual Flutter serializer.
// Run with Dart SDK, passing the destination JSON path as the only argument.
void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Supply an output JSON path.');
  const comparison = CreationComparison(
      comparisonEvidenceId: 'contract-evidence',
      participantIds: ['owner', 'peer'],
      date: '2026-10-29');
  final planning = PlanningContext(
      start: DateTime.utc(2026, 10, 29, 16),
      end: DateTime.utc(2026, 10, 29, 17),
      participantIds: ['owner', 'peer'],
      sourceSlotId: 'contract-slot',
      groupId: 'g',
      comparisonId: 'slot-comparison',
      comparisonEvidenceId: 'slot-evidence');
  final drafts = {
    'direct': const ActivityDraft(groupId: 'g', title: 'Contract direct'),
    'compared': const ActivityDraft(
        groupId: 'g', title: 'Contract compared', comparison: comparison),
    'scheduled': ActivityDraft(
        groupId: 'g',
        title: 'Contract scheduled',
        startsAt: planning.start,
        endsAt: planning.end,
        planning: planning),
    'legacy': const ActivityDraft(
        groupId: 'g', title: 'Contract legacy', measurementVersion: null),
  };
  final payloads = {
    for (final entry in drafts.entries)
      entry.key: entry.value.validated().publication('contract-${entry.key}')
  };
  final output = File(args.single);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(payloads)}\n');
  stdout.writeln(
      'Exported ${payloads.length} real Flutter publication payloads.');
}

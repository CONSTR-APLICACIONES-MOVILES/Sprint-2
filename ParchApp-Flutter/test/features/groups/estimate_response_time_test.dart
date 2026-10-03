import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/groups/data/repositories/firestore_response_time_insights_repository.dart';
import 'package:parchapp/features/groups/data/repositories/mock_response_time_insights_repository.dart';
import 'package:parchapp/features/groups/domain/entities/active_group.dart';
import 'package:parchapp/features/groups/domain/entities/response_time_estimate.dart';
import 'package:parchapp/features/groups/domain/use_cases/estimate_response_time.dart';

ResponseTimeEstimate _estimate(int size, double minutes) => ResponseTimeEstimate(
    groupSize: size, minutes: minutes, kind: EstimateKind.allResponded);

ActiveGroup _group(String id, int members, {bool roster = true}) => ActiveGroup(
      id: id,
      name: id,
      category: GroupCategory.sports,
      memberCount: members,
      subtitle: '',
      statusText: '',
      tone: GroupTone.warning,
      detail: '',
      primaryAction: GroupAction.voteRsvp,
      secondaryAction: GroupAction.teamChat,
      progressCurrent: roster ? 1 : null,
      progressTotal: roster ? members : null,
    );

void main() {
  final estimate = EstimateResponseTime(MockResponseTimeInsightsRepository());
  final measured = [_estimate(4, 95), _estimate(8, 200), _estimate(12, 300)];

  test('uses the exact size when it was measured', () {
    expect(estimate.forGroupSize(8, measured)!.minutes, 200);
  });

  test('uses the closest size and the smaller one on a tie', () {
    expect(estimate.forGroupSize(5, measured)!.groupSize, 4);
    expect(estimate.forGroupSize(6, measured)!.groupSize, 4);
    expect(estimate.forGroupSize(30, measured)!.groupSize, 12);
  });

  test('gives no estimate without data', () {
    expect(estimate.forGroupSize(6, const []), isNull);
    expect(estimate.forGroupSize(0, measured), isNull);
  });

  test('only groups that collect RSVPs get an estimate', () {
    final result = estimate.forGroups(
        [_group('match', 6), _group('lounge', 16, roster: false)], measured);
    expect(result.keys, ['match']);
  });

  test('durations read as estimates', () {
    expect(_estimate(4, 45).durationLabel, '45 min');
    expect(_estimate(4, 95).durationLabel, '1.5 h');
    expect(_estimate(4, 210).durationLabel, '3.5 h');
    expect(_estimate(4, 1440).durationLabel, '1 day');
    expect(_estimate(4, 2880).durationLabel, '2 days');
  });

  test('reads only the sizes the backend published', () {
    final parsed = parseEstimates({
      'by_group_size': [
        {'group_size': 4, 'estimate_minutes': 95.5, 'estimate_kind': 'all_responded'},
        {'group_size': 6, 'estimate_minutes': 40, 'estimate_kind': 'per_response'},
        {'group_size': 12, 'estimate_minutes': null, 'estimate_kind': null},
      ],
    });
    expect(parsed.map((e) => e.groupSize), [4, 6]);
    expect(parsed.last.kind, EstimateKind.perResponse);
    expect(parseEstimates(null), isEmpty);
  });
}
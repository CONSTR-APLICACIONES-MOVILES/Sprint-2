import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/groups/domain/entities/active_group.dart';
import 'package:parchapp/features/groups/domain/use_cases/activity_timing.dart';

ActiveGroup _group(String id, {DateTime? startsAt}) => ActiveGroup(
      id: id,
      name: id,
      category: GroupCategory.study,
      memberCount: 4,
      subtitle: 'Shared group',
      statusText: '',
      tone: GroupTone.info,
      detail: '',
      primaryAction: GroupAction.viewDetails,
      secondaryAction: GroupAction.viewSchedule,
      activityStartsAt: startsAt,
    );

void main() {
  final now = DateTime(2026, 10, 30, 10);

  test('the label follows how far the activity is from now', () {
    expect(ActivityTiming.label(null, now), isNull);
    expect(ActivityTiming.label(now.subtract(const Duration(hours: 1)), now),
        'Happening now');
    expect(ActivityTiming.label(now.subtract(const Duration(hours: 5)), now),
        isNull);
    expect(ActivityTiming.label(now.add(const Duration(minutes: 45)), now),
        'In 45 min');
    expect(ActivityTiming.label(DateTime(2026, 10, 30, 13, 30), now), 'In 3 h');
    expect(ActivityTiming.label(DateTime(2026, 10, 31, 9), now), 'Tomorrow');
    expect(ActivityTiming.label(DateTime(2026, 11, 2, 9), now), 'In 3 days');
    expect(ActivityTiming.label(DateTime(2026, 11, 20), now), isNull);
  });

  test('activities in the next two hours are highlighted', () {
    expect(ActivityTiming.isSoon(now.add(const Duration(minutes: 90)), now),
        isTrue);
    expect(ActivityTiming.isSoon(now.add(const Duration(hours: 5)), now),
        isFalse);
    expect(ActivityTiming.isSoon(null, now), isFalse);
  });

  test('the closest upcoming activity goes first', () {
    final sorted = ActivityTiming.byUpcoming([
      _group('no activity'),
      _group('next week', startsAt: DateTime(2026, 11, 4)),
      _group('past', startsAt: DateTime(2026, 10, 20)),
      _group('in one hour', startsAt: DateTime(2026, 10, 30, 11)),
    ], now);
    expect(sorted.map((g) => g.id),
        ['in one hour', 'next week', 'no activity', 'past']);
  });
}
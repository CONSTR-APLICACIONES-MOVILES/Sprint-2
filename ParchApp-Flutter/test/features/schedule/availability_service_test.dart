import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/schedule/domain/entities/schedule_block.dart';
import 'package:parchapp/features/schedule/domain/services/availability_service.dart';

void main() {
  const service = AvailabilityService();
  final day = DateTime(2026, 10, 19);
  test('rejects nonpositive durations and steps instead of looping forever',
      () {
    for (final invalid in [Duration.zero, const Duration(minutes: -1)]) {
      expect(
          () => service.findCommonSlots(
              day: day, busyBlocks: [], duration: invalid),
          throwsArgumentError);
      expect(
          () => service.findCommonSlots(
              day: day,
              busyBlocks: [],
              duration: const Duration(hours: 1),
              step: invalid),
          throwsArgumentError);
    }
  });
  test('respects half-open busy boundaries and requested duration', () {
    final slots = service.findCommonSlots(
        day: day,
        duration: const Duration(hours: 1),
        startHour: 8,
        endHour: 11,
        busyBlocks: [
          ScheduleBlock(
              id: 'busy',
              start: DateTime(2026, 10, 19, 9),
              end: DateTime(2026, 10, 19, 10),
              type: ScheduleBlockType.friendBusy)
        ]);
    expect(slots.map((s) => s.start.hour), [8, 10]);
  });
}

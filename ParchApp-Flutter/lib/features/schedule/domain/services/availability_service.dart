import '../entities/common_slot.dart';
import '../entities/schedule_block.dart';

class AvailabilityService {
  const AvailabilityService();

  List<CommonSlot> findCommonSlots({
    required DateTime day,
    required List<ScheduleBlock> busyBlocks,
    required Duration duration,
    int startHour = 8,
    int endHour = 18,
    Duration step = const Duration(minutes: 30),
  }) {
    final dayStart = DateTime(
      day.year,
      day.month,
      day.day,
      startHour,
    );

    final dayEnd = DateTime(
      day.year,
      day.month,
      day.day,
      endHour,
    );

    final slots = <CommonSlot>[];

    var candidateStart = dayStart;

    while (!candidateStart.add(duration).isAfter(dayEnd)) {
      final candidateEnd = candidateStart.add(duration);

      final conflicts = busyBlocks.any(
        (block) => block.overlaps(
          candidateStart,
          candidateEnd,
        ),
      );

      if (!conflicts) {
        slots.add(
          CommonSlot(
            id: '${candidateStart.millisecondsSinceEpoch}-${candidateEnd.millisecondsSinceEpoch}',
            start: candidateStart,
            end: candidateEnd,
          ),
        );
      }

      candidateStart = candidateStart.add(step);
    }

    return slots;
  }
}

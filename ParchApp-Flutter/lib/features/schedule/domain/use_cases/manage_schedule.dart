import '../entities/common_slot.dart';
import '../entities/schedule_block.dart';
import '../entities/schedule_friend.dart';
import '../repositories/schedule_repository.dart';
import '../services/availability_service.dart';

class ScheduleDayResult {
  final List<ScheduleBlock> myBlocks;
  final List<ScheduleBlock> friendBlocks;
  final List<CommonSlot> commonSlots;

  const ScheduleDayResult({
    required this.myBlocks,
    required this.friendBlocks,
    required this.commonSlots,
  });
}

class ManageSchedule {
  final ScheduleRepository _repository;
  final AvailabilityService _availabilityService;

  const ManageSchedule(
    this._repository,
    this._availabilityService,
  );

  Future<List<ScheduleFriend>> loadFriends() => _repository.getFriends();

  Future<ScheduleDayResult> loadDay({
    required DateTime day,
    required List<String> friendIds,
    required Duration duration,
  }) async {
    final myBlocks = await _repository.getMySchedule(
      day: day,
    );

    final friendBlocks = await _repository.getFriendsBusyBlocks(
      day: day,
      friendIds: friendIds,
    );

    final allBusy = [
      ...myBlocks,
      ...friendBlocks,
    ];

    final commonSlots = _availabilityService.findCommonSlots(
      day: day,
      busyBlocks: allBusy,
      duration: duration,
    );

    return ScheduleDayResult(
      myBlocks: myBlocks,
      friendBlocks: friendBlocks,
      commonSlots: commonSlots,
    );
  }
}

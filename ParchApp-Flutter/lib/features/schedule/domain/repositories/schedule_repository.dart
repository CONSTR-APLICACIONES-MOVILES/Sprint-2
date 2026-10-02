import '../entities/schedule_block.dart';
import '../entities/schedule_friend.dart';

abstract interface class ScheduleRepository {
  Future<List<ScheduleFriend>> getFriends();

  Future<List<ScheduleBlock>> getMySchedule({
    required DateTime day,
  });

  Future<List<ScheduleBlock>> getFriendsBusyBlocks({
    required DateTime day,
    required List<String> friendIds,
  });

  Future<void> replaceImportedCalendarBlocks(
    List<ScheduleBlock> blocks,
  );
}
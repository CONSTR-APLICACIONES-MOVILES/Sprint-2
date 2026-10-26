import '../entities/schedule_block.dart';
import '../entities/schedule_friend.dart';
import '../entities/user_location.dart';

abstract interface class ScheduleRepository {
  /// Returns accepted friends of the authenticated user.
  Future<List<ScheduleFriend>> getFriends();

  Future<Map<String, UserLocation>>
      getFriendLocations({
    required List<String> friendIds,
  });

  /// Returns the authenticated user's private schedule.
  Future<List<ScheduleBlock>>
      getMySchedule({
    required DateTime day,
  });

  /// Returns privacy-safe busy blocks of selected friends.
  Future<List<ScheduleBlock>>
      getFriendsBusyBlocks({
    required DateTime day,
    required List<String> friendIds,
  });

  /// Replaces the user's imported Google Calendar events.
  Future<void>
      replaceImportedCalendarBlocks(
    List<ScheduleBlock> blocks,
  );
}
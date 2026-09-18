import '../../domain/entities/schedule_block.dart';
import '../../domain/entities/schedule_friend.dart';
import '../../domain/repositories/schedule_repository.dart';

class MockScheduleRepository implements ScheduleRepository {
  static const friends = [
    ScheduleFriend(
      id: 'sarah',
      name: 'Sarah',
      fullName: 'Sarah Jenkins',
      initials: 'SJ',
    ),
    ScheduleFriend(
      id: 'marcus',
      name: 'Marcus',
      fullName: 'Marcus Thorne',
      initials: 'MT',
    ),
    ScheduleFriend(
      id: 'mariana',
      name: 'Mariana',
      fullName: 'Mariana Polania',
      initials: 'MP',
    ),
  ];

  @override
  Future<List<ScheduleFriend>> getFriends() async {
    await Future.delayed(
      const Duration(milliseconds: 150),
    );

    return friends;
  }

  @override
  Future<List<ScheduleBlock>> getMySchedule({
    required DateTime day,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 100),
    );

    if (day.weekday == DateTime.tuesday) {
      return [
        ScheduleBlock(
          id: 'linear-algebra',
          start: DateTime(
            day.year,
            day.month,
            day.day,
            13,
            30,
          ),
          end: DateTime(
            day.year,
            day.month,
            day.day,
            15,
          ),
          type: ScheduleBlockType.personalEvent,
          title: 'Linear Algebra',
          subtitle: 'MATH 224',
          location: 'Math Hall 101',
        ),
      ];
    }

    return [];
  }

  @override
  Future<List<ScheduleBlock>> getFriendsBusyBlocks({
    required DateTime day,
    required List<String> friendIds,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 100),
    );

    final blocks = <ScheduleBlock>[];

    if (day.weekday != DateTime.tuesday) {
      return blocks;
    }

    if (friendIds.contains('sarah')) {
      blocks.addAll([
        ScheduleBlock(
          id: 'sarah-1',
          ownerId: 'sarah',
          start: DateTime(
            day.year,
            day.month,
            day.day,
            9,
          ),
          end: DateTime(
            day.year,
            day.month,
            day.day,
            10,
          ),
          type: ScheduleBlockType.friendBusy,
        ),
        ScheduleBlock(
          id: 'sarah-2',
          ownerId: 'sarah',
          start: DateTime(
            day.year,
            day.month,
            day.day,
            13,
            30,
          ),
          end: DateTime(
            day.year,
            day.month,
            day.day,
            14,
            30,
          ),
          type: ScheduleBlockType.friendBusy,
        ),
      ]);
    }

    if (friendIds.contains('marcus')) {
      blocks.addAll([
        ScheduleBlock(
          id: 'marcus-1',
          ownerId: 'marcus',
          start: DateTime(
            day.year,
            day.month,
            day.day,
            10,
            30,
          ),
          end: DateTime(
            day.year,
            day.month,
            day.day,
            11,
          ),
          type: ScheduleBlockType.friendBusy,
        ),
        ScheduleBlock(
          id: 'marcus-2',
          ownerId: 'marcus',
          start: DateTime(
            day.year,
            day.month,
            day.day,
            15,
          ),
          end: DateTime(
            day.year,
            day.month,
            day.day,
            16,
          ),
          type: ScheduleBlockType.friendBusy,
        ),
      ]);
    }

    if (friendIds.contains('mariana')) {
      blocks.add(
        ScheduleBlock(
          id: 'mariana-1',
          ownerId: 'mariana',
          start: DateTime(
            day.year,
            day.month,
            day.day,
            11,
            30,
          ),
          end: DateTime(
            day.year,
            day.month,
            day.day,
            12,
            30,
          ),
          type: ScheduleBlockType.friendBusy,
        ),
      );
    }

    return blocks;
  }
}

import '../../domain/entities/common_slot.dart';
import '../../domain/entities/schedule_block.dart';
import '../../domain/entities/schedule_friend.dart';

enum ScheduleLoadStatus {
  loading,
  ready,
  error,
}

enum CalendarImportStatus {
  idle,
  importing,
  imported,
  error,
}

class ScheduleState {
  final ScheduleLoadStatus status;

  // Google Calendar import state
  final CalendarImportStatus calendarImportStatus;
  final String? calendarImportMessage;

  final List<ScheduleFriend> friends;
  final Set<String> selectedFriendIds;

  final DateTime selectedDay;
  final Duration meetingDuration;

  final List<ScheduleBlock> myBlocks;
  final List<ScheduleBlock> friendBlocks;
  final List<CommonSlot> commonSlots;

  final CommonSlot? selectedSlot;

  final String? error;

  const ScheduleState({
    required this.selectedDay,
    this.status = ScheduleLoadStatus.loading,
    this.calendarImportStatus = CalendarImportStatus.idle,
    this.calendarImportMessage,
    this.friends = const [],
    this.selectedFriendIds = const {},
    this.meetingDuration = const Duration(hours: 1),
    this.myBlocks = const [],
    this.friendBlocks = const [],
    this.commonSlots = const [],
    this.selectedSlot,
    this.error,
  });

  ScheduleState copyWith({
    ScheduleLoadStatus? status,

    CalendarImportStatus? calendarImportStatus,
    String? calendarImportMessage,
    bool clearCalendarImportMessage = false,

    List<ScheduleFriend>? friends,
    Set<String>? selectedFriendIds,

    DateTime? selectedDay,
    Duration? meetingDuration,

    List<ScheduleBlock>? myBlocks,
    List<ScheduleBlock>? friendBlocks,
    List<CommonSlot>? commonSlots,

    CommonSlot? selectedSlot,
    bool clearSelectedSlot = false,

    String? error,
  }) {
    return ScheduleState(
      status: status ?? this.status,

      calendarImportStatus:
          calendarImportStatus ?? this.calendarImportStatus,

      calendarImportMessage: clearCalendarImportMessage
          ? null
          : calendarImportMessage ?? this.calendarImportMessage,

      friends: friends ?? this.friends,

      selectedFriendIds:
          selectedFriendIds ?? this.selectedFriendIds,

      selectedDay: selectedDay ?? this.selectedDay,

      meetingDuration:
          meetingDuration ?? this.meetingDuration,

      myBlocks: myBlocks ?? this.myBlocks,

      friendBlocks: friendBlocks ?? this.friendBlocks,

      commonSlots: commonSlots ?? this.commonSlots,

      selectedSlot: clearSelectedSlot
          ? null
          : selectedSlot ?? this.selectedSlot,

      error: error ?? this.error,
    );
  }
}
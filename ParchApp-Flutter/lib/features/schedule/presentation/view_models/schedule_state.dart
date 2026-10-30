import '../../domain/entities/common_slot.dart';
import '../../domain/entities/schedule_block.dart';
import '../../domain/entities/schedule_friend.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/entities/schedule_preferences.dart';

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

enum NearbyFriendsStatus {
  idle,
  loading,
  ready,
  error,
}

enum ScheduleConnectivityStatus {
  online,
  cached,
  offlineNoCache,
}

class ScheduleState {
  final ScheduleLoadStatus status;

  final CalendarImportStatus calendarImportStatus;

  final String? calendarImportMessage;

  final List<ScheduleFriend> friends;

  final List<ScheduleFriend> nearbyFriends;

  final NearbyFriendsStatus nearbyFriendsStatus;

  final String? nearbyFriendsMessage;

  final UserLocation? currentLocation;

  final List<String> selectedFriendIds;

  final DateTime selectedDay;

  final Duration meetingDuration;

  final List<int> quickDurationsMinutes;

  final List<ScheduleBlock> myBlocks;

  final List<ScheduleBlock> friendBlocks;

  final List<CommonSlot> commonSlots;

  final CommonSlot? selectedSlot;

  final String? error;

  // ===============================================================
  // EVENTUAL CONNECTIVITY
  // ===============================================================

  final ScheduleConnectivityStatus connectivityStatus;

  final DateTime? scheduleLastUpdatedAt;

  final bool isRefreshing;

  const ScheduleState({
    this.status = ScheduleLoadStatus.loading,
    this.calendarImportStatus = CalendarImportStatus.idle,
    this.calendarImportMessage,
    this.friends = const [],
    this.nearbyFriends = const [],
    this.nearbyFriendsStatus = NearbyFriendsStatus.idle,
    this.nearbyFriendsMessage,
    this.currentLocation,
    this.selectedFriendIds = const [],
    required this.selectedDay,
    this.meetingDuration = const Duration(
      minutes: 60,
    ),
    this.quickDurationsMinutes =
        SchedulePreferences.defaultQuickDurationsMinutes,
    this.myBlocks = const [],
    this.friendBlocks = const [],
    this.commonSlots = const [],
    this.selectedSlot,
    this.error,
    this.connectivityStatus = ScheduleConnectivityStatus.online,
    this.scheduleLastUpdatedAt,
    this.isRefreshing = false,
  });

  ScheduleState copyWith({
    ScheduleLoadStatus? status,
    CalendarImportStatus? calendarImportStatus,
    String? calendarImportMessage,
    List<ScheduleFriend>? friends,
    List<ScheduleFriend>? nearbyFriends,
    NearbyFriendsStatus? nearbyFriendsStatus,
    String? nearbyFriendsMessage,
    UserLocation? currentLocation,
    List<String>? selectedFriendIds,
    DateTime? selectedDay,
    Duration? meetingDuration,
    List<int>? quickDurationsMinutes,
    List<ScheduleBlock>? myBlocks,
    List<ScheduleBlock>? friendBlocks,
    List<CommonSlot>? commonSlots,
    CommonSlot? selectedSlot,
    String? error,
    ScheduleConnectivityStatus? connectivityStatus,
    DateTime? scheduleLastUpdatedAt,
    bool? isRefreshing,
    bool clearCalendarImportMessage = false,
    bool clearNearbyFriendsMessage = false,
    bool clearCurrentLocation = false,
    bool clearSelectedSlot = false,
    bool clearError = false,
    bool clearScheduleLastUpdatedAt = false,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      calendarImportStatus: calendarImportStatus ?? this.calendarImportStatus,
      calendarImportMessage: clearCalendarImportMessage
          ? null
          : calendarImportMessage ?? this.calendarImportMessage,
      friends: friends ?? this.friends,
      nearbyFriends: nearbyFriends ?? this.nearbyFriends,
      nearbyFriendsStatus: nearbyFriendsStatus ?? this.nearbyFriendsStatus,
      nearbyFriendsMessage: clearNearbyFriendsMessage
          ? null
          : nearbyFriendsMessage ?? this.nearbyFriendsMessage,
      currentLocation:
          clearCurrentLocation ? null : currentLocation ?? this.currentLocation,
      selectedFriendIds: selectedFriendIds ?? this.selectedFriendIds,
      selectedDay: selectedDay ?? this.selectedDay,
      meetingDuration: meetingDuration ?? this.meetingDuration,
      quickDurationsMinutes:
          quickDurationsMinutes ?? this.quickDurationsMinutes,
      myBlocks: myBlocks ?? this.myBlocks,
      friendBlocks: friendBlocks ?? this.friendBlocks,
      commonSlots: commonSlots ?? this.commonSlots,
      selectedSlot:
          clearSelectedSlot ? null : selectedSlot ?? this.selectedSlot,
      error: clearError ? null : error ?? this.error,
      connectivityStatus: connectivityStatus ?? this.connectivityStatus,
      scheduleLastUpdatedAt: clearScheduleLastUpdatedAt
          ? null
          : scheduleLastUpdatedAt ?? this.scheduleLastUpdatedAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

import '../../../activities/domain/entities/planning_context.dart';
import 'package:flutter/foundation.dart';
import '../../domain/use_cases/authorize_google_calendar.dart';
import '../../domain/entities/common_slot.dart';
import '../../domain/use_cases/manage_schedule.dart';
import 'schedule_state.dart';
import '../../domain/use_cases/import_google_calendar.dart';

DateTime _todayInBogota() {
  final now = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return DateTime(now.year, now.month, now.day);
}

class ScheduleViewModel extends ValueNotifier<ScheduleState> {
  final ManageSchedule _schedule;
  final AuthorizeGoogleCalendar _authorizeGoogleCalendar;
  final ImportGoogleCalendar _importGoogleCalendar;

  bool _disposed = false;
  bool _loading = false;
  int _requestVersion = 0;

  ScheduleViewModel(
    this._schedule,
    this._importGoogleCalendar, {
    required AuthorizeGoogleCalendar authorizeGoogleCalendar,
    DateTime? initialDay,
  })  : _authorizeGoogleCalendar = authorizeGoogleCalendar,
        super(
          ScheduleState(
            selectedDay: initialDay ?? _todayInBogota(),
          ),
        );

  void _emit(ScheduleState state) {
    if (!_disposed) {
      value = state;
    }
  }

  Future<PlanningContext> preparePlan({String? groupId}) async {
    final selected = value;
    final slot = selected.selectedSlot;
    if (slot == null || selected.status != ScheduleLoadStatus.ready) {
      throw StateError('Select a current common slot first.');
    }
    final version = _requestVersion;
    DateTime instant(DateTime wall) =>
        DateTime.utc(wall.year, wall.month, wall.day, wall.hour, wall.minute)
            .add(const Duration(hours: 5));
    final result = await _schedule.validatePlanningSlot(PlanningContext(
        start: instant(slot.start),
        end: instant(slot.end),
        participantIds: selected.selectedFriendIds.toList()..sort(),
        sourceSlotId: slot.id,
        groupId: groupId));
    if (_disposed ||
        version != _requestVersion ||
        value.selectedSlot?.id != slot.id) {
      throw StateError('The comparison changed. Select a slot again.');
    }
    return result;
  }

  Future<void> load() async {
    if (_loading || _disposed) return;

    _loading = true;

    _emit(
      value.copyWith(
        status: ScheduleLoadStatus.loading,
      ),
    );

    try {
      final friends = await _schedule.loadFriends();
      if (_disposed) return;

      final defaultIds = friends.take(2).map((friend) => friend.id).toSet();

      _emit(
        value.copyWith(
          friends: friends,
          selectedFriendIds: defaultIds,
        ),
      );

      await _refreshDay();
    } catch (_) {
      _emit(
        value.copyWith(
          status: ScheduleLoadStatus.error,
          error: 'Unable to load the schedule.',
        ),
      );
    } finally {
      _loading = false;
    }
  }

  Future<void> importGoogleCalendar() async {
    if (_disposed ||
        value.calendarImportStatus == CalendarImportStatus.importing) {
      return;
    }

    _emit(
      value.copyWith(
        calendarImportStatus: CalendarImportStatus.importing,
        clearCalendarImportMessage: true,
      ),
    );

    try {
      await _authorizeGoogleCalendar();
      if (_disposed) return;
      final importedCount = await _importGoogleCalendar();

      _emit(
        value.copyWith(
          calendarImportStatus: CalendarImportStatus.imported,
          calendarImportMessage: '$importedCount busy intervals synced.',
        ),
      );

      await _refreshDay();
    } catch (_) {
      _emit(
        value.copyWith(
          calendarImportStatus: CalendarImportStatus.error,
          calendarImportMessage: 'Unable to import Google Calendar.',
        ),
      );
    }
  }

  Future<void> selectDay(DateTime day) async {
    if (_disposed) return;
    _emit(
      value.copyWith(
        selectedDay: day,
        clearSelectedSlot: true,
      ),
    );

    await _refreshDay();
  }

  Future<void> setDuration(
    Duration duration,
  ) async {
    if (_disposed) return;
    _emit(
      value.copyWith(
        meetingDuration: duration,
        clearSelectedSlot: true,
      ),
    );

    await _refreshDay();
  }

  Future<void> toggleFriend(
    String friendId,
  ) async {
    if (_disposed) return;
    final selected = Set<String>.from(
      value.selectedFriendIds,
    );

    if (selected.contains(friendId)) {
      selected.remove(friendId);
    } else {
      selected.add(friendId);
    }

    _emit(
      value.copyWith(
        selectedFriendIds: selected,
        clearSelectedSlot: true,
      ),
    );

    await _refreshDay();
  }

  void selectSlot(CommonSlot slot) {
    _emit(
      value.copyWith(
        selectedSlot: slot,
      ),
    );
  }

  Future<void> _refreshDay() async {
    if (_disposed) return;
    final version = ++_requestVersion;
    final request = value;
    _emit(value.copyWith(
      status: ScheduleLoadStatus.loading,
      myBlocks: const [],
      friendBlocks: const [],
      commonSlots: const [],
      clearSelectedSlot: true,
      clearError: true,
    ));
    try {
      final result = await _schedule.loadDay(
        day: request.selectedDay,
        friendIds: request.selectedFriendIds.toList(),
        duration: request.meetingDuration,
      );
      if (_disposed || version != _requestVersion) return;

      final selected =
          result.commonSlots.isEmpty ? null : result.commonSlots.first;

      _emit(
        value.copyWith(
          status: ScheduleLoadStatus.ready,
          myBlocks: result.myBlocks,
          friendBlocks: result.friendBlocks,
          commonSlots: result.commonSlots,
          selectedSlot: selected,
          clearSelectedSlot: selected == null,
          clearError: true,
        ),
      );
    } catch (error) {
      if (_disposed || version != _requestVersion) return;
      _emit(
        value.copyWith(
          status: ScheduleLoadStatus.error,
          error: error is StateError
              ? error.message.toString()
              : 'Unable to compare availability.',
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}

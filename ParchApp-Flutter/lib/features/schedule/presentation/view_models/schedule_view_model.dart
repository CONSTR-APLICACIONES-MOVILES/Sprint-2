import 'package:flutter/foundation.dart';
import '../../domain/use_cases/authorize_google_calendar.dart';
import '../../domain/entities/common_slot.dart';
import '../../domain/use_cases/manage_schedule.dart';
import 'schedule_state.dart';
import '../../domain/use_cases/import_google_calendar.dart';

class ScheduleViewModel extends ValueNotifier<ScheduleState> {
  final ManageSchedule _schedule;
  final AuthorizeGoogleCalendar _authorizeGoogleCalendar;
  final ImportGoogleCalendar _importGoogleCalendar;

  bool _disposed = false;
  bool _loading = false;

  ScheduleViewModel(
    this._schedule,
    this._importGoogleCalendar, {
    required AuthorizeGoogleCalendar authorizeGoogleCalendar,
    DateTime? initialDay,
  }) : _authorizeGoogleCalendar = authorizeGoogleCalendar,
       super(
          ScheduleState(
            selectedDay:
                initialDay ??
                    DateTime(2026, 10, 15),
          ),
        );

  void _emit(ScheduleState state) {
    if (!_disposed) {
      value = state;
    }
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
    if (value.calendarImportStatus ==
        CalendarImportStatus.importing) {
      return;
    }

    _emit(
      value.copyWith(
        calendarImportStatus:
            CalendarImportStatus.importing,
        clearCalendarImportMessage: true,
      ),
    );

    try {
      await _authorizeGoogleCalendar();
      final importedCount =
          await _importGoogleCalendar();

      _emit(
        value.copyWith(
          calendarImportStatus:
              CalendarImportStatus.imported,
          calendarImportMessage:
              '$importedCount calendar events imported.',
        ),
      );

      await _refreshDay();
    } catch (_) {
      _emit(
        value.copyWith(
          calendarImportStatus:
              CalendarImportStatus.error,
          calendarImportMessage:
              'Unable to import Google Calendar.',
        ),
      );
    }
  }

  Future<void> selectDay(DateTime day) async {
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
    try {
      final result = await _schedule.loadDay(
        day: value.selectedDay,
        friendIds: value.selectedFriendIds.toList(),
        duration: value.meetingDuration,
      );

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
          error: null,
        ),
      );
    } catch (_) {
      _emit(
        value.copyWith(
          status: ScheduleLoadStatus.error,
          error: 'Unable to compare availability.',
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  
}

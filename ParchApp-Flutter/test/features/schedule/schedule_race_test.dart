import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:parchapp/features/schedule/domain/entities/schedule_block.dart';
import 'package:parchapp/features/schedule/domain/repositories/calendar_import_repository.dart';
import 'package:parchapp/features/schedule/domain/services/availability_service.dart';
import 'package:parchapp/features/schedule/domain/use_cases/authorize_google_calendar.dart';
import 'package:parchapp/features/schedule/domain/use_cases/import_google_calendar.dart';
import 'package:parchapp/features/schedule/domain/use_cases/manage_schedule.dart';
import 'package:parchapp/features/schedule/presentation/view_models/schedule_state.dart';
import 'package:parchapp/features/schedule/presentation/view_models/schedule_view_model.dart';

class _Schedule extends MockScheduleRepository {
  final requests = <Completer<List<ScheduleBlock>>>[];
  @override
  Future<List<ScheduleBlock>> getMySchedule({required DateTime day}) {
    final pending = Completer<List<ScheduleBlock>>();
    requests.add(pending);
    return pending.future;
  }

  @override
  Future<List<ScheduleBlock>> getFriendsBusyBlocks({
    required DateTime day,
    required List<String> friendIds,
  }) async =>
      [];
}

class _Calendar implements CalendarImportRepository {
  int authorizations = 0;
  @override
  Future<void> authorizeCalendar() async {
    authorizations++;
  }

  @override
  Future<List<ScheduleBlock>> importCalendar() async => [];
}

void main() {
  late _Schedule repository;
  late _Calendar calendar;
  late ScheduleViewModel model;
  setUp(() {
    repository = _Schedule();
    calendar = _Calendar();
    model = ScheduleViewModel(
      ManageSchedule(repository, const AvailabilityService()),
      ImportGoogleCalendar(calendar, repository),
      authorizeGoogleCalendar: AuthorizeGoogleCalendar(calendar),
    );
  });
  tearDown(() => model.dispose());

  test('opens the current day instead of the prototype date', () {
    final now = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    expect(model.value.selectedDay.year, now.year);
    expect(model.value.selectedDay.month, now.month);
    expect(model.value.selectedDay.day, now.day);
  });

  test('a slow previous day cannot overwrite the newest selection', () async {
    final old = model.selectDay(DateTime(2026, 10, 19));
    final latest = model.selectDay(DateTime(2026, 10, 20));
    repository.requests[1].complete([]);
    await latest;
    final slots = model.value.commonSlots;
    repository.requests[0].complete([]);
    await old;
    expect(model.value.commonSlots, same(slots));
    expect(slots.first.start.day, 20);
  });

  test('stale failures cannot replace a successful newer request', () async {
    final old = model.selectDay(DateTime(2026, 10, 19));
    final latest = model.selectDay(DateTime(2026, 10, 20));
    repository.requests[1].complete([]);
    await latest;
    repository.requests[0].completeError(StateError('offline'));
    await old;
    expect(model.value.status, ScheduleLoadStatus.ready);
    expect(model.value.error, isNull);
  });

  test('retry clears error and stale slots cannot be selected while loading',
      () async {
    final failed = model.selectDay(DateTime(2026, 10, 19));
    repository.requests[0].completeError(StateError('offline'));
    await failed;
    expect(model.value.error, isNotNull);
    final retry = model.selectDay(DateTime(2026, 10, 20));
    expect(model.value.selectedSlot, isNull);
    expect(model.value.commonSlots, isEmpty);
    repository.requests[1].complete([]);
    await retry;
    expect(model.value.error, isNull);
    expect(model.value.status, ScheduleLoadStatus.ready);
  });
  test(
      'cached schedule stays marked cached even when platform reports a connection',
      () async {
    model.dispose();
    model = ScheduleViewModel(
      ManageSchedule(repository, const AvailabilityService()),
      ImportGoogleCalendar(calendar, repository),
      authorizeGoogleCalendar: AuthorizeGoogleCalendar(calendar),
      isOffline: () => true,
    );
    final load = model.selectDay(DateTime(2026, 10, 20));
    repository.requests.single.complete([]);
    await load;
    expect(model.value.status, ScheduleLoadStatus.ready);
    expect(model.value.connectivityStatus, ScheduleConnectivityStatus.cached);
    expect(model.value.scheduleLastUpdatedAt, isNull);
  });

  test(
      'missing offline data clears previous slots instead of inventing availability',
      () async {
    final first = model.selectDay(DateTime(2026, 10, 20));
    repository.requests.single.complete([]);
    await first;
    expect(model.value.commonSlots, isNotEmpty);
    final missing = model.selectDay(DateTime(2026, 10, 21));
    repository.requests.last.completeError(StateError('No saved schedule'));
    await missing;
    expect(model.value.status, ScheduleLoadStatus.error);
    expect(model.value.commonSlots, isEmpty);
    expect(model.value.selectedSlot, isNull);
  });
}

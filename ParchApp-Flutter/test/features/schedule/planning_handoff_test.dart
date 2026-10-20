import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/activities/domain/entities/planning_context.dart';
import 'package:parchapp/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:parchapp/features/schedule/domain/entities/schedule_block.dart';
import 'package:parchapp/features/schedule/domain/entities/schedule_friend.dart';
import 'package:parchapp/features/schedule/domain/repositories/calendar_import_repository.dart';
import 'package:parchapp/features/schedule/domain/services/availability_service.dart';
import 'package:parchapp/features/schedule/domain/use_cases/authorize_google_calendar.dart';
import 'package:parchapp/features/schedule/domain/use_cases/import_google_calendar.dart';
import 'package:parchapp/features/schedule/domain/use_cases/manage_schedule.dart';
import 'package:parchapp/features/schedule/presentation/view_models/schedule_view_model.dart';

class Schedule extends MockScheduleRepository implements PlanningSlotValidator {
  PlanningContext? received;
  Completer<PlanningContext>? delayed;
  @override
  Future<List<ScheduleFriend>> getFriends() async => const [
        ScheduleFriend(
            id: 'member',
            name: 'Camila',
            fullName: 'Camila Rojas',
            initials: 'CR')
      ];
  @override
  Future<List<ScheduleBlock>> getMySchedule({required DateTime day}) async =>
      [];
  @override
  Future<List<ScheduleBlock>> getFriendsBusyBlocks(
          {required DateTime day, required List<String> friendIds}) async =>
      [];
  @override
  Future<PlanningContext> validatePlanningSlot(PlanningContext context) async {
    received = context;
    return delayed?.future ??
        Future.value(PlanningContext.fromMap({
          ...context.toMap(),
          'participantIds': ['organizer', ...context.participantIds],
          'comparisonId': 'server-comparison'
        }));
  }
}

class Calendar implements CalendarImportRepository {
  @override
  Future<void> authorizeCalendar() async {}
  @override
  Future<List<ScheduleBlock>> importCalendar() async => [];
}

void main() {
  late Schedule repository;
  late ScheduleViewModel model;
  setUp(() {
    repository = Schedule();
    final calendar = Calendar();
    model = ScheduleViewModel(
        ManageSchedule(repository, const AvailabilityService()),
        ImportGoogleCalendar(calendar, repository),
        authorizeGoogleCalendar: AuthorizeGoogleCalendar(calendar),
        initialDay: DateTime(2030, 10, 2));
  });
  tearDown(() => model.dispose());
  test(
      'handoff retains selected participants, group, duration and Bogota instants',
      () async {
    await model.load();
    model.selectSlot(model.value.commonSlots.first);
    final plan = await model.preparePlan(groupId: 'group');
    expect(repository.received!.participantIds, ['member']);
    expect(plan.participantIds, ['organizer', 'member']);
    expect(plan.groupId, 'group');
    expect(plan.start, DateTime.utc(2030, 10, 2, 13));
    expect(plan.end, DateTime.utc(2030, 10, 2, 14));
    expect(plan.durationMinutes, model.value.meetingDuration.inMinutes);
    expect(plan.comparisonId, 'server-comparison');
    expect(plan.sourceSlotId, model.value.selectedSlot!.id);
  });
  test('late validation cannot open a draft for a different slot selection',
      () async {
    await model.load();
    model.selectSlot(model.value.commonSlots.first);
    repository.delayed = Completer<PlanningContext>();
    final pending = model.preparePlan(groupId: 'group');
    final assertion = expectLater(pending, throwsStateError);
    model.selectSlot(model.value.commonSlots[1]);
    repository.delayed!.complete(repository.received!);
    await assertion;
  });
}

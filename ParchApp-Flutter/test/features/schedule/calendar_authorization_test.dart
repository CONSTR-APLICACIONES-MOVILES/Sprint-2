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

class _Calendar implements CalendarImportRepository {
  final bool deny;
  final calls = <String>[];
  _Calendar({this.deny = false});

  @override
  Future<void> authorizeCalendar() async {
    calls.add('authorize');
    if (deny) throw StateError('Authorization declined');
  }

  @override
  Future<List<ScheduleBlock>> importCalendar() async {
    calls.add('import');
    return [
      ScheduleBlock(
        id: 'imported-event',
        start: DateTime(2026, 10, 15, 10),
        end: DateTime(2026, 10, 15, 11),
        type: ScheduleBlockType.personalEvent,
      ),
    ];
  }
}

void main() {
  for (final deny in [false, true]) {
    test(
        deny
            ? 'denied authorization prevents import'
            : 'authorizes before import', () async {
      final calendar = _Calendar(deny: deny);
      final schedule = MockScheduleRepository();
      final model = ScheduleViewModel(
        ManageSchedule(schedule, const AvailabilityService()),
        ImportGoogleCalendar(calendar, schedule),
        authorizeGoogleCalendar: AuthorizeGoogleCalendar(calendar),
        initialDay: DateTime(2026, 10, 15),
      );
      addTearDown(model.dispose);

      await model.importGoogleCalendar();

      expect(calendar.calls, deny ? ['authorize'] : ['authorize', 'import']);
      expect(model.value.calendarImportStatus,
          deny ? CalendarImportStatus.error : CalendarImportStatus.imported);
      final persisted =
          await schedule.getMySchedule(day: DateTime(2026, 10, 15));
      expect(persisted.any((block) => block.id == 'imported-event'), !deny);
    });
  }
}

import '../../domain/entities/schedule_block.dart';
import '../../domain/repositories/calendar_import_repository.dart';

import '../adapters/google_calendar_adapter.dart';
import '../data_sources/google_calendar_auth_data_source.dart';
import '../data_sources/google_calendar_data_source.dart';

class CalendarImportRepositoryImpl
    implements CalendarImportRepository {
  final GoogleCalendarDataSource dataSource;
  final GoogleCalendarAuthDataSource authDataSource;
  final GoogleCalendarAdapter adapter;

  const CalendarImportRepositoryImpl({
    required this.dataSource,
    required this.authDataSource,
    required this.adapter,
  });

  @override
  Future<void> authorizeCalendar() async {
    await authDataSource.authorizeCalendar();
  }

  @override
  Future<List<ScheduleBlock>> importCalendar() async {
    final events = await dataSource.importEvents();

    return events
        .map(
          adapter.toScheduleBlock,
        )
        .toList();
  }
}
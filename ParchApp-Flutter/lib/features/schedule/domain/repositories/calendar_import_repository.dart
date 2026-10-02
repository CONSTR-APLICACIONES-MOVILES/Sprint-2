import '../entities/schedule_block.dart';

abstract interface class CalendarImportRepository {
  Future<void> authorizeCalendar();

  Future<List<ScheduleBlock>> importCalendar();
}
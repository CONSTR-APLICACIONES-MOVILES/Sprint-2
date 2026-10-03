import '../repositories/calendar_import_repository.dart';
import '../repositories/schedule_repository.dart';

class ImportGoogleCalendar {
  final CalendarImportRepository _calendarRepository;
  final ScheduleRepository _scheduleRepository;

  const ImportGoogleCalendar(
    this._calendarRepository,
    this._scheduleRepository,
  );

  Future<int> call() async {
    final blocks =
        await _calendarRepository.importCalendar();

    await _scheduleRepository
        .replaceImportedCalendarBlocks(
      blocks,
    );

    return blocks.length;
  }
}
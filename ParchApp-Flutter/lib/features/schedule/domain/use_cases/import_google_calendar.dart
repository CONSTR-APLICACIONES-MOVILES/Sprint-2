import 'package:flutter/foundation.dart';

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
    debugPrint(
      'IMPORT FLOW 1 -> Starting Google Calendar import...',
    );

    final blocks =
        await _calendarRepository.importCalendar();

    debugPrint(
      'IMPORT FLOW 2 -> ${blocks.length} ScheduleBlocks created.',
    );

    debugPrint(
      'IMPORT FLOW 3 -> Starting Firestore persistence...',
    );

    await _scheduleRepository
        .replaceImportedCalendarBlocks(
      blocks,
    );

    debugPrint(
      'IMPORT FLOW 4 -> Firestore persistence completed.',
    );

    return blocks.length;
  }
}
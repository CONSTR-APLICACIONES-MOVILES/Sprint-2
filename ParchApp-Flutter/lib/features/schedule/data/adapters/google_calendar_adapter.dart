import '../../domain/entities/schedule_block.dart';
import '../models/google_calendar_event_model.dart';

class GoogleCalendarAdapter {
  const GoogleCalendarAdapter();

  ScheduleBlock toScheduleBlock(
    GoogleCalendarEventModel event,
  ) {
    return ScheduleBlock(
      id: 'google-${event.id}',
      start: event.start,
      end: event.end,
      type: ScheduleBlockType.personalEvent,
      title: event.title,
      subtitle: event.description,
      location: event.location,
    );
  }
}
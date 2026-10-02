import '../models/google_calendar_event_model.dart';

abstract interface class GoogleCalendarDataSource {
  Future<List<GoogleCalendarEventModel>> importEvents();
}
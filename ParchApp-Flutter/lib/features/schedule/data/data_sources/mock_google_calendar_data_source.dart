import 'google_calendar_data_source.dart';
import '../models/google_calendar_event_model.dart';

class MockGoogleCalendarDataSource implements GoogleCalendarDataSource {
  @override
  Future<List<GoogleCalendarEventModel>> importEvents() async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    return [
      GoogleCalendarEventModel(
        id: 'google-isis3510',
        title: 'ISIS3510',
        description: 'Mobile Application Development',
        location: 'ML 603',
        start: DateTime(2026, 10, 15, 10),
        end: DateTime(2026, 10, 15, 11, 30),
      ),
      GoogleCalendarEventModel(
        id: 'google-project-meeting',
        title: 'Project Meeting',
        location: 'SD 202',
        start: DateTime(2026, 10, 15, 14),
        end: DateTime(2026, 10, 15, 15),
      ),
    ];
  }
}
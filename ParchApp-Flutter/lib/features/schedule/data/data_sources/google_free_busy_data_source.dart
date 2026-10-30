import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/google_calendar_event_model.dart';
import 'google_calendar_data_source.dart';

/// Reads no event titles, descriptions, places or attendees from Google.
class GoogleFreeBusyDataSource implements GoogleCalendarDataSource {
  final Future<Map<String, String>> Function() headers;
  final http.Client Function() createClient;
  final DateTime Function() now;
  GoogleFreeBusyDataSource(
      {required this.headers,
      http.Client Function()? createClient,
      DateTime Function()? now})
      : createClient = createClient ?? http.Client.new,
        now = now ?? DateTime.now;

  @override
  Future<List<GoogleCalendarEventModel>> importEvents() async {
    final today = now().toUtc().subtract(const Duration(hours: 5));
    final start = DateTime.utc(today.year, today.month, today.day, 5);
    final end = start.add(const Duration(days: 56));
    final authHeaders = await headers();
    final client = createClient();
    try {
      final response = await client
          .post(
            Uri.parse('https://www.googleapis.com/calendar/v3/freeBusy'),
            headers: {...authHeaders, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'timeMin': start.toIso8601String(),
              'timeMax': end.toIso8601String(),
              'timeZone': 'America/Bogota',
              'items': [
                {'id': 'primary'}
              ]
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw StateError('Google Calendar import failed.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final calendars = data['calendars'] as Map<String, dynamic>;
      final calendar = calendars['primary'] ??
          (calendars.length == 1 ? calendars.values.single : null);
      if (calendar == null ||
          (calendar['errors'] as List?)?.isNotEmpty == true ||
          calendar['busy'] is! List) {
        throw StateError(
            'Google Calendar did not return complete availability.');
      }
      return [
        for (final block in calendar['busy'] as List)
          GoogleCalendarEventModel(
              id: '${block['start']}-${block['end']}',
              title: 'Busy',
              start: DateTime.parse(block['start'] as String),
              end: DateTime.parse(block['end'] as String))
      ];
    } finally {
      client.close();
    }
  }
}

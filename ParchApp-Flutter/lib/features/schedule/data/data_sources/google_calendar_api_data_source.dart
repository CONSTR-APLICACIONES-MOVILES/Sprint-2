import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart'
    as google_calendar;

import '../models/google_calendar_event_model.dart';
import 'google_calendar_auth_data_source.dart';
import 'google_calendar_data_source.dart';

class GoogleCalendarApiDataSource
    implements GoogleCalendarDataSource {
  final GoogleCalendarAuthDataSource
      authDataSource;

  const GoogleCalendarApiDataSource({
    required this.authDataSource,
  });

  @override
  Future<List<GoogleCalendarEventModel>>
      importEvents() async {
    final authorization =
        await authDataSource
            .getCalendarAuthorization();

    final client =
        authorization.authClient(
      scopes:
          GoogleCalendarAuthDataSource
              .calendarScopes,
    );

    try {
      final calendarApi =
          google_calendar.CalendarApi(
        client,
      );

      final importedEvents =
          <GoogleCalendarEventModel>[];

      String? pageToken;

      final timeMin =
          DateTime(
            2026,
            1,
            1,
          ).toUtc();

      final timeMax =
          DateTime(
            2027,
            1,
            1,
          ).toUtc();

      do {
        final response =
            await calendarApi.events.list(
          'primary',
          timeMin: timeMin,
          timeMax: timeMax,
          singleEvents: true,
          orderBy: 'startTime',
          showDeleted: false,
          maxResults: 2500,
          pageToken: pageToken,
        );

        final events =
            response.items ??
                const <
                    google_calendar.Event>[];

        for (final event in events) {
          final converted =
              _toModel(event);

          if (converted != null) {
            importedEvents.add(
              converted,
            );
          }
        }

        pageToken =
            response.nextPageToken;
      } while (
          pageToken != null &&
          pageToken.isNotEmpty);

      importedEvents.sort(
        (first, second) =>
            first.start.compareTo(
          second.start,
        ),
      );

      return importedEvents;
    } finally {
      client.close();
    }
  }

  GoogleCalendarEventModel? _toModel(
    google_calendar.Event event,
  ) {
    if (event.status == 'cancelled') {
      return null;
    }

    final id = event.id;

    if (id == null ||
        id.trim().isEmpty) {
      return null;
    }

    final start =
        event.start?.dateTime ??
            event.start?.date;

    final end =
        event.end?.dateTime ??
            event.end?.date;

    if (start == null ||
        end == null) {
      return null;
    }

    if (!end.isAfter(start)) {
      return null;
    }

    final rawTitle =
        event.summary?.trim();

    final title =
        rawTitle == null ||
                rawTitle.isEmpty
            ? 'Untitled event'
            : rawTitle;

    return GoogleCalendarEventModel(
      id: id,
      title: title,
      description:
          _cleanOptionalText(
        event.description,
      ),
      location:
          _cleanOptionalText(
        event.location,
      ),
      start: start.toLocal(),
      end: end.toLocal(),
    );
  }

  String? _cleanOptionalText(
    String? value,
  ) {
    final cleaned =
        value?.trim();

    if (cleaned == null ||
        cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }
}
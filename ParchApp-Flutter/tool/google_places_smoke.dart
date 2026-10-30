// Explicit live integration check: one autocomplete request and one details request.
// No Firebase user account or activity is created.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:parchapp/features/activities/data/data_sources/google_places_source.dart';
import 'package:parchapp/features/activities/domain/entities/activity_location.dart';
import 'package:parchapp/features/activities/presentation/views/location_picker_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const source = GooglePlacesSource();
  ActivityLocation? place;
  String status;
  final session = 'smoke${DateTime.now().microsecondsSinceEpoch}';
  try {
    if (!await source.isConfigured()) throw StateError('Maps not configured');
    final rows = await source.search(
        'Universidad de los Andes Bogotá', session, 4.601, -74.066);
    if (rows.isEmpty) throw StateError('No Google Places results');
    place = await source.details(rows.first.id, session);
    status = jsonEncode({
      'status': 'PASS',
      'source': 'Google Places Android SDK live',
      'results': rows.length,
      'location': place.toMap(),
    });
  } catch (error) {
    status = jsonEncode({'status': 'FAIL', 'errorType': error.runtimeType.toString()});
  } finally {
    await source.endSession(session);
  }
  debugPrint('GOOGLE_PLACES_SMOKE $status');
  runApp(MaterialApp(
      home: place == null
          ? Scaffold(body: Center(child: Text(status)))
          : LocationPickerView(initial: place, source: source)));
}

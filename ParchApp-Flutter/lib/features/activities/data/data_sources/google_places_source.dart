import 'package:flutter/services.dart';
import '../../../../core/platform/google_maps_availability.dart';
import '../../domain/entities/activity_location.dart';
import '../../domain/repositories/places_source.dart';

class GooglePlacesSource implements PlacesSource {
  static const channel = MethodChannel('parchapp/google_places');
  const GooglePlacesSource();
  @override
  Future<bool> isConfigured() async {
    return GoogleMapsAvailability.isConfigured();
  }

  @override
  Future<List<PlaceSuggestion>> search(
      String query, String session, double latitude, double longitude) async {
    final rows = await channel.invokeListMethod<Map>('search', {
          'query': query,
          'session': session,
          'latitude': latitude,
          'longitude': longitude
        }) ??
        [];
    return rows
        .map((r) => PlaceSuggestion(
            r['id'] as String, r['title'] as String, r['address'] as String))
        .toList();
  }

  @override
  Future<ActivityLocation> details(String id, String session) async {
    final data = await channel.invokeMapMethod<String, dynamic>(
        'details', {'id': id, 'session': session});
    final result = ActivityLocation.fromMap(data);
    if (result == null) {
      throw StateError('The place has no valid map location.');
    }
    return result;
  }

  @override
  Future<void> endSession(String session) =>
      channel.invokeMethod<void>('endSession', {'session': session});
}

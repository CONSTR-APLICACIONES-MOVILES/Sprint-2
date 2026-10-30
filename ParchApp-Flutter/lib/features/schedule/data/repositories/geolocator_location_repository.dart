import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_repository.dart';

class GeolocatorLocationRepository implements LocationRepository {
  const GeolocatorLocationRepository();

  @override
  Future<UserLocation> getCurrentLocation() async {
    // ==============================================================
    // 1. Verify that device location services are enabled
    // ==============================================================

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw StateError(
        'Location services are disabled. '
        'Enable GPS/location services to find nearby friends.',
      );
    }

    // ==============================================================
    // 2. Check permissions
    // ==============================================================

    var permission = await Geolocator.checkPermission();

    // ==============================================================
    // 3. Ask permission if necessary
    // ==============================================================

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw StateError(
        'Location permission was denied.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is permanently denied. '
        'Enable it from the device settings.',
      );
    }

    // ==============================================================
    // 4. Obtain current device position
    // ==============================================================

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    debugPrint(
      'GPS -> '
      'latitude=${position.latitude}, '
      'longitude=${position.longitude}',
    );

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

import 'dart:math' as math;

import '../entities/user_location.dart';

class DistanceService {
  const DistanceService();

  /// Calculates distance between two geographic points using
  /// the Haversine formula.
  ///
  /// Result is returned in meters.
  double distanceMeters(
    UserLocation a,
    UserLocation b,
  ) {
    const earthRadiusMeters = 6371000.0;

    final lat1 = _degreesToRadians(
      a.latitude,
    );

    final lat2 = _degreesToRadians(
      b.latitude,
    );

    final deltaLatitude = _degreesToRadians(
      b.latitude - a.latitude,
    );

    final deltaLongitude = _degreesToRadians(
      b.longitude - a.longitude,
    );

    final haversine = math.sin(
              deltaLatitude / 2,
            ) *
            math.sin(
              deltaLatitude / 2,
            ) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(
              deltaLongitude / 2,
            ) *
            math.sin(
              deltaLongitude / 2,
            );

    final angularDistance = 2 *
        math.atan2(
          math.sqrt(haversine),
          math.sqrt(
            1 - haversine,
          ),
        );

    return earthRadiusMeters * angularDistance;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees * math.pi / 180;
  }
}

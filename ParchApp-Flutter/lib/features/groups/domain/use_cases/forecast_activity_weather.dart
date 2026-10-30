import '../entities/active_group.dart';
import '../entities/weather_forecast.dart';
import '../repositories/weather_repository.dart';

class ForecastActivityWeather {
  static const campusLatitude = 4.6021;
  static const campusLongitude = -74.0654;
  static const _maxAhead = Duration(days: 7);
  static const _maxGap = Duration(minutes: 90);

  final WeatherRepository _weather;
  const ForecastActivityWeather(this._weather);

  Future<Map<String, WeatherForecast>> forGroups(
      List<ActiveGroup> groups, DateTime now) async {
    final result = <String, WeatherForecast>{};
    final byPlace = <String, Future<List<WeatherForecast>>>{};
    for (final group in groups) {
      final startsAt = group.activityStartsAt;
      if (startsAt == null ||
          !startsAt.isAfter(now) ||
          startsAt.difference(now) > _maxAhead) {
        continue;
      }
      final latitude = group.activityLatitude ?? campusLatitude;
      final longitude = group.activityLongitude ?? campusLongitude;
      final place =
          '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
      final hours = await byPlace.putIfAbsent(
          place, () => _weather.hourlyForecast(latitude, longitude));
      final match = closestHour(hours, startsAt);
      if (match != null) result[group.id] = match;
    }
    return Map.unmodifiable(result);
  }

  WeatherForecast? closestHour(List<WeatherForecast> hours, DateTime time) {
    WeatherForecast? best;
    for (final hour in hours) {
      final gap = hour.time.difference(time).abs();
      if (gap > _maxGap) continue;
      if (best == null || gap < best.time.difference(time).abs()) best = hour;
    }
    return best;
  }
}
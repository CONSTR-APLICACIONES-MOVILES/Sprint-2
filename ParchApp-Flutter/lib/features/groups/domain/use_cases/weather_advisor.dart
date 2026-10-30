import '../entities/activity_weather.dart';
import '../entities/weather_forecast.dart';

abstract final class WeatherAdvisor {
  static const _window = Duration(hours: 4);
  static const _minGain = 15;

  static ActivityWeather advise({
    required WeatherForecast current,
    required List<WeatherForecast> hours,
    required DateTime startsAt,
    required DateTime now,
    required bool outdoor,
  }) {
    if (!current.bad) return ActivityWeather(current);
    final day = startsAt.toLocal();
    WeatherForecast? best;
    var bestScore = score(current, startsAt, outdoor) + _minGain - 1;
    for (final hour in hours) {
      final local = hour.time.toLocal();
      if (local.year != day.year ||
          local.month != day.month ||
          local.day != day.day ||
          !hour.time.isAfter(now) ||
          hour.time.isAtSameMomentAs(current.time) ||
          hour.time.difference(startsAt).abs() > _window) {
        continue;
      }
      final value = score(hour, startsAt, outdoor);
      if (value > bestScore) {
        best = hour;
        bestScore = value;
      }
    }
    if (best == null) return ActivityWeather(current);
    return ActivityWeather(current,
        betterHour: best, reason: reasonFor(current, best, outdoor));
  }

  static int score(WeatherForecast hour, DateTime startsAt, bool outdoor) {
    var value = 100.0;
    value -= hour.rainChance * (outdoor ? 0.6 : 0.3);
    if (hour.stormy) value -= outdoor ? 50 : 15;
    if (outdoor) {
      value -= _discomfort(hour) * 2;
      if (!hour.isDay) value -= 20;
    }
    value -= hour.time.difference(startsAt).abs().inMinutes / 60 * 3;
    return value.clamp(0, 100).round();
  }

  static String reasonFor(
      WeatherForecast from, WeatherForecast to, bool outdoor) {
    final drier = from.rainChance - to.rainChance >= 20;
    final parts = <String>[
      if (from.stormy && !to.stormy) 'no storm',
      if (drier && to.rainChance < 30) 'dry' else if (drier) 'less rain',
      if (outdoor && !from.isDay && to.isDay) 'daylight',
      if (outdoor && _discomfort(to) + 3 <= _discomfort(from)) 'milder',
    ];
    return parts.isEmpty ? 'better weather' : parts.take(2).join(' and ');
  }

  static double _discomfort(WeatherForecast hour) => hour.temperature < 14
      ? 14 - hour.temperature
      : hour.temperature > 24
          ? hour.temperature - 24
          : 0;
}
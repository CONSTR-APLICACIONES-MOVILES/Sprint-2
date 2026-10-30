import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/weather_forecast.dart';
import '../../domain/repositories/weather_repository.dart';

class CachedWeatherRepository implements WeatherRepository {
  static const fresh = Duration(hours: 1);
  static const usable = Duration(hours: 24);

  final WeatherRepository _remote;
  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _now;
  final Map<String, List<WeatherForecast>> _memory = {};

  CachedWeatherRepository(this._remote, this._preferences,
      {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  @override
  Future<List<WeatherForecast>> hourlyForecast(
      double latitude, double longitude) async {
    final key =
        'weather.v1.${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
    final saved = _memory[key] ?? await _read(key);
    if (saved != null && _age(saved) < fresh) return saved;
    try {
      final hours = await _remote.hourlyForecast(latitude, longitude);
      _memory[key] = hours;
      await _write(key, hours);
      return hours;
    } catch (_) {
      if (saved != null && _age(saved) < usable) return saved;
      rethrow;
    }
  }

  Duration _age(List<WeatherForecast> hours) {
    final fetchedAt = hours.isEmpty ? null : hours.first.fetchedAt;
    return fetchedAt == null ? usable : _now().difference(fetchedAt);
  }

  Future<List<WeatherForecast>?> _read(String key) async {
    try {
      final raw = (await _preferences()).getString(key);
      if (raw == null) return null;
      final rows = jsonDecode(raw);
      if (rows is! List) return null;
      final hours = List<WeatherForecast>.unmodifiable(
          rows.map(_decode).whereType<WeatherForecast>());
      _memory[key] = hours;
      return hours;
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, List<WeatherForecast> hours) async {
    try {
      await (await _preferences())
          .setString(key, jsonEncode(hours.map(_encode).toList()));
    } catch (_) {}
  }
}

Map<String, Object?> _encode(WeatherForecast hour) => {
      'time': hour.time.toIso8601String(),
      'temperature': hour.temperature,
      'rain': hour.rainChance,
      'code': hour.weatherCode,
      'day': hour.isDay,
      'fetchedAt': hour.fetchedAt?.toIso8601String(),
    };

WeatherForecast? _decode(Object? row) {
  if (row is! Map) return null;
  final time = DateTime.tryParse('${row['time']}');
  final temperature = row['temperature'];
  final rain = row['rain'];
  final code = row['code'];
  if (time == null || temperature is! num || rain is! num || code is! num) {
    return null;
  }
  return WeatherForecast(
      time: time,
      temperature: temperature.toDouble(),
      rainChance: rain.toInt(),
      weatherCode: code.toInt(),
      isDay: row['day'] != false,
      fetchedAt: DateTime.tryParse('${row['fetchedAt']}'));
}
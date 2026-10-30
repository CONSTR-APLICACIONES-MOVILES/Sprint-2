import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/weather_forecast.dart';
import '../../domain/repositories/weather_repository.dart';

class OpenMeteoWeatherRepository implements WeatherRepository {
  final http.Client _client;

  OpenMeteoWeatherRepository([http.Client? client])
      : _client = client ?? http.Client();

  @override
  Future<List<WeatherForecast>> hourlyForecast(
      double latitude, double longitude) async {
    final url = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'hourly':
          'temperature_2m,precipitation_probability,weather_code,is_day',
      'timezone': 'GMT',
      'forecast_days': '7',
    });
    final response =
        await _client.get(url).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw StateError('Weather is unavailable right now.');
    }
    return parseHourlyForecast(jsonDecode(response.body));
  }
}

List<WeatherForecast> parseHourlyForecast(Object? data) {
  final hourly = data is Map ? data['hourly'] : null;
  if (hourly is! Map) return const [];
  final times = hourly['time'];
  final temperatures = hourly['temperature_2m'];
  final rain = hourly['precipitation_probability'];
  final codes = hourly['weather_code'];
  final days = hourly['is_day'];
  if (times is! List ||
      temperatures is! List ||
      rain is! List ||
      codes is! List) {
    return const [];
  }
  final result = <WeatherForecast>[];
  for (var i = 0;
      i < times.length &&
          i < temperatures.length &&
          i < rain.length &&
          i < codes.length;
      i++) {
    final time = DateTime.tryParse('${times[i]}Z');
    final temperature = temperatures[i];
    final chance = rain[i];
    final code = codes[i];
    if (time == null || temperature is! num || chance is! num || code is! num) {
      continue;
    }
    result.add(WeatherForecast(
        time: time,
        temperature: temperature.toDouble(),
        rainChance: chance.toInt(),
        weatherCode: code.toInt(),
        isDay: days is List && i < days.length ? days[i] != 0 : true));
  }
  return List.unmodifiable(result);
}
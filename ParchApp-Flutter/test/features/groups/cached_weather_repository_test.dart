import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/groups/data/repositories/cached_weather_repository.dart';
import 'package:parchapp/features/groups/domain/entities/weather_forecast.dart';
import 'package:parchapp/features/groups/domain/repositories/weather_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Remote implements WeatherRepository {
  int calls = 0;
  bool offline = false;
  DateTime fetchedAt = DateTime(2026, 10, 30, 8);

  @override
  Future<List<WeatherForecast>> hourlyForecast(
      double latitude, double longitude) async {
    calls++;
    if (offline) throw StateError('offline');
    return [
      WeatherForecast(
          time: DateTime.utc(2026, 10, 30, 23),
          temperature: 17,
          rainChance: 30,
          weatherCode: 3,
          fetchedAt: fetchedAt),
    ];
  }
}

void main() {
  late _Remote remote;
  late DateTime now;

  CachedWeatherRepository build() => CachedWeatherRepository(
      remote, SharedPreferences.getInstance,
      now: () => now);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    remote = _Remote();
    now = DateTime(2026, 10, 30, 8, 10);
  });

  test('a fresh forecast is reused without calling the network', () async {
    final cache = build();
    await cache.hourlyForecast(4.6021, -74.0654);
    await cache.hourlyForecast(4.6021, -74.0654);
    expect(remote.calls, 1);
  });

  test('an old forecast is downloaded again', () async {
    final cache = build();
    await cache.hourlyForecast(4.6021, -74.0654);
    now = DateTime(2026, 10, 30, 9, 30);
    await cache.hourlyForecast(4.6021, -74.0654);
    expect(remote.calls, 2);
  });

  test('offline it falls back to the saved copy', () async {
    await build().hourlyForecast(4.6021, -74.0654);
    remote.offline = true;
    now = DateTime(2026, 10, 30, 12);
    final hours = await build().hourlyForecast(4.6021, -74.0654);
    expect(hours.single.rainChance, 30);
    expect(hours.single.fetchedAt, DateTime(2026, 10, 30, 8));
  });

  test('the saved copy survives an app restart', () async {
    await build().hourlyForecast(4.6021, -74.0654);
    final restarted = build();
    await restarted.hourlyForecast(4.6021, -74.0654);
    expect(remote.calls, 1);
  });

  test('offline without a recent copy the error is kept', () async {
    await build().hourlyForecast(4.6021, -74.0654);
    remote.offline = true;
    now = DateTime(2026, 11, 1, 9);
    expect(() => build().hourlyForecast(4.6021, -74.0654), throwsStateError);
  });
}
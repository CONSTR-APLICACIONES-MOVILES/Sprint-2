import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/groups/data/repositories/open_meteo_weather_repository.dart';
import 'package:parchapp/features/groups/domain/entities/active_group.dart';
import 'package:parchapp/features/groups/domain/entities/weather_forecast.dart';
import 'package:parchapp/features/groups/domain/repositories/active_groups_repository.dart';
import 'package:parchapp/features/groups/domain/repositories/weather_repository.dart';
import 'package:parchapp/features/groups/domain/use_cases/forecast_activity_weather.dart';
import 'package:parchapp/features/groups/domain/use_cases/manage_active_groups.dart';
import 'package:parchapp/features/groups/presentation/view_models/active_groups_view_model.dart';

class _FakeWeather implements WeatherRepository {
  final List<WeatherForecast> hours;
  final List<String> places = [];
  bool fail = false;
  _FakeWeather(this.hours);

  @override
  Future<List<WeatherForecast>> hourlyForecast(
      double latitude, double longitude) async {
    places.add('$latitude,$longitude');
    if (fail) throw StateError('offline');
    return hours;
  }
}

class _Groups implements ActiveGroupsRepository {
  final List<ActiveGroup> groups;
  _Groups(this.groups);

  @override
  Future<List<ActiveGroup>> getActiveGroups() async => groups;
  @override
  Future<List<ActiveGroup>> confirmRsvp(String id) async => groups;
  @override
  Future<List<ActiveGroup>> dropIn(String id) async => groups;
}

ActiveGroup _group(String id,
        {DateTime? startsAt, double? latitude, double? longitude}) =>
    ActiveGroup(
      id: id,
      name: id,
      category: GroupCategory.sports,
      memberCount: 4,
      subtitle: 'Shared group',
      statusText: '',
      tone: GroupTone.info,
      detail: '',
      primaryAction: GroupAction.viewDetails,
      secondaryAction: GroupAction.viewSchedule,
      activityStartsAt: startsAt,
      activityLatitude: latitude,
      activityLongitude: longitude,
    );

void main() {
  final now = DateTime.utc(2026, 10, 30, 12);
  final hours = [
    WeatherForecast(
        time: DateTime.utc(2026, 10, 30, 17),
        temperature: 18.4,
        rainChance: 20,
        weatherCode: 2),
    WeatherForecast(
        time: DateTime.utc(2026, 10, 30, 18),
        temperature: 16.6,
        rainChance: 70,
        weatherCode: 61),
  ];

  test('reads the Open-Meteo hourly response', () {
    final forecast = parseHourlyForecast({
      'hourly': {
        'time': ['2026-10-30T18:00', 'not a date'],
        'temperature_2m': [16.6, 10],
        'precipitation_probability': [70, 5],
        'weather_code': [61, 0],
      }
    });
    expect(forecast, hasLength(1));
    expect(forecast.single.time, DateTime.utc(2026, 10, 30, 18));
    expect(forecast.single.label, 'Rain · 17°C · 70% rain');
    expect(forecast.single.rainLikely, isTrue);
  });

  test('each upcoming activity gets the hour closest to its start', () async {
    final weather = _FakeWeather(hours);
    final result = await ForecastActivityWeather(weather).forGroups([
      _group('football', startsAt: DateTime.utc(2026, 10, 30, 18, 20)),
      _group('study', startsAt: DateTime.utc(2026, 10, 30, 16, 50)),
    ], now);
    expect(result['football']!.rainChance, 70);
    expect(result['study']!.rainChance, 20);
    expect(weather.places, ['4.6021,-74.0654']);
  });

  test('the activity place is used when it has one', () async {
    final weather = _FakeWeather(hours);
    await ForecastActivityWeather(weather).forGroups([
      _group('football',
          startsAt: DateTime.utc(2026, 10, 30, 18),
          latitude: 4.65,
          longitude: -74.1),
    ], now);
    expect(weather.places, ['4.65,-74.1']);
  });

  test('past, distant and unscheduled activities get no forecast', () async {
    final result = await ForecastActivityWeather(_FakeWeather(hours)).forGroups([
      _group('past', startsAt: now.subtract(const Duration(hours: 1))),
      _group('far', startsAt: now.add(const Duration(days: 10))),
      _group('none'),
      _group('no-hour', startsAt: DateTime.utc(2026, 10, 31, 9)),
    ], now);
    expect(result, isEmpty);
  });

  test('the cards still load when the weather service fails', () async {
    final weather = _FakeWeather(hours)..fail = true;
    final model = ActiveGroupsViewModel(
        ManageActiveGroups(_Groups(
            [_group('football', startsAt: DateTime.utc(2026, 10, 30, 18))])),
        weather: ForecastActivityWeather(weather),
        now: () => now);
    await model.load();
    expect(model.value.groups, hasLength(1));
    expect(model.value.weather, isEmpty);
    expect(model.value.error, isNull);
    model.dispose();
  });

  test('the view model gives each card its forecast', () async {
    final model = ActiveGroupsViewModel(
        ManageActiveGroups(_Groups(
            [_group('football', startsAt: DateTime.utc(2026, 10, 30, 18))])),
        weather: ForecastActivityWeather(_FakeWeather(hours)),
        now: () => now);
    await model.load();
    expect(model.value.weatherFor(model.value.groups.single)?.rainChance, 70);
    model.dispose();
  });
}
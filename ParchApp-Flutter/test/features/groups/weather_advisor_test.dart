import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/groups/domain/entities/weather_forecast.dart';
import 'package:parchapp/features/groups/domain/use_cases/weather_advisor.dart';

WeatherForecast _hour(int hour,
        {int rain = 10,
        int code = 2,
        double temperature = 18,
        bool isDay = true}) =>
    WeatherForecast(
        time: DateTime(2026, 10, 30, hour),
        temperature: temperature,
        rainChance: rain,
        weatherCode: code,
        isDay: isDay);

void main() {
  final startsAt = DateTime(2026, 10, 30, 18);
  final rainyEvening = _hour(18, rain: 70, code: 61, temperature: 16, isDay: false);

  test('good weather needs no advice', () {
    final advice = WeatherAdvisor.advise(
        current: _hour(18),
        hours: [_hour(15), _hour(18)],
        startsAt: startsAt,
        now: DateTime(2026, 10, 30, 9),
        outdoor: true);
    expect(advice.betterHour, isNull);
    expect(advice.noBetterTime, isFalse);
  });

  test('a dry daylight hour is suggested for an outdoor plan', () {
    final advice = WeatherAdvisor.advise(
        current: rainyEvening,
        hours: [_hour(15), _hour(16, rain: 20), rainyEvening],
        startsAt: startsAt,
        now: DateTime(2026, 10, 30, 9),
        outdoor: true);
    expect(advice.betterHour?.time, DateTime(2026, 10, 30, 15));
    expect(advice.reason, 'dry and daylight');
  });

  test('when it rains all afternoon there is no better time', () {
    final advice = WeatherAdvisor.advise(
        current: rainyEvening,
        hours: [
          _hour(15, rain: 80, code: 61),
          _hour(16, rain: 75, code: 61),
          rainyEvening,
        ],
        startsAt: startsAt,
        now: DateTime(2026, 10, 30, 9),
        outdoor: true);
    expect(advice.betterHour, isNull);
    expect(advice.noBetterTime, isTrue);
  });

  test('hours that already passed are never suggested', () {
    final advice = WeatherAdvisor.advise(
        current: rainyEvening,
        hours: [_hour(15), _hour(16), rainyEvening],
        startsAt: startsAt,
        now: DateTime(2026, 10, 30, 16, 30),
        outdoor: true);
    expect(advice.betterHour, isNull);
  });

  test('a study plan indoors is not moved for a small gain', () {
    final advice = WeatherAdvisor.advise(
        current: rainyEvening,
        hours: [_hour(15), rainyEvening],
        startsAt: startsAt,
        now: DateTime(2026, 10, 30, 9),
        outdoor: false);
    expect(advice.betterHour, isNull);
    expect(advice.noBetterTime, isTrue);
  });

  test('a storm-free hour explains that the storm is avoided', () {
    final storm = _hour(18, rain: 40, code: 95);
    final advice = WeatherAdvisor.advise(
        current: storm,
        hours: [_hour(17, rain: 20, code: 3), storm],
        startsAt: startsAt,
        now: DateTime(2026, 10, 30, 9),
        outdoor: true);
    expect(advice.betterHour?.time, DateTime(2026, 10, 30, 17));
    expect(advice.reason, startsWith('no storm'));
  });
}
import 'weather_forecast.dart';

class ActivityWeather {
  final WeatherForecast forecast;
  final WeatherForecast? betterHour;
  final String? reason;

  const ActivityWeather(this.forecast, {this.betterHour, this.reason});

  bool get noBetterTime => forecast.bad && betterHour == null;
}
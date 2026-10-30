import '../entities/weather_forecast.dart';

abstract interface class WeatherRepository {
  Future<List<WeatherForecast>> hourlyForecast(
      double latitude, double longitude);
}
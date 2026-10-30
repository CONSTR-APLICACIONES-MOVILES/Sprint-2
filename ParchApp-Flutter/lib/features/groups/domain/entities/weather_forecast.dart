class WeatherForecast {
  final DateTime time;
  final double temperature;
  final int rainChance;
  final int weatherCode;

  const WeatherForecast({
    required this.time,
    required this.temperature,
    required this.rainChance,
    required this.weatherCode,
  });

  bool get rainLikely => rainChance >= 50;

  String get sky => switch (weatherCode) {
        0 => 'Clear',
        1 || 2 => 'Partly cloudy',
        3 => 'Cloudy',
        45 || 48 => 'Fog',
        >= 51 && <= 67 => 'Rain',
        >= 80 && <= 82 => 'Showers',
        >= 95 => 'Storm',
        _ => 'Mixed',
      };

  String get label => '$sky · ${temperature.round()}°C · $rainChance% rain';
}

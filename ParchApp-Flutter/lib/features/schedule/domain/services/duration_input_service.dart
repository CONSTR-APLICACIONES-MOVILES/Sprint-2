class DurationInputService {
  static const int minMinutes = 5;
  static const int maxMinutes = 240;

  const DurationInputService();

  /// Acepta:
  ///
  /// 90
  /// 90m
  /// 1:30
  /// 1h
  /// 1h30
  /// 1h 30m
  int? parse(String input) {
    var value = input
        .trim()
        .toLowerCase()
        .replaceAll(' ', '');

    if (value.isEmpty) {
      return null;
    }

    // ============================================================
    // SOLO MINUTOS
    // Ejemplos:
    // 90
    // 90m
    // ============================================================

    if (value.endsWith('m')) {
      value = value.substring(
        0,
        value.length - 1,
      );
    }

    final onlyMinutes = int.tryParse(value);

    if (onlyMinutes != null) {
      return _validate(onlyMinutes);
    }

    // ============================================================
    // FORMATO HORA:MINUTOS
    // Ejemplo:
    // 1:30
    // 2:15
    // ============================================================

    if (value.contains(':')) {
      final parts = value.split(':');

      if (parts.length != 2) {
        return null;
      }

      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);

      if (hours == null ||
          minutes == null ||
          minutes < 0 ||
          minutes >= 60) {
        return null;
      }

      return _validate(
        hours * 60 + minutes,
      );
    }

    // ============================================================
    // FORMATO CON H
    // Ejemplos:
    // 1h
    // 1h30
    // 1h30m
    // ============================================================

    if (value.contains('h')) {
      final parts = value.split('h');

      if (parts.length != 2) {
        return null;
      }

      final hours = int.tryParse(parts[0]);

      if (hours == null) {
        return null;
      }

      var minutePart = parts[1];

      if (minutePart.endsWith('m')) {
        minutePart = minutePart.substring(
          0,
          minutePart.length - 1,
        );
      }

      final minutes = minutePart.isEmpty
          ? 0
          : int.tryParse(minutePart);

      if (minutes == null ||
          minutes < 0 ||
          minutes >= 60) {
        return null;
      }

      return _validate(
        hours * 60 + minutes,
      );
    }

    return null;
  }

  int? _validate(int minutes) {
    if (minutes < minMinutes ||
        minutes > maxMinutes) {
      return null;
    }

    return minutes;
  }

  String formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}m';
  }

  String formatDuration(Duration duration) {
    return formatMinutes(
      duration.inMinutes,
    );
  }
}
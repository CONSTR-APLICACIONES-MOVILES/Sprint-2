enum EstimateKind {
  allResponded,

  perResponse,
}

class ResponseTimeEstimate {
  final int groupSize;
  final double minutes;
  final EstimateKind kind;

  const ResponseTimeEstimate({
    required this.groupSize,
    required this.minutes,
    required this.kind,
  });

  Duration get duration => Duration(seconds: (minutes * 60).round());

  String get durationLabel {
    if (minutes < 60) return '${minutes.round().clamp(1, 59)} min';
    if (minutes < 24 * 60) return '${_half(minutes / 60)} h';
    final days = _half(minutes / (24 * 60));
    return days == '1' ? '1 day' : '$days days';
  }

  static String _half(double value) {
    final rounded = (value * 2).round() / 2;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }
}

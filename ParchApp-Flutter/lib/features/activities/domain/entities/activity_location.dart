class ActivityLocation {
  final double latitude, longitude;
  final String label;
  final String? placeId;
  const ActivityLocation(
      {required this.latitude,
      required this.longitude,
      required this.label,
      this.placeId});
  ActivityLocation validated() {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        label.trim().isEmpty ||
        label.length > 500 ||
        (placeId != null && (placeId!.isEmpty || placeId!.length > 300))) {
      throw const FormatException('Choose a valid place on the map.');
    }
    return this;
  }

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'label': label,
        if (placeId != null) 'placeId': placeId
      };
  static ActivityLocation? fromMap(dynamic data, {String? expectedLabel}) {
    if (data is! Map) return null;
    try {
      final result = ActivityLocation(
              latitude: (data['latitude'] as num).toDouble(),
              longitude: (data['longitude'] as num).toDouble(),
              label: data['label'] as String,
              placeId: data['placeId'] as String?)
          .validated();
      return expectedLabel != null && result.label != expectedLabel
          ? null
          : result;
    } catch (_) {
      return null;
    }
  }

  Uri get mapsUrl => Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '$latitude,$longitude',
        if (placeId != null) 'query_place_id': placeId!
      });
  @override
  bool operator ==(Object other) =>
      other is ActivityLocation &&
      latitude == other.latitude &&
      longitude == other.longitude &&
      label == other.label &&
      placeId == other.placeId;
  @override
  int get hashCode => Object.hash(latitude, longitude, label, placeId);
}

class UserLocation {
  final double latitude;
  final double longitude;

  const UserLocation({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() {
    return 'UserLocation('
        'latitude: $latitude, '
        'longitude: $longitude'
        ')';
  }
}

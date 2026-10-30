import '../entities/user_location.dart';

abstract interface class LocationRepository {
  Future<UserLocation> getCurrentLocation();
}

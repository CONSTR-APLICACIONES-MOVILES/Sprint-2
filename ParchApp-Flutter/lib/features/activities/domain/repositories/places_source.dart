import '../entities/activity_location.dart';

class PlaceSuggestion {
  final String id, title, address;
  const PlaceSuggestion(this.id, this.title, this.address);
}

abstract interface class PlacesSource {
  Future<bool> isConfigured();
  Future<List<PlaceSuggestion>> search(
      String query, String session, double latitude, double longitude);
  Future<ActivityLocation> details(String id, String session);
  Future<void> endSession(String session);
}

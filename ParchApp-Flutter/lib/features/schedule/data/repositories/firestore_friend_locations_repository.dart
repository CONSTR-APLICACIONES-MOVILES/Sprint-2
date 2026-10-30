import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_location.dart';

class FirestoreFriendLocationsRepository {
  final FirebaseFirestore firestore;
  const FirestoreFriendLocationsRepository({required this.firestore});

  Future<Map<String, UserLocation>> getFriendLocations({
    required List<String> friendIds,
  }) async {
    if (friendIds.isEmpty) {
      debugPrint(
        'FRIEND LOCATIONS -> No friend IDs received',
      );

      return const {};
    }

    debugPrint(
      'FRIEND LOCATIONS -> '
      'Loading ${friendIds.length} locations',
    );

    final result = <String, UserLocation>{};

    for (final friendId in friendIds) {
      debugPrint(
        'FRIEND LOCATIONS -> '
        'Reading locations/$friendId',
      );

      final snapshot =
          await firestore.collection('locations').doc(friendId).get();

      if (!snapshot.exists) {
        debugPrint(
          'FRIEND LOCATIONS -> '
          'No location document for $friendId',
        );

        continue;
      }

      final data = snapshot.data();

      if (data == null) {
        continue;
      }

      final rawLocation = data['location'];

      if (rawLocation is! GeoPoint) {
        debugPrint(
          'FRIEND LOCATIONS -> '
          '$friendId does not contain a valid GeoPoint',
        );

        continue;
      }

      final location = UserLocation(
        latitude: rawLocation.latitude,
        longitude: rawLocation.longitude,
      );

      result[friendId] = location;

      debugPrint(
        'FRIEND LOCATIONS -> '
        '$friendId = '
        '${location.latitude}, '
        '${location.longitude}',
      );
    }

    debugPrint(
      'FRIEND LOCATIONS -> '
      '${result.length} valid locations loaded',
    );

    return result;
  }
}
